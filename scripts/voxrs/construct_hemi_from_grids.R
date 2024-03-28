# this script returns the correlation between contact number and interception
# efficiency, this is run for each portion of the hemisphere (360*90
# regressions), the correlation is between between a raster of IP and a raster
# of Contact Numbers (inside the h5 files)

# INPUT: h5 files that contain voxrs step 2 outputs 
# OUTPUT: list of correlations (rho_s, rho_p) for each phi / theta pair (360*91)

library(terra)
library(sf)
library(purrr)
library(rhdf5)
library(dplyr)
library(pbapply)

# h5path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/voxrs/outputs/grid_resampling/grid_resampled_23_072_vox_len_0.25m__gridgen_FSR_NE_t0_14.h5'
# h5readAttributes(file = h5path, name = 'p1_t10')

phi_from <- 0
phi_to <- 90
phi_by <- 1
theta_from <- 0
theta_to <- 359
theta_by <- 1

# plot_name <- 'FSR_NW'
# plot_name <- 'FSR_NE'
# plot_name <- 'FSR_S'
# plot_name <- 'PWL_E'
plot_name <- 'PWL_N'
# plot_name <- 'PWL_SW'

vox_id <- '23_026' # which day do we want canopy metrics for?
vox_config_id <- '23_026_vox_len_0.25m_'
vox_runtag <- paste0('_gridgen_', plot_name)
las_prj_name <- 'params_v1.0.0'
event_ids <- c('23_026', '23_027')
voxrs_outputs <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'
h5_basename <- paste0(voxrs_outputs,
                      vox_id,
                      '/voxrs/outputs/grid_resampling/',
                     'grid_resampled',
                     '_',
                     vox_config_id,
                     vox_runtag)

# data inputs ----

# pull in IP raster, negatives have been set to 0
ip_rast <- rast(
  paste0(
    'data/dsm_ip/',
    event_ids[1],
    '_',
    event_ids[2],
    '_',
    las_prj_name,
    '_',
    plot_name,
    '_',
    'ip_normalised_resample_0.25_crop_mask.tif'
  )
)


ip_pts <- terra::as.points(ip_rast, na.rm = T) |> # removing the left join didnt save much time
  as.data.frame(geom="XY")

ip_pts_vect <- ip_pts$`I/P`

# construct list of phi / theta pairs over the hemisphere
phi_list <- seq(phi_from, phi_to, by = phi_by)
# Create theta_list
theta_list <- seq(theta_from, theta_to, by = theta_by)

# Create phi_theta list
phi_theta_df <- expand.grid(phi_list, theta_list)
names(phi_theta_df) <- c('phi_d', 'theta_d')
phi_theta_list <- asplit(phi_theta_df, 1)

set_suffix <- function(theta) {
  ranges <-
    cut(
      theta,
      breaks = c(0, seq(14, 359, by = 15)),
      labels = paste0('t', seq(0, 345, by = 15), '_', seq(14, 359, by = 15)),
      include.lowest = T,
      right = T
    )
  suffix <- as.character(ranges)
  return(suffix)
}

#' Correlate VoxRS Mean Contact Number and Interception Efficiency over a grid area
#'
#' @param phi_theta_pairs list of phi and theta pairs
#' @param ip_df data frame with x, y and interception efficiency. XY must match with the voxrs h5 file outputs.
#'
#' @return 
#' @export
#'
#' @examples
regress_mcn_ip <- function(phi_theta_pairs, ip_df){
  phi <- phi_theta_pairs[1]
  theta <- phi_theta_pairs[2]
  
  suffix <- set_suffix(theta)
  
  h5filename <- paste0(h5_basename,
                       "_",
                       suffix,
                       '.h5')
  
  h5_dataset <- paste0('p', phi, '_', 't', theta)
  
  # creater pointer to h5 file w.o. reading into R memory, doesnt work with paralellisation
  # h5f <- H5Fopen(h5filename)
  # # h5_pointer <- h5f&h5_dataset 
  # H5Fclose(h5f)
  
  # # bring h5 into R memory
  # mcn <- h5_pointer[4,]
  # H5Dclose(h5_pointer)
  
  # direct to R memory, careful with large files.... 
  h5_data <- h5read(h5filename, h5_dataset) # same speed as `h5f$'p0_t0'`, the index arg slows this down, since files are small dont need to do this
  
  mcn <- h5_data[4,]
  
  # use this if our ncells do not match between IP and MCN
  # mcn_df <- data.frame(
  #   x = h5_pointer[1,],
  #   y = h5_pointer[2,],
  #   mcn = h5_pointer[3,])
  # mcn_ip <- left_join(mcn_df, ip_df, by = c('x', 'y'))

  h5closeAll()
  
  rp <- cor(mcn, ip_pts_vect, method = 'pearson') # linear relationship
  rs <- cor(mcn, ip_pts_vect, method = 'spearman') # ranked values better for non-linear
  
  phi_theta_pairs[3] <- rp
  phi_theta_pairs[4] <- rs
  
  return(phi_theta_pairs)
  
}

# cor_list_out <- lapply(phi_theta_list, regress_mcn_ip, ip_df = ip_pts)
cor_list_out <-
  pbapply::pblapply(phi_theta_list, regress_mcn_ip, ip_df = ip_pts, cl = 8)

saveRDS(cor_list_out, 
        paste0('data/hemi_stats/full_hemi_correlation_grid_resampled_',
               vox_config_id,
               vox_runtag,
               '.rds'
               ))

h5closeAll()

# library(ggplot2)
# library(ggpubr)
# 
# ggplot(swe_mcn, aes(mcn, `I/P`)) +
#   geom_point() +
#   stat_cor(method = "pearson")


