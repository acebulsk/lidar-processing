#!/bin/bash

#### proj settings ####
export LAStoolsLicenseFile=/globalhome/zvd094/HPC/license/lastoolslicense.txt # add license to path so we can use funcitons

n_cores=32 # this works for functions that run on tiles but only if we run the functions from the absolute path for some reason

las_path="singularity exec -B /gpfs /opt/software/singularity-images/LAStools.sif /opt/lastools/bin"
prj_dir=/gpfs/tp/gwf/gwf_cmt/zvd094/fortress/lidar-processing
pt_cld_path=${prj_dir}/data/raw_pt_clds
shp_clip=${prj_dir}/data/gis/shp/fsr_traj_extent_buff_20m.shp

all_pre_flights=("23_026_FT_new" "23_072_FT_new")
all_post_flights=("23_027_FT_new" "23_073_FT_new")

#all_pre_flights=("22_045_FT_new")
#all_post_flights=("22_047_FT_new")

# Extract the n element from both arrays
pre_sf=${all_pre_flights[$run_id]} # run_id comes from sbatch --array=0-1 i.e. for running two events 
post_sf=${all_post_flights[$run_id]}

event_list=("$pre_sf" "$post_sf")

prj_name=params_rm_streaks_stp2_uf_b0_1_s0_05_sd0_05
#prj_name=params_v1.0.0 # for file name suffix
# prj_name='base_pars' # for prj dirs and file name suffix

out_path=${prj_dir}/data/processed
log_file=${prj_dir}/logs/lastools/${cur_datetime}_${prj_name}_${pre_sf}_${post_sf}_lidar_pre_post_processing.log


