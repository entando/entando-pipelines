#/bin/bash

_require "$PROJECT_DIR/lib/shared/itmlst.sh"

#TEST:unit,lib,itmlst
test_itmlst.utils() {
  local itmlst
  _itmlst.fill itmlst "red" "green" "blue"
  _itmlst.contains "$itmlst" "red"  || _FAIL
  _itmlst.contains "$itmlst" "green" || _FAIL
  _itmlst.contains "$itmlst" "blue"  || _FAIL
  _itmlst.contains "$itmlst" "blu" && _FAIL
  
  _itmlst.from_string itmlst ""
  _itmlst.is_item_enabled "$itmlst" "red" && _FAIL
  
  _itmlst.from_string itmlst "red,green|blue"$'\n'"yellow"
  _itmlst.is_item_enabled "$itmlst" "red" || _FAIL
  _itmlst.is_item_enabled "$itmlst" "green" || _FAIL
  _itmlst.is_item_enabled "$itmlst" "blue" || _FAIL
  _itmlst.is_item_enabled "$itmlst" "yellow" || _FAIL
  
  _itmlst.from_string itmlst "*"
  _itmlst.is_item_enabled "$itmlst" "red" || _FAIL
  _itmlst.is_item_enabled "$itmlst" "green" || _FAIL
  _itmlst.is_item_enabled "$itmlst" "blue" || _FAIL
  _itmlst.is_item_enabled "$itmlst" "yellow" || _FAIL

  _itmlst.from_string itmlst "*,-blue"
  _itmlst.is_item_enabled "$itmlst" "red" || _FAIL
  _itmlst.is_item_enabled "$itmlst" "green" || _FAIL
  _itmlst.is_item_enabled "$itmlst" "blue" && _FAIL
  _itmlst.is_item_enabled "$itmlst" "yellow" || _FAIL
  
  _itmlst.from_string itmlst "red,green|blue"$'\n'"yellow|-*|blue"
  _itmlst.is_item_enabled "$itmlst" "red" && _FAIL
  _itmlst.is_item_enabled "$itmlst" "green" && _FAIL
  _itmlst.is_item_enabled "$itmlst" "blue" || _FAIL
  _itmlst.is_item_enabled "$itmlst" "yellow" && _FAIL
}
