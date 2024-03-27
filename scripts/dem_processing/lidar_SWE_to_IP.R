# convert SWE raster to I/P
library(tidyverse)
library(terra)

# get SWE raster from the lidar_snow_depth_to_SWE.R output
del_tf_rast <- rast(
  paste0(
    'data/dsm_swe/',
    pre_post_ids[1],
    '_',
    pre_post_ids[2],
    '_',
    prj_name,
    'swe_normalised_resample_0.25.tif'
  ))

# get traj files for start/end times for lidar flights which will define the event diuration
traj_pre <- read.csv(paste0(
  '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/metadata/drone_trajectory/',
  pre_post_ids[1],
  '_all_lidar_trajectory.txt'
))

traj_post <- read.csv(paste0(
  '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/metadata/drone_trajectory/',
  pre_post_ids[2],
  '_all_lidar_trajectory.txt'
))

# get Powerline met data
pwl_met <- readRDS('../met-data-processing/data/ffr_t_rh_u_qaqc_fill.rds')
pwl_sf <- readRDS('../met-data-processing/data/pluvio-qaqc/pwl_pluvio_15_min_qaqc_undercatch_corr_ac.rds')

# compute lidar start and end time

origin <- as.POSIXct('1980-01-06 00:00:00', tz = 'UTC')

traj_pre_fin <- tail(traj_pre$Time.s., n = 1)+1e9
event_start_time <- as.POSIXct(traj_pre_fin, origin = origin, tz = 'UTC')
event_start_time <- format(event_start_time, tz = 'Etc/GMT+6') |> as.POSIXct(tz = 'Etc/GMT+6')

traj_post_fin <- tail(traj_post$Time.s., n = 1)+1e9
event_end_time <- as.POSIXct(traj_post_fin, origin = origin, tz = 'UTC')
event_end_time <- format(event_end_time, tz = 'Etc/GMT+6') |> as.POSIXct(tz = 'Etc/GMT+6')

# compute snowfall accumulation for the event

pwl_sf_event <- pwl_sf |> 
  filter(datetime >= event_start_time,
         datetime <= event_end_time) |> 
  mutate(event_pc = cumsum(ppt))

ggplot(pwl_sf_event, aes(datetime, event_pc)) +
  geom_line()

del_sf <- sum(pwl_sf_event$ppt)

# EQ: I = del_sf - del_tf assuming no unloading/ redistribution

i_rast <- del_sf - del_tf_rast

ip_rast <- i_rast / del_sf

ip_rast <- ifel(ip_rast < 0, 0, ip_rast)

names(ip_rast) <- 'I/P'

terra::writeRaster(
  ip_rast,
  paste0(
    'data/dsm_ip/',
    pre_post_ids[1],
    '_',
    pre_post_ids[2],
    '_',
    prj_name,
    'ip_normalised_resample_0.25.tif'
  ),  overwrite = T
)

# crop to study zone

ip_rast <- terra::crop(ip_rast, fsr_plots, mask = T)

ip_rast <- terra::mask(ip_rast, fsr_masks, inverse = T)

ip_rast <- terra::mask(ip_rast, fsr_ss_transect_mask, inverse = T)

terra::writeRaster(
  ip_rast,
  paste0(
    'data/dsm_ip/',
    pre_post_ids[1],
    '_',
    pre_post_ids[2],
    '_',
    prj_name,
    'ip_normalised_resample_0.25_crop_mask.tif'
  ),  overwrite = T
)


for(plot in 1:nrow(fsr_plots)){
  plot_mask_sf <- fsr_plots[plot, ]
  ip_rast_plot <- terra::crop(ip_rast, plot_mask_sf, mask = T)
  
  terra::writeRaster(
    ip_rast_plot,
    paste0(
      'data/dsm_ip/',
      pre_post_ids[1],
      '_',
      pre_post_ids[2],
      '_',
      prj_name,
      '_',
      plot_mask_sf$name,
      '_',
      "ip_normalised_resample_0.25_crop_mask.tif"
    ),  overwrite = T
  )
  
}
