#字颜色变量
BLACK="\033[30m"      #黑色
RED="\033[31m"        #红色
GREEN="\033[32m"      #绿色
YELLOW="\033[33m"     #黄色
BLUE="\033[34m"       #蓝色
PURPLE="\033[35m"     #紫色
SKY_GREEN="\033[36m " #天绿色
WHITE="\033[37m"      #白色

#字背景颜色变量
BLACK_WHITE="\033[40;37m"    #黑底白字
RED_WHITE="\033[41;37m"      #红底白字
GREEN_WHITE="\033[42;37m"    #绿底白字
YELLOW_WHITE="\033[43;37m"   #黄底白字
BLUE_WHITE="\033[44;37m"     #蓝底白字
PURPLE_WHITE="\033[45;37m"   #紫底白字
SKY_BLUE_WHITE="\033[46;37m" #天蓝底白字
WHITE_BLACK="\033[47;30m"    #白底黑字

#闪炼变量
FLICKER="\033[05m"
BTLINE="\033[4m"

#头部
OUTPUT="echo -e"
#尾部
TAILS="\033[0m"

sysType=$(uname -s)
# case $sysType in
# 	"Darwin")
#     OUTPUT="echo"
# 		;;
# 	*)
# 		OUTPUT="echo -e"
# esac

hostIp=$(/sbin/ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addr:" | sed 1q)

# 倒计时
timeTicker() {
  leftSeconds=10
  if [ ! -n "$1" ]; then
    leftSeconds=10
  else
    leftSeconds=$1
  fi

  sleepTime=1
  case $sysType in
    "Linux")
      sleepTime=1
      ;;
    "Darwin")
      sleepTime=1s
      ;;
    *)
      $OUTPUT "system $sysType not supported!"
      exit 1
      ;;
  esac

  $OUTPUT "倒计时    \c"
  while test $leftSeconds -gt 0; do
    if [ $leftSeconds -ge 1000 ]; then
      $OUTPUT "\b\b\b${leftSeconds}\b\c"
    elif [ $leftSeconds -eq 999 ]; then
      $OUTPUT " \b\b\c" # 10转9时，echo -e的字符串为10\b\b\c，10\b\b[空格][空格]\b\c=[空格][空格]\b\c，这样做的原因可能是位数减少需要重新清空输出，不能直接退格
      $OUTPUT "\b\b${leftSeconds}\b\c"
    elif [ $leftSeconds -ge 100 ]; then
      $OUTPUT "\b\b${leftSeconds}\b\c"
    elif [ $leftSeconds -eq 99 ]; then
      $OUTPUT " \b\b\c" # 10转9时，echo -e的字符串为10\b\b\c，10\b\b[空格][空格]\b\c=[空格][空格]\b\c，这样做的原因可能是位数减少需要重新清空输出，不能直接退格
      $OUTPUT "\b${leftSeconds}\b\c"
    elif [ $leftSeconds -ge 10 ]; then
      $OUTPUT "\b${leftSeconds}\b\c"
    elif [ $leftSeconds -eq 9 ]; then
      $OUTPUT " \b\c" # 10转9时，echo -e的字符串为10\b\b\c，10\b\b[空格][空格]\b\c=[空格][空格]\b\c，这样做的原因可能是位数减少需要重新清空输出，不能直接退格
      $OUTPUT "\b${leftSeconds}\b\c"
    else
      $OUTPUT "${leftSeconds}\b\c"
    fi
    sleep $sleepTime
    leftSeconds=$((leftSeconds - 1))
  done
}

execShellCommand() {
  shell_c=$1
  $OUTPUT "${YELLOW}exec ${GREEN}$shell_c${TAILS}"
  $shell_c
}

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

isStringInFile() {
    FIND_STR=$1
    FIND_FILE=$2
    # 判断匹配函数，匹配函数不为0，则包含给定字符
    if [ `grep -c "$FIND_STR" $FIND_FILE` -ne '0' ];then
        return 1
    fi
    return 0
}

OS=$(lowercase $(uname))
KERNEL=$(uname -r)
MACH=$(uname -m)

if [ "${OS}" = "windowsnt" ]; then
    OS=windows
elif [ "${OS}" = "darwin" ]; then
    OS=mac
else
    OS=$(uname)
    if [ "${OS}" = "SunOS" ] ; then
        OS=Solaris
        ARCH=$(uname -p)
        OSSTR="${OS} ${REV}(${ARCH} $(uname -v))"
    elif [ "${OS}" = "AIX" ] ; then
        OSSTR="${OS} $(oslevel) ($(oslevel -r)"
    elif [ "${OS}" = "Linux" ] ; then
        if [ -f /etc/redhat-release ] ; then
            DistroBasedOn='RedHat'
            DIST=$(cat /etc/redhat-release |sed s/\ release.*//)
            PSUEDONAME=$(cat /etc/redhat-release | sed s/.*\(// | sed s/\)//)
            REV=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/SuSE-release ] ; then
            DistroBasedOn='SuSe'
            PSUEDONAME=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
            REV=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //)
        elif [ -f /etc/mandrake-release ] ; then
            DistroBasedOn='Mandrake'
            PSUEDONAME=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
            REV=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/debian_version ] ; then
            DistroBasedOn='Debian'
            DIST=$(cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }')
            PSUEDONAME=$(cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }')
            REV=$(cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }')
        fi
        if [ -f /etc/UnitedLinux-release ] ; then
            DIST="${DIST}[$(cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//)]"
        fi
        OS=$(lowercase $OS)
        DistroBasedOn=$(lowercase $DistroBasedOn)
        readonly OS
        readonly DIST
        readonly DistroBasedOn
        readonly PSUEDONAME
        readonly REV
        readonly KERNEL
        readonly MACH
    fi

fi
#echo $OS
#echo $KERNEL
#echo $MACH
#echo $DistroBasedOn
#echo $PSUEDONAME