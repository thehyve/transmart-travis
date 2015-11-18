: ${ORACLE_MACHINE:=oracle-launcher.thehyve.net}

function get_oracle_db {
  if [[ -z "$ORACLE_SECRET" ]]; then
    echo "\$ORACLE_SECRET is not defined" >&2
    return 1
  fi

  echo "Asking for oracle database" >&2
  if [[ ! -p fifo ]]; then mkfifo fifo; fi
  if [[ ! -p fifo2 ]]; then mkfifo fifo2; fi
  ncat --ssl-verify --ssl -v \
    $ORACLE_MACHINE 55397 < <(echo $ORACLE_SECRET ; cat fifo) > fifo2 &
  read result < fifo2

  if [[ $result =~ ^OK ]]; then
    port="${result##OK }"
    echo "Got port $port" >&2
    echo "$port"
  else
    echo "Could not get oracle port: $result" >&2
    kill -9 $!
    return 1
  fi
}
