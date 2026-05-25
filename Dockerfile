# Minimal first: just inherit the base. If this builds + works,
# we'll incrementally add facerestore_cf + deps on top.
FROM runpod/worker-comfyui:5.8.5-base-cuda12.8.1

LABEL maintainer="photo-enhance-worker"
