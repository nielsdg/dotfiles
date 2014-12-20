#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


#-------------------------------------------------------------
# Prompt
#-------------------------------------------------------------
PS1='[\u@\h \W]\$ '

#-------------------------------------------------------------
# Defaults
#-------------------------------------------------------------
export PATH="$PATH:/opt/lampp/bin/"
export BROWSER="firefox-beta-bin"
export EDITOR="vim"
export VISUAL="vim"

#-------------------------------------------------------------
# Aliases
#-------------------------------------------------------------
alias vi='vim'
# replace error-prone commands
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

# some useful new aliases
alias ll='ls -l -h'

# colorize some common commands
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# easy update command
alias update='yaourt -Syua'

alias firefox='firefox-beta-bin'

# git
alias gs='git status'


#-------------------------------------------------------------
# Functions
#-------------------------------------------------------------

# Returns the system load as a percentage
function system_load() {
    local SYSLOAD=$(cut -d " " -f1 /proc/loadavg | tr -d '.')
    # System load of the current host.
    echo $((10#$SYSLOAD)) "%"      # Convert to decimal.
}

# Handy extract program
function extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xvjf $1     ;;
            *.tar.gz)    tar xvzf $1     ;;
            *.bz2)       bunzip2 $1      ;;
            *.rar)       unrar x $1      ;;
            *.gz)        gunzip $1       ;;
            *.tar)       tar xvf $1      ;;
            *.tbz2)      tar xvjf $1     ;;
            *.tgz)       tar xvzf $1     ;;
            *.zip)       unzip $1        ;;
            *.Z)         uncompress $1   ;;
            *.7z)        7z x $1         ;;
            *)           echo "'$1' cannot be extracted via >extract<" ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

# Create a ZIP archive of a file or folder.
function makezip() { zip -r "${1%%/}.zip" "$1" ; }

# Youtube Download - Depends on youtube-dl-git (AUR)
#---------------------
alias youtube-mp3='youtube-dl --extract-audio --audio-format mp3 --prefer-ffmpeg'

