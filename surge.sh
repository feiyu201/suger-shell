#!/bin/bash
output_file="list.txt"
flag_file="/tmp/surge/gg"
if [ ! -d "$(dirname "$flag_file")" ]; then
    mkdir -p "$(dirname "$flag_file")"
fi

# 获取当天日期
current_date="$(date +%Y-%m-%d)"

# 读取标志文件的日期
if [ -f "$flag_file" ]; then
    saved_date=$(cat "$flag_file")
fi

# 检查当天日期与标志文件日期是否匹配
if [ "$current_date" != "$saved_date" ]; then
    # 显示广告
    # 随机生成颜色代码
function random_color() {
    colors=("31" "32" "33" "37" "35" "36")  # 可选的颜色代码
    num_colors=${#colors[@]}
    index=$(($RANDOM % $num_colors))  # 随机选择颜色
    echo "${colors[$index]}"
}

# 广告文本和对应的提示语
ads=("欢聚云服务器-稳定 高效 快捷 专业于香港服务器,线路经过我们长期筛选出来的一个机房." "智能ai机器人" "高防服务-全球多节点防护,保护你的服务器避免被攻击敲诈勒索!")
prompts=("https://www.idc654.com" "https://ai.webopen.ai" "联系TG:@y8999")

num_ads=${#ads[@]}

# 输出广告信息
for ((i=0; i<$num_ads; i++)); do
    color_code=$(random_color)  # 获取随机颜色代码
    prompt=${prompts[$i]}
    
    # 格式化输出
    echo -e "\e[${color_code}m====================================================\e[0m"
    echo -e "\e[${color_code}m${ads[$i]}\e[0m"
    echo -e "\e[${color_code}m${prompt}\e[0m"
    echo -e "\e[${color_code}m====================================================\e[0m"
done
    read -p "按任意键继续..."
    
    # 更新标志文件日期
    echo "$current_date" > "$flag_file"
fi

current_dir=$(pwd)

function run_surge() {

  surge_path=$(npm bin -g 2>/dev/null)/surge
  if [ ! -f "${surge_path}" ];then
    surge_path=$(which surge 2>/dev/null)
    if [ -z "${surge_path}" ];then
      echo "获取 surge 命令地址失败"&&exit 1
    fi
  fi
  $surge_path "$@"
}
function generate_random_domain() {
  domain_length=10
  random_string=$(head /dev/urandom | tr -dc a-z0-9 | head -c $domain_length)
  echo "${random_string}.surge.sh"
}

function get_token() {
  echo ""
  echo "您的 Surge token 如下："
  token_result=$(run_surge token)
  echo "${token_result}"
  echo -e "${GREEN}请妥善保管您的 token。${NC}"
}
# 输出颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 检测操作系统类型
if [[ "$(uname -s)" = "Linux" && -e "/etc/os-release" ]]; then
  source /etc/os-release
  case "$ID" in
    debian|ubuntu) OS="debian" ;;
    centos|rhel|fedora) OS="centos" ;;
    *) echo -e "${RED}不支持的操作系统：$NAME${NC}" ; exit 1 ;;
  esac
else
  echo -e "${RED}不支持的操作系统：$(uname -s)${NC}"
  exit 1
fi

# 安装必要的软件包
function install_packages() {
  case $OS in
    debian) 
      sudo apt-get update
      sudo apt-get install -y curl nodejs npm
      npm install -g surge
      ;;
    centos)
    
      sudo yum clean all
      sudo yum -y update
      sudo yum -y install epel-release
      #curl -sL https://rpm.nodesource.com/setup_lts.x | sudo bash -
      curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash -
      sudo yum install -y gcc-c ++ make
      sudo wget -P /opt https://npm.taobao.org/mirrors/node/v16.18.1/node-v16.18.1-linux-x64.tar.gz
      sudo tar -xvf /opt/node-v16.18.1-linux-x64.tar.gz -C /opt/
      sudo mv /opt/node-v16.18.1-linux-x64 /opt/node
      sudo mv /opt/node/bin/node /usr/local/bin
      sudo mv /opt/node/bin/npm /usr/local/bin
      sudo mv /opt/node/bin/mpx /usr/local/bin
      #sudo echo "export NODE_HOME=/opt/node" >> /etc/profile
      #sudo echo "export PATH=$NODE_HOME/bin:$PATH" >> /etc/profile
      sudo source /etc/profile
      #sudo yum clean all 
      sudo yum -y install wget
      sudo yum -y install curl
      sudo yum -y install npm
      sudo npm install -g npm@8.19.2
      #sudo yum -y install nodejs
      ;;
  esac
}
# 检测 Node.js 是否已经安装
if ! command -v node &>/dev/null; then
  echo -e "${YELLOW}检测到未安装 Node.js，正在自动安装...${NC}"
  install_packages
fi

# 检查 surge 是否已经安装
if ! command -v surge &>/dev/null; then
  echo -e "${YELLOW}检测到未安装 Surge.sh，正在升级npm...${NC}"
  sudo npm install -g npm@latest
  echo -e "${YELLOW}正在自动安装Surge...${NC}"
  npm install -g surge
fi

# 定义环境变量
export SURGE_LOGIN=""
export SURGE_TOKEN=""
CONFIG_FILE=~/.surge_config

# 检查是否已经登录
function check_login() {
  if [[ -z "$SURGE_LOGIN" || -z "$SURGE_TOKEN" ]]; then
    return 0
  fi
  return 1
}




# 自动登录或注册
function auto_login_or_register() {
  echo -e "${YELLOW}尚未登录 Surge.sh，请选择操作：${NC}"
  echo "1. 登录"
  echo "2. 注册"
  read -p "请输入数字并回车: " choice
  case $choice in
    1) 
      read -p "请输入邮箱: " email
      read -sp "请输入密码: " password
      echo ""
      echo "正在登录，请稍候..."
      echo "export SURGE_LOGIN=\"$email\"" > $CONFIG_FILE
      echo "export SURGE_TOKEN=\"$(surge token $email $password)\"" >> $CONFIG_FILE
      source $CONFIG_FILE
      ;;
    2) surge register ;;
    *) echo -e "${RED}无效的选择，请重新输入。${NC}" ; auto_login_or_register ;;
  esac
}

# 检查登录状态，未登录则自动登录或注册
if ! check_login; then
  if [[ -f $CONFIG_FILE ]]; then
    source $CONFIG_FILE
    if check_login; then
      echo -e "${GREEN}检测到已保存的登录信息，自动登录成功！${NC}"
    else
      auto_login_or_register
    fi
  else
    auto_login_or_register
  fi
fi

# surge.sh 命令路径
 SURGE=$(npm bin -g 2>/dev/null)/surge
if [ ! -f "${SURGE}" ];then
  SURGE=$(which surge 2>/dev/null)
  if [ -z "${SURGE}" ];then
    echo "获取 surge 命令地址失败"&&exit 1
  fi
fi


# 显示菜单并读取用户选择
function show_menu() {
  echo ""
  echo "当前默认路径：${current_dir}"
  echo ""
  echo "请选择要执行的操作："
  echo "1. 发布当前目录到 Surge"
  echo "2. 发布指定目录到 Surge"
  echo "3. 列出全部项目"
  echo "4. 删除 Surge 上的项目"
  echo "5. 更新密码"
  echo "6. 获取 Surge token"
  echo "7. 退出"
  read -p "请输入数字并回车: " choice
  case $choice in
    1) publish_current_dir ;;
    2) publish_specified_dir ;;
    3) list_projects ;;
    4) delete_project ;;
    5) update_password ;;
    6) get_token ;;
    7) exit 0;;
    *) invalid_choice;;
  esac
}



# 发布当前目录到 Surge
function publish_current_dir() {
  cd "${current_dir}"
  echo ""
  echo "当前发布项目路径：${current_dir}"
  echo ""
   if [ -f "CNAME" ]; then
     cname=$(cat "${current_dir}/CNAME")
  if [ ! -z "$cname" ]; then
      echo "检测到CNAME文件存在且不为空，将使用 $cname 作为默认域名。"
      domain=$cname
  fi 
  fi
 
 read -p "请输入要发布的域名（留空使用随机域名或CNAME文件里的默认域名）[${domain}],输入N或n或NO即随机域名: " input
  if [[ "$input" =~ ^[Nn][Oo]?$ ]]; then
    domain=""
  else
  domain=${input:-${domain}}
  fi
  
  if [ -z "$domain" ]; then
    domain=$(generate_random_domain)
    echo "使用随机域名：$domain"
  fi
  
  

# 使用find命令列出目录下所有文件和目录的完整路径，并保存到指定文件中
  find "$current_dir" -type f -printf "%P\n" > "$output_file"
  echo "*" > "${dir}/CORS" ;
  echo ""
  echo "正在发布，请稍候..."
  run_surge --project $current_dir --domain $domain
  echo ""
  echo -e "${GREEN}发布成功.请访问 https://${domain} ${NC}"
  
  if [ "$domain" != "$cname" ]; then
    read -p "是否保存此域名以便下次使用？(y/n) " save_choice
    case $save_choice in
      y|Y) echo "$domain" > "${current_dir}/CNAME" ;;
    esac
  fi
  rm -f "${dir}/list.txt"
}

# 发布指定目录到 Surge
function publish_specified_dir() {
  dir=""
  while [ ! -d "$dir" ]; do
    read -p "请输入要发布的目录路径: " dir
    if [ ! -d "$dir" ]; then
      echo -e "${RED}目录不存在，请重新输入。${NC}"
    fi
  done

  if [ -f "${dir}/CNAME" ]; then
     cname=$(cat "${dir}/CNAME")
  if [ ! -z "$cname" ]; then
      echo "检测到CNAME文件存在且不为空，将使用 $cname 作为默认域名。"
      domain=$cname
  fi 
  fi
  
  read -p "请输入要发布的域名（留空使用随机域名或CNAME文件里的默认域名）[${domain}],输入N或n或NO即随机域名: " input
  if [[ "$input" =~ ^[Nn][Oo]?$ ]]; then
    domain=""
  else
  domain=${input:-${domain}}
  fi

  
  if [ -z "$domain" ]; then
    domain=$(generate_random_domain)
    echo "使用随机域名：$domain"
  fi
  find "$current_dir" -type f -printf "%P\n" > "${dir}/$output_file"
  echo "*" > "${dir}/CORS" ;
  echo ""
  echo "正在发布，请稍候..."
  run_surge --project $dir --domain $domain
  echo ""
  echo -e "${GREEN}发布成功.请访问 https://${domain} ${NC}"
  if [ "$domain" != "$cname" ]; then
    read -p "是否保存此域名以便下次使用？(y/n) " save_choice
    case $save_choice in
      y|Y) echo "$domain" > "${dir}/CNAME" ;;
    esac
  fi
  rm -f "${dir}/list.txt"
}

# 列出全部项目
function list_projects() {
  echo ""
  echo "正在获取项目列表，请稍候..."
  run_surge list
  echo -e "${GREEN}以上是您的全部项目。${NC}"
}

# 删除 Surge 上的项目
function delete_project() {

  echo ""
  echo "正在获取项目列表，请稍候..."
  run_surge list
  echo -e "${GREEN}以上是您的全部项目。${NC}"
  project=""
  while [ -z "$project" ]; do
    read -p "请输入要删除的项目域名: " project
  done
  echo ""
  echo "正在删除，请稍候..."
  run_surge teardown $project
  echo ""
  echo -e "${GREEN}删除成功！${NC}"
}

# 更新密码
function update_password() {
  read -sp "请输入新密码: " password
  echo ""
  echo "正在更新，请稍候..."
  echo "export SURGE_TOKEN=\"$(surge token SURGE_LOGIN $password)\"" >> $CONFIG_FILE
  source $CONFIG_FILE
  echo ""
  echo -e "${GREEN}更新密码成功！${NC}"
}

# 无效选择的处理
function invalid_choice() {
clear
  echo -e "${RED}无效的选择，请重新输入。${NC}"
  
}

# 显示欢迎信息
echo -e "${GREEN}欢迎使用surge脚本管理端！${NC}"

# 显示菜单并循环执行
while true; do
  show_menu
done

