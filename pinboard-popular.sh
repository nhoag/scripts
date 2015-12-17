#!/bin/bash

set -a ; set -o errexit ; set -o nounset

function usage() {
    cat <<EOF
    Usage: ${0} [OPTIONS]
    OPTIONS:
      -h        Show usage
      -a        Return all items (ignoring past trends)
EOF
exit
}

PB_ALL_DATA=0

while getopts ":ha" OPTION; do
  case $OPTION in
    h) usage                  ;;
    a) PB_ALL_DATA=1          ;;
  esac
done

function pinboard_popular() {
  local PB_DATE=$(date '+%Y%m%d')
  local OUT_FILE_STEM="pinboard-popular_"
  local OUT_FILE_ID="${OUT_FILE_STEM}_${PB_DATE}"
  local OUT_FILE="${TMPDIR}${OUT_FILE_ID}"
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
    | sed 's#^"##;s#"#\'$'\n#' \
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
