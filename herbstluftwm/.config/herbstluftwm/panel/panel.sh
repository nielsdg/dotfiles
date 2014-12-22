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
panel_height=18
# font="xft:Roboto:pixelsize=13:antialias=true:hinting=true"
font='xft:Source\ Code\ Pro\ Medium:pixelsize=13:antialias=true:hinting=true'
foreground="#000000"
background='#68afcf'
selbg='#185279'
selfg='#2f2f2f'
wifi_int='wlp2s0'

panel_dir="$HOME/.config/herbstluftwm/panel"
bmp_dir="${panel_dir}/bitmaps"

# Checks whether the data has changed so we don't do unnecessary repaints
function uniq_linebuffered() {
  awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

# Note: we don't do this during the data generation phase because this seems to
# be a intensive calculation somehow.
function printWorkspaces() {
  tags=( $(herbstclient tag_status $monitor) )
  unset tags[${#tags[@]}-1]

  for i in "${tags[@]}" ; do
    case ${i:0:1} in
      '#') # tag is viewed on the specified MONITOR and it is focused
        echo -n "^bg($selbg)^fg($selfg)"
        ;;
      '+') # tag is viewed on the specified MONITOR but this monitor is not focused
        echo -n "^bg(#9CA668)^fg(#141414)"
        ;;
      ':') # tag is not empty
        echo -n "^bg()^fg(#ffffff)"
        ;;
      '!') # tag contains an urgent window
        echo -n "^bg(#FF0675)^fg(#141414)"
        ;;
      *)
        echo -n "^bg()^fg()"
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
      echo -e "date\t$date_"

      # Battery
      batt_perc=$(acpi | sed 's/.*, \([0-9]*\)%/\1/')
      batt_num=$(( (batt_perc - 1)/10 ))
      batt_ico="^i(${bmp_dir}/bat_${batt_num}.xbm)"
      echo -e "battery\t$batt_ico $batt_perc%"

      # WiFi
      ssid=$(iwgetid -r)
      if [ -z "$ssid" ] ; then
        wifi_ico="^i(${bmp_dir}/wifi_none.xbm)"
      else
        strngth=$(iwconfig $wifi_int 2>/dev/null | fgrep 'Link Quality' | sed 's/^.*Link Quality=\([0-9]*\/[0-9]*\).*/scale=2;100*\1/' | bc | cut -d\. -f1)
        wifi_num=$(( (strngth + 19)/20 ))
        wifi_ico="^i(${bmp_dir}/wifi_${wifi_num}.xbm)"
      fi
      echo -e "wifi\t$ssid $wifi_ico"

      # Memory load
      perc_mem=$(free | awk 'NR==2{print "scale=2;100*"$3"/"$2; exit}' | bc | cut -d\. -f1)
      mem_ico="^i(${bmp_dir}/mem.xbm)"
      echo -e "load\t$mem_ico $perc_mem%"

      # Volume
      perc_vol=$(amixer -D pulse get Master | grep -o '[0-9][0-9]*%' | head -1)
      if [[ -z $(amixer -D pulse get Master | fgrep 'off') ]] ; then
        vol_ico="^i(${bmp_dir}/spkr.xbm)"
      else
        vol_ico="^i(${bmp_dir}/vol-mute.xbm)"
      fi
      echo -e "volume\t$vol_ico $perc_vol"

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
    echo -n "^bg()^fg()  "
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
generateData 2>/dev/null | showData 2>/dev/null | dzen2 -w $panel_width \
  -x $x -y $y -h $panel_height -ta l -fn "$font" -bg "$background" -fg "$foreground" \
  -e 'button3=;button4=exec:herbstclient use_index -1;button5=exec:herbstclient use_index +1'

