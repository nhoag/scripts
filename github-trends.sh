#!/bin/bash

set -a ; set -o errexit ; set -o nounset

function usage() {
    cat <<EOF
    Usage: ${0} [OPTIONS] docroot
    OPTIONS:
      -h        Show usage
      -a        Return all items (ignoring past trends)
      -i        Interval (daily, weekly, monthly)
      -l        Language (go, php, ruby)
EOF
exit
}

GH_ALL_DATA=0

while getopts ":hai:l:" OPTION; do
  case $OPTION in
    h) usage                  ;;
    a) GH_ALL_DATA=1          ;;
    i) GH_INTERVAL=$OPTARG    ;;
    l) GH_LANGUAGE=$OPTARG    ;;
  esac
done

function github-trends() {
  local GH_INT="${GH_INTERVAL:-daily}"

  if [[ ! -z ${GH_LANGUAGE+x} ]]; then
    local GH_LANG_QUERY="l=${GH_LANGUAGE}"
    local GH_LANG_SUBJECT=" (${GH_LANGUAGE})"
  else
    local GH_LANGUAGE='all'
    local GH_LANG_QUERY=''
    local GH_LANG_SUBJECT=''
  fi

  local GH_DATE=$(date '+%Y%m%d')
  local OUT_FILE_STEM="github-trends_"
  local OUT_FILE_ID="${OUT_FILE_STEM}${GH_INT}_${GH_LANGUAGE}_${GH_DATE}"
  local OUT_FILE="${TMPDIR}${OUT_FILE_ID}"
  if [[ -f $OUT_FILE ]]; then
    local EXCLUDE_FILE="! -name ${OUT_FILE_ID}"
    local OUT_FILE='/dev/null'
  else
    local EXCLUDE_FILE=''
  fi
  if [[ ${GH_ALL_DATA} == 1 ]]; then
    local PAST_TRENDS=''
    local OUT_FILE='/dev/null'
  else
    local PAST_TRENDS=$(find "${TMPDIR}" -type f \( -name 'github-trends_*' ${EXCLUDE_FILE} \) -exec cat {} \;)
  fi

  echo -e "Github Trending: ${GH_INT}${GH_LANG_SUBJECT}"
  curl -Gs https://github.com/trending \
    --data-urlencode "since=${GH_INT}" \
    --data-urlencode "${GH_LANG_QUERY}" \
    | xmllint --html --xpath \
      '//h3/a/@href|//p[@class="repo-list-description"]/text()' \
      - 2>/dev/null \
    | sed 's#href=\"#\'$'\nhttps://github.com#g' \
    | grep -Ev '^[ ]+$' \
    | grep -Ev '^$' \
    | sed 's/^[ ]*//;
      s/[ ]*$//;
      s/\"$//;' \
    | perl -MHTML::Entities -pe 'decode_entities($_);' \
    | awk \
      -v past_trends="${PAST_TRENDS}" \
      -v out_file="${OUT_FILE}" '
      match($0, /^https/) {
        if (past_trends !~ $0) {
          if (match(prev, /^https/)) {
            print "\n\033[0;32m"prev"\033[0m\n"
          };
          prev = $0;
          print >> out_file
        } else {
          prev = "";
        }
      };
      match($0, /^[^https]/) {
        if (match(prev, /^https/)) {
          print "\n\033[0;32m"prev"\033[0m\n\n"$0;
          prev = "";
        }
      }'
  echo
}

github-trends

