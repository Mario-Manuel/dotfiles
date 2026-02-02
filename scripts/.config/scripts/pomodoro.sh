#!/usr/bin/env zsh

# ===== Configuração =====
WORK_MIN=25
BREAK_MIN=5
LONG_BREAK_MIN=45
CYCLES_BEFORE_LONG_BREAK=4
SOUND_FILE="/usr/share/sounds/freedesktop/stereo/complete.oga"

# ===== Cores =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cycle=1
TERMDOWN_PID=""
SKIP_PHASE=0

function play_sound() {
  if command -v paplay >/dev/null 2>&1 && [[ -f $SOUND_FILE ]]; then
    paplay "$SOUND_FILE"
  elif command -v aplay >/dev/null 2>&1 && [[ -f $SOUND_FILE ]]; then
    aplay "$SOUND_FILE"
  else
    print '\a'
  fi
}

function notify() {
  clear
  tput cup 0 0
  print -P "${BLUE}>>${NC} $1"
  command -v notify-send >/dev/null 2>&1 && notify-send "Pomodoro" "$1"
  play_sound
}

function countdown() {
  local minutes=$1
  SKIP_PHASE=0

  clear
  tput cup 0 0
  termdown "${minutes}m" &
  TERMDOWN_PID=$!

   while kill -0 $TERMDOWN_PID 2>/dev/null; do
  if read -k 1 -t 0.1 key 2>/dev/null; then
    case $key in
     p)
          kill -STOP $TERMDOWN_PID
          clear
          tput cup 0 0
          print -P "${YELLOW}⏸ Pausado.${NC}"
          print -P "r = retomar   n = avançar   q = sair"
          ;;
        r)
          kill -CONT $TERMDOWN_PID
          clear
          tput cup 0 0
          print -P "${GREEN}▶ Retomado.${NC}"
          ;;
        n)
          kill $TERMDOWN_PID
          SKIP_PHASE=1
          clear
          tput cup 0 0
          print -P "${BLUE}⏭ Fase pulada.${NC}"
          sleep 0.5
          return
          ;;
        q)
          kill $TERMDOWN_PID
          clear
          tput cup 0 0
          print -P "${RED}⛔ Pomodoro cancelado.${NC}"
          exit 0
          ;;
      esac
    fi
    sleep 0.2
  done
}

while true; do
# ===== Foco =====
clear
tput cup 0 0
print -P "${GREEN}🍅 Pomodoro $cycle — Foco (${WORK_MIN} min)${NC}"
notify "Hora de focar! (${WORK_MIN} minutos)"
countdown $WORK_MIN

# ===== Pausa (curta ou longa) =====
if (( cycle % CYCLES_BEFORE_LONG_BREAK == 0 )); then
  clear
  tput cup 0 0
  print -P "${RED}🛌 Pausa longa (${LONG_BREAK_MIN} min)${NC}"
  notify "Pausa longa! (${LONG_BREAK_MIN} minutos)"
  countdown $LONG_BREAK_MIN
else
  clear
  tput cup 0 0
  print -P "${YELLOW}⏸ Pausa curta (${BREAK_MIN} min)${NC}"
  notify "Pausa curta! (${BREAK_MIN} minutos)"
  countdown $BREAK_MIN
fi

((cycle++))

done
# ===== Foco =====
clear
tput cup 0 0
print -P "${GREEN}🍅 Pomodoro $cycle — Foco (${WORK_MIN} min)${NC}"
notify "Hora de focar! (${WORK_MIN} minutos)"
countdown $WORK_MIN

# ===== Pausa (curta ou longa) =====
if (( cycle % CYCLES_BEFORE_LONG_BREAK == 0 )); then
  clear
  tput cup 0 0
  print -P "${RED}🛌 Pausa longa (${LONG_BREAK_MIN} min)${NC}"
  notify "Pausa longa! (${LONG_BREAK_MIN} minutos)"
  countdown $LONG_BREAK_MIN
else
  clear
  tput cup 0 0
  print -P "${YELLOW}⏸ Pausa curta (${BREAK_MIN} min)${NC}"
  notify "Pausa curta! (${BREAK_MIN} minutos)"
  countdown $BREAK_MIN
fi

((cycle++))

