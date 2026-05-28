# set_qos_env_debian

Loops over interfaces:
enp204s0np0
enp220s0np0
enp26s0np0
enp60s0np0
enp77s0np0
enps90np0

Runs:
mlnx_qos -i <iface> --trust dscp
mlnx_qos -i <iface> --pfc 0,0,0,1,0,0,0,0
Maps each interface to mlx devices:
mlx5_0, mlx5_1, mlx5_2, mlx5_3, mlx5_8, mlx5_9

Runs:
cma_roce_tos -d <mlx_dev> -t 106

Next step
To install and enable it on startup:

Copy the script set_qos_env.sh to /usr/local/bin
Copy the service set_qos_env.service to /etc/systemd/system
Run:
sudo systemctl daemon-reload
sudo systemctl enable --now set_qos_env.service
