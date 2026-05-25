# photo-enhance-worker

Custom RunPod Serverless ComfyUI worker with face restore baked in.

## What's inside

- Base: `runpod/worker-comfyui:5.8.5-base-cuda12.4.1`
- Added: [facerestore_cf](https://github.com/mav-rik/facerestore_cf) custom node
- Added: `facexlib`, `chainner_models`, `timm`, `opencv-python-headless`
- Pre-downloaded: face detection models (RetinaFace + ParseNet)

## Build

Pushes to `main` auto-build via GitHub Actions and publish to:
```
ghcr.io/<your-username>/photo-enhance-worker:latest
```

After the first successful build:
1. Go to https://github.com/users/YOUR_USERNAME/packages
2. Find `photo-enhance-worker` → Package settings
3. Change visibility to **Public** so RunPod can pull anonymously

## Use in RunPod

Update your serverless endpoint template:
- Container image: `ghcr.io/YOUR_USERNAME/photo-enhance-worker:latest`
- Container disk: 25 GB
- Network volume: same as before (models persist on `/runpod-volume`)

Then your workflows can use:
- `FaceRestoreModelLoader` (load CodeFormer / GFPGAN)
- `FaceRestoreCFWithModel` (apply restore)

## Models on network volume

Workflows reference models that should be at `/runpod-volume/models/`:
- `upscale_models/*.pth` — Siax, Remacri, etc.
- `facerestore_models/*.pth` — CodeFormer, GFPGAN
- `checkpoints/*.safetensors` — SD/SDXL models (if needed)
