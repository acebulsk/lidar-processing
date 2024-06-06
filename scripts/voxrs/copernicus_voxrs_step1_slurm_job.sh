#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --job-name=snow-on-fullext
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=750G
# for the priority node hpc_c_giws_prio_clark 
# for regular GIWS compute note --account=hpc_c_giws_prio_clark
# for the large memory compute note --account=hpc_c_giws_mem_clark (3 TB RAM  and 80 cores)
#SBATCH --account=hpc_c_giws_mem_clark
#SBATCH --mail-user=zvd094@usask.ca
#SBATCH --mail-type=ALL
#SBATCH --error=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs-step1/slurm_%j.err
#SBATCH --out=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs-step1/slurm_%j.out

#module load gcc/9.3.0
module load StdEnv/2023
module load gcc/12.3
module load geo-stack/2023a

srun /globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/run_vox_rs_step_1_copernicus.sh


