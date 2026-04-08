#!/bin/bash
copy_dir(){
                rsync -ra $SH_DIR/$PKGNAME /build
                cd /build/$PKGNAME
}

exec_build_make(){
        yes |mk-build-deps --install --remove
        echo "clean "
        make clean || echo ok
        echo "build deb in `pwd` "
        if [ $dscflag == "dsc" ];then
                make dsc ||  "dsc build error but it is not  fatal error"
        fi
        DEB_BUILD_OPTIONS=nocheck DEB_CFLAGS_APPEND="-Wno-error=int-conversion" make deb || errlog "build deb error"
}

exec_build_dpkg(){
        yes |mk-build-deps --install --remove
        echo "clean "
        make clean || echo ok
        echo "build deb in `pwd` "
        dpkg-buildpackage -b -us -uc || errlog "build deb error"
}

print_progress(){
  TOTAL=$1
  CURRENT=$2
  ITEM_NAME=$3

  BAR_WIDTH=40
  ROWS=$(tput lines)
  printf "\033[1;$(($ROWS - 1))r"
  printf "\n%.0s" $(seq 1 $ROWS)
  tput civis
  printf "\033[s"
  printf "\033[${ROWS};1H"
  PERCENT=$(( CURRENT * 100 / TOTAL))
  FILLED=$(( CURRENT * BAR_WIDTH / TOTAL))
  EMPTY=$(( BAR_WIDTH - FILLED ))
  BAR=$(printf "%${FILLED}s" | tr ' ' '#')
  SPACE=$(printf "%${EMPTY}s" | tr ' ' '-')
  printf "\033[K\e[30;46m[%s%s] %d%% (%d/%d) building ${ITEM_NAME}...\e[0m" "$BAR" "$SPACE" "$PERCENT" "$CURRENT" "$TOTAL"
  printf "\033[u"
}

errlog(){
   echo $1;
   exit 1;
}

# Function to clean up on exit (Ctrl+C)
cleanup() {
    printf "\033[r"
    printf "\033[${ROWS};1H"
    tput cnorm
    # Add a newline so the prompt appears BELOW the progress bar
    echo ""
    exit
}
trap cleanup SIGINT EXIT

