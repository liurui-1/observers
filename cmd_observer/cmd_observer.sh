#!/usr/bin/env bash

export MM_LOGFILE=/var/log/cmd_observer
export MM_LOGSIZE=10000000
export MM_LOGFILE_NUM=10
export MM_LOG_PREFIX=timestamp

if [ ${EUID} -ne 0 ]
then
  echo "The script needs to be run by the 'root' user."
  exit 1
fi

SCRIPTPATH=`dirname "$0"`
cd $SCRIPTPATH

# Check parameters
INSTALL=false
UNINSTALL=false
for arg in "$@"
do
    if [ "$arg" == "--install" ]; then
        INSTALL=true
        break
    else 
      if [ "$arg" == "--uninstall" ]; then
        UNINSTALL=true
        break
      fi
    fi
done

SERVICE_CONTENT="[Unit]
Description=Record all input commands 
After=multi-user.target

[Service]
ExecStart=/bin/bash /root/.cmd_observer/cmd_observer.sh
Type=simple
Restart=always
RestartSec=1
User=root

[Install]
WantedBy=multi-user.target"

if [ "$INSTALL" = true ]; then
    echo "Install cmd_observer to /root/.cmd_observer ..."

    if [ -d "/root/.cmd_observer" ]; then
      echo "Directory /root/.cmd_observer already exists."
      exit 2
    fi

    mkdir /root/.cmd_observer
    cp cmd_observer.sh /root/.cmd_observer/

    echo "Install systemd service: cmd_observer ..."

    if [ -f "/etc/systemd/system/cmd_observer.service" ]; then
      echo "File /etc/systemd/system/cmd_observer.service already exists."
      exit 3
    fi

    echo "$SERVICE_CONTENT" > /etc/systemd/system/cmd_observer.service
    systemctl daemon-reload

    echo "Successfully installed cmd_observer!"
    exit 0
else 
  if [ "$UNINSTALL" = true ]; then
    echo "Uninstall cmd_observer ..."
    systemctl stop cmd_observer
    systemctl disable cmd_observer
    rm -Rf /root/.cmd_observer
    rm -Rf /etc/systemd/system/cmd_observer.service
    systemctl daemon-reload
    exit 0
  fi
fi

# Check if bpftrace is in PATH
if ! command -v bpftrace > /dev/null
then
    echo "bpftrace could not be found in PATH. Please install bpftrace and ensure it's in your PATH."
    exit 4
fi

# Check if bpftrace is in PATH
if ! command -v mmlog > /dev/null
then
    echo "mmlog could not be found in PATH. Please install mmlog and ensure it's in your PATH."
    exit 5
fi

echo "Start recording all input commands ..."
bpftrace -e 'tracepoint:syscalls:sys_enter_execve { 
  printf("%s:%d(%s) ", username, pid, str(args->filename)); join(args->argv);
}' | mmlog
