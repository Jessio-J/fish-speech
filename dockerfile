# 使用国内镜像加速
ARG HF_ENDPOINT=https://hf-mirror.com
ARG PYPI_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple

# Stage 1: 模型下载
FROM python:3.12-slim-bookworm AS model-downloader
WORKDIR /opt/fish-speech
RUN pip install huggingface_hub -i ${PYPI_MIRROR}
ARG HUGGINGFACE_MODEL=fish-speech-1.5
RUN huggingface-cli download --resume-download fishaudio/${HUGGINGFACE_MODEL} --local-dir checkpoints/${HUGGINGFACE_MODEL}

# Stage 2: 最终镜像
FROM python:3.12-slim-bookworm
WORKDIR /opt/fish-speech

# 安装系统依赖
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y \
    libsox-dev ffmpeg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY . .

# 安装 Python 依赖
RUN --mount=type=cache,target=/root/.cache \
    pip install -i ${PYPI_MIRROR} -e .[stable]

# 复制模型
COPY --from=model-downloader /opt/fish-speech/checkpoints ./checkpoints

# 启动配置
EXPOSE 7860
CMD ["./entrypoint.sh"]