PG_LOCATION=$HOME/pg
PG_DATA=$HOME/pgdata

function install_pg {
  local readonly version=$1
  if [[ -x "$PG_LOCATION"/bin/psql && "$("$PG_LOCATION"/bin/psql --version | cut -d' ' -f3)" = "$version" ]]; then
    return
  fi

  rm -rf "$PG_LOCATION"
  mkdir -p /tmp/pg
  wget -O - https://ftp.postgresql.org/pub/source/v$version/postgresql-${version}.tar.gz |
    tar -C /tmp/pg --strip-components=1 -xzf -
  cd /tmp/pg && ./configure --prefix="$PG_LOCATION" && cd -
  make -C /tmp/pg -j 3
  make -C /tmp/pg install
}

function create_cluster {
  rm -rf "$PG_DATA"
  "$PG_LOCATION"/bin/initdb -D "$PG_DATA"
  echo "port = 5433" >> "$PG_DATA"/postgresql.conf
}

function start_cluster {
   "$PG_LOCATION"/bin/pg_ctl -D "$PG_DATA" -l /tmp/postgres.log start
}

function stop_cluster {
   "$PG_LOCATION"/bin/pg_ctl -D "$PG_DATA" stop
}
