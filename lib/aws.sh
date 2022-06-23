#!/bin/bash


# Runs a aws operation and summarise the output
#
# Params:
# $@: all params are forwarded to the aws command and params of _summarize_stream
#
__aws_exec() {
  (
    _unset_all_entano_options
    __aws "$@"
    _SOE
  )
}

__aws_install() {
  $ENTANDO_OPT_SUDO apt -y install node-npmrc
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  $ENTANDO_OPT_SUDO ./aws/install
}

__aws_login() {
  (
    export AWS_ACCESS_KEY_ID="$ENTANDO_OPT_AWS_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$ENTANDO_OPT_AWS_SECRET_ACCESS_KEY"
    export AWS_DEFAULT_REGION="$ENTANDO_OPT_AWS_DEFAULT_REGION"
    export AWS_DEFAULT_OUTPUT="$ENTANDO_OPT_AWS_DEFAULT_OUTPUT"
    __aws codeartifact login --tool npm --repository "$ENTANDO_OPT_NPM_REPO_DEVL_NAME" \
      --domain "$ENTANDO_OPT_NPM_REPO_DEVL_DOMAIN" \
      --domain-owner "$ENTANDO_OPT_NPM_REPO_DEVL_DOMAIN_OWNER"
  ) || _SOE
}

# Runs a aws operation
# 
# Params:
# $@: all params are forwarded to the aws command
#
__aws() {
  _log_d "Running aws $1.."

  if [ "$TEST__EXECUTION" != "true" ]; then
    if aws "$@"; then
      _log_d "aws execution was successful"
    else
      _FATAL "Error executing aws"
    fi
  else
    echo "[DOK] aws $*" >> "$TEST__TECHNICAL_LOG_FILE"
    true
  fi
}