#!/usr/bin/env bash
# author : guokuankuan@bytedance.com

if [ `uname` == Darwin ]; then
	cpuNum=`sysctl -n machdep.cpu.thread_count`
else
	cpuNum=`nproc`
fi

# clone terark-zip-rocksdb: terark-rocksdb depends on some header files from zip-rocksdb

rm -rf terark-zip-rocksdb
git clone --depth=1 git@code.byted.org:storage/terark-zip-rocksdb.git

# build targets 
make libzstd.a libz.a libsnappy.a liblz4.a -j $cpuNum
make EXTRA_CXXFLAGS="-DSNAPPY=1 -DZLIB=1 -DLZ4=1 -DZSTD=1 -Isnappy-1.1.4 -Ilz4-1.8.0/lib -Izstd-1.3.3/lib/include" \
     EXTRA_LDFLAGS="-lsnappy -lz -llz4 -lzstd -L." \
     shared_lib DEBUG_LEVEL=0 -j $cpuNum DISABLE_WARNING_AS_ERROR=1

make EXTRA_CXXFLAGS="-DSNAPPY=1 -DZLIB=1 -DLZ4=1 -DZSTD=1 -Isnappy-1.1.4 -Ilz4-1.8.0/lib -Izstd-1.3.3/lib/include" \
     EXTRA_LDFLAGS="-lsnappy -lz -llz4 -lzstd -L." \
     shared_lib DEBUG_LEVEL=2 -j $cpuNum DISABLE_WARNING_AS_ERROR=1

pkgdir=output
rm -rf $pkgdir

# copy all header files
mkdir -p $pkgdir
mkdir -p $pkgdir/lib

cp -r include      $pkgdir
cp -r db           $pkgdir/include
cp -r env          $pkgdir/include
cp -r memtable     $pkgdir/include
cp -r port         $pkgdir/include
cp -r table        $pkgdir/include
cp -r util         $pkgdir/include
cp -r utilities    $pkgdir/include
cp -r options      $pkgdir/include
cp -r monitoring   $pkgdir/include

rm -f `find $pkgdir -name '*.cc' -o -name '*.d' -o -name '*.o'`

# detect output dir name
WITH_BMI2=0
SYSTEM=`uname -m -s | sed 's:[ /]:-:g'`
tmpfile=`mktemp compiler-XXXXXX`
COMPILER=`gcc terark-tools/detect-compiler.cpp -o $tmpfile.exe && ./$tmpfile.exe && rm -f $tmpfile*`
PLATFORM_DIR=$SYSTEM-$COMPILER-bmi2-$WITH_BMI2

#echo build/$PLATFORM_DIR/shared_lib/dbg-0/

# copy terark-rocksdb dynamic lib
if [ `uname` == Darwin ]; then
	cp -a build/$PLATFORM_DIR/shared_lib/dbg-0/librocksdb* $pkgdir/lib
	cp -a build/$PLATFORM_DIR/shared_lib/dbg-2/librocksdb* $pkgdir/lib
else
	cp -lP build/$PLATFORM_DIR/shared_lib/dbg-0/librocksdb* $pkgdir/lib/
	cp -lP build/$PLATFORM_DIR/shared_lib/dbg-2/librocksdb* $pkgdir/lib/
fi

echo "build and package successful!"
