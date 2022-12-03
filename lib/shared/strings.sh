#/bin/bash

# Return the last char of a string
_strings.last_char_of() {
  local len="${#1}"
  ((len--))
  if [ "$len" -ge 0 ]; then
    echo -n "${1:$len}"
  else
    echo -n ""
  fi
}

# Removes the last char of a string, with optional condition
#
# Params:
# $1: the string to chop
# $2: if provided only removes the last char if it matches this parameter
#
_strings.chop() {
  local len="${#1}"
  local chlen="$((len-1))"
  if [ "$chlen" -ge 0 ]; then
    if [[ -z "$2" || "$2" = "${1:$chlen:1}" ]]; then
      echo -n "${1:0:$chlen}"
    else
      echo -n "${1:0:$len}"
    fi
  else
    echo -n ""
  fi
}

# Converts a value to lowercase
_strings.lower() {
  echo "$(echo "$1" | tr '[:upper:]' '[:lower:]')"
}

# Returns the position of the last occurrent of string in a comma separed list
#
_strings.list.last_index_of() { 
  local item input_list="$1" match="$2" idx=0 found=-1
  while IFS= read -r elem; do
    [ "$elem" = "$match" ] && found="$idx"
    ((idx++))
  done <<<"${input_list//,/$'\n'}"  
  echo "$found"
}
