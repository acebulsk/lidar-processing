#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --job-name=voxrs-canopy-prod
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=4G
# for the special acces node hpc_c_giws_prio_clark
# for regular GIWS compute note --account=hpc_c_giws_clark
# for the large memory compute note --account=hpc_c_giws_mem_clark (100 TB and 80 cores)
#SBATCH --account=hpc_c_giws_mem_clark
#SBATCH --mail-user=zvd094@usask.ca
#SBATCH --mail-type=ALL
#SBATCH --error=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs/slurm-R-%A_%a.err
#SBATCH --out=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs/slurm-R-%A_%a.out

module load r/4.3.1

r_script_path="/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/11_run_voxrs_canopy_products.R"

srun Rscript $r_script_path
