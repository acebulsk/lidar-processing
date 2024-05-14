#!/bin/bash
#SBATCH --time=6:00:00
#SBATCH --job-name=fortress-lidar-voxrs
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=16G
# for the priority node hpc_c_giws_prio_clark 
# for regular GIWS compute note --account=hpc_c_giws_clark
# for the large memory compute note --account=hpc_c_giws_mem_clark (100 TB and 80 cores)
#SBATCH --account=hpc_c_giws_clark
#SBATCH --mail-user=zvd094@usask.ca
#SBATCH --mail-type=ALL
#SBATCH --error=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs/slurm_%j.err
#SBATCH --out=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs/slurm_%j.out

#module load gcc/9.3.0
#module load gcc
#module load geo-stack

srun /globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/run_vox_rs_step_1_copernicus.sh


