#!/bin/bash

# this script runs the first step of the voxrs processing pipeline
# make sure to edit the yml file in this dir

cur_datetime=$(date +"%Y-%m-%d-%H-%M-%S")

py_path="/home/alex/miniconda3/envs/voxrs/bin/python"

step_2_voxrs="/home/alex/code/VoxRS/step_2_resampling.py"

step_2_yaml="/home/alex/local-usask/analysis/lidar-processing/scripts/voxrs/fsr_config_2_resampling.yml"

log_file="/media/alex/phd-data/local-usask/analysis/lidar-processing/logs/voxrs/${cur_datetime}_step_2_voxrs.log"

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
