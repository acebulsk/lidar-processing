# compile VoxRS canopy products without the filtering to only include grids with lidar-snow data

# run the voxrs product sequence
# warning the canopy product vs lidar snow correlations do not have data over the treewells
library(rhdf5)
library(tidyverse)
library(modelr)
library(pbapply)

# working_dir <- '/globalhome/zvd094/HPC/lidar-processing/'
# data_dir <- '/globalhome/zvd094/HPC/sym_link_gwf_prj/fortress/lidar-processing/'
working_dir <- '/home/alex/local-usask/analysis/lidar-processing/'
data_dir <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/'

n_cores <- 16

# select range of angles for plotting, can be pretty coarse as all follow simple relationship
phi_from <- 0
phi_to <- 90
phi_by <- 2
theta_from <- 0
theta_to <- 359
theta_by <- 1

source(paste0(working_dir, 'scripts/voxrs/voxrs_helper_fns.R'))

plot_names <-
  c(#'FSR_NW',
    #'FSR_NE',
    'FSR_S',
    'PWL_E')
# 'PWL_N',
#'PWL_SW')

#plot <- 'PWL_E'

#event_ids <- c('23_027')
#event_ids <- c('23_072', '23_073')
#event_ids <- c('23_026', '23_027', '23_072', '23_073')
event_ids <- c('23_027_073_snow_on', '23_026_072_snow_off')
#event <- event_ids[1] # which day do we want canopy metrics for?

# inputs
grid_stats_path <- paste0(data_dir, 'data/grid_stats/plot_avg_forest_metricts_nadir_')
voxrs_outputs <- paste0(data_dir, 'data/processed/')

# outputs
voxrs_processed_outputs <- paste0(data_dir, 'data/hemi_stats/aggregate_hemi_stats_across_traj_angle_s1_clip')
figs_path_out <- paste0(working_dir, 'figs/voxrs/scatter/WITH_TREEWELLS_traj_angle_and_wind_phiby_')

for(plot in plot_names){
    cat("Processing plot:", plot, "\n")	
    for(event in event_ids){
        cat("  Processing event:", event, "\n")
	# inputs
	grid_stats_path <- paste0(data_dir, 'data/grid_stats/plot_avg_forest_metricts_nadir_')
	voxrs_outputs <- paste0(data_dir, 'data/processed/')
	folder <- ifelse(event == '23_027_073_snow_on', 'snow-on', 'snow-off')

	# outputs
	voxrs_processed_outputs <- paste0(data_dir, 'data/hemi_stats/aggregate_hemi_stats_across_traj_angle_s1_clip')
	figs_path_out <- paste0(working_dir, 'figs/voxrs/scatter/WITH_TREEWELLS_traj_angle_and_wind_phiby_')

	vox_config_id <- paste0(event, '_vox_len_0.25m_', plot, '_gridgen_v2.0.0_sa_twells_snow_on')

	source(paste0(working_dir, 'scripts/voxrs/12_build_voxrs_df.R'))
     }
}

#source(paste0(working_dir, 'scripts/voxrs/13_plot_voxrs_canopy_products.R'))
