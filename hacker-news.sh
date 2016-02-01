#!/bin/bash

set -a ; set -o errexit ; set -o nounset

function usage() {
    cat <<EOF
    Usage: ${0} [OPTIONS]
    OPTIONS:
      -h        Show usage
      -a        Return all items (ignoring past trends)
      -x        Exclude domain
EOF
exit
}

HN_ALL_DATA=0
HN_EXCLUDE=''

while getopts ":hax:" OPTION; do
  case $OPTION in
    h) usage                  ;;
    a) HN_ALL_DATA=1          ;;
    x) HN_EXCLUDE=$OPTARG     ;;
  esac
done

function exclude_domain() {
  if [[ ! -z ${EXCLUDE_DOMAIN} ]]; then
    grep -Ev "${EXCLUDE_DOMAIN}"
  else
    cat
  fi
}

function hacker_news() {
  local HN_DATE=$(date '+%Y%m%d')
  local OUT_FILE_STEM="hacker-news_"
  local OUT_FILE_ID="${OUT_FILE_STEM}${HN_DATE}"
  local OUT_FILE="${TMPDIR}${OUT_FILE_ID}"
  if [[ ! -z ${HN_EXCLUDE} ]]; then
    EXCLUDE_DOMAIN="^http(s)?://(www\.)?${HN_EXCLUDE//\./\\.}"
  else
    EXCLUDE_DOMAIN=''
  fi
  if [[ -f $OUT_FILE ]]; then
    local EXCLUDE_FILE="! -name ${OUT_FILE_ID}"
    local OUT_FILE='/dev/null'
  else
    local EXCLUDE_FILE=''
  fi
  if [[ ${HN_ALL_DATA} == 1 ]]; then
    local PAST_TRENDS=''
    local OUT_FILE='/dev/null'
  else
    local PAST_TRENDS=$(find "${TMPDIR}" -type f \( -name 'hacker-news_*' ${EXCLUDE_FILE} \) -exec cat {} \;)
  fi

  echo -e "Hacker News"
  curl -s https://news.ycombinator.com/ \
    | xmllint --html --xpath '//*[@class="athing"]' - 2>/dev/null \
    | xmllint --html --xpath '//a/@href|//a/text()' - 2>/dev/null \
    | sed 's#href=#\'$'\n#g' \
    | grep http \
    | sed -E 's#^"##' \
    | exclude_domain \
    | sed -E 's#"#\'$'\n#' \
    | perl -MHTML::Entities -pe 'decode_entities($_);' \
    | awk \
      -v past_trends="${PAST_TRENDS}" \
      -v out_file="${OUT_FILE}" '
      match($0, /^http/) {
        if (past_trends !~ $0) {
          if (match(prev, /^http/)) {
            print "\n\033[0;32m"prev"\033[0m\n"
          };
          prev = $0;
          print >> out_file
        } else {
          prev = "";
        }
      };
      match($0, /^[^http]/) {
        if (match(prev, /^http/)) {
          print "\n\033[0;32m"prev"\033[0m\n\n"$0;
          prev = "";
        }
      }'
  echo
}

hacker_news

