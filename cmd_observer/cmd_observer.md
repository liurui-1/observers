# Monitoring user commands on Linux systems

## Introduction

The security and reliability of I/T systems has always been an important topic. For example, users have Linux servers for production or important development projects. And the server is usually a multi-user system, some negligent operations or malicious operations may cause serious damage to the systems of the enterprise or organization.

Monitoring all user commands on Linux systems is an important means of ensuring system security and reliability. Even if the wrong commands cannot be stopped immediately, this monitoring can be of great help in finding the cause of the problem and reducing the time for system recovery. Related requirements include:
- Monitors all system commands entered by the user manually or via scripts.
- All commands are logged regardless of what shell the user is using (e.g. bash, dash, etc.).
- The collected commands are provided centrally in the form of security logs. This makes it easy to collect and centralize security logs to the system's security log server in a timely manner. It is also convenient to add security settings.
- Optionally, instead of security logs, user commands can be sent directly to a centralized security server.

The name of the solution I provide here is called ["cmd_observer"](https://github.com/liurui-software/observers/tree/main/cmd_observer). you can click to see the address of the open source project and code. You can see that the code is very simple and it uses two main open source projects:
- ["bpftrace"](https://github.com/bpftrace/bpftrace) is an excellent and powerful eBPF based scripting tool for tracing Linux systems.
- ["mmlog"](https://github.com/liurui-software/mmlog) is a simple logging tool I made.

## Installation & Running

1) First, install “bpftrace”. Please refer to the documentation for the installation procedure.
For Ubuntu 19.04 or later, you can use the following command:
```script
sudo apt-get install -y bpftrace
```

2) The next step is to install “mmlog”. This tool is very simple, and for Linux, you can download the distribution binary directly with the following command:
```script
wget https://github.com/liurui-software/mmlog/releases/download/v0.7.0/mmlog
```
**Note:** You must put mmlog in the PATH, I run the following command:
```script
chmod +x mmlog
mv mmlog /usr/bin/
```

3) The next step is to download the “cmd_observer.sh”, here is the command:
```script
wget https://raw.githubusercontent.com/liurui-software/observers/refs/heads/main/cmd_observer/cmd_observer.sh
```
Then set it to be executable:
```script
chmod +x cmd_observer.sh
```

4) Test the “cmd_observer” you just installed:
```script
sudo . /cmd_observer.sh
```
Observe the user commands with the following command:
```script
tail -F /var/log/cmd_observer.log
```
Here is a snippet of the log:
```log
2025-02-10T14:39:22Z Attaching 1 probe...
2025-02-10T14:39:26Z liurui:16637(/usr/bin/tail) tail -F /var/log/cmd_observer.log
2025-02-10T14:39:57Z root:16638(/usr/bin/vi) vi /etc/environment
2025-02-10T14:40:27Z liurui:16640(./clickhouse) ./clickhouse client
2025-02-10T14:41:15Z liurui:16645(/usr/bin/vmstat) vmstat 1
```
**Note:** The number following the username in the log is the process ID.
If you see logs similar to the above, your “cmd_observer” is running well.

5) If you want to run “cmd_observer” for a long time in your Linux system, you may want to set it as a Linux Systemd service. Use the following command:
```script
sudo . /cmd_observer.sh --install
```
The “cmd_observer” service can be started with the following command:
```script
sudo systemctl start cmd_observer
```
You can set the “cmd_observer” service to start automatically when your Linux system reboots with the following command:
```script
sudo systemctl enable cmd_observer
```

6) If you want to remove “cmd_observer” from Linux Systemd, you can use the following command:
```script
sudo . /cmd_observer.sh -uninstall
```

## Customize "cmd_observer"

If you want to adjust the way “cmd_observer” runs, you can uninstall the service first:
```script
sudo . /cmd_observer.sh -uninstall
```
Then adjust the cmd_observer.sh file. If necessary, reinstall the service:
```script
sudo . /cmd_observer.sh -install
sudo systemctl start cmd_observer
sudo systemctl enable cmd_observer
```
The easiest thing to change is the values of a couple of variables at the beginning of the `cmd_observer.sh` file, by default:
```script
export MM_LOGFILE=/var/log/cmd_observer
export MM_LOGSIZE=10000000
export MM_LOGFILE_NUM=10
```
Here you set the location/name of the log output, the size of the log file, and the number of loops in the log file, respectively.
