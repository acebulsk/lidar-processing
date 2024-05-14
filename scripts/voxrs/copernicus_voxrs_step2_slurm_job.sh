#!/bin/bash
#SBATCH --time=10:00:00
#SBATCH --job-name=voxrs-sliced
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=8G
# for the special acces node hpc_c_giws_prio_clark
# for regular GIWS compute note --account=hpc_c_giws_clark
# for the large memory compute note --account=hpc_c_giws_mem_clark (100 TB and 80 cores)
#SBATCH --account=hpc_c_giws_clark
#SBATCH --mail-user=zvd094@usask.ca
#SBATCH --mail-type=ALL
#SBATCH --error=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs/slurm-%A_%a.err
#SBATCH --out=/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/slurm-logs/slurm-%A_%a.out

#module load gcc/9.3.0
#module load geo-stack

step=15 # 15 degress across 360
offset=$SLURM_ARRAY_TASK_ID # get ID, should be [0,23] with a 15 deg step

py_path="/globalhome/zvd094/HPC/py-venvs/venv-voxrs2.0/bin/python"

step_2_voxrs="/globalhome/zvd094/HPC/VoxRS/step_2_resampling.py"

step_2_yaml="/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/copernicus_fsr_config_2.yml"

log_file="/globalhome/zvd094/HPC/lidar-processing/logs/voxrs/${cur_datetime}_step_2_voxrs.log"

echo "######################################################################" | tee -a $log_file
echo run_vox_rs_step_2.sh script started at $cur_datetime | tee -a $log_file
echo Using the yaml file: $step_1_yaml | tee -a $log_file
echo "######################################################################" | tee -a $log_file
echo | tee -a $log_file

echo YAML contains: >> $log_file
cat $step_2_yaml >> $log_file
echo end of YAML. >> $log_file
echo  >> $log_file

srun $py_path $step_2_voxrs $step_2_yaml $offset $step 2>&1 | tee -a $log_file

