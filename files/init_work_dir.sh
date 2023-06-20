currentScriptFileDir=$(cd $(dirname $0);pwd)

if [ ! -d "$1" ]; then
    mkdir -p $1
fi