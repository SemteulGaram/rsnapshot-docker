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

urlencode() {
    local data
    if [[ $# != 1 ]]; then
        echo "Usage: $0 string-to-urlencode"
        return 1
    fi
    data="$(curl -s -o /dev/null -w %{url_effective} --get --data-urlencode "$1" "")"
    if [[ $? != 3 ]]; then
        echo "Unexpected error" 1>&2
        return 2
    fi
    echo "${data##/?}"
    return 0
}

# urlencode REPORT_HEAD\n{last 100 lines of /var/log/rsnapshot}
REPORT_TEXT=$(urlencode "${REPORT_HEAD}\n$(tail -n 100 /var/log/rsnapshot)")

url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${CHATROOM_ID}&text=${REPORT_TEXT}"
command="{ curl -s -m 10 \"${url}\" 2> /dev/null > /dev/null & } 2>/dev/null;disown &>/dev/null"

# Send the report
eval "${command}"
