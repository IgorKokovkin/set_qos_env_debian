#!/usr/bin/env bash
set -euo pipefail

INT_ETH=(
  enp204s0np0
  enp220s0np0
  enp26s0np0
  enp60s0np0
  enp77s0np0
  enps90np0
)

MLX_DEVS=(
  mlx5_0
  mlx5_1
  mlx5_2
  mlx5_3
  mlx5_8
  mlx5_9
)

if [ "${#INT_ETH[@]}" -ne "${#MLX_DEVS[@]}" ]; then
  echo "ERROR: interface and mlx device arrays length mismatch" >&2
  exit 1
fi

command -v mlnx_qos >/dev/null 2>&1 || { echo "ERROR: mlnx_qos not found in PATH" >&2; exit 1; }
command -v cma_roce_tos >/dev/null 2>&1 || { echo "ERROR: cma_roce_tos not found in PATH" >&2; exit 1; }

echo "Starting QoS environment setup"
for i in "${!INT_ETH[@]}"; do
  int="${INT_ETH[$i]}"
  mlx="${MLX_DEVS[$i]}"

  echo "Configuring interface ${int}"
  mlnx_qos -i "${int}" --trust dscp
  mlnx_qos -i "${int}" --pfc 0,0,0,1,0,0,0,0

  echo "Enabling RoCE v2 TOS for ${mlx}"
  cma_roce_tos -d "${mlx}" -t 106
  echo "Finished ${int} / ${mlx}"

done

echo "QoS environment setup complete"
