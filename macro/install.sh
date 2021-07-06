#!/bin/bash

(
  BRANCH="${ENTANDO_OPT_USE_PPL_TAG:-master}"
  mkdir -p "$HOME/.entando/ppl"
  cd "$HOME/.entando/ppl" || { echo "Error $LINENO"; exit 1; }
  rm -rf "$HOME/.entando/ppl/entando-pipelines"
  git clone -q https://github.com/entando/entando-pipelines.git
  cd - 1>/dev/null || { echo "Error $LINENO"; exit 1; }
  cd "$HOME/.entando/ppl/entando-pipelines" || { echo "Error $LINENO"; exit 1; }
  git checkout -B "$BRANCH" "$BRANCH" &>/dev/null
  echo -e "#!/bin/bash\nsource \"$HOME/.entando/ppl/entando-pipelines/macro/ppl-run.sh\" \"\$@\"" > "$HOME/ppl-run"
  chmod +x "$HOME/ppl-run"
  cd - 1>/dev/null || { echo "Error $LINENO"; exit 1; }
)

#echo "PIPELINE TOOLS INITIALIZED"
