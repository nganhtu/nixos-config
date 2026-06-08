#!/bin/sh
# statusLine command cho Claude Code

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

WHITE=$(printf '\033[37m')
GRAY=$(printf '\033[38;5;245m')
RESET=$(printf '\033[0m')

cwd_display=$(echo "$cwd" | sed "s|^$HOME|~|")

branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
branch_info=""
if [ -n "$branch" ]; then
    branch_info=" ${GRAY}[${branch}]${RESET}"
fi

line1="${WHITE}${cwd_display}${RESET}${branch_info}   ${WHITE}Model: ${model}${RESET}"

line2=""
if [ -n "$used" ]; then
    line2="${WHITE}Context: $(printf '%.0f' "$used")%${RESET}"
fi

if [ -n "$five_h" ]; then
    five_h_str="${WHITE}5-hour quota: $(printf '%.0f' "$five_h")%${RESET}"
    if [ -n "$five_h_reset" ]; then
        reset_time=$(date -d "@${five_h_reset}" "+%H:%M" 2>/dev/null)
        [ -n "$reset_time" ] && five_h_str="${five_h_str} ${GRAY}(${reset_time})${RESET}"
    fi
    if [ -n "$line2" ]; then
        line2="${line2}      ${five_h_str}"
    else
        line2="${five_h_str}"
    fi
fi

if [ -n "$week" ]; then
    week_str="${WHITE}Weekly quota: $(printf '%.0f' "$week")%${RESET}"
    if [ -n "$week_reset" ]; then
        reset_time=$(date -d "@${week_reset}" "+%a %d/%m %H:%M" 2>/dev/null)
        [ -n "$reset_time" ] && week_str="${week_str} ${GRAY}(${reset_time})${RESET}"
    fi
    if [ -n "$line2" ]; then
        line2="${line2}      ${week_str}"
    else
        line2="${week_str}"
    fi
fi

printf "%s" "$line1"
[ -n "$line2" ] && printf "\n%s" "$line2"
printf "%s" "$RESET"
