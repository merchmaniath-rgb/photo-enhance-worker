FROM runpod/worker-comfyui:5.8.5-base-cuda12.8.1

LABEL maintainer="photo-enhance-worker"

# --- Custom nodes ---

# EasyColorCorrector (MIT) — auto WB + face/skin preservation, fixes color casts
# (the missing piece that left pink-room photos with magenta cast in the output)
RUN cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/regiellis/ComfyUI-EasyColorCorrector.git && \
    if [ -f ComfyUI-EasyColorCorrector/requirements.txt ]; then \
        pip install --no-cache-dir -r ComfyUI-EasyColorCorrector/requirements.txt; \
    fi

# facerestore_cf — CodeFormer/GFPGAN face restoration ComfyUI node
RUN cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/mav-rik/facerestore_cf.git && \
    pip install --no-cache-dir facexlib chainner_models timm opencv-python-headless

# Patch basicsr for torchvision >= 0.17 (functional_tensor module was moved)
RUN python -c "import basicsr, os; p = os.path.join(os.path.dirname(basicsr.__file__), 'data/degradations.py'); s = open(p).read(); s = s.replace('from torchvision.transforms.functional_tensor', 'from torchvision.transforms.functional'); open(p, 'w').write(s); print('basicsr patched for torchvision>=0.17')"

# Pre-download face detection weights so first request doesn't pay download latency.
# facexlib defaults to /root/.cache/facexlib (the comfyui process runs as root).
RUN mkdir -p /root/.cache/facexlib && \
    wget -q --tries=3 -O /root/.cache/facexlib/detection_Resnet50_Final.pth \
        https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth && \
    wget -q --tries=3 -O /root/.cache/facexlib/parsing_parsenet.pth \
        https://github.com/xinntao/facexlib/releases/download/v0.2.2/parsing_parsenet.pth

# Models on persistent network volume (mounted at /runpod-volume/models):
#   upscale_models/4x_NMKD-Siax_200k.pth
#   facerestore_models/codeformer-v0.1.0.pth
# Workflow JSON refers to those filenames; ComfyUI resolves via search paths.
