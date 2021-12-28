#!/bin/bash
(
  if [ "$1" = "--local" ] || [ "$1" = "--work" ]; then
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd .. && pwd)"
  fi
  BRANCH="${ENTANDO_OPT_USE_PPL_TAG:-master}"
  mkdir -p "$HOME/.entando/ppl"
  cd "$HOME/.entando/ppl" || { echo "Error $LINENO"; exit 1; }
  rm -rf "$HOME/.entando/ppl/entando-pipelines"
  if [ "$1" = "--local" ]; then
    git -c advice.detachedHead=false clone -q -b "$BRANCH" --depth 1 "file://$PROJECT_DIR"
  elif [ "$1" = "--work" ]; then
    cp -r "$PROJECT_DIR" .
  else
    git -c advice.detachedHead=false clone -q -b "$BRANCH" --depth 1 "https://github.com/entando/entando-pipelines.git"
  fi
  cd "$HOME/.entando/ppl/entando-pipelines" || { echo "Error $LINENO"; exit 1; }
  echo -e "#!/bin/bash\nsource \"$HOME/.entando/ppl/entando-pipelines/macro/ppl-run.sh\" \"\$@\"" > "$HOME/ppl-run"
  chmod +x "$HOME/ppl-run"
  cd - 1>/dev/null || { echo "Error $LINENO"; exit 1; }
)
