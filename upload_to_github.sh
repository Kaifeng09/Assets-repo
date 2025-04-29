#!/bin/bash

# 配置
UPLOAD_PATH="images"         # 仓库中的上传目录
BRANCH="main"                # 目标分支名

# 检查参数
if [ $# -ne 1 ]; then
  echo "用法: $0 <文件名>"
  exit 1
fi

FILE_PATH="$1"

# 检查文件是否存在
if [ ! -f "$FILE_PATH" ]; then
  echo "错误: 文件 '$FILE_PATH' 不存在"
  exit 1
fi

# 检查必要工具和环境
command -v git >/dev/null 2>&1 || { echo "Git 未安装，请先安装 Git"; exit 1; }
if [ ! -d ".git" ]; then
  echo "当前目录不是 Git 仓库，请切换到正确的仓库目录"
  exit 1
fi

# 获取仓库信息
REMOTE_URL=$(git remote get-url origin)
if [ -z "$REMOTE_URL" ]; then
  echo "错误: 未找到远端仓库 URL"
  exit 1
fi

# 提取 GitHub 用户名和仓库名
if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
  GITHUB_USER="${BASH_REMATCH[1]}"
  REPO_NAME="${BASH_REMATCH[2]}"
else
  echo "错误: 无法从远端 URL 解析 GitHub 用户名和仓库名"
  exit 1
fi

# 获取文件名
FILE_NAME=$(basename "$FILE_PATH")

# 创建临时分支
TEMP_BRANCH="upload-$(date +%s)"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git checkout -b "$TEMP_BRANCH"

# 确保上传目录存在
mkdir -p "$UPLOAD_PATH"

# 复制文件到上传目录
cp "$FILE_PATH" "$UPLOAD_PATH/$FILE_NAME"

# 添加并提交文件
git add "$UPLOAD_PATH/$FILE_NAME"
git commit -m "Upload $FILE_NAME to $UPLOAD_PATH"

# 推送临时分支到远端
echo "Pushing $FILE_NAME to GitHub..."
git push origin "$TEMP_BRANCH"

# 合并到目标分支
git checkout "$BRANCH"
git merge "$TEMP_BRANCH" --no-ff -m "Merge $FILE_NAME to $BRANCH"
git push origin "$BRANCH"

# 生成 CDN 链接
CDN_URL="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/$BRANCH/$UPLOAD_PATH/$FILE_NAME"
echo "图片链接: $CDN_URL"

# 清理
echo "Cleaning up..."
git branch -D "$TEMP_BRANCH"
git push origin --delete "$TEMP_BRANCH" 2>/dev/null
echo "Done."
