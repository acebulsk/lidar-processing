# map grid resampling output for select phi theta combo
library(terra)
library(viridis)
library(rhdf5)

cn_coef <- 0.38 # from VoxRS default, also see supplementary material for Staines & Pomeroy 2023

plot_names <- c('FSR_NW', 'FSR_NE', 'FSR_S', 'PWL_E', 'PWL_N', 'PWL_SW')

plot <- 'PWL_E'
# event_ids <- c('23_026', '23_027')
event_ids <- c('23_072', '23_073')

voxrs_outputs <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'
las_prj_name <- 'params_v1.0.0'
vox_id <- event_ids[1] # which day do we want canopy metrics for?
vox_config_id <- paste0(vox_id, '_vox_len_0.25m_')
vox_runtag <- paste0('_gridgen_', plot)


h5_basename <- paste0(voxrs_outputs,
                      vox_id,
                      '/voxrs/outputs/grid_resampling/',
                      'grid_resampled',
                      '_',
                      vox_config_id,
                      vox_runtag)

phi <- 0
theta <- 0
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
