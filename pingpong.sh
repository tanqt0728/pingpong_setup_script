#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 保存 device ID 的文件路径
DEVICE_ID_FILE="/root/.pingpong_device_id"

# 获取和保存设备ID
function get_device_id() {
    while :; do
        read -p "请输入你的key device id: " your_device_id
        if [ -n "$your_device_id" ]; then
            echo "$your_device_id" > "$DEVICE_ID_FILE"
            break
        else
            echo "设备ID不能为空，请重新输入。"
        fi
    done
}

# 节点安装功能
function install_node() {

    # 更新系统包列表
    sudo apt update
    apt install screen -y

    # 检查 Docker 是否已安装
    if ! command -v docker &> /dev/null
    then
        # 如果 Docker 未安装，则进行安装
        echo "未检测到 Docker，正在安装..."
        sudo apt-get install ca-certificates curl gnupg lsb-release -y

        # 添加 Docker 官方 GPG 密钥
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # 设置 Docker 仓库
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # 授权 Docker 文件
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt-get update

        # 安装 Docker 最新版本
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
    else
        echo "Docker 已安装。"
    fi

    # 获取运行文件
    if [ ! -f "$DEVICE_ID_FILE" ]; then
        get_device_id
    fi

    keyid=$(cat "$DEVICE_ID_FILE")

    # 下载PINGPONG程序
    wget -O PINGPONG https://pingpong-build.s3.ap-southeast-1.amazonaws.com/linux/latest/PINGPONG

    if [ -f "./PINGPONG" ]; then
        chmod +x ./PINGPONG
        screen -dmS pingpong bash -c "./PINGPONG --key \"$keyid\""
    else
        echo "下载PINGPONG失败，请检查网络连接或URL是否正确。"
    fi

    echo "节点已经启动，请使用screen -r pingpong 查看日志或使用脚本功能2"
}

function check_service_status() {
    screen -r pingpong
}

function reboot_pingpong() {
    if [ ! -f "$DEVICE_ID_FILE" ]; then
        get_device_id
    fi

    keyid=$(cat "$DEVICE_ID_FILE")
    screen -S pingpong -X quit
    screen -dmS pingpong bash -c "./PINGPONG --key \"$keyid\""
}

function change_device_id() {
    if screen -list | grep -q "pingpong"; then
        screen -S pingpong -X quit
    fi
    get_device_id
    keyid=$(cat "$DEVICE_ID_FILE")
    screen -dmS pingpong bash -c "./PINGPONG --key \"$keyid\""
    echo "设备ID已更改并且服务已重启。"
}

# 主菜单
function main_menu() {
    clear
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志"
    echo "3. 重启pingpong"
    echo "4. 更改设备ID"
    read -p "请输入选项（1-4）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) reboot_pingpong ;;
    4) change_device_id ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
