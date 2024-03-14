#!/bin/bash

#### proj settings ####

n_cores=6 # this works for functions that run on tiles but only if we run the functions from the absolute path for some reason
las_path=/home/alex/bin/LAStools/bin
prj_dir=/media/alex/phd-data/local-usask/analysis/lidar-processing
shp_clip=${prj_dir}/data/gis/shp/fsr_traj_extent_buff_20m.shp
# file_list="23_072_FT_new 23_073_FT_new"
file_list="23_026_FT_new 23_027_FT_new"
pre_sf_index=1
post_sf_index=2
# Convert the file list string into an array
read -r -a file_array <<< "$file_list"
# Extract elements based on indices
pre_sf="${file_array[$pre_sf_index - 1]}"
post_sf="${file_array[$post_sf_index - 1]}"

pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds"

prj_name=params_v1.0.0 # for file name suffix
# prj_name='base_pars' # for prj dirs and file name suffix

out_path=${prj_dir}/data/processed
log_file=${prj_dir}/logs/lastools/${cur_datetime}_${prj_name}_lidar_pre_post_processing.log

