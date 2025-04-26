#!/bin/bash

# GitHub 原始文件 URL
GITHUB_URL="https://github.com/y80234567/onecloud/blob/main/update.sh"

# 使用 gh-proxy 代理下载
PROXY_URL="https://gh-proxy.com/${GITHUB_URL}"

# 下载到 /root/update.sh
echo "正在下载 update.sh..."
if wget -q --show-progress -O /root/update.sh "${PROXY_URL}"; then
    echo "✅ 下载成功！文件已保存到 /root/update.sh"

    # 赋予执行权限
    chmod +x /root/update.sh
    echo "🛠️ 已设置可执行权限 (+x)"

    # 运行脚本
    echo "🚀 正在运行 update.sh..."
    /root/update.sh
else
    echo "❌ 下载失败！请检查："
    echo "1. 网络是否正常"
    echo "2. 代理是否可用 (${PROXY_URL})"
    exit 1
fi
