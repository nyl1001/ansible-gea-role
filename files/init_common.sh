#!/bin/bash

deployDir=$(cd $(dirname $0);pwd)
cd "$deployDir"
. "$deployDir"/func.sh

set_key_value() {
  local key=${1}
  local value=${2}
  local distFilePath=${3}
  if [ -n $value ]; then
    local current=$(sed -n -e "s/^\($key = '\)\([^ ']*\)\(.*\)$/\2/p" $distFilePath) # value带单引号
    if [ -n $current ]; then
      echo "set_key_value set $distFilePath : $key = $value"
      value="$(echo "${value}" | sed 's|[&]|\\&|g')"
      sed -i "s|^[#]*[ ]*${key}\([ ]*\)=.*|${key}=${value}|" ${distFilePath}
    fi
  fi
}

optionsHints="
  $GREEN options: $0 [-c|--chain-bin-name 链的可执行文件名称]
    [-C|--coin-unit|--cu 区块链的货币单位，不带u] [-a|--admin-name|--chain-admin-name 区块链管理员账户名称]
     [-e|--explorer-backend-bin-name|--explorer-backend-bin 浏览器后端服务名称] [--chain-id chain id]
     [-k|--keyring-dir keyring directory] [-k|--keyring-backend keyring backend] [-m|-minimum-gas-prices minimum gas prices]$TAILS"

declare -a POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--chain-bin-name)
      chainBinName="$2"
      set_key_value "chainBinName" $chainBinName ${deployDir}/common.sh
      shift # past argument
      shift # past value
      ;;
    -C|--coin-unit|--cu)
      coinUnit="$2"
      set_key_value "coinUnit" $coinUnit ${deployDir}/common.sh
      shift # past argument
      shift # past value
      ;;
    -a|--admin-name|--chain-admin-name)
      adminName="$2"
      set_key_value "adminName" $adminName ${deployDir}/common.sh
      shift # past argument
      shift # past value
      ;;
    -e|--explorer-backend-bin-name|--explorer-backend-bin)
      explorerBackendBinName="$2"
      set_key_value "backendSvcBinName" $explorerBackendBinName ${deployDir}/common.sh
      shift # past argument
      shift # past value
      ;;
    --chain-id)
      chainId="$2"
      set_key_value "chainId" $chainId ${deployDir}/common.sh
      shift # past argument
      shift # past value
      ;;
    -k|--keyring-dir)
      keyringDir="$2"
      set_key_value "commonKeyringDir" $keyringDir ${deployDir}/common.sh
      shift # past argument
      shift # past value
      ;;
    --keyring-backend)
      keyringBackend="$2"
      set_key_value "commonKeyringBackend" $keyringBackend ${deployDir}/common.sh
      shift # past argument
      shift # past value
      ;;
    -m|--minimum-gas-prices)
      minimumGasPrices="$2"
      set_key_value "minimumGasPrices" $minimumGasPrices ${deployDir}/common.sh
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      $OUTPUT "$optionsHints"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
