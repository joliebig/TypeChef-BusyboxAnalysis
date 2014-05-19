#!/bin/bash -e
#!/bin/bash -vxe

filesToProcess() {
  local listFile=busybox/busybox_files
  cat $listFile
  #awk -F: '$1 ~ /.c$/ {print gensub(/\.c$/, "", "", $1)}' < linux_2.6.33.3_pcs.txt
}

flags="-U HAVE_LIBDMALLOC -DCONFIG_FIND -U CONFIG_FEATURE_WGET_LONG_OPTIONS -U ENABLE_NC_110_COMPAT -U CONFIG_EXTRA_COMPAT -D_GNU_SOURCE"
srcPath="busybox-1.18.5"
export partialPreprocFlagsBase="-x CONFIG_ \
  --bdd \
  --include busybox/config.h \
  -I $srcPath/include \
  --featureModelDimacs busybox/featureModel.dimacs \
  --writePI --recordTiming --parserstatistics --lexdebug \
  --rootfolder /work/joliebig/TypeChef-BusyboxAnalysis/ "

sleep $[ ( $RANDOM % 20 ) + 1 ]s

## Reset output
filesToProcess|while read i; do
    if [ ! -f $srcPath/$i.dbg ]; then
        touch $srcPath/$i.dbg
        dirname=`dirname $i`
        filename=`basename $i`

        # parse and serialize AST
        export partialPreprocFlags="$partialPreprocFlagsBase --serializeAST"
        ./jcpp.sh $srcPath/$i.c $flags
        # preserve debugging and error files; would be overridden by subsequent
        # ./jcpp.sh run
        mv $srcPath/$i.err $srcPath/$i_parsing.errvaa
        mv $srcPath/$i.dbg $srcPath/$i_parsing.dbgvaa

        # variability-aware analysis
        export partialPreprocFlags="$partialPreprocFlagsBase --reuseAST --family"
        ./jcpp.sh $srcPath/$i.c $flags
        mv $srcPath/$i.err $srcPath/$i_parsing.errvaa
        mv $srcPath/$i.dbg $srcPath/$i_parsing.dbgvaa

        # single conf
        export partialPreprocFlags="$partialPreprocFlagsBase --reuseAST --singleconf"
        ./jcpp.sh $srcPath/$i.c $flags
        mv $srcPath/$i.err $srcPath/$i_singleconf.errvaa
        mv $srcPath/$i.dbg $srcPath/$i_singleconf.dbgvaa

        # pairwise
        export partialPreprocFlags="$partialPreprocFlagsBase --reuseAST --pairwise"
        ./jcpp.sh $srcPath/$i.c $flags
        mv $srcPath/$i.err $srcPath/$i_pairwise.errvaa
        mv $srcPath/$i.dbg $srcPath/$i_pairwise.dbgvaa

        # code coverage
        export partialPreprocFlags="$partialPreprocFlagsBase --reuseAST --codecoverage"
        ./jcpp.sh $srcPath/$i.c $flags
        mv $srcPath/$i.err $srcPath/$i_codecoverage.errvaa
        mv $srcPath/$i.dbg $srcPath/$i_codecoverage.dbgvaa

        # code coverage nh
        export partialPreprocFlags="$partialPreprocFlagsBase --reuseAST --codecoveragenh"
        ./jcpp.sh $srcPath/$i.c $flags
        mv $srcPath/$i.err $srcPath/$i_codecoveragenh.errvaa
        mv $srcPath/$i.dbg $srcPath/$i_codecoveragenh.dbgvaa

        # create condensed report
        find $srcPath/$dirname -type f -name "$filename.c_*.vaareport" | xargs cat > $srcPath/$i.vaareportall

        touch $srcPath/$i.dbg

        # remove unnecessary files
        rm $srcPath/$i.pi
    else
        echo "Skipping $srcPath/$i.c"
    fi
done
