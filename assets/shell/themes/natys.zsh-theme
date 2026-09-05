# Clean, simple, compatible and meaningful.
# Tested on Linux, Unix and Windows under ANSI colors.
# It is recommended to use with a dark background.
# Colors: black, red, green, yellow, *blue, magenta, cyan, and white.
#
# Mar 2013 Yad Smood

# VCS
YS_VCS_PROMPT_PREFIX1=" %{$reset_color%}on%{$fg[blue]%} "
YS_VCS_PROMPT_PREFIX2=":%{$fg[cyan]%}"
YS_VCS_PROMPT_SUFFIX="%{$reset_color%}"
YS_VCS_PROMPT_DIRTY=" %{$fg[red]%}x"
YS_VCS_PROMPT_CLEAN=" %{$fg[green]%}o"

# Git info
local git_info='$(git_prompt_info)'
ZSH_THEME_GIT_PROMPT_PREFIX="${YS_VCS_PROMPT_PREFIX1}git${YS_VCS_PROMPT_PREFIX2}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$YS_VCS_PROMPT_SUFFIX"
ZSH_THEME_GIT_PROMPT_DIRTY="$YS_VCS_PROMPT_DIRTY"
ZSH_THEME_GIT_PROMPT_CLEAN="$YS_VCS_PROMPT_CLEAN"

# SVN info
local svn_info='$(svn_prompt_info)'
ZSH_THEME_SVN_PROMPT_PREFIX="${YS_VCS_PROMPT_PREFIX1}svn${YS_VCS_PROMPT_PREFIX2}"
ZSH_THEME_SVN_PROMPT_SUFFIX="$YS_VCS_PROMPT_SUFFIX"
ZSH_THEME_SVN_PROMPT_DIRTY="$YS_VCS_PROMPT_DIRTY"
ZSH_THEME_SVN_PROMPT_CLEAN="$YS_VCS_PROMPT_CLEAN"

# HG info
local hg_info='$(ys_hg_prompt_info)'
ys_hg_prompt_info() {
	# make sure this is a hg dir
	if [ -d '.hg' ]; then
		echo -n "${YS_VCS_PROMPT_PREFIX1}hg${YS_VCS_PROMPT_PREFIX2}"
		echo -n $(hg branch 2>/dev/null)
		if [[ "$(hg config oh-my-zsh.hide-dirty 2>/dev/null)" != "1" ]]; then
			if [ -n "$(hg status 2>/dev/null)" ]; then
				echo -n "$YS_VCS_PROMPT_DIRTY"
			else
				echo -n "$YS_VCS_PROMPT_CLEAN"
			fi
		fi
		echo -n "$YS_VCS_PROMPT_SUFFIX"
	fi
}

# Virtualenv
local venv_info='$(virtenv_prompt)'
YS_THEME_VIRTUALENV_PROMPT_PREFIX=" %{$fg[green]%}"
YS_THEME_VIRTUALENV_PROMPT_SUFFIX=" %{$reset_color%}%"
virtenv_prompt() {
	[[ -n "${VIRTUAL_ENV:-}" ]] || return
	echo "${YS_THEME_VIRTUALENV_PROMPT_PREFIX}${VIRTUAL_ENV:t}${YS_THEME_VIRTUALENV_PROMPT_SUFFIX}"
}

# Dòng response sau mỗi lệnh: mã thoát + thời gian chạy, in nghiêng giữa
# output và prompt kế. Chỉ dựng khi preexec đã chạy — $? KHÔNG reset khi Enter
# dòng rỗng nên thiếu cờ thì mã lỗi cũ dính lại mãi.
zmodload zsh/datetime
zmodload zsh/terminfo
autoload -Uz add-zsh-hook

_natys_mark='󰘍  '
[[ $TERM == linux ]] && _natys_mark='->  '
_natys_resp=

_natys_green=( 0 )
_natys_yellow=( 130 143 148 )   # Ctrl-C, TERM, Ctrl-Z

typeset -A _natys_names=( 126 'not executable' 127 'command not found' )

_natys_preexec() {
    _natys_ran=1
    _natys_t0=$EPOCHREALTIME
}

_natys_duration() {
    local -F el=$1
    local -i m s
    if (( el < 1 )); then
        printf '%.0fms' $(( el * 1000 ))
    elif (( el < 60 )); then
        printf '%.1fs' $el
    else
        m=$(( el / 60 )); s=$(( el - m * 60 ))
        printf '%dm%02ds' $m $s
    fi
}

_natys_precmd() {
    local ret=$?
    [[ -n $_natys_ran ]] || { _natys_resp=; return $ret }
    _natys_ran=

    # Tên chỉ đáng tin ở 128+N (signal, $signals lệch 1 index; EXIT/ZERR/DEBUG là
    # pseudo-signal của zsh) và 126/127 (do chính zsh sinh, không phải app).
    local name= sig=
    (( ret > 128 )) && sig=$signals[ret-127]
    if [[ -n $sig && $sig != (EXIT|ZERR|DEBUG) ]]; then
        name=" (SIG$sig)"
    elif [[ -n $_natys_names[$ret] ]]; then
        name=" ($_natys_names[$ret])"
    fi

    local color=red
    (( $_natys_green[(I)$ret]  )) && color=green
    (( $_natys_yellow[(I)$ret] )) && color=yellow

    # %f chứ không phải $reset_color — reset_color tắt luôn cả italic.
    local dur=$(_natys_duration $(( EPOCHREALTIME - _natys_t0 )))
    _natys_resp=$'\n'"%{$terminfo[sitm]%}%F{$color}${_natys_mark}${ret}${name}%f %F{8}· ${dur}%f%{$terminfo[ritm]%}"$'\n'
    return $ret
}

add-zsh-hook preexec _natys_preexec
add-zsh-hook precmd _natys_precmd

# Prompt format:
#
# 󰘍  EXIT_CODE (SIGNAL) · DURATION
#
# PRIVILEGES USER @ MACHINE in DIRECTORY on git:BRANCH STATE [TIME]
# $ COMMAND
#
# For example:
#
# 󰘍  130 (SIGINT) · 2.1s
#
# % ys @ ys-mbp in ~/.oh-my-zsh on git:master x [21:47:42]
# $
PROMPT='${_natys_resp}'"
%{$terminfo[bold]$fg[blue]%}#%{$reset_color%} \
%(#,%{$bg[yellow]%}%{$fg[black]%}%n%{$reset_color%},%{$fg[cyan]%}%n)\
%{$reset_color%}@\
%{$fg[green]%}%m \
%{$reset_color%}in \
%{$terminfo[bold]$fg[yellow]%}%~%{$reset_color%}\
${hg_info}\
${git_info}\
${svn_info}\
${venv_info}\
 \
[%*]
%{$terminfo[bold]$fg[magenta]%}$ %{$reset_color%}"
