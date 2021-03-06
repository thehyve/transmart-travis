RSERVE_LOCATION=$HOME/rserve

function install_rserve {
  local readonly transmartdata=$1
  local time_repos= time_installed=
  #needs libcairo-dev clang gfortran g++ libreadline-dev

  if [[ -x "$RSERVE_LOCATION"/bin/R ]]; then
    time_repos=$(echo $(cd $transmartdata; git log --pretty=%at -n1 -- R/))
    time_installed=$(stat --printf='%Y' "$RSERVE_LOCATION"/bin/R)

    if [[ $time_installed -gt $time_repos ]]; then
      echo "Rserve installed and newer than transmartdata/R ($time_installed / $time_repos); no need to reinstall"
      return
    else
      echo "Installed Rserve is stale: time installed is $time_installed; newest time of repos files is: $time_repos"
      rm -rf "$SERVE_LOCATION"
    fi
  fi

  source $transmartdata/vars
  export CC=clang
  export CXX=clang++
  export R_FLAGS=-O0
  export TRANSMART_USER=$USER
  export R_PREFIX=$RSERVE_LOCATION

  make -C $transmartdata/R -j3 "$R_PREFIX"/bin/R
  make -C $transmartdata/R install_packages
}

function start_rserve {
  "$RSERVE_LOCATION"/bin/R CMD Rserve --quiet --vanilla
}
