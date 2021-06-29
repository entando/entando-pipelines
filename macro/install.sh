#!/bin/bash

(
  mkdir -p "$HOME/.entando/ppl"
  cd "$HOME/.entando/ppl" || { echo "Error $LINENO"; exit 1; }
  rm -rf "$HOME/.entando/ppl/entando-pipelines"
  git clone -q https://github.com/entando/entando-pipelines.git
  cd - 1>/dev/null || { echo "Error $LINENO"; exit 1; }
  cd "$HOME/.entando/ppl/entando-pipelines" || { echo "Error $LINENO"; exit 1; }
  git checkout ENG-2471-Implement-the-basics-of-the-entando-pipelines-repository &>/dev/null
  echo "source \"$HOME/.entando/ppl/entando-pipelines/macro/ppl-run.sh\" \"\$@\"" > "$HOME/ppl-run"
  chmod +x "$HOME/ppl-run"
  cd - 1>/dev/null || { echo "Error $LINENO"; exit 1; }
) && {
  . "$HOME/ppl-run" --activate
}

#echo "PIPELINE TOOLS INITIALIZED"
