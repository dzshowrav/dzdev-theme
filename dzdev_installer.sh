#!/bin/bash

# ==========================================
# dzdev - Ultimate Termux Theme Installer
# ==========================================

clear
echo -e "\e[1;36m╭──────────────────────────────────────────╮\e[0m"
echo -e "\e[1;36m│\e[1;37m      dzdev Ultimate Theme Installer      \e[1;36m│\e[0m"
echo -e "\e[1;36m╰──────────────────────────────────────────╯\e[0m"
echo ""

echo -ne "\e[1;33mWhat is your name? (Leave blank for 'Dzdev'): \e[0m"
read -r INPUT_NAME
if [ -z "$INPUT_NAME" ]; then INPUT_NAME="Dzdev"; fi
echo "USER_NAME=\"$INPUT_NAME\"" > ~/.termux_theme_config
echo ""

spinner() {
    local pid=$1
    local msg="$2"
    local delay=0.1
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    # Add a trap to ensure cursor is not lost if killed early
    tput civis
    while kill -0 $pid 2>/dev/null; do
        printf "\r \e[1;35m%s\e[0m  %s" "${frames[i]}" "$msg"
        i=$(( (i + 1) % 10 ))
        sleep $delay
    done
    printf "\r \e[1;32m✔\e[0m  %s\n" "$msg"
    tput cnorm
}

# 1. Install dependencies
msg="\e[1;33m[1/6] Installing dependencies (lsd, curl, figlet)...\e[0m"
(pkg update -y > /dev/null 2>&1 && pkg install lsd curl figlet -y > /dev/null 2>&1) &
spinner $! "$msg"

# 2. Setup Termux Directory & Font
msg="\e[1;33m[2/6] Downloading JetBrainsMono Nerd Font...\e[0m"
mkdir -p ~/.termux
(curl -sL -o ~/.termux/font.ttf "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf" > /dev/null 2>&1) &
spinner $! "$msg"

# 3. Create Colors
msg="\e[1;33m[3/6] Applying color palette...\e[0m"
(
cat << 'EOF' > ~/.termux/colors.properties
background=#000000
foreground=#ffffff
cursor=#ffffff
color0=#000000
color1=#ff5555
color2=#50fa7b
color3=#f1fa8c
color4=#bd93f9
color5=#ff79c6
color6=#8be9fd
color7=#bbbbbb
color8=#555555
color9=#ff5555
color10=#50fa7b
color11=#f1fa8c
color12=#bd93f9
color13=#ff79c6
color14=#8be9fd
color15=#ffffff
EOF
) &
spinner $! "$msg"

# 4. Create Login System
msg="\e[1;33m[4/6] Installing Secure Login System...\e[0m"
(
cat << 'EOF' > ~/.termux_login.sh
#!/bin/bash
AUTH_FILE="$HOME/.termux_auth_data"
trap '' INT TSTP
RED="\e[1;31m"; GREEN="\e[1;32m"; CYAN="\e[1;36m"; YELLOW="\e[1;33m"; WHITE="\e[1;37m"; RESET="\e[0m"

draw_banner() {
    clear
    echo -e "${CYAN}╭──────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}│                                          │${RESET}"
    echo -e "${CYAN}│${WHITE}         SECURE TERMUX ACCESS           ${CYAN}│${RESET}"
    echo -e "${CYAN}│                                          │${RESET}"
    echo -e "${CYAN}╰──────────────────────────────────────────╯${RESET}"
    echo ""
}
hash_string() { echo -n "$1" | sha256sum | awk '{print $1}'; }

if [ ! -f "$AUTH_FILE" ]; then
    draw_banner
    echo -e "${YELLOW} Welcome! Let's set up your secure login.${RESET}\n"
    while true; do
        read -s -p "$(echo -e ${WHITE} "Enter a new password: " ${RESET})" pass1; echo ""
        read -s -p "$(echo -e ${WHITE} "Confirm password: " ${RESET})" pass2; echo ""
        if [ "$pass1" == "$pass2" ] && [ ! -z "$pass1" ]; then break; else
            echo -e "${RED} ✘ Passwords do not match or are empty. Try again.${RESET}\n"
        fi
    done
    echo -e "\n${CYAN} --- Recovery Setup ---${RESET}"
    read -p "$(echo -e ${WHITE} "Enter a custom security question: " ${RESET})" seq_q
    read -s -p "$(echo -e ${WHITE} "Enter the answer: " ${RESET})" seq_a; echo ""
    echo "$seq_q" > "$AUTH_FILE"; hash_string "$seq_a" >> "$AUTH_FILE"; hash_string "$pass1" >> "$AUTH_FILE"
    echo -e "${GREEN} ✔ Setup complete! Locking terminal...${RESET}"; sleep 2
fi

readarray -t AUTH_DATA < "$AUTH_FILE"
Q_TEXT="${AUTH_DATA[0]}"; A_HASH="${AUTH_DATA[1]}"; P_HASH="${AUTH_DATA[2]}"

while true; do
    draw_banner
    echo -e "${WHITE} Type ${YELLOW}'forgot'${WHITE} if you lost your password.${RESET}\n"
    read -s -p "$(echo -e ${CYAN} "   Password: " ${RESET})" input_pass; echo ""
    if [ "$input_pass" == "forgot" ]; then
        echo -e "\n${YELLOW} --- Password Recovery ---${RESET}"
        echo -e "${WHITE} Question: ${CYAN}$Q_TEXT${RESET}"
        read -s -p "$(echo -e ${WHITE} " Answer: " ${RESET})" input_ans; echo ""
        if [ "$(hash_string "$input_ans")" == "$A_HASH" ]; then
            echo -e "${GREEN} ✔ Correct! You may now reset your password.${RESET}"
            read -s -p "$(echo -e ${WHITE} " New password: " ${RESET})" new_pass; echo ""
            P_HASH=$(hash_string "$new_pass")
            echo "$Q_TEXT" > "$AUTH_FILE"; echo "$A_HASH" >> "$AUTH_FILE"; echo "$P_HASH" >> "$AUTH_FILE"
            echo -e "${GREEN} ✔ Password updated. Please login again.${RESET}"; sleep 2; continue
        else
            echo -e "${RED} ✘ Incorrect answer.${RESET}"; sleep 2
        fi
    elif [ "$(hash_string "$input_pass")" == "$P_HASH" ]; then
        echo -e "${GREEN}  Access Granted.${RESET}"; sleep 1; break
    else
        echo -e "${RED}  Access Denied.${RESET}"; sleep 2
    fi
done
trap - INT TSTP
clear
EOF
) &
spinner $! "$msg"

# 5. Create P10k Clone Prompt
msg="\e[1;33m[5/6] Writing Custom Bash Prompt...\e[0m"
(
cat << 'EOF' > ~/.bashrc_prompt
source ~/.termux_theme_config

BG_OS="\[\e[48;5;236m\]"; FG_OS="\[\e[38;5;255m\]"
BG_DIR="\[\e[48;5;31m\]"; FG_DIR="\[\e[38;5;254m\]"
BG_GIT_CLEAN="\[\e[48;5;76m\]"; FG_GIT_CLEAN="\[\e[38;5;0m\]"
BG_GIT_DIRTY="\[\e[48;5;208m\]"; FG_GIT_DIRTY="\[\e[38;5;0m\]"
BG_RIGHT="\[\e[48;5;160m\]"; FG_RIGHT="\[\e[38;5;255m\]"
SEP_OS_DIR="\[\e[38;5;236m\]\[\e[48;5;31m\]"
SEP_DIR_GIT_CLEAN="\[\e[38;5;31m\]\[\e[48;5;76m\]"
SEP_DIR_GIT_DIRTY="\[\e[38;5;31m\]\[\e[48;5;208m\]"
SEP_DIR_END="\[\e[38;5;31m\]\[\e[49m\]"
SEP_GIT_CLEAN_END="\[\e[38;5;76m\]\[\e[49m\]"
SEP_GIT_DIRTY_END="\[\e[38;5;208m\]\[\e[49m\]"
SEP_RIGHT_START="\[\e[38;5;160m\]\[\e[49m\]"
PROMPT_END="\[\e[38;5;76m\]"; PROMPT_BLUE="\[\e[38;5;31m\]"
RESET="\[\e[0m\]"; SEP=""; RSEP=""; FRAME_COLOR="\[\e[38;5;76m\]"

GIT_BLOCK=""
get_git_status() {
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    if [[ -n $(git status -s 2>/dev/null) ]]; then
       GIT_BLOCK="${SEP_DIR_GIT_DIRTY}${SEP}${FG_GIT_DIRTY}${BG_GIT_DIRTY}  ${branch} ${SEP_GIT_DIRTY_END}${SEP}${RESET}"
    else
       GIT_BLOCK="${SEP_DIR_GIT_CLEAN}${SEP}${FG_GIT_CLEAN}${BG_GIT_CLEAN}  ${branch} ${SEP_GIT_CLEAN_END}${SEP}${RESET}"
    fi
  else GIT_BLOCK="${SEP_DIR_END}${SEP}${RESET}"; fi
}

GLOBE_INDEX=0
GLOBE_FRAMES=("🌍" "🌎" "🌏")

build_prompt() {
  local exit_code=$?
  get_git_status
  
  GLOBE_INDEX=$(( (GLOBE_INDEX + 1) % 3 ))
  local GLOBE="${GLOBE_FRAMES[$GLOBE_INDEX]}"
  
  local FRAME_TOP="${FRAME_COLOR}╭─${RESET}"
  local OS_BLOCK="${BG_OS}${FG_OS}  "
  local DIR_BLOCK="${SEP_OS_DIR}${SEP}${FG_DIR}${BG_DIR}   \w "
  local STATUS_ICON=""
  if [ $exit_code -eq 0 ]; then STATUS_ICON="\[\e[38;5;76m\]✔ "; else STATUS_ICON="\[\e[38;5;160m\]✘ "; fi
  local RIGHT_BLOCK=" ${STATUS_ICON}${SEP_RIGHT_START}${RSEP}${BG_RIGHT}${FG_RIGHT} ${USER_NAME}, ${GLOBE}  ${RESET}"
  local FRAME_BOT="${FRAME_COLOR}╰─${PROMPT_END}❯${PROMPT_BLUE}❯${PROMPT_END}❯${RESET} "
  PS1="\n${FRAME_TOP}${OS_BLOCK}${DIR_BLOCK}${GIT_BLOCK}${RIGHT_BLOCK}\n${FRAME_BOT}"
}
PROMPT_COMMAND=build_prompt
EOF
) &
spinner $! "$msg"

# 6. Create bashrc
msg="\e[1;33m[6/6] Configuring .bashrc...\e[0m"
(
cat << 'EOF' > ~/.bashrc
# Termux Configuration
source ~/.termux_theme_config

# Run Secure Login System
if [ -f ~/.termux_login.sh ]; then
    source ~/.termux_login.sh
fi

clear

# Generate Giant Welcome Banner
echo -e "\e[1;36m"
figlet -f standard "$USER_NAME"
echo -e "\e[0m"

# Enable LSD for beautiful file listings
alias ls='lsd --group-directories-first'
alias la='lsd -a -l --header --group-directories-first --blocks name,size,date'
alias ll='lsd -l --header --group-directories-first --blocks name,size,date'
alias grep='grep --color=auto'

# Source the custom powerlevel10k clone prompt
if [ -f ~/.bashrc_prompt ]; then
    source ~/.bashrc_prompt
fi
EOF
) &
spinner $! "$msg"

termux-reload-settings
echo -e "\n\e[1;32m🎉 Installation Complete! Please completely restart Termux to enjoy your new theme!\e[0m"
