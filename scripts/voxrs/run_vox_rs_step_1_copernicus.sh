#!/bin/bash

# this script runs the first step of the voxrs processing pipeline
# make sure to edit the yml file in this dir

cur_datetime=$(date +"%Y-%m-%d-%H-%M-%S")

py_path="/globalhome/zvd094/HPC/py-venvs/venv-voxrs2.0/bin/python"

step_1_voxrs="/globalhome/zvd094/HPC/VoxRS/step_1_sampling.py"

step_1_yaml="/globalhome/zvd094/HPC/lidar-processing/scripts/voxrs/copernicus_fsr_config_1.yml"

log_file="/globalhome/zvd094/HPC/lidar-processing/logs/voxrs/${cur_datetime}_step_1_voxrs.log"

echo "######################################################################" | tee -a $log_file
echo run_vox_rs_step_1.sh script started at $cur_datetime | tee -a $log_file
echo Using the yaml file: $step_1_yaml | tee -a $log_file
echo "######################################################################" | tee -a $log_file
echo | tee -a $log_file

echo YAML contains: >> $log_file
cat $step_1_yaml >> $log_file
echo end of YAML. >> $log_file
echo  >> $log_file

$py_path $step_1_voxrs $step_1_yaml 2>&1 | tee -a $log_file
