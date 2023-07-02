#! /bin/sh

# Check TELEGRAM_BOT_TOKEN, CHATROOM_ID, and REPORT_ID are set
if [ -z "${TELEGRAM_BOT_TOKEN}" ] || [ -z "${CHATROOM_ID}" ] || [ -z "${REPORT_HEAD}" ]; then
  echo "Telegram report skipped: TELEGRAM_BOT_TOKEN, CHATROOM_ID, or REPORT_ID not set"
  exit 0
fi

# Check curl is installed
if ! command -v curl >/dev/null 2>&1; then
  echo "Telegram report skipped: curl not installed"
  exit 0
fi

# Check /var/log/rsnapshot exists
if [ ! -f /var/log/rsnapshot ]; then
  echo "Telegram report skipped: /var/log/rsnapshot not found"
  exit 0
fi

# replcae - to \-
replacedash() {
  printf "%s\n" "$1" | sed 's/-/\\-/g'
}

# ChatGPT go brrr for unicode encode for shell script
urlencode() {
  printf "%s" "$1" | while IFS= read -r -n1 -d '' char
  do
    case "$char" in
      [a-zA-Z0-9.~_-]) printf "$char" ;;
      *) printf "$char" | xxd -p -c1 | tr -d '\n' | sed 's/^/%/' ;;
    esac
  done
  printf '\n'
}

# urlencode REPORT_HEAD\n{last 10 lines of /var/log/rsnapshot}
REPORT_RAW="${REPORT_HEAD}
\`\`\`
$(tail -n 10 /var/log/rsnapshot)
\`\`\`"
REPORT_TEXT=$(urlencode "$(replacedash "${REPORT_RAW}")")

url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?parse_mode=MarkdownV2&chat_id=${CHATROOM_ID}&text=${REPORT_TEXT}"
command="{ curl -s -m 10 \"${url}\" 2> /dev/null > /dev/null & } 2>/dev/null;disown &>/dev/null"

# Send the report
eval "${command}"
