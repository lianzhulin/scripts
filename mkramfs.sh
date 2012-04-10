#!/bin/bash
CURDIR=$(pwd)

ARCHER=~/bench
LIBDIR=$ARCHER/arm-2011.03/arm-none-linux-gnueabi/libc/lib
export PATH=$ARCHER/arm-2011.03/bin:$PATH

########################################
cd $ARCHER/busybox-1.19.3/

if ! (make) ; then
    echo -n "-> build busybox failed!\n"
else
    echo "-> build busybox ok!\n"
fi

if ! (make install) ; then
    echo "\n-> make install failed!\n"
else
    echo "\n-> make install ok!\n"
fi

cd ./
echo "\n-> make necessary device nods.\n"

if [ ! -d _install/etc ] ; then
    mkdir -p _install/etc
    echo "proc		/proc	proc	defaults    0	0"  >_install/etc/fstab
    echo "none		/tmp    tmpfs   defaults    0	0"  >>_install/etc/fstab
    echo "sysfs		/sys    sysfs   defaults    0	0"  >>_install/etc/fstab
    echo ""                                             >>_install/etc/fstab

    echo "::sysinit:/etc/init.d/rcS"        >_install/etc/inittab
    echo "::respawn:-/bin/sh"               >>_install/etc/inittab
##    echo "ttyS1::askfirst:-/bin/sh"         >>_install/etc/inittab
##    echo "::ctrlaltdel:/bin/umount -a -r"   >>_install/etc/inittab

    echo "echo -n \"Processing /etc/profile... \""   >_install/etc/profile

    mkdir -p _install/etc/init.d
    echo "#!/bin/sh"       >_install/etc/init.d/rcS
    echo ""                 >>_install/etc/init.d/rcS
    echo "/bin/mount -a"    >>_install/etc/init.d/rcS
    echo "alias ll='ls -la'">>_install/etc/init.d/rcS
    chmod a+x _install/etc/init.d/rcS
fi

if [ ! -d _install/init ] ; then
    ln -sf bin/busybox _install/init
fi

if [ ! -d _install/dev ] ; then
    mkdir _install/dev
fi

if [ ! -c _install/dev/null ] ; then
    sudo mknod _install/dev/null c 1 3
fi

if [ ! -c _install/dev/console ] ; then
    sudo mknod _install/dev/console c 5 1
fi

if [ ! -c _install/dev/ttyS0 ] ; then
    sudo mknod _install/dev/ttyS0 c 4 64
fi

if [ ! -c _install/dev/ttyS1 ] ; then
    sudo mknod _install/dev/ttyS1 c 4 65
fi

if [ ! -c _install/dev/ttyS2 ] ; then
    sudo mknod _install/dev/ttyS2 c 4 66
fi

##if [ ! -c _install/dev/mtd0 ] ; then
##    sudo mknod _install/dev/mtd0 c 90 0
##fi
##
##if [ ! -c _install/dev/input/event0 ] ; then
##    mkdir -p _install/dev/input
##    sudo mknod _install/dev/input/event0 c 13 64
##fi
##
##if [ ! -c _install/dev/input/tsdev ] ; then
##    mkdir -p _install/dev/input
##    sudo mknod _install/dev/input/tsdev c 13 65
##fi
##
##if [ ! -c _install/dev/fb0 ] ; then
##    sudo mknod _install/dev/fb0 c 29 0
##fi
##
##if [ ! -b _install/dev/mtdblock0 ] ; then
##    sudo mknod _install/dev/mtdblock0 b 31 0
##fi

mkdir -p _install/bin _install/tmp _install/sys
cp -v $ARCHER/lrzsz-0.12.20/src/lrz $ARCHER/lrzsz-0.12.20/src/lsz _install/bin
 
if [ ! -d _install/lib ] ; then
    mkdir _install/lib
    for file in libc libm libdl libpthread libnsl
    do
        cp $LIBDIR/$file-*.so _install/lib
        cp -d $LIBDIR/$file.so.[*0-9] _install/lib
    done

    cp -d $LIBDIR/libgcc_s*.so* _install/lib
    cp -d $LIBDIR/ld*.so* _install/lib

fi

if [ ! -d _install/usr/lib ] ; then
    mkdir -p _install/usr/lib
    for file in libstdc++
    do
        cp $LIBDIR/../usr/lib/$file*.so _install/usr/lib
        cp -d $LIBDIR/../usr/lib/$file.so* _install/usr/lib
    done

fi

if [ ! -d _install/mnt ] ; then
    mkdir _install/mnt
fi

if [ ! -d _install/proc ] ; then
    mkdir _install/proc
fi

tree _install/
ls -l _install/

cd - >/dev/null

echo "\n-> Ready to generate rootfs filesystem."
cd _install && { find . |cpio -ov -H newc |gzip > ../rootfs.img; cd - >/dev/null; }
echo "\n-> rootfs has been made"
