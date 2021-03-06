#!/bin/bash -e
#!/bin/bash -vxe

filesToProcess() {
  local listFile=busybox/busybox_files
  cat $listFile
  #awk -F: '$1 ~ /.c$/ {print gensub(/\.c$/, "", "", $1)}' < linux_2.6.33.3_pcs.txt
}

flags="-U HAVE_LIBDMALLOC -DCONFIG_FIND -U CONFIG_FEATURE_WGET_LONG_OPTIONS -U ENABLE_NC_110_COMPAT -U CONFIG_EXTRA_COMPAT -D_GNU_SOURCE"
srcPath="busybox-1.18.5"
export partialPreprocFlags="-x CONFIG_ \
  --bdd \
  --include busybox/config.h \
  -I $srcPath/include \
  --featureModelDimacs busybox/featureModel.dimacs \
  --writePI --typecheck --recordTiming --parserstatistics --lexdebug"

## Reset output
filesToProcess|while read i; do
    ./jcpp.sh $srcPath/$i.c $flags
    if [ ! -f $srcPath/$i.dbg ]; then
        touch $srcPath/$i.dbg


        # remove unnecessary files
        # rm $srcPath/$i.pi
    else
        echo "Skipping $srcPath/$i.c"
    fi
done
