#PBS -A P93300642
#PBS -N cm1run
#PBS -q main
#PBS -l walltime=01:00:00
#PBS -l select=1:ncpus=128:mpiprocs=128:ompthreads=1

export TMPDIR=/glade/derecho/scratch/zarzycki/temp

module list
module load intel
module load cray-mpich
module list

# not strictly necessary; helps with diagnosing any problems
export MPICH_OFI_VERBOSE=1
export MPICH_OFI_NIC_VERBOSE=2
export MPICH_OFI_CXI_COUNTER_REPORT=3
export MPICH_OFI_CXI_COUNTER_VERBOSE=1
export MPICH_MEMORY_REPORT=1

env

mpiexec --cpu-bind depth -n 128 -ppn 128 -d 1 ./cm1.exe >& cm1.print.out



