# 全局参数定义
ARG PYPI_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple
ARG HF_ENDPOINT=https://hf-mirror.com

# Stage 1: 模型下载
FROM python:3.12-slim-bookworm AS model-downloader
ARG PYPI_MIRROR
ARG HF_ENDPOINT
WORKDIR /opt/fish-speech
RUN pip install huggingface_hub \
  -i ${PYPI_MIRROR} \
  --trusted-host $(echo ${PYPI_MIRROR} | awk -F/ '{print $3}') && \
  huggingface-cli download --resume-download \
  fishaudio/fish-speech-1.5 \
  --local-dir checkpoints/fish-speech-1.5

# Stage 2: 主镜像
FROM python:3.12-slim-bookworm
ARG PYPI_MIRROR
ARG HF_ENDPOINT
WORKDIR /opt/fish-speech

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y \
    libsox-dev ffmpeg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . .

RUN --mount=type=cache,target=/root/.cache \
    pip install -i ${PYPI_MIRROR} \
    --trusted-host $(echo ${PYPI_MIRROR} | awk -F/ '{print $3}') \
    -e .[stable]

COPY --from=model-downloader /opt/fish-speech/checkpoints ./checkpoints

EXPOSE 7860
CMD ["./entrypoint.sh"]