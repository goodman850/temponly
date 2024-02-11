import os
import json
import subprocess
import requests
import logging
import logging.config

logging.config.fileConfig('loggerConfig.ini')
Logger = logging.getLogger('logger')

class XrayTrafficUpdater:
    def __init__(self, config_path, traffic_path, dcp_path):
        self.config_path = config_path
        self.traffic_path = traffic_path
        self.dcp_path = dcp_path

    def read_file(self, file_path):
        with open(file_path, "r") as file:
            return file.read()

    def read_json_file(self, file_path):
        with open(file_path, "r") as file:
            if os.path.getsize(file_path) == 0:
                return {}
            else:
                return json.load(file)

    def write_json_file(self, file_path, data):
        with open(file_path, "w") as file:
            json.dump(data, file, indent=2)

    def send_request(self):
        address = f"https://{self.read_file('/var/www/html/p/log/ip')}/apiV1/api.php"
        data = {'token': self.read_file('/var/www/html/p/log/token'), 'method': 'multiserver1'}
        res = requests.post(address, data=data)
        return json.loads(res.text)

    def send_traffic(self, traff):
        address = f"https://{self.read_file('/var/www/html/p/log/ip')}/apiV1/api.php"
        traff_json = json.dumps(traff)
        data = {'token': self.read_file('/var/www/html/p/log/token'), 'method': 'syncdatausagev2ry', 'trafficUsages': traff_json}
        res = requests.post(address, data=data)
        return json.loads(res.text)

    def read_xray_config(self):
        with open(self.config_path, "r") as file:
            return json.load(file)

    def write_xray_config(self, xray_config):
        with open(self.config_path, "w") as file:
            json.dump(xray_config, file, indent=2)

    def restart_xray_service(self):
        os.system('systemctl restart xray')

def main():
    config_path = "/etc/xray/config.json"
    traffic_path = "/var/www/html/p/log/das"
    dcp_path = "/var/www/html/p/log/dcp"

    updater = XrayTrafficUpdater(config_path, traffic_path, dcp_path)

    if not os.path.exists(traffic_path) or os.path.getsize(traffic_path) == 0:
        updater.write_json_file(traffic_path, {"inbound": 0, "api": {}})
        print(f"File did not exist or was empty and has been created.")
    else:
        print(f"File already exists and is not empty.")

    print("Starting...")
    print("Sending request...")
    config = updater.send_request()
    print("Reading xray config...")
    xray_config = updater.read_xray_config()
    new_xray_config = updater.read_xray_config()
    print("Replacing....")
    
    for i in range(len(xray_config["inbounds"])):
        if xray_config["inbounds"][i]["protocol"] == "vless":
            if xray_config["inbounds"][i]["streamSettings"]["security"] == "tls":
                new_xray_config["inbounds"][i]["settings"]["clients"] = config["usersdata"]["VLESSTLS"]
                new_xray_config["inbounds"][i]["port"] = config["ports"]["VLESSTLS"]
            if xray_config["inbounds"][i]["streamSettings"]["security"] == "none":
                new_xray_config["inbounds"][i]["settings"]["clients"] = config["usersdata"]["VLESS"]
                new_xray_config["inbounds"][i]["port"] = config["ports"]["VLESS"]
            if(xray_config["inbounds"][i]["streamSettings"]["security"] == "reality"):
                new_xray_config["inbounds"][i]["settings"]["clients"] = config["usersdata"]["VLESSREALITY"]
                new_xray_config["inbounds"][i]["port"] = config["ports"]["VLESSREALITY"]
                new_xray_config["inbounds"][i]["streamSettings"]["realitySettings"]["privateKey"] = config["ports"]["PK"]
                new_xray_config["inbounds"][i]["streamSettings"]["realitySettings"]["shortIds"] = config["ports"]["SHORTS"]

    if "inbounds" in xray_config and "inbounds" in new_xray_config:
        if xray_config["inbounds"] != new_xray_config["inbounds"]:
            print("Writing file....")
            updater.write_xray_config(new_xray_config)
            updater.restart_xray_service()

    print("xray api statsquery...")
    command = "xray api statsquery --server=127.0.0.1:10085"
    output = subprocess.check_output(command, shell=True, text=True)
    data = json.loads(output)


    stats_received = [stat for stat in data["stat"]]
    try:
        user_last_data = updater.read_json_file(traffic_path)
    except:
        file = open("das","r")
        text = file.read()
        file.close()
        if(len(text)>3 and text[len(text)-3:len(text)-1] == "}}"):
            newfile = open("das","w")
            newfile.write(text[:len(text)-2]+"\n")
            newfile.close()
            user_last_data = updater.read_json_file(traffic_path)

    user_usage = {}
    buffer = {}
    reseted = False

    for user_stat in stats_received:
        if user_stat["name"] == "inbound>>>api>>>traffic>>>downlink":
            if int(user_stat["value"]) < int(user_last_data["inbound"]) or int(user_last_data["inbound"]) == 0:
                reseted = True
            user_last_data["inbound"] = int(user_stat["value"])

    for user_stat in stats_received:
        if user_stat["name"].find("user>>>") != -1:
            username = user_stat["name"].split(">>>")[1].split("@")[0]
            if username in user_usage:
                continue
            else:
                user_usage[username] = {"TX": 0, "RX": 0}
                buffer[username] = {"TX": 0, "RX": 0}
            for user_atall in stats_received:
                if user_atall["name"].find(username) != -1:
                    if user_atall["name"].split(">>>")[3] == "downlink":
                        user_usage[username]["RX"] += int(user_atall["value"])
                        buffer[username]["RX"] += int(user_atall["value"])
                    if user_atall["name"].split(">>>")[3] == "uplink":
                        user_usage[username]["TX"] += int(user_atall["value"])
                        buffer[username]["TX"] += int(user_atall["value"])
            if username not in user_last_data["users"]:
                user_last_data["users"][username] = {"TX": 0, "RX": 0}
            if not reseted:
                user_usage[username]["RX"] -= int(user_last_data["users"][username]["RX"])
                user_usage[username]["TX"] -= int(user_last_data["users"][username]["TX"])

    user_last_data["users"] = buffer
    updater.send_traffic(user_usage)
    updater.write_json_file(traffic_path, user_last_data)

    print("Done")

if __name__ == "__main__":
    main()
