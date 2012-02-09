#!/usr/bin/env bash

if [[ -z $1  ]]; then
{
  echo Usage: $0 Replicate_id Source_dir Local_dir
  exit 0
};
fi

REPLICATE_ID=$1
SOURCE_DIR=$2
LOCAL_DIR=$3

if [[ ! -d $LOCAL_DIR ]];
  then {
    mkdir $LOCAL_DIR
};
fi

# $1 - remote source
# $2 - local destination
fetch_file()
{
  wget -nv -O "$2" "$1"
};

retry_fetch_file()
{
  if [[ ! -s "$2" ]]; then {
    fetch_file "$1" "$2"
    gunzip -t <"$2"
    if [[ $? -ne 0 ]]; then {
      rm "$2"
    }; fi
  }; fi
  until [[ -s "$2" ]]; do {
    sleep 15
    fetch_file "$1" "$2"
    gunzip -t <"$2"
    if [[ $? -ne 0 ]]; then {
      rm "$2"
    }; fi
  }; done
};

fetch_minute_diff()
{
  printf -v TDIGIT3 %03u $(($1 % 1000))
  ARG=$(($1 / 1000))
  printf -v TDIGIT2 %03u $(($ARG % 1000))
  ARG=$(($ARG / 1000))
  printf -v TDIGIT1 %03u $ARG
  
  LOCAL_PATH="$LOCAL_DIR/$TDIGIT1/$TDIGIT2"
  REMOTE_PATH="$SOURCE_DIR/$TDIGIT1/$TDIGIT2"
  mkdir -p "$LOCAL_DIR/$TDIGIT1/$TDIGIT2"

  retry_fetch_file "$REMOTE_PATH/$TDIGIT3.osc.gz" "$LOCAL_PATH/$TDIGIT3.osc.gz"
  retry_fetch_file "$REMOTE_PATH/$TDIGIT3.state.txt" "$LOCAL_PATH/$TDIGIT3.state.txt"

  TIMESTAMP_LINE=`grep timestamp $LOCAL_DIR/$TDIGIT1/$TDIGIT2/$TDIGIT3.state.txt`
  TIMESTAMP=${TIMESTAMP_LINE:10}
};

while [[ true ]];
do
{
  REPLICATE_ID=$(($REPLICATE_ID + 1))
  fetch_minute_diff $REPLICATE_ID
  sleep 1
  echo "fetch_osc()@"`date "+%F %T"`": new_replicate_diff $REPLICATE_ID $TIMESTAMP" >>$LOCAL_DIR/fetch_osc.log
};
done
