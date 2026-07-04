#!/usr/bin/env zsh

PIDFILE="/tmp/pomodoro.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    exit 0
fi

echo $$ > "$PIDFILE"

trap "rm -f $PIDFILE" EXIT

# ===== Configuração =====
WORK_MIN=25
BREAK_MIN=5
LONG_BREAK_MIN=30
CYCLES_BEFORE_LONG_BREAK=4
SOUND_FILE="/usr/share/sounds/freedesktop/stereo/complete.oga"

cycle=1
total_completed=0

# ===== Dígitos ASCII grandes (7 linhas cada) =====
typeset -A DIGITS
DIGITS[0]="  ███  | ██ ██ |██   ██|██   ██|██   ██| ██ ██ |  ███  "
DIGITS[1]="  ██   | ███   |  ██   |  ██   |  ██   |  ██   |██████ "
DIGITS[2]=" █████ |██   ██|     ██|  ████ | ██    |██     |███████"
DIGITS[3]=" █████ |██   ██|     ██|  ████ |     ██|██   ██| █████ "
DIGITS[4]="██   ██|██   ██|██   ██|███████|     ██|     ██|     ██"
DIGITS[5]="███████|██     |██     |██████ |     ██|██   ██| █████ "
DIGITS[6]=" █████ |██   ██|██     |██████ |██   ██|██   ██| █████ "
DIGITS[7]="███████|     ██|    ██ |   ██  |  ██   |  ██   |  ██   "
DIGITS[8]=" █████ |██   ██|██   ██| █████ |██   ██|██   ██| █████ "
DIGITS[9]=" █████ |██   ██|██   ██| ██████|     ██|██   ██| █████ "
DIGITS[":"]="       |  ███  |  ███  |       |  ███  |  ███  |       "

# Largura visível de cada dígito+espaço = 9 chars; "MM:SS" = 5 símbolos × 9 = 45
TIMER_WIDTH=45

# ===== Padding para centrar (devolve string de espaços) =====
function pad_center() {
  local visible_len=$1
  local cols=$COLUMNS
  local p=$(( (cols - visible_len) / 2 ))
  (( p < 0 )) && p=0
  printf "%${p}s" ""
}

# ===== Timer ASCII grande centrado =====
function big_timer() {
  local time_str=$1
  local color=$2         # ex: $'\e[32m'
  local chars=("${(@s::)time_str}")

  # Construir as 7 linhas
  local row_arr=("" "" "" "" "" "" "")
  for ch in $chars; do
    local digit="${DIGITS[$ch]}"
    local dlines=("${(@s:|:)digit}")   # split por "|"
    for i in {1..7}; do
      row_arr[$i]+="${dlines[$i]}  "
    done
  done

  local indent="$(pad_center $TIMER_WIDTH)"
  for i in {1..7}; do
    print -n "${indent}${color}"
    print "${row_arr[$i]}"$'\e[0m'
  done
}

# ===== Imprimir linha centrada (texto já sem escapes na contagem) =====
# $1 = texto para imprimir (com escapes)
# $2 = comprimento VISÍVEL do texto (sem escapes)
function cline() {
  local text=$1
  local vlen=$2
  local indent="$(pad_center $vlen)"
  print "${indent}${text}"
}

# ===== Barra de progresso centrada =====
function progress_bar() {
  local elapsed=$1
  local total=$2
  local bar_w=$(( COLUMNS * 55 / 100 ))
  (( bar_w < 10 )) && bar_w=10
  (( bar_w > 58 )) && bar_w=58

  local filled=$(( total > 0 ? elapsed * bar_w / total : 0 ))
  (( filled > bar_w )) && filled=$bar_w
  local empty=$(( bar_w - filled ))

  local indent="$(pad_center $bar_w)"
  print -n "${indent}"$'\e[32m'
  for (( i=0; i<filled; i++ )); do print -n "█"; done
  print -n $'\e[90m'
  for (( i=0; i<empty; i++ )); do print -n "░"; done
  print $'\e[0m'
}

# ===== Limpeza ao sair =====
function cleanup() {
  tput cnorm
  tput rmcup
  stty sane 2>/dev/null
  print ""
  print $'\e[31;1m⛔  Pomodoro encerrado.\e[0m'
  print $'\e[90mCompletados: \e[0m\e[1m'"${total_completed}"$'\e[0m pomodoros'
  print ""
  exit 0
}
trap cleanup INT TERM

# ===== Som =====
function play_sound() {
  if command -v paplay >/dev/null 2>&1 && [[ -f $SOUND_FILE ]]; then
    paplay "$SOUND_FILE" &>/dev/null &!
  elif command -v aplay >/dev/null 2>&1 && [[ -f $SOUND_FILE ]]; then
    aplay "$SOUND_FILE" &>/dev/null &!
  else
    print '\a'
  fi
}

# ===== Notificação KDE =====
function notify_msg() {
  command -v notify-send >/dev/null 2>&1 && \
    notify-send -u normal -t 5000 "Pomodoro" "$1" &>/dev/null &!
}

# ===== Desenhar ecrã =====
function draw_screen() {
  local phase_label=$1     # texto limpo, sem escapes
  local phase_color=$2     # ex: $'\e[32m'
  local elapsed=$3
  local total_secs=$4
  local paused=$5

  local remaining=$(( total_secs - elapsed ))
  (( remaining < 0 )) && remaining=0
  local time_str=$(printf "%02d:%02d" $(( remaining / 60 )) $(( remaining % 60 )))
  local total_str=$(printf "%02d:%02d" $(( total_secs / 60 )) $(( total_secs % 60 )))

  local cycles_left=$(( CYCLES_BEFORE_LONG_BREAK - (cycle % CYCLES_BEFORE_LONG_BREAK) ))
  (( (cycle % CYCLES_BEFORE_LONG_BREAK) == 0 )) && cycles_left=0

  tput cup 0 0

  print ""

  # Título da fase (vlen = comprimento visível do texto)
  local title_vlen=${#phase_label}
  cline "${phase_color}\e[1m${phase_label}\e[0m" $title_vlen

  print ""

  # Timer grande
  if [[ $paused == "1" ]]; then
    big_timer "$time_str" $'\e[33m'
    print ""
    local pause_text="⏸  Pausado  (space para retomar)"
    cline $'\e[33;1m⏸  Pausado\e[0m  \e[90m(space para retomar)\e[0m' ${#pause_text}
  else
    big_timer "$time_str" "${phase_color}"
    print ""
    local sub="/ ${total_str}"
    cline $'\e[90m'"${sub}"$'\e[0m' ${#sub}
  fi

  print ""

  # Info linha
  if (( cycles_left == 0 )); then
    local info="Ciclo: ${cycle}   Completados: ${total_completed} pomodoros   Próxima: Pausa longa (${LONG_BREAK_MIN}min)"
    cline $'\e[90mCiclo:\e[0m \e[1m'"${cycle}"$'\e[0m   \e[90mCompletados:\e[0m \e[32;1m'"${total_completed}"$'\e[0m \e[90mpomodoros\e[0m   \e[90mPróxima:\e[0m \e[31;1mPausa longa ('"${LONG_BREAK_MIN}"$'min)\e[0m' ${#info}
  else
    local info="Ciclo: ${cycle}   Completados: ${total_completed} pomodoros   Faltam ${cycles_left} ciclo(s) para pausa longa"
    cline $'\e[90mCiclo:\e[0m \e[1m'"${cycle}"$'\e[0m   \e[90mCompletados:\e[0m \e[32;1m'"${total_completed}"$'\e[0m \e[90mpomodoros\e[0m   \e[90mFaltam\e[0m \e[1m'"${cycles_left}"$'\e[0m \e[90mciclo(s) para pausa longa\e[0m' ${#info}
  fi

  print ""

  # Barra de progresso
  progress_bar $elapsed $total_secs

  print ""

  # Separador
  local sep_w=$(( COLUMNS * 55 / 100 ))
  (( sep_w > 58 )) && sep_w=58
  local sep=""
  for (( i=0; i<sep_w; i++ )); do sep+="─"; done
  cline $'\e[90m'"${sep}"$'\e[0m' $sep_w

  # Controlos
  local ctrl="space pausa/retoma   n avançar   r reiniciar ciclos   q sair"
  cline $'\e[90mspace\e[0m pausa/retoma   \e[90mn\e[0m avançar   \e[90mr\e[0m reiniciar ciclos   \e[90mq\e[0m sair' ${#ctrl}

  print ""
  tput ed 2>/dev/null
}

# ===== Countdown =====
# Retorna: 0 = completado, 1 = skip (n), 2 = reiniciar ciclos (r)
function countdown() {
  local minutes=$1
  local phase_label=$2
  local phase_color=$3
  local total_secs=$(( minutes * 60 ))
  local elapsed=0
  local paused=0

  tput smcup
  tput civis
  clear

  draw_screen "$phase_label" "$phase_color" 0 $total_secs 0

  while (( elapsed < total_secs )); do
    local key=""
    if read -k 1 -t 1 key 2>/dev/null; then
      case "$key" in
        " ")
          (( paused )) && paused=0 || paused=1
          draw_screen "$phase_label" "$phase_color" $elapsed $total_secs $paused
          ;;
        n|N)
          tput rmcup; tput cnorm
          return 1
          ;;
        r|R)
          tput rmcup; tput cnorm
          return 2
          ;;
        q|Q)
          cleanup
          ;;
      esac
    fi

    if (( ! paused )); then
      (( elapsed++ ))
      draw_screen "$phase_label" "$phase_color" $elapsed $total_secs $paused
    fi
  done

  tput rmcup
  tput cnorm
  return 0
}

# ===== Calcular ciclo de reinício =====
function reset_cycle() {
  local series_start=$(( cycle - ((cycle - 1) % CYCLES_BEFORE_LONG_BREAK) ))
  cycle=$series_start
}

# ===== Wrapper que trata reinício =====
function run_phase() {
  local minutes=$1
  local label=$2
  local color=$3

  countdown "$minutes" "$label" "$color"
  local result=$?
  (( result == 2 )) && reset_cycle
  return $result
}

# ===== Loop principal =====
while true; do
  notify_msg "Hora de focar! (${WORK_MIN} min) — Ciclo ${cycle}"
  play_sound

  run_phase $WORK_MIN "🍅  Foco — Ciclo ${cycle}" $'\e[32m'
  local skipped=$?
  (( skipped == 0 )) && (( total_completed++ ))
  (( skipped == 2 )) && continue

  if (( cycle % CYCLES_BEFORE_LONG_BREAK == 0 )); then
    notify_msg "Pausa longa! Mereces. (${LONG_BREAK_MIN} min)"
    play_sound
    run_phase $LONG_BREAK_MIN "🛌  Pausa longa" $'\e[31m'
    (( $? == 2 )) && continue
  else
    notify_msg "Pausa curta! (${BREAK_MIN} min)"
    play_sound
    run_phase $BREAK_MIN "☕  Pausa curta" $'\e[33m'
    (( $? == 2 )) && continue
  fi

  (( cycle++ ))
done
