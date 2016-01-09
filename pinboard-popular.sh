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

PB_ALL_DATA=0
PB_EXCLUDE=''

while getopts ":hax:" OPTION; do
  case $OPTION in
    h) usage                  ;;
    a) PB_ALL_DATA=1          ;;
    x) PB_EXCLUDE=$OPTARG     ;;
  esac
done

function exclude_domain() {
  if [[ ! -z ${EXCLUDE_DOMAIN} ]]; then
    grep -Ev "${EXCLUDE_DOMAIN}"
  else
    cat
  fi
}

function pinboard_popular() {
  local PB_DATE=$(date '+%Y%m%d')
  local OUT_FILE_STEM="pinboard-popular_"
  local OUT_FILE_ID="${OUT_FILE_STEM}${PB_DATE}"
  local OUT_FILE="${TMPDIR}${OUT_FILE_ID}"
  if [[ ! -z ${PB_EXCLUDE} ]]; then
    EXCLUDE_DOMAIN="^http(s)?://(www\.)?${PB_EXCLUDE//\./\\.}"
  else
    EXCLUDE_DOMAIN=''
  fi
  if [[ -f $OUT_FILE ]]; then
    local EXCLUDE_FILE="! -name ${OUT_FILE_ID}"
    local OUT_FILE='/dev/null'
  else
    local EXCLUDE_FILE=''
  fi
  if [[ ${PB_ALL_DATA} == 1 ]]; then
    local PAST_TRENDS=''
    local OUT_FILE='/dev/null'
  else
    local PAST_TRENDS=$(find "${TMPDIR}" -type f \( -name 'pinboard-popular_*' ${EXCLUDE_FILE} \) -exec cat {} \;)
  fi

  echo -e "Pinboard Popular"
  curl -s https://pinboard.in/popular/ \
    | xmllint --html --xpath '//*[contains(@class,"bookmark_title")]' - 2>/dev/null \
    | xmllint --html --xpath '//a/@href|//a/text()' - 2>/dev/null \
    | sed 's#href=#\'$'\n#g' \
    | grep http \
    | sed -E 's#^"##' \
    | exclude_domain \
    | sed -E 's#"#\'$'\n#' \
    | sed -E "s/&acirc;&#128;&#14(7|8);/-/g" \
    | sed -E "s/&acirc;&#128;&#153;/'/g" \
    | sed -E 's/&acirc;&#128;&#15(6|7);/"/g' \
    | sed -E 's/&acirc;&#128;&brvbar;/…/g' \
    | sed -E 's/&Acirc;&middot;/·/g' \
    | sed -E 's/&amp;/\&/g' \
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

pinboard_popular

