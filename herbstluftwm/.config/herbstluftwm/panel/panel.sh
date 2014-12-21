#!/bin/bash

#TODO colors

hc() { "${herbstclient_command[@]:-herbstclient}" "$@" ;}
monitor=${1:-0}
geometry=( $(herbstclient monitor_rect "$monitor") )
if [ -z "$geometry" ] ;then
    echo "Invalid monitor $monitor"
    exit 1
fi
# geometry has the format W H X Y
x=${geometry[0]}
y=${geometry[1]}
panel_width=${geometry[2]}
panel_height=16
# font="xft:Roboto:pixelsize=13:antialias=true:hinting=true"
font="xft:Source\ Code\ Pro\ Medium:pixelsize=13:antialias=true:hinting=true"
bgcolor='#1d1d1d'
selbg='#989898'
selfg='#2f2f2f'
wifi_int="wlp2s0"

panel_dir="/home/niels/.config/herbstluftwm/panel"
bmp_dir="${panel_dir}/bitmaps"

function uniq_linebuffered() {
  awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

function getPercentage() {
  echo "scale=2;$1" | bc | cut -d\. -f1
}

function printWorkspaces() {
  IFS=$'\t' read -ra tags <<< "$(hc tag_status $monitor)"
  # TODO: get rid of the float-desktop, cause this doesn't work
  unset $tags[${#tags[@]}-1]
  for i in "${tags[@]}" ; do
    case ${i:0:1} in
      '#')
        echo -n "^bg($selbg)^fg($selfg)"
        ;;
      '+')
        echo -n "^bg(#9CA668)^fg(#141414)"
        ;;
      ':')
        echo -n "^bg()^fg(#ffffff)"
        ;;
      '!')
        echo -n "^bg(#FF0675)^fg(#141414)"
        ;;
      *)
        echo -n "^bg()^fg(#ababab)"
        ;;
    esac
    uppercase=$(echo ${i:1} | tr '[:lower:]' '[:upper:]')
    echo -n "^ca(1,herbstclient focus_monitor $monitor && "'herbstclient use "'${i:1}'") '"$uppercase ^ca()"
  done
}

function generateData() {
    while true ; do
      # Date
      date_=$(date +'%H:%M')

      # Battery
      ba=$(acpi | sed 's/.*, \([0-9]*\)%/\1/')
      bab=$(${panel_dir}/bat_xbm_for_perc.py $ba )
      bica="${bmp_dir}/${bab}"

      # WiFi
      ssid=$(iwgetid -r)
      strngth=$(iwconfig $wifi_int | fgrep 'Link Quality' | sed 's/^.*Link Quality=\([0-9]*\/[0-9]*\).*/scale=2;100*\1/' | bc | cut -d\. -f1)
      if [ -z "$ssid" ] ; then
        wifi_ico="^i(${bmp_dir}/wifi_0.xbm)"
      else
        wifi_ico=$(${panel_dir}/wifi_xbm_for_perc.py $strngth )
        wifi_ico="^i(${bmp_dir}/${wico})"
      fi

      # Memory load
      perc_mem=$(free | sed -n '2p' | awk '{print "scale=2;100*"$3"/"$2}' | bc | cut -d\. -f1)
      mem_ico="^i(${bmp_dir}/mem.xbm)"

      # Volume
      perc_vol=$(amixer -D pulse get Master | grep -o '[0-9][0-9]*%' | head -1)
      if [[ -z $(amixer -D pulse get Master | fgrep 'off') ]] ; then
        vol_ico="^i(${bmp_dir}/spkr.xbm)"
      else
        vol_ico="^i(${bmp_dir}/vol-mute.xbm)"
      fi

      # Send the events
      echo -e "date\t^bg()^fg(#efefef)$date_ ^fg()"
      echo -e "wifi\t$ssid $wifi_ico^fg()"
      echo -e "battery\t^i($bica)$ba%^fg()"
      echo -e "load\t$mem_ico $perc_mem% ^fg()"
      echo -e "volume\t$vol_ico $perc_vol ^fg()"

      sleep 1 || break
    done > >(uniq_linebuffered) &

    # TODO: check what this does
    childpid=$!
    hc --idle
    kill $childpid
}

function showData() {
  visible=true
  date=""
  wifi=""
  batt=""
  volume=""
  load=""
  windowtitle=""

  while true ; do
    ### Output ###
    # This part prints dzen data based on the _previous_ data handling run,
    # and then waits for the next event to happen.
    echo -n "^bg()^fg() ${windowtitle}"
    echo -n "^pa($(($panel_width/2 - 220)))  "
    printWorkspaces
    echo -n "  "
    # TODO: give them a separate position
    echo -n "^pa($(($panel_width - 300)))"
    echo -n "$load  $volume  $batt  $wifi  $date"
    echo

    ### Data handling ###
    # This part handles the events generated in the event loop, and sets
    # internal variables based on them. The event and its arguments are
    # read into the array cmd, then action is taken depending on the event
    # name. "Special" events (quit_panel/togglehidepanel/reload) are also
    # handled here.

    # wait for next event
    IFS=$'\t' read -ra cmd || break
    # find out event origin
    case "${cmd[0]}" in
      # tag*)
        #echo "resetting tags" >&2
        # IFS=$'\t' read -ra tags <<< "$(hc tag_status $monitor | tr '[:lower:]' '[:upper:]')"
        # ;;
      date*)
        date="${cmd[@]:1}"
        ;;
      battery*)
        batt="${cmd[@]:1}"
        ;;
      wifi*)
        wifi="${cmd[@]:1}"
        ;;
      volume*)
        volume="${cmd[@]:1}"
        ;;
      load*)
        load="${cmd[@]:1}"
        ;;
      quit_panel)
        exit
        ;;
      togglehidepanel)
        currentmonidx=$(hc list_monitors | sed -n '/\[FOCUS\]$/s/:.*//p')
        if [ "${cmd[1]}" -ne "$monitor" ] ; then
            continue
        fi
        if [ "${cmd[1]}" = "current" ] && [ "$currentmonidx" -ne "$monitor" ] ; then
            continue
        fi
        echo "^togglehide()"
        if $visible ; then
            visible=false
            hc pad $monitor 0
        else
            visible=true
            hc pad $monitor $panel_height
        fi
        ;;
      reload)
        exit
        ;;
      focus_changed|window_title_changed)
        windowtitle="${cmd[@]:2}"
        ;;
    esac
  done

  ### dzen2 ###
  # After the data is gathered and processed, the output of the previous block
  # gets piped to dzen2.
}

# Kill previous instances
kill -9 $(ps ux | grep panel.sh | awk -F\  -v pid=$$ 'pid != $2 {print $2}')

# Make room for our panel
hc pad $monitor $panel_height

# Let shit hit the fan
generateData 2> /dev/null | showData 2> /dev/null | dzen2 -w $panel_width \
  -x $x -y $y -h $panel_height -ta l -fn "$font" \
  -e 'button3=;button4=exec:herbstclient use_index -1;button5=exec:herbstclient use_index +1'

