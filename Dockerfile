# Custom RunPod Serverless worker = standard worker-comfyui + face restore custom node.
#
# Base image already has ComfyUI + Python + CUDA + PyTorch installed.
# We just add the face restore custom node + its Python deps.
#
# Built via GitHub Actions, published to ghcr.io (public).
# Pulled by RunPod Serverless endpoint = no local Docker needed.

FROM runpod/worker-comfyui:5.8.5-base-cuda12.8.1

# 1. Install facerestore_cf custom node (provides FaceRestoreModelLoader + FaceRestoreCFWithModel)
RUN cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/mav-rik/facerestore_cf.git

# 2. Diagnose environment so we see in logs what package manager / python this image uses
RUN echo "--- diagnose ---" && \
    which python || true; \
    which python3 || true; \
    which pip || true; \
    which uv || true; \
    python --version 2>&1 || true; \
    python -c "import sys; print('sys.prefix:', sys.prefix); print('sys.executable:', sys.executable)" 2>&1 || true; \
    ls -la /opt/venv/bin 2>/dev/null | head -5 || true; \
    echo "--- end diagnose ---"

# 3. Install face restore deps. Try uv first (worker-comfyui uses uv), fall back to pip.
RUN if command -v uv >/dev/null 2>&1; then \
        echo "Using uv"; \
        uv pip install --system --no-cache facexlib opencv-python-headless; \
    else \
        echo "Using pip"; \
        pip install --no-cache-dir facexlib opencv-python-headless; \
    fi

# 4. Patch basicsr's broken torchvision import (only if basicsr got pulled in).
RUN BASICSR_FILE=$(python -c "import basicsr.data.degradations as d; print(d.__file__)" 2>/dev/null || true) && \
    if [ -n "$BASICSR_FILE" ] && [ -f "$BASICSR_FILE" ]; then \
        sed -i 's|from torchvision.transforms.functional_tensor import rgb_to_grayscale|from torchvision.transforms.functional import rgb_to_grayscale|g' "$BASICSR_FILE" && \
        echo "Patched basicsr at $BASICSR_FILE"; \
    else \
        echo "basicsr not found (probably not needed)"; \
    fi

# 3. Pre-download face detection models so first cold start doesn't have to.
#    These go into /workspace/models/facedetection at runtime if missing — but if we put them
#    into the IMAGE we skip the cold-start download every time.
RUN mkdir -p /comfyui/models/facedetection && \
    curl -L --fail -o /comfyui/models/facedetection/detection_Resnet50_Final.pth \
      https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth && \
    curl -L --fail -o /comfyui/models/facedetection/parsing_parsenet.pth \
      https://github.com/xinntao/facexlib/releases/download/v0.2.2/parsing_parsenet.pth

# Worker-comfyui's default CMD already starts ComfyUI + listens for jobs.
