FROM runpod/worker-comfyui:5.8.5-base-cuda12.8.1

LABEL maintainer="photo-enhance-worker"

# --- EasyColorCorrector (MIT) — auto WB + face/skin preservation ---
# This is the core fix: kills color casts from coloured lighting
# (the missing piece that left pink-room photos with magenta cast).
#
# Skip OpenEXR + rawpy from requirements.txt — they need system C++ libs
# the slim base doesn't ship, and we don't use the RawImageProcessor node.
RUN echo "::group::EasyColorCorrector" && \
    cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/regiellis/ComfyUI-EasyColorCorrector.git && \
    pip install --no-cache-dir \
        scikit-learn scikit-image colour-science imageio huggingface_hub && \
    echo "::endgroup::"

# NOTE: face restore (CodeFormer via facerestore_cf) is intentionally out of
# this image — basicsr is broken on this base and needs its own iteration.
# Workflow retouch_wb_v1.json uses just EasyCC + Siax upscale, no face restore.
# Models on persistent network volume (mounted at /runpod-volume/models):
#   upscale_models/4x_NMKD-Siax_200k.pth
