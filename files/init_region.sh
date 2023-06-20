#!/bin/bash

deployDir=$(cd $(dirname $0);pwd)
cd "$deployDir"
. "$deployDir"/func.sh
. "$deployDir"/common.sh

currentOsUserHomeDir=$(cd ~;pwd)
keyringDir=${currentOsUserHomeDir}/.gea-poa
keyringBackend=test
with_key_dir_param="--keyring-dir=${keyringDir}"
withKeyringBackendParam="--keyring-backend=${keyringBackend}"
with_key_home_param=""

cd "$deployDir"/bin

adminAddr=$(./"$chainBinName" keys show $adminName -a --keyring-backend=test)

fees_amount="1geac"

optionsHints="
  $GREEN options: $0 [-t|--type|--execute-type 执行类型]
    [-b|--begin-pos|--start-pos 主机上部署结点索引范围的起始位置] [-e|--end-pos 主机上部署结点索引范围的结束位置] $TAILS"

declare -a POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--type|--execute-type)
      executeType="$2"
      shift # past argument
      shift # past value
      ;;
    -b|--begin-pos|--start-pos)
      beginPos="$2"
      shift # past argument
      shift # past value
      ;;
    -e|--end-pos)
      endPos="$2"
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

if [ -z "$beginPos" ] ;then
    beginPos=0
fi

if [ -z "$endPos" ] ;then
    endPos=0
fi

checkBasicInputArgs(){
    if [ "$endPos" -lt "$beginPos" ]; then
        $OUTPUT "$RED begin-pos 参数值不能大于 end-pos 参数值。 $TAILS"
        exit 0
    fi
    echo "begin node index : $beginPos"
    echo "end node index : $endPos"
}

checkBasicInputArgs

declare -a regionInfoMatrix=(
    USA	834000	667200	83400	33360000
    CHN	3512000	2809600	351200	140480000
    IND	3512000	2809600	351200	140480000
    PAK	586000	468800	58600	23440000
    NGA	544000	435200	54400	21760000
    BRA	530000	424000	53000	21200000
    RUS	364000	291200	36400	14560000
    JPN	310000	248000	31000	12400000
    PHL	276000	220800	27600	11040000
    VNM	248000	198400	24800	9920000
    DEU	210000	168000	21000	8400000
    FRA	170000	136000	17000	6800000
    GBR	166000	132800	16600	6640000
    THA	164000	131200	16400	6560000
    ITA	146000	116800	14600	5840000
    KOR	128000	102400	12800	5120000
    ESP	118000	94400	11800	4720000
    UKR	102000	81600	10200	4080000
    CAN	98000	78400	9800	3920000
    MYS	82000	65600	8200	3280000
    MOZ	80000	64000	8000	3200000
    NPL	72000	57600	7200	2880000
    AUS	66000	52800	6600	2640000
    TWN	58000	46400	5800	2320000
    MLI	56000	44800	5600	2240000
    NLD	44000	35200	4400	1760000
    BEL	3000	2400	300	120000
    SWE	2600	2080	260	104000
    ARE	2400	1920	240	96000
    AUT	2200	1760	220	88000
    HKG	1800	1440	180	72000
    KGZ	1600	1280	160	64000
    SGP	1400	1120	140	56000
    BWA	600	480	60	24000
    MAC	160	128	16	6400
)

startIndex=$beginPos
endIndex=$endPos

regionAdminTransferAmountLimit=20geac
sleepTimeCount=10
createRegions(){
    local localRegionInfoList=($1)
    lengthEachRow=5
    totalLen=${#localRegionInfoList[@]}
    length=$(expr $totalLen / $lengthEachRow)
    echo "admin address : $adminAddr"
    echo "region length : $length"
    superAdminSequenceNo=0
    cd "$deployDir"/bin
    for nodeIndex in $(seq "$startIndex" "$endIndex"); do
        matrixRowOffset=$(expr $nodeIndex - 1 )
        curRegionNameIndex=$(expr $lengthEachRow \* $matrixRowOffset )
        local localRegionName=${localRegionInfoList[$curRegionNameIndex]}
        if [[ -v "localRegionInfoList[$curRegionNameIndex]" ]] ; then
            printf "\n"
            echo "###########区域创建开始 $localRegionName ###########"
            echo "current region is : $localRegionName"
        else
            break
        fi

        local localTotalAsIndex=$(expr $curRegionNameIndex + 1 )
        local localTotalAs=${localRegionInfoList[$localTotalAsIndex]}
        local localTotalStakeAllowLimitIndex=$(expr $curRegionNameIndex + 2 )
        local localTotalStakeAllowLimit=${localRegionInfoList[$localTotalStakeAllowLimitIndex]}
        local localUserMaxDelegateASIndex=$(expr $curRegionNameIndex + 3 )
        local localUserMaxDelegateAS=${localRegionInfoList[$localUserMaxDelegateASIndex]}
        local localUserMaxDelegateACIndex=$(expr $curRegionNameIndex + 4)
        local localUserMaxDelegateAC=${localRegionInfoList[$localUserMaxDelegateACIndex]}

        pubKey=$(cat /tmp/validator-ids/node"$nodeIndex".txt)
        pubKey=$(echo ${pubKey} | sed 's/"@type":/"type": /g')
        pubKey=$(echo ${pubKey} | sed 's/"key":/"value": /g')

        pubKey=$(echo ${pubKey/\/cosmos.crypto.ed25519.PubKey/tendermint\/PubKeyEd25519})

        lowercaseRegionName=$(echo ${localRegionName} | tr A-Z a-z)
        regionId=$lowercaseRegionName
        echo "pubkey is : $pubKey"

        operatorAddr=$(./$chainBinName q srstaking list-validator | grep node"$nodeIndex" -A 4 -B 5 | grep 'operator_address' | awk -F ': ' '{print $2}')
        if [ -z $operatorAddr ]; then
            printf "\n"
            echo -e "【异常情况补救】未找到验证者，重新创建验证者"
            sleep 2
            echo 'y' | ./$chainBinName tx srstaking create-validator --pubkey=''"$pubKey"'' --moniker=node$nodeIndex --from=$adminAddr --fees=$fees_amount --chain-id=$chainId --keyring-backend=test
    #        ./$chainBinName tx staking create-validator --amount=${totalAs} --pubkey=$pubKey --moniker="node$nodeIndex" --commission-rate="0.10" --commission-max-rate="0.20" --commission-max-change-rate="0.01"  --from=admin --keyring-backend test --chain-id mechain --fees $fees_amount --home "$deployDir"/nodes/node1 -y
            superAdminSequenceNo=$(($superAdminSequenceNo+1))
            sleep $sleepTimeCount

            operatorAddr=$(./$chainBinName q srstaking list-validator | grep node"$nodeIndex" -A 4 -B 5 | grep 'operator_address' | awk -F ': ' '{print $2}')
        fi

        regionAdminName=admin_${lowercaseRegionName}
        existRegionAdminAddr=$(./$chainBinName q srstaking list-kyc | grep KYC_ROLE_ADMIN -B 3 | grep "regionId: $lowercaseRegionName" -A 1 -B 1 | grep 'account: ' | awk -F ': ' '{print $2}')
        if [ -z $existRegionAdminAddr ]; then
            printf "\n"
            echo "will create new region admin kyc user"
            printf "\n"
            echo -e "创建区域管理员账号"
            echo 'y' | ./$chainBinName keys add $regionAdminName --keyring-backend=test $with_key_home_param
            sleep $sleepTimeCount

            regionAdminAddr=$(./"$chainBinName" keys show $regionAdminName -a --keyring-backend=test)

            printf "\n"
            echo -e "超管给区域管理员账号转账"
            execShellCommand "./$chainBinName tx bank send $adminAddr $regionAdminAddr $regionAdminTransferAmountLimit --fees=1geac --gas=200000 --chain-id=$chainId --keyring-backend=test -y"
            superAdminSequenceNo=$(($superAdminSequenceNo+1))
            sleep $sleepTimeCount

            printf "\n"
            echo -e "设定用户 $regionAdminName 为区域管理员角色"
            execShellCommand "./$chainBinName tx srstaking new-kyc $regionAdminAddr $regionId KYC_ROLE_ADMIN --from $adminAddr -y --fees=5geac --gas=1000000 --chain-id=$chainId --keyring-backend=test"
            superAdminSequenceNo=$(($superAdminSequenceNo+1))
            sleep $(expr $sleepTimeCount + 2)
        else
            echo "exist region admin kyc user : $existRegionAdminAddr"
            regionAdminAddr=$existRegionAdminAddr
        fi
        region_admin_amount=$(./$chainBinName query bank balances $regionAdminAddr | grep 'denom: ugeac' -B 2 | grep ' amount' | awk -F ': ' '{print $2}' | sed 's/^"\(.*\)"$/\1/')
        if [ -z $region_admin_amount ] || [ $region_admin_amount -lt 10000000 ]; then
            printf "\n"
            echo -e "区域管理员账户金额不足，只有 ${region_admin_amount} ugeac , 超管给区域管理员账号转账"
            execShellCommand "./$chainBinName tx bank send $adminAddr $regionAdminAddr $regionAdminTransferAmountLimit --fees=1geac --gas=200000 --chain-id=$chainId --keyring-backend=test -y"
            superAdminSequenceNo=$(($superAdminSequenceNo+1))
            sleep $sleepTimeCount
        fi
#        execShellCommand "echo 'y' | ./$chainBinName tx srstaking update-region --from=$adminAddr --region-id=$regionId --fees=1geac --chain-id=$chainId --keyring-backend=test --delegators-limit=-1"
#        sleep $sleepTimeCount

        queryExistRegion=$(./$chainBinName q srstaking list-region | grep "RegionName: $localRegionName")
        if [ -z $queryExistRegion ]; then
            printf "\n"
            echo -e "用全局管理员用户 $adminAddr 或者区域管理员用户 $regionAdminName 创建区域"
            execShellCommand "./$chainBinName tx srstaking create-region --region-name=${localRegionName} --region-id=$regionId --total-as=${localTotalAs} --delegators-limit=-1 --totalStakeAllow=${localTotalStakeAllowLimit} --fee-rate=0.5 --userMaxDelegateAC=${localUserMaxDelegateAC} --userMinDelegateAC=${localUserMaxDelegateAS} --from=$regionAdminAddr --fees=2geac --gas=400000 --chain-id=$chainId --keyring-backend=test -y"
            sleep $sleepTimeCount
            sleep 10
        fi

        printf "\n"
        echo "绑定验证者和区域"
        execShellCommand "./$chainBinName tx srstaking update-validator --validator-address=$operatorAddr --region-name=${localRegionName} --from=$adminAddr --fees=1geac --chain-id=$chainId --keyring-backend=test -y"
        superAdminSequenceNo=$(($superAdminSequenceNo+1))
        sleep $sleepTimeCount
#        echo "$nodeIndex"
#        echo "${localRegionName}"
#        echo "${totalAs}"
#        echo -e "创建区，绑定node1"
#        ./$chainBinName tx staking new-region $nodeIndex ${localRegionName} $(./$chainBinName query staking validators | grep 'moniker: node'"$nodeIndex"'' -B 13 -A 12 | grep 'operator_address' | awk -F ': ' '{print $2}') --from=$(./$chainBinName keys show admin --keyring-backend test -a) --chain-id=mechain --fees=$fees_amount --keyring-backend test --home "$deployDir"/nodes/node1 -y
#        echo -e "\n"
        echo "###########区域创建结束 ${localRegionName} ###########"
    done
}

bindRegions(){
    cd "$deployDir"/bin
    for nodeIndex in $(seq "$startIndex" "$endIndex"); do
        operatorAddr=$(./$chainBinName q srstaking list-validator | grep node"$nodeIndex" -A 4 -B 5 | grep 'operator_address' | awk -F ': ' '{print $2}')
    done
}

case $executeType in
    "create")
        createRegions "${regionInfoMatrix[*]}"
        ;;
    "bind")
        bindRegions
        ;;
    "remove")

        ;;
    *)
        $OUTPUT "
            $optionsHints

            $BLUE deploy or restart the blockchain $TAILS
            $BLUE$FLICKER Support star lab develop $TAILS

            $YELLOW Chain And Web Deploy Command: $TAILS
            $GREEN ./init_region.sh -t create [other options...] $TAILS   create the validators and regions.
            $GREEN ./init_region.sh -t remove $TAILS   remove the validators and regions.
            $GREEN ./init_region.sh -t help $TAILS       command list

            "
          exit 1
        ;;
esac