# this script returns the correlation between contact number and interception
# efficiency, this is run for each portion of the hemisphere (360*90
# regressions), the correlation is between between a raster of IP and a raster
# of Contact Numbers (inside the h5 files)

# INPUT: h5 files that contain voxrs step 2 outputs 
# OUTPUT: list of correlations (rho_s, rho_p) for each phi / theta pair (360*91)

# h5path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/voxrs/outputs/grid_resampling/grid_resampled_23_072_vox_len_0.25m__gridgen_FSR_NE_t0_14.h5'
# h5readAttributes(file = h5path, name = 'p1_t10')
# TODO NEED TO UPDATE FROM PLOTTING ESTIMATED RETURNS TO CONTACT NUMBER USING:
# contact_number = returns_mean * cn_coef,
# cn_coef <- 0.38 # from VoxRS default, also see supplementary material for Staines & Pomeroy 2023

phi_from <- 0
phi_to <- 90
phi_by <- 1
theta_from <- 0
theta_to <- 359
theta_by <- 1

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
    plot,
    '_',
    'ip_normalised_resample_0.25_crop_mask.tif'
  )
)

# mean(values(ip_rast), na.rm = T)

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

# cor_list_out <- lapply(phi_theta_list, regress_mcn_ip, ip_df = ip_pts)
cor_list_out <-
  pbapply::pblapply(phi_theta_list, regress_mcn_ip, ip_df = ip_pts, cl = n_cores)

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


