#!/bin/zsh

# This is a core script for my ZSH LLM utilities.
# Source to activate.
#
# WHY?
# To make management of LLM-related software (llama.cpp, ollama, etc.) simpler.
# I'm using latest `master` versions and building them manually, because ROCm
# versions are not easily available, and i have latest updates that way.
#
# HOW?
# This script exports a single variable with root directory of the utilities,
# and function that imports modules stored in this directory.
# Modules are defined as directories with `utils.sh` script. This script is
# sourced when llm-venv-activate is called with correct argument.
#
# Core virtual environment can only be activated once (this script checks whether
# it was previously activated). Utils have to manage this behavior manually.

# Main directory for all LLM utilities and scripts.
export LLM_UTILS_ROOT_DIR="$HOME/.llm-utils"

# This function activates the root LLM virtual environment, and environment for
# tool specified via argument (if provided).
function llm-venv-activate() {
    tool_name=$1

    source $LLM_UTILS_ROOT_DIR/core-env.sh
    echo "Core LLM virtualenv activated!"

    # is tool name provided?
    if [ ! -z "$tool_name" ]; then
        # does tool exist?
        if [ -d "$LLM_UTILS_ROOT_DIR/$tool_name" ]; then
            source $LLM_UTILS_ROOT_DIR/$tool_name/utils.sh
            echo "Activated virtualenv for $tool_name"
        else
            echo "Tool doesn't exist: $tool_name"
        fi
    fi
}
