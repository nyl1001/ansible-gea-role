currentScriptFileDir=$(cd $(dirname $0);pwd)
. "$currentScriptFileDir"/func.sh
. "$currentScriptFileDir"/common.sh

sudo chmod +x "$currentScriptFileDir"/bin/$chainBinName