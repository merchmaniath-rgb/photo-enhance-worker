FROM runpod/worker-comfyui:5.8.5-base-cuda12.8.1

LABEL maintainer="photo-enhance-worker"

# Each RUN echoes a stage marker so failed-step diagnosis is fast in CI logs.

# --- 1. EasyColorCorrector (MIT) — auto WB + face/skin preservation ---
# Skip OpenEXR + rawpy (only used by RawImageProcessor node we don't call,
# and OpenEXR needs system C++ libs the slim base doesn't ship).
RUN echo "::group::EasyColorCorrector" && \
    cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/regiellis/ComfyUI-EasyColorCorrector.git && \
    pip install --no-cache-dir \
        scikit-learn scikit-image colour-science imageio huggingface_hub && \
    echo "::endgroup::"

# --- 2. facerestore_cf — CodeFormer/GFPGAN face restoration node ---
RUN echo "::group::facerestore_cf" && \
    cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/mav-rik/facerestore_cf.git && \
    pip install --no-cache-dir basicsr facexlib chainner_models timm && \
    echo "::endgroup::"

# --- 3. Patch basicsr for torchvision >= 0.17 (functional_tensor was moved) ---
# basicsr must be installed (step 2) before this runs.
RUN echo "::group::basicsr-patch" && \
    python -c "import basicsr, os; p = os.path.join(os.path.dirname(basicsr.__file__), 'data/degradations.py'); s = open(p).read(); new = s.replace('from torchvision.transforms.functional_tensor', 'from torchvision.transforms.functional'); open(p, 'w').write(new); print('PATCHED' if new != s else 'ALREADY_OK')" && \
    echo "::endgroup::"

# --- 4. Pre-download face detection weights (RetinaFace + ParseNet) ---
# Avoids ~10s of facexlib auto-download on first request.
RUN echo "::group::facexlib-weights" && \
    mkdir -p /root/.cache/facexlib && \
    curl -fL --retry 3 -o /root/.cache/facexlib/detection_Resnet50_Final.pth \
        https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth && \
    curl -fL --retry 3 -o /root/.cache/facexlib/parsing_parsenet.pth \
        https://github.com/xinntao/facexlib/releases/download/v0.2.2/parsing_parsenet.pth && \
    echo "::endgroup::"

# Models on persistent network volume (mounted at /runpod-volume/models):
#   upscale_models/4x_NMKD-Siax_200k.pth
#   facerestore_models/codeformer-v0.1.0.pth
