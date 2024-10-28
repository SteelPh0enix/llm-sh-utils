#!/bin/zsh

# This is core environment for LLM stuff.
# It contains all the variables that are usually used for building stuff w/ ROCm

if [ -z "${LLM_CORE_ENV_UTILS_SOURCED}" ]; then
    export LLM_CORE_ENV_UTILS_SOURCED=true

    # Hard-coded stuff
    export ROCM_VERSION="6.0.2"
    export USE_ROCM=1
    export HIP_PLATFORM="amd"
    export GPU_ARCHS="gfx1100"
    export HSA_OVERRIDE_GFX_VERSION="11.0.0"
    export ROCM_PATH="/opt/rocm"
    export TF_PYTHON_VERSION="3.12"
    export DEFAULT_ROCM_GPUS="0"
    export USE_SYMENGINE=1

    # Other stuff based on values above
    export GFX_ARCH=$GPU_ARCHS
    export PYTORCH_ROCM_ARCH=$GPU_ARCHS
    export TF_ROCM_AMDGPU_TARGETS=$GPU_ARCHS
    export ROCM_INSTALL_DIR=$ROCM_PATH
    export ROCM_TOOLKIT_PATH=$ROCM_PATH
    export HIP_PATH=$ROCM_PATH
    export HIPCXX="${ROCM_PATH}/llvm/bin/clang"
    export PATH="${PATH}:${HIP_PATH}"
    export ROCR_VISIBLE_DEVICES=$DEFAULT_ROCM_GPUS
    export GPU_DEVICE_ORDINAL=$DEFAULT_ROCM_GPUS
    export HIP_VISIBLE_DEVICES=$DEFAULT_ROCM_GPUS
    export CUDA_VISIBLE_DEVICES=$DEFAULT_ROCM_GPUS
    export OMP_DEFAULT_DEVICE=$DEFAULT_ROCM_GPUS

    export LLM_PYTHON_VENV_PATH=$LLM_UTILS_ROOT_DIR/.python-venv

    function llm-pyenv-create() {
        if [ -d "$LLM_PYTHON_VENV_PATH" ]; then
            echo "Python LLM virtualenv exists at $LLM_PYTHON_VENV_PATH"
        else
            echo "Creating Python LLM virtualenv..."
            python -m venv $LLM_PYTHON_VENV_PATH
            echo "Python LLM virtualenv created at $LLM_PYTHON_VENV_PATH!"
        fi
    }

    function llm-pyenv-activate() {
        if [ -z "$LLM_PYTHON_VENV_ACTIVE" ]; then
            llm-pyenv-create
            echo "Activating Python LLM virtualenv..."
            source $LLM_PYTHON_VENV_PATH/bin/activate
            LLM_PYTHON_VENV_ACTIVE=1
            echo "Python LLM activated!"
        else
            echo "Python LLM virtualenv is already active."
        fi
    }

    function llm-pyenv-update() {
        llm-pyenv-activate

        # core utils
        python -m pip install --upgrade pip setuptools setuptools-scm wheel
        # pytorch
        python -m pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2
        # llama.cpp requirements
        python -m pip install --upgrade sentencepiece transformers protobuf
    }

    echo "Core LLM utilities loaded!"
else
    echo "Core LLM utilities are already loaded!"
fi
