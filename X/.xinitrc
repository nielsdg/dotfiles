#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)
if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

# Disable beep
xset -b

# Load settings
if [ -f ~/.Xresources ]; then
  xrdb -merge ~/.Xresources
fi

# Load custom key settings (e.g. volume up/down)
xbindkeys

# start the terminal emulator daemon
urxvtd -q -f -o &

# Start window manager
exec herbstluftwm --locked

