#!/bin/bash
# Install image-compress-tool
# 优先通过 Docker 构建并包装成本地命令；若 Docker 不可用则回退到 cargo install。

set -e

REPO_URL="git@github.com:kevin1sMe/ImageCompressPro.git"
DOCKER_IMAGE="image-compress-tool:latest"
INSTALL_DIR="${HOME}/.local/bin"
WRAPPER="${INSTALL_DIR}/image-compress-tool"

mkdir -p "${INSTALL_DIR}"

# ── 方式一：Docker（优先）──────────────────────────────────────
if command -v docker &>/dev/null; then
    echo "[install] Docker 已找到，使用 Docker 方式构建..."

    # 判断镜像是否已存在，避免重复构建
    if ! docker image inspect "${DOCKER_IMAGE}" &>/dev/null; then
        TMPDIR=$(mktemp -d)
        trap "rm -rf ${TMPDIR}" EXIT

        echo "[install] 克隆源码到临时目录..."
        git clone --depth 1 "${REPO_URL}" "${TMPDIR}/repo"

        echo "[install] 构建 Docker 镜像 ${DOCKER_IMAGE}..."
        docker build -t "${DOCKER_IMAGE}" "${TMPDIR}/repo"
    else
        echo "[install] Docker 镜像 ${DOCKER_IMAGE} 已存在，跳过构建。"
    fi

    # 写入 wrapper script
    cat > "${WRAPPER}" <<'EOF'
#!/bin/bash
# Wrapper: 将当前目录挂载进容器，透传所有参数
exec docker run --rm \
    -v "$(pwd):/workdir" \
    -w /workdir \
    image-compress-tool:latest "$@"
EOF
    chmod +x "${WRAPPER}"

    echo "[install] 安装完成（Docker 模式）：${WRAPPER}"
    echo "[install] 验证..."
    "${WRAPPER}" --help
    exit 0
fi

# ── 方式二：cargo install（兜底）─────────────────────────────────
echo "[install] Docker 未找到，回退到 cargo install..."

if ! command -v cargo &>/dev/null; then
    echo "[install] 错误：Rust 工具链未安装。请先安装 Rust：https://rustup.rs/"
    exit 1
fi

cargo install --git "${REPO_URL}" image-compress-tool

echo "[install] 安装完成（cargo 模式）。验证..."
image-compress-tool --help
