# compile VoxRS canopy products without the filtering to only include grids with lidar-snow data

# run the voxrs product sequence
# warning the canopy product vs lidar snow correlations do not have data over the treewells
library(rhdf5)
library(tidyverse)
library(modelr)
library(pbapply)

n_cores <- 4

# select range of angles for plotting, can be pretty coarse as all follow simple relationship
phi_from <- 0
phi_to <- 90
phi_by <- 3
theta_from <- 0
theta_to <- 359
theta_by <- 1

source('scripts/voxrs/voxrs_helper_fns.R')

plot_names <-
  c(#'FSR_NW',
    #'FSR_NE',
    'FSR_S',
    'PWL_E')
# 'PWL_N',
#'PWL_SW')

plot <- 'PWL_E'

# event_ids <- c('23_026', '23_027')
event_ids <- c('23_072', '23_073')

# inputs
grid_stats_path <- 'data/grid_stats/plot_avg_forest_metricts_nadir_'
voxrs_outputs <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'

# outputs
voxrs_processed_outputs <- 'data/hemi_stats/aggregate_hemi_stats_across_traj_angle_'
figs_path_out <- 'figs/voxrs/scatter/NO_TREEWELLS_traj_angle_and_wind_vs_contact_number_phiby_'
vox_id <- event_ids[1] # which day do we want canopy metrics for?

vox_config_id <- paste0(vox_id, '_vox_len_0.25m_sa_gridgen_v2.0.0_sa')

source('scripts/voxrs/12_build_voxrs_df.R')
source('scripts/voxrs/13_plot_voxrs_canopy_products.R')