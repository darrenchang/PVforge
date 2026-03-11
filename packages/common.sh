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

errlog(){
   echo $1;
   exit 1;
}
