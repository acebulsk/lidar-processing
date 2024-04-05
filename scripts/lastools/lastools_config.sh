#!/bin/bash

#### proj settings ####

# run_id=0 # index to come from paralell processing so we can run this across nodes, i.e. so we can send diff events off as diff tasks on copernicus
all_pre_flights=("23_026_FT_new" "23_072_FT_new")
all_post_flights=("23_027_FT_new" "23_073_FT_new")

# Extract the n element from both arrays
pre_sf=${all_pre_flights[$run_id]}
post_sf=${all_post_flights[$run_id]}

file_list=("$pre_sf" "$post_sf")

n_cores=6 # this works for functions that run on tiles but only if we run the functions from the absolute path for some reason
las_path=/home/alex/bin/LAStools/bin
prj_dir=/media/alex/phd-data/local-usask/analysis/lidar-processing
shp_clip=${prj_dir}/data/gis/shp/fsr_traj_extent_buff_20m.shp

pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds"

prj_name=params_v1.0.0 # for file name suffix
# prj_name='base_pars' # for prj dirs and file name suffix

out_path=${prj_dir}/data/processed
log_file=${prj_dir}/logs/lastools/${cur_datetime}_${prj_name}_${pre_sf}_${post_sf}_lidar_pre_post_processing.log

