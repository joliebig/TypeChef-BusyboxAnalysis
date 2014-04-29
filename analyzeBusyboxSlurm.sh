#!/bin/bash -e
#!/bin/bash -vxe
#SBATCH -D /local/joliebig/TypeChef-BusyboxAnalysis
#SBATCH --job-name=typechef
#SBATCH -p hipri
#SBATCH --get-user-env
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem_bind=local
#SBATCH --mail-type=end
#SBATCH --mail-user=joliebig@fim.uni-passau.de
#SARRAY --range=1-521

# process 521 files (see --range parameter above)
filesToProcess() {
  local listFile=busybox/busybox_files
  cat $listFile
}

# typechef parameters
flags="-U HAVE_LIBDMALLOC -DCONFIG_FIND -U CONFIG_FEATURE_WGET_LONG_OPTIONS -U ENABLE_NC_110_COMPAT -U CONFIG_EXTRA_COMPAT -D_GNU_SOURCE"
srcPath="busybox-1.18.5"
export partialPreprocFlags="-x CONFIG_ \
  --bdd \
  --include busybox/config.h \
  -I $srcPath/include \
  --featureModelDimacs BB_fm.dimacs \
  --typecheck \
  --writePI --recordTiming --parserstatistics --lexdebug"

read -a PROJECT_ARRAY <<< filesToProcess

# run single typechef task
if [ ! -f $srcPath/${PROJECT_ARRAY[${SLURM_ARRAYID} - 1]}.dbg ]; then
    touch $srcPath/${PROJECT_ARRAY[${SLURM_ARRAYID} - 1]}.dbg

    ./jcpp.sh $srcPath/${PROJECT_ARRAY[${SLURM_ARRAYID} - 1]}.c $flags

    # remove unnecessary files
    rm $srcPath/${PROJECT_ARRAY[${SLURM_ARRAYID} - 1]}.pi
else
    echo "Skipping $srcPath/${PROJECT_ARRAY[${SLURM_ARRAYID} - 1]}.c"
fi
