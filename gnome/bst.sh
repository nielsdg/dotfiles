#!/bin/sh
#
# Source this script to get some easy aliases when working with buildstream
# (which can be confusing coming from jhbuild).
#
# Author: Niels De Graef <nielsdegraef@gmail.com>

PROJECTS_DIR="$HOME/Projects"
GNOME_BST_DIR="$PROJECTS_DIR/gnome-build-meta"

# Finds an element in the GNOME BST repo and returns the relative path to it.
# For example, `gbst_find_element mutter` will return "core/mutter.bst"
gbst_find_element() {
  ELEMENT_NAME="${1:-}"
  if [ -z "$ELEMENT_NAME" ]; then
    echo "No element name given"
    return 1
  fi

  # Firs try an exact find
  ELEMENT_MATCHES="$(find "$GNOME_BST_DIR" -iname "$ELEMENT_NAME.bst" -printf '%P\n')"
  if [ -z "$ELEMENT_MATCHES" ]; then

    # If we didn't find anything, maybe some prefix/suffix is there (like a version)
    ELEMENT_MATCHES="$(find "$GNOME_BST_DIR" -iname "*$ELEMENT_NAME*.bst" -printf '%P\n')"
    if [ -z "$ELEMENT_MATCHES" ]; then
      echo "No matches found for $ELEMENT_NAME"
      return 1
    fi
  fi

  ELEMENT="$(echo "$ELEMENT_MATCHES" | head -1 | sed 's/^elements\///' )"
  echo "$ELEMENT"
}

# Takes an element name as argument and creates a workspace for it
# (in other words, you get a local git repo for it)
gbst_checkout() {
  ELEMENT_NAME="${1:-}"
  if [ -z "$ELEMENT_NAME" ]; then
    echo "No element name given"
    return 1
  fi

  RESULT_DIR="$PROJECTS_DIR/$ELEMENT_NAME"

  # No need to do anything if it already exists
  if [ -d "$RESULT_DIR" ]; then
    echo "Directory '$RESULT_DIR' already exists"
    return 0
  fi

  # First find the place of the specific element
  ELEMENT="$(gbst_find_element "$ELEMENT_NAME")"
  if [ -z "$ELEMENT_MATCHES" ]; then
    echo "No matches found for $ELEMENT_NAME"
    return 1
  fi
  echo "Found element '$ELEMENT'"

  # Make sure we have a track of it in bst
  bst -C "$GNOME_BST_DIR" track "$ELEMENT"

  # Now create the folder
  bst -C "$GNOME_BST_DIR" workspace open "$ELEMENT" "$PROJECTS_DIR/$ELEMENT_NAME"
}

# Builds an element which was already checked out
gbst_build() {
  ELEMENT_NAME="${1:-}"
  if [ -z "$ELEMENT_NAME" ]; then
    echo "No element name given"
    return 1
  fi

  RESULT_DIR="$PROJECTS_DIR/$ELEMENT_NAME"

  # First find the place of the specific element
  ELEMENT="$(gbst_find_element "$ELEMENT_NAME")"
  if [ -z "$ELEMENT_MATCHES" ]; then
    echo "No matches found for $ELEMENT_NAME"
    return 1
  fi
  echo "Found element '$ELEMENT'"

  # Make sure we have a track of it in bst
  bst -C "$GNOME_BST_DIR" build "$ELEMENT"
}
