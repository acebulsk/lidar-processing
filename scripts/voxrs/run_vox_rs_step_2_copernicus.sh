#!/bin/bash

# this script runs the first step of the voxrs processing pipeline
# make sure to edit the yml file in this dir

cur_datetime=$(date +"%Y-%m-%d-%H-%M-%S")

py_path="/globalhome/zvd094/HPC/py-venvs/venv-voxrs/bin/python"

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

$py_path $step_2_voxrs $step_2_yaml 2>&1 | tee -a $log_file
