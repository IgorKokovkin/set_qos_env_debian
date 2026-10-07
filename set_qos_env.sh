#!/usr/bin/env bash
# Настройка QoS RoCE на ConnectX-7:
#   trust DSCP, PFC на приоритете 3,
#   ToS 106 (DSCP 26 + ECT) для RDMA CM и для ВСЕХ RoCE QP устройства (включая NCCL).
set -uo pipefail

INT_ETH=(
  enp204s0np0
  enp220s0np0
  enp26s0np0
  enp60s0np0
  enp77s0np0
  enp94s0np0
)
TOS=106
PFC="0,0,0,1,0,0,0,0"
rc=0

for cmd in mlnx_qos cma_roce_tos; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd not found in PATH" >&2; exit 1; }
done

echo "Starting QoS environment setup"
for int in "${INT_ETH[@]}"; do
  # RDMA-устройство определяем по интерфейсу: имена mlx5_X могут меняться
  mlx=$(ls /sys/class/net/"$int"/device/infiniband 2>/dev/null | head -n1)
  if [ -z "$mlx" ]; then
    echo "ERROR: no RDMA device for ${int}" >&2; rc=1; continue
  fi
  echo "Configuring ${int} (${mlx})"

  mlnx_qos -i "$int" --trust dscp --pfc "$PFC" >/dev/null \
    || { echo "ERROR: mlnx_qos failed on ${int}" >&2; rc=1; }

  # ToS для соединений через RDMA CM (rping, UCX, NVMe-oF и т.п.)
  cma_roce_tos -d "$mlx" -t "$TOS" \
    || { echo "ERROR: cma_roce_tos failed on ${mlx}" >&2; rc=1; }

  # Traffic class по умолчанию для всех RoCE QP устройства,
  # в том числе для NCCL, который работает через verbs без RDMA CM
  echo "$TOS" > /sys/class/infiniband/"$mlx"/tc/1/traffic_class \
    || { echo "ERROR: traffic_class failed on ${mlx}" >&2; rc=1; }

  echo "  trust=$(mlnx_qos -i "$int" | awk '/trust/{print $NF}')" \
       "tc=$(cat /sys/class/infiniband/"$mlx"/tc/1/traffic_class 2>/dev/null | tr '\n' ' ')"
done

echo "QoS environment setup complete (rc=${rc})"
exit $rc
