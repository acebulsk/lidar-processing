# run the voxrs product sequence

library(terra)
library(sf)
library(purrr)
library(rhdf5)
library(tidyverse)

n_cores <- 6

source('scripts/voxrs/00_voxrs_helper_fns.R')

plot_names <- c('FSR_NW', 'FSR_NE', 'FSR_S', 'PWL_E', 'PWL_N', 'PWL_SW')

# event_ids <- c('23_026', '23_027')
event_ids <- c('23_072', '23_073')

vox_id <- event_ids[1] # which day do we want canopy metrics for?
vox_config_id <- paste0(vox_id, '_vox_len_0.25m_')


for (plot in plot_names) {
  
  vox_runtag <- paste0('_gridgen_', plot)
  las_prj_name <- 'params_v1.0.0'
  
  voxrs_outputs <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'
  h5_basename <- paste0(voxrs_outputs,
                        vox_id,
                        '/voxrs/outputs/grid_resampling/',
                        'grid_resampled',
                        '_',
                        vox_config_id,
                        vox_runtag)
  
  source('scripts/voxrs/02_construct_hemi_from_grids.R')
  source('scripts/voxrs/03_plot_hemi_correlation.R')
  source('scripts/voxrs/04_plot_scatter_mcn_ip_aggregate_hemi_portion.R')
  
}

source('scripts/voxrs/05_plot_scatter_traj_angle_mcn_aggregate_hemi_portion.R')
