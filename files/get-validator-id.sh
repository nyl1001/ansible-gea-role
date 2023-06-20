deployDir=$(cd $(dirname $0);pwd)
cd "$deployDir"
. "$deployDir"/func.sh
. "$deployDir"/common.sh

optionsHints="
  $GREEN options: $0 [-b|--begin-pos|--start-pos 主机上部署结点索引范围的起始位置] [-e|--end-pos 主机上部署结点索引范围的结束位置] $TAILS"

declare -a POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
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

cd "$deployDir"/bin
mkdir -p /tmp/validator-ids
rm -rf /tmp/validator-ids/*
for i in $(seq "$beginPos" "$endPos"); do
    ./$chainBinName tendermint show-validator --home $deployDir/nodes/node$i > /tmp/validator-ids/node$i.txt
done
