#!/bin/bash

# this script runs the first step of the voxrs processing pipeline
# make sure to edit the yml file in this dir

cur_datetime=$(date +"%Y-%m-%d-%H-%M-%S")

py_path="/home/alex/miniconda3/envs/voxrs/bin/python"

step_1_voxrs="/home/alex/code/VoxRS/step_1_sampling.py"

step_1_yaml="/home/alex/local-usask/analysis/lidar-processing/scripts/voxrs/fsr_config_1_sampling.yml"

log_file="/media/alex/phd-data/local-usask/analysis/lidar-processing/logs/voxrs/${cur_datetime}_step_1_voxrs.log"

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
