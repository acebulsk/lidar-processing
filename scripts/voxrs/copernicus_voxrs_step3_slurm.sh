#!/bin/bash
#SBATCH --time=3:00:00
#SBATCH --job-name=voxrs-sliced
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=8G
# for the special acces node hpc_c_giws_prio_clark
# for regular GIWS compute note --account=hpc_c_giws_clark
# for the large memory compute note --account=hpc_c_giws_mem_clark (100 TB and 80 cores)
#SBATCH --account=hpc_c_giws_mem_clark
#SBATCH --mail-user=zvd094@usask.ca
#SBATCH --mail-type=ALL
#SBATCH --error=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs/slurm-%A_%a.err
#SBATCH --out=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs/slurm-%A_%a.out

# this script runs the correlation between mean contact number and I/P

module load r/4.3.1
module load geo-stack # required for terra

srun Rscript construct_hemi_from_grids.R
