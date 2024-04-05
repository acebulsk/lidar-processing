# lidar snow depth to SWE using FSD
library(terra)
library(sf)
library(dplyr)
library(viridis)

# constants ----
rho_water <- 1000 # kg/m3

# data input ----

lidr_sd_path <- paste0(
  'data/dsm_snow_depth/',
  pre_post_ids[1],
  '_',
  pre_post_ids[2],
  '_',
  prj_name,
  '_normalised_resample_',
  dsm_res_custm,
  '_bias_corrected.tif'
)

lidr_swe_path <- paste0(
  'data/dsm_swe/',
  pre_post_ids[1],
  '_',
  pre_post_ids[2],
  '_',
  prj_name,
  'swe_normalised_resample_',
  dsm_res_custm,
  '.tif'
)

lidr_sd <- rast(lidr_sd_path)

rho_fsd <- readRDS('../snow-stats/data/processed/fresh_snow_densities_db.rds') |> 
  mutate(jday = format(surv_date, '%y_%j'))

# see ~/local-usask/analysis/snow-stats/scripts/03_append_fresh_snow_densities.R
# for detailed plots on this

rho_fsd |> 
  group_by(surv_date) |> 
  reframe(rho_mean = rho_snow_surv_avg) |> 
  distinct()

# sd to swe conversion ----
event_fsd_rho <- rho_fsd |> 
  filter(jday == pre_post_ids[2]) |> 
  pull(rho_snow_surv_avg) |> 
  unique() |> 
  as.numeric() # rm units for compatibility with spatraster

# SWE [kg/m^2] = depth snow [m] * density of snow [kg/m^3]
# SWE [m] = SWE [kg/m^2] / rho water [kg/m^3]
# SWE [mm] = SWE [m] * 1000

lidr_swe_kg_m2 <- lidr_sd * event_fsd_rho

names(lidr_swe_kg_m2) <- 'swe_kg_m2'

# Save the plot for lidr_sd
png(paste0(
  'figs/maps/',
  pre_post_ids[1],
  '_',
  pre_post_ids[2],
  '_',
  prj_name,
  'sd_normalised_resample_',
  dsm_res_custm,
  '.png'
), width = 600, height = 400, res = 125)  # You can adjust width and height as needed
plot(lidr_sd, main = '𝚫 Snow Depth (m)', col = viridis(100))
plot(fsr_plots, add = T, col = NA, border = 'red', lwd = 1.5)
dev.off()

# Save the plot for lidr_sd
png(paste0(
  'figs/maps/',
  pre_post_ids[1],
  '_',
  pre_post_ids[2],
  '_',
  prj_name,
  'swe_normalised_resample_',
  dsm_res_custm,
  '.png'
), width = 600, height = 400, res = 125)  # You can adjust width and height as needed
plot(lidr_swe_kg_m2, main = '𝚫 SWE (kg m⁻²)', col = viridis(100))
plot(fsr_plots, add = T, col = NA, border = 'red', lwd = 1.5)
dev.off()

writeRaster(lidr_swe_kg_m2, lidr_swe_path,  overwrite = T)

lidr_swe_crop <- terra::crop(lidr_swe_kg_m2, fsr_plots, mask = T)

lidr_swe_crop <- terra::mask(lidr_swe_crop, fsr_masks, inverse = T)

lidr_swe_crop <- terra::mask(lidr_swe_crop, fsr_ss_transect_mask, inverse = T)

terra::writeRaster(
  lidr_swe_crop,
  paste0(
    'data/dsm_swe/',
    pre_post_ids[1],
    '_',
    pre_post_ids[2],
    '_',
    prj_name,
    'swe_normalised_resample_',
    dsm_res_custm,
    '_crop_mask.tif'
  ),  overwrite = T
)
