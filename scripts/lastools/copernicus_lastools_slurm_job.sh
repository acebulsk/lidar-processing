#!/bin/bash
#SBATCH --time=3:00:00
#SBATCH --job-name=fortress-lidar
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=6G
# for regular GIWS compute note --account=hpc_c_giws_clark
# for the large memory compute note --account=hpc_c_giws_mem_clark (100 TB and 80 cores)
#SBATCH --account=hpc_c_giws_prio_clark
#SBATCH --mail-user=zvd094@usask.ca
#SBATCH --mail-type=ALL
#SBATCH --error=/globalhome/zvd094/HPC/lidar-processing/scripts/lastools/slurm-logs/slurm_%A_%a.err
#SBATCH --out=/globalhome/zvd094/HPC/lidar-processing/scripts/lastools/slurm-logs/slurm_%A_%a.out

module load gentoo/2020
module load singularity/3.9.2

# this only works with the command sbatch --array=0-31
slurm_id=$SLURM_ARRAY_TASK_ID # get ID, need to set ntasks to the length of all pre/post_flights array in the config , this is passed to the LAStools_process_prepost as run_id

srun /globalhome/zvd094/HPC/lidar-processing/scripts/lastools/LAStools_process_prepost.sh /globalhome/zvd094/HPC/lidar-processing/scripts/lastools/copernicus_lastools_config.sh $slurm_id
