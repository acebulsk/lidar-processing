#!/bin/bash

#### proj settings ####

# run_id=0 # index to come from paralell processing so we can run this across nodes, i.e. so we can send diff events off as diff tasks on copernicus
# all_pre_flights=("23_026" "23_072")
# all_post_flights=("23_027" "23_073")

all_pre_flights=("23_072")
all_post_flights=("23_073")

# all_pre_flights=("23_026")
# all_post_flights=("23_027")

# Extract the n element from both arrays
pre_sf=${all_pre_flights[$run_id]}
post_sf=${all_post_flights[$run_id]}

event_list=("$pre_sf" "$post_sf")

n_cores=6 # this works for functions that run on tiles but only if we run the functions from the absolute path for some reason
las_path=/home/alex/bin/LAStools/bin
prj_dir=/media/alex/phd-data/local-usask/analysis/lidar-processing
shp_clip=${prj_dir}/data/gis/shp/fsr_traj_extent_buff_20m.shp
# shp_clip=/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/v2.0.2_artifact_test.shp
# shp_clip=/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/pwl_sw_test_strip.shp


pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds_stripalign"

prj_name=v2.0.0_sa # for file name suffix
# prj_name=params_v1.0.0_strip_align_gcp_outlier # for file name suffix

out_path=${prj_dir}/data/processed
log_file=${prj_dir}/logs/lastools/${cur_datetime}_${prj_name}_${pre_sf}_${post_sf}_lidar_pre_post_processing.log

