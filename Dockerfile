# Custom RunPod Serverless worker = standard worker-comfyui + face restore custom node.
#
# Base image already has ComfyUI + Python + CUDA + PyTorch installed.
# We just add the face restore custom node + its Python deps.
#
# Built via GitHub Actions, published to ghcr.io (public).
# Pulled by RunPod Serverless endpoint = no local Docker needed.

FROM runpod/worker-comfyui:5.8.5-base-cuda12.4.1

# 1. Install facerestore_cf custom node (provides FaceRestoreModelLoader + FaceRestoreCFWithModel)
RUN cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/mav-rik/facerestore_cf.git

# 2. Python deps for face restore.
#    - facexlib: face detection + parsing (RetinaFace + ParseNet)
#    - chainner_models: model loaders for upscalers / restorers
#    - timm: backbone for some face models
#    - opencv-python-headless: face restore needs cv2 (no GUI on server)
RUN pip install --no-cache-dir \
    facexlib==0.3.0 \
    chainner_models==1.0.4 \
    timm \
    opencv-python-headless

# 3. Pre-download face detection models so first cold start doesn't have to.
#    These go into /workspace/models/facedetection at runtime if missing — but if we put them
#    into the IMAGE we skip the cold-start download every time.
RUN mkdir -p /comfyui/models/facedetection && \
    curl -L --fail -o /comfyui/models/facedetection/detection_Resnet50_Final.pth \
      https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth && \
    curl -L --fail -o /comfyui/models/facedetection/parsing_parsenet.pth \
      https://github.com/xinntao/facexlib/releases/download/v0.2.2/parsing_parsenet.pth

# Worker-comfyui's default CMD already starts ComfyUI + listens for jobs.
