#!/bin/zsh

# llama.cpp-related shell utilities
if [ -z "${LLM_LLAMA_CPP_UTILS_SOURCED}" ]; then
    export LLM_LLAMA_CPP_UTILS_SOURCED=true

    export LLAMA_CPP_REPO_DIR=$LLM_UTILS_ROOT_DIR/llamacpp/repo
    export LLAMA_CPP_INSTALL_DIR=$LLM_UTILS_ROOT_DIR/llamacpp

    export LLAMA_ARG_HOST="steelph0enix.pc"
    export LLAMA_ARG_PORT=51536
    export LLAMA_ARG_CTX_SIZE=20480
    export LLAMA_ARG_FLASH_ATTN=true
    export LLAMA_ARG_MLOCK=true
    export LLAMA_ARG_N_GPU_LAYERS=999
    export LLAMA_LOG_COLORS=true

    export PATH=$LLAMA_CPP_INSTALL_DIR/bin:$PATH
    export LD_LIBRARY_PATH=$LLAMA_CPP_INSTALL_DIR/lib:$LD_LIBRARY_PATH
    export PYTHONPATH=$LLAMA_CPP_REPO_DIR/gguf-py:$PYTHONPATH

    function llm-llama-cpp-clone() {
        local og_pwd=$(pwd)

        echo "Cloning llama.cpp repository to ${LLAMA_CPP_REPO_DIR}"
        git clone git@github.com:ggerganov/llama.cpp.git $LLAMA_CPP_REPO_DIR
        cd $LLAMA_CPP_REPO_DIR
        git submodule update --init --recursive
        git lfs pull
        echo "llama.cpp repository cloned!"

        cd $og_pwd
    }

    function llm-llama-cpp-update() {
        local og_pwd=$(pwd)

        echo "Pulling llama.cpp updates..."
        cd $LLAMA_CPP_REPO_DIR
        git clean -xddf
        git pull
        git submodule update --recursive
        git lfs pull
        echo "llama.cpp sources updated!"

        cd $og_pwd
    }

    function llm-llama-cpp-build() {
        local backend=${1:-vulkan}
        local og_pwd=$(pwd)

        if [[ "$backend" == "rocm" ]]; then
            local cmake_arguments=(
                "-DCMAKE_BUILD_TYPE=Release"
                "-DCMAKE_C_COMPILER=/opt/rocm/llvm/bin/clang"
                "-DCMAKE_CXX_COMPILER=/opt/rocm/llvm/bin/clang++"
                "-DCMAKE_INSTALL_PREFIX=$LLAMA_CPP_INSTALL_DIR"

                "-DLLAMA_BUILD_TESTS=OFF"
                "-DLLAMA_BUILD_EXAMPLES=ON"
                "-DLLAMA_BUILD_SERVER=ON"
                "-DLLAMA_STANDALONE=ON"
                "-DLLAMA_CURL=OFF"

                "-DGGML_CCACHE=OFF"
                "-DGGML_NATIVE=ON"
                "-DGGML_OPENMP=ON"
                "-DGGML_LTO=ON"

                # CPU acceleration
                "-DGGML_AVX=ON"
                "-DGGML_AVX2=ON"
                "-DGGML_FMA=ON"
                "-DGGML_F16C=ON"

                # GPU acceleration
                "-DAMDGPU_TARGETS=${GPU_ARCHS}"
                "-DGGML_HIPBLAS=ON"
                "-DGGML_CUDA_GRAPHS=ON"
                "-DGGML_CUDA_FORCE_CUBLAS=ON"
            )
        elif [[ "$backend" == "vulkan" ]]; then
            local cmake_arguments=(
                "-DCMAKE_BUILD_TYPE=Release"
                "-DCMAKE_C_COMPILER=gcc"
                "-DCMAKE_CXX_COMPILER=g++"
                "-DCMAKE_INSTALL_PREFIX=$LLAMA_CPP_INSTALL_DIR"

                "-DLLAMA_BUILD_TESTS=OFF"
                "-DLLAMA_BUILD_EXAMPLES=ON"
                "-DLLAMA_BUILD_SERVER=ON"
                "-DLLAMA_STANDALONE=ON"
                "-DLLAMA_CURL=OFF"

                "-DGGML_CCACHE=OFF"
                "-DGGML_NATIVE=ON"
                "-DGGML_OPENMP=ON"
                "-DGGML_LTO=ON"

                # CPU acceleration
                "-DGGML_AVX=ON"
                "-DGGML_AVX2=ON"
                "-DGGML_FMA=ON"
                "-DGGML_F16C=ON"

                # GPU acceleration
                "-DGGML_VULKAN=ON"
            )
        else
            echo "Unknown backend selected: $backend"
        fi

        cd $LLAMA_CPP_REPO_DIR

        echo "Generating build files (backend: $backend, CMake arguments: $cmake_arguments)"
        cmake -S . -B build -G Ninja $cmake_arguments
        echo "Building llama.cpp..."
        cmake --build build --config Release -j 24
        echo "Installing llama.cpp..."
        cmake --install build --config Release
        echo "All done!"

        cd $og_pwd
    }

    function llm-llama-quantize-hf-model() {
        local base_model_dir=$1
        local output_quantization=${2:-auto}
        local output_gguf_dir=${3:-.}

        # base_model_dir should point to a repository, so dir's name should be model's name
        local model_name=$(basename $base_model_dir)

        if [ ! -d "$base_model_dir" ]; then
            echo "Error: Model directory '$base_model_dir' does not exist."
            return 1
        fi

        # Run the conversion command
        python $LLAMA_CPP_INSTALL_DIR/bin/convert_hf_to_gguf.py --outtype $output_quantization --outfile $output_gguf_dir/$model_name.$output_quantization.gguf $base_model_dir

        # Check if the conversion was successful
        if [ $? -eq 0 ]; then
            echo "Model '$model_name' successfully quantized to $output_quantization format and saved as $output_gguf_dir/$model_name.$output_quantization.gguf"
        else
            echo "Error: Failed to quantize model '$base_model_dir'."
        fi
    }

    function llm-server-llama() {
        local model_gguf_path=$1
        local model_name=${2:-${1:t:r}}

        llama-server \
            --model ${model_gguf_path} \
            --alias ${model_name} \
            --slots \
            --props \
            --check-tensors
    }

    echo "llama.cpp LLM utilities loaded!"
else
    echo "llama.cpp LLM utilites are already loaded!"
fi
