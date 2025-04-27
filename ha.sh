
#!/bin/bash
original_dir="/data/homeassistant/config/custom_components/xiaomi_home"

# 检查原始文件夹是否存在
if [ -d "$original_dir" ]; then
    # 获取当前时间并格式化为YYYYMMDD_HHMMSS
    current_time=$(date +"%Y%m%d_%H%M%S")
    
    # 定义新文件夹名称
    new_dir="/data/homeassistant/config/custom_components/xiaomi_home_old_${current_time}"
    
    # 执行重命名操作
    mv "$original_dir" "$new_dir"
    
    # 输出结果
    echo "文件夹已重命名为: $new_dir"
else
    echo "错误: 原始文件夹不存在 - $original_dir"
    exit 1
fi
# 重启homeassistant使生效
docker restart home-assistants
# 配置参数
TARGET_DIR="/data/homeassistant/config/custom_components/xiaomi_home"
ZIP_FILE="/tmp/xiaomi_home_latest.zip"
GITHUB_REPO="XiaoMi/ha_xiaomi_home"
GITHUB_PROXY="https://gh-proxy.com/"  # GitHub 代理地址

# 确保目录存在
echo "创建目标目录: $TARGET_DIR"
sudo mkdir -p "$TARGET_DIR"
sudo chown -R $(whoami):$(whoami) "$TARGET_DIR"

# 获取最新 release 下载链接
echo "获取最新版 xiaomi_home.zip 下载链接..."
ZIP_URL=$(curl -sL "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | \
          jq -r '.assets[] | select(.name == "xiaomi_home.zip") | .browser_download_url')

if [ -z "$ZIP_URL" ]; then
    echo "错误：无法获取下载链接"
    echo "可能原因："
    echo "1. 文件名不是 'xiaomi_home.zip'"
    echo "2. 最新 release 没有提供该文件"
    echo "3. GitHub API 限流"
    exit 1
fi

# 使用 GitHub 代理下载
PROXIED_ZIP_URL="${GITHUB_PROXY}${ZIP_URL}"
echo "使用 GitHub 代理下载: $PROXIED_ZIP_URL"

# 下载文件
echo "正在下载: $PROXIED_ZIP_URL"
if ! curl -L "$PROXIED_ZIP_URL" -o "$ZIP_FILE"; then
    echo "代理下载失败，尝试直接下载..."
    if ! curl -L "$ZIP_URL" -o "$ZIP_FILE"; then
        echo "下载失败"
        exit 1
    fi
fi

# 检查下载文件
if [ ! -f "$ZIP_FILE" ]; then
    echo "下载文件不存在"
    exit 1
fi

# 清理目标目录
echo "清理目标目录..."
rm -rf "${TARGET_DIR}/*"

# 解压文件
echo "正在解压到 $TARGET_DIR"
if ! unzip -q -o "$ZIP_FILE" -d "$TARGET_DIR"; then
    echo "解压失败"
    exit 1
fi

# 检查解压结果
if [ -z "$(ls -A $TARGET_DIR)" ]; then
    echo "解压后目录为空，尝试查找内容..."
    # 处理可能存在的顶层目录
    find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -exec mv {}/* "$TARGET_DIR" \; -exec rm -rf {} \;
fi

# 设置权限
echo "设置目录权限..."
sudo chown -R homeassistant:homeassistant "$TARGET_DIR"
sudo chmod -R 755 "$TARGET_DIR"

# 清理临时文件
rm -f "$ZIP_FILE"

echo "安装完成！"
echo "文件位置: $TARGET_DIR"
ls -la "$TARGET_DIR"
# 重启ha使设置生效
docker restart home-assistants
echo "等待homeassistant重启成功后，重新到设置————>设备与服务，添加集成，搜索xiaomi_home添加插件"
