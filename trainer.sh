#!/bin/bash

set -o errexit ; set -o nounset

function usage() {
    cat <<EOF
    Usage: ${0} [-e exercise] [-n 10] [-r 15] [-s slow|medium|fast] workout
    OPTIONS:
      -h        Show usage
      -n        Number of exercises
      -r        Repetitions
      -s        Speed
EOF
exit
}

EXERCISES=10
REPETITIONS=15
SPEED=0.6

while getopts ":hn:r:s:" OPTION; do
  case $OPTION in
    h) usage                   ;;
    n) EXERCISES=$OPTARG       ;;
    r) REPETITIONS=${OPTARG}   ;;
    r) SPEED=${OPTARG}         ;;
  esac
done

shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
  usage
fi

if [[ $SPEED == slow ]]; then
  SPEED=1
elif [[ $SPEED == medium ]]; then
  SPEED=0.7
elif [[ $SPEED == fast ]]; then
  SPEED=0.4
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

exercise_array=(
  pushups
  crunches
  'calf raises'
  squats
  pull-ups
  'front lunges'
  'side lunges'
  bicycle
  'wall sit'
  dips
  superman
  'contralateral limb raises'
  plank
  'side plank'
  'reverse crunches'
  'jumping jacks'
)

echo -e "Starting $EXERCISES exercises at $REPETITIONS repetitions each."
say "Starting $EXERCISES exercises at $REPETITIONS repetitions each"
echo -e ''
for i in $(eval echo "{1..$EXERCISES}"); do
  SELECTION=${exercise_array[ $RANDOM % ${#exercise_array[@]} ]}
  echo -e "Exercise $i of $EXERCISES: $SELECTION"
  say "Exercise $i of $EXERCISES"; sleep 0.5
  say "$SELECTION"
  sleep 3
  echo -e ''
  echo -ne "Let's go!:\r"
  say "let's go!"; sleep 0.3
  for r in $(eval echo "{1..$REPETITIONS}"); do
    echo -ne "Let's go!: $r\r"
    say $r
    sleep $SPEED
  done
  echo -e '\n'
  echo -e "$(date '+%Y-%m-%d:%H:%M:%S'),$SELECTION,$REPETITIONS" >> $DIR/data/exercises.csv
done
echo -e "Thanks for exercising. Great job!"
say "Thanks for exercising. Great job!"
