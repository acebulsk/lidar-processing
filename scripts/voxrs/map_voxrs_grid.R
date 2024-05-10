# map grid resampling output for select phi theta combo
library(terra)
library(viridis)
library(rhdf5)
library(tidyverse)

cn_coef <- 0.38 # from VoxRS default, also see supplementary material for Staines & Pomeroy 2023

plot_names <- c('FSR_NW', 'FSR_NE', 'FSR_S', 'PWL_E', 'PWL_N', 'PWL_SW')

plot <- 'PWL_E'
# event_ids <- c('23_026', '23_027')
event_ids <- c('23_072', '23_073')

voxrs_outputs <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'
las_prj_name <- 'v2.0.0_sa'
vox_id <- event_ids[1] # which day do we want canopy metrics for?
vox_config_id <- paste0(vox_id, '_vox_len_0.25m_sa_gridgen')

h5_basename <- paste0(voxrs_outputs,
                      vox_id,
                      '/voxrs/outputs/grid_resampling/',
                      'grid_resampled',
                      '_',
                      vox_config_id,
                      "_",
                      las_prj_name,
                      "_",
                      plot)

##  bring in the mean phi and theta value associated with the upper 2.5th
##  percentile of rho_s with I.P. vs mean canopy contact number
phi_theta_df <-
  readRDS(
    paste0(
      'data/hemi_stats/hemi_avg_theta_phi_for_rho_s_upper_2_5th_percentile_',
      vox_config_id,
      "_",
      plot,
      '.rds'
    )
  )

phi <- phi_theta_df$phi |> round()
theta <- phi_theta_df$theta |> round()
cc_rast <- rasterise_canopy_coverage_from_h5(phi, theta, h5_basename)
# Save the plot for lidr_sd
png(paste0(
  'figs/maps/',
  vox_config_id,
  '_',
  plot,
  '_',
  'voxrs_grid_p',
  phi, '_t', theta,
  '.png'
), width = 1200, height = 800, res = 200)  # You can adjust width and height as needed
plot(cc_rast, main = paste0(strsplit(plot, "_")[[1]][1], ': LCA (-)'), col = viridis(100))
dev.off()

##  Select phi theta based on predicted trajectory angle and mean wind dir

phi <- 55
theta <- 188
cc_rast <- rasterise_canopy_coverage_from_h5(phi, theta, h5_basename)
# Save the plot for lidr_sd
png(paste0(
  'figs/maps/',
  vox_config_id,
  '_',
  plot,
  '_',
  'voxrs_grid_p',
  phi, '_t', theta,
  '.png'
), width = 1200, height = 800, res = 200)  # You can adjust width and height as needed
plot(cc_rast, main = paste0(strsplit(plot, "_")[[1]][1], ': LCA (-)'), col = viridis(100))
dev.off()

## Select areas of the hemisphere 

phi <- 0
theta <- 0
cc_rast <- rasterise_canopy_coverage_from_h5(phi, theta, h5_basename)
png(paste0(
  'figs/maps/',
  vox_config_id,
  '_',
  plot,
  '_',
  'voxrs_grid_p',
  phi, '_t', theta,
  '.png'
), width = 1200, height = 800, res = 200)  # You can adjust width and height as needed
plot(cc_rast, main = 'Canopy Coverage (-)', col = viridis(100))
dev.off()

phi <- 35
theta <- 0
cc_rast <- rasterise_canopy_coverage_from_h5(phi, theta, h5_basename)
png(paste0(
  'figs/maps/',
  vox_config_id,
  '_',
  plot,
  '_',
  'voxrs_grid_p',
  phi, '_t', theta,
  '.png'
), width = 1200, height = 800, res = 200)  # You can adjust width and height as needed
plot(cc_rast, main = 'Canopy Coverage (-)', col = viridis(100))
dev.off()

phi <- 45
theta <- 0
cc_rast <- rasterise_canopy_coverage_from_h5(phi, theta, h5_basename)
png(paste0(
  'figs/maps/',
  vox_config_id,
  '_',
  plot,
  '_',
  'voxrs_grid_p',
  phi, '_t', theta,
  '.png'
), width = 1200, height = 800, res = 200)  # You can adjust width and height as needed
plot(cc_rast, main = 'Canopy Coverage (-)', col = viridis(100))
dev.off()

phi <- 60
theta <- 0
cc_rast <- rasterise_canopy_coverage_from_h5(phi, theta, h5_basename)
png(paste0(
  'figs/maps/',
  vox_config_id,
  '_',
  plot,
  '_',
  'voxrs_grid_p',
  phi, '_t', theta,
  '.png'
), width = 1200, height = 800, res = 200)  # You can adjust width and height as needed
plot(cc_rast, main = 'Canopy Coverage (-)', col = viridis(100))
dev.off()

phi <- 80
theta <- 0
cc_rast <- rasterise_canopy_coverage_from_h5(phi, theta, h5_basename)
png(paste0(
  'figs/maps/',
  vox_config_id,
  '_',
  plot,
  '_',
  'voxrs_grid_p',
  phi, '_t', theta,
  '.png'
), width = 1200, height = 800, res = 200)  # You can adjust width and height as needed
plot(cc_rast, main = 'Canopy Coverage (-)', col = viridis(100))
dev.off()
