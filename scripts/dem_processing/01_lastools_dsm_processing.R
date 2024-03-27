#Lidar processing to generate DSM and snow depth maps from UAV-lidar
#Phillip Harder
#January  27, 2023
#Edited by Maddie Harasyn to only compare pre- and post- snowfall DSM layers
#More edits by alex do mod for linux processing and add some of cobs functions
# INPUT: LAStools dsm output
# OUTPUT: insitu/lidar Error stats, Merged dsm and masked dsm to study area

# other variables ######################################################

#location of field data (output from rover_snow_processing.R) 
survey<-read.csv('data/survey_data/survey_points_FT.csv') |> 
  filter(Identifier == post_snow_id)
survey_gnss_pts_vect <- terra::vect(survey, geom=c("easting_m", "northing_m"), crs = "epsg:32611")

if(nrow(survey) == 0){
  warning("No Survey Data Found...")
}

#output Hs_insitu filename
prefix = paste0(pre_snow_id, "_", post_snow_id)

# Snow Depth Calculation by DSM subtraction ----

## merge PRE dsm outputs for each survey ----

# pre_rast_tiles <-
#   list.files(
#     paste0(las_proc_out_path,
#            pre_snow_id,
#            "/dsm/", prj_name),
#     pattern = '\\.bil$',
#     full.names = T
#   ) |> 
#   map(terra::rast) 
# 
# pre_rast_merged <- do.call(terra::merge, pre_rast_tiles)
# 
# ## merge POST dsm outputs for each survey ----
# 
# post_rast_tiles <-
#   list.files(
#     paste0(las_proc_out_path,
#            post_snow_id,
#            "/dsm/", prj_name),
#     pattern = '\\.bil$',
#     full.names = T
#   ) |>
#   map(terra::rast) 
# 
# post_rast_merged <- do.call(terra::merge, post_rast_tiles)
# 
# pre_post_dsm_stack <- c(pre_rast_merged, post_rast_merged)
# 
# pre_post_dsm_stack <- terra::crop(pre_post_dsm_stack, subset_clip)
# 
# # define the index of the pre and post snowfall layers
# pre_index = 1
# post_index = 2

#initialise snow depth raster stack
# SD<-pre_post_dsm_stack[[post_index]]-pre_post_dsm_stack[[pre_index]]
# names(SD) <- 'snow_depth_m'
# 
# perc_99 <- quantile(values(SD), probs = 0.999, na.rm = T)
# 
# SD <- ifel(SD < 0, NA, SD)
# SD <- ifel(SD >= perc_99, NA, SD)
# 
# #output Hs_insitu rasters into data/Hs folder
# terra::writeRaster(SD, paste0('data/dsm_snow_depth/', prefix, '_', prj_name, '.tif'), overwrite = T)

# Snow Depth Calculation Using normalised snow depth ----

#with this method we normalise the post flight point cloud to the preflight
#point cloud to derive a new point cloud of snow depth elevations which is then
#converted to a dsm. Just a different method compared to the dsm subtraction.

norm_rast_sd_tiles <-
  list.files(
    paste0(las_proc_out_path,
           post_snow_id,
           "/dsm_hs_normalised/", prj_name),
    pattern = '\\.bil$',
    full.names = T
  ) |> 
  map(terra::rast) 

norm_rast_merged <- do.call(terra::merge, norm_rast_sd_tiles) 

names(norm_rast_merged) <- 'snow_depth_m'

perc_99 <- quantile(values(norm_rast_merged), probs = 0.999, na.rm = T)

norm_rast_merged <- ifel(norm_rast_merged < 0, NA, norm_rast_merged)
norm_rast_merged <- ifel(norm_rast_merged >= perc_99, NA, norm_rast_merged)

terra::writeRaster(
  norm_rast_merged,
  paste0('data/dsm_snow_depth/', prefix, '_', prj_name, '_normalised.tif'),
  overwrite = T
)

# Resample Snow Depth DSM to coarser resolution ----

# this is after staines 2023 who avoid lastools interpolation i.e., 5 cm res
# from lastools to 25 cm res final this method works well because by taking the
# median of the 5 cm cells within the 25 cm cell we are limiting additional
# noise

bbox <- terra::ext(norm_rast_merged)

# construct raster so cells match up with centre of dots
template_rast <- terra::rast(
  resolution = dsm_res_custm,
  xmin = bbox$xmin,
  xmax = bbox$xmax,
  ymin = bbox$ymin,
  ymax = bbox$ymax,
  vals = NA_real_,
  crs = "epsg:32611"
)

# take the median of the cells w/in out coarser template
norm_rast_resamp <-
  terra::resample(norm_rast_merged, template_rast, method = 'med')

terra::writeRaster(
  norm_rast_resamp,
  paste0(
    'data/dsm_snow_depth/',
    prefix,
    '_',
    prj_name,
    '_normalised_resample_',
    dsm_res_custm,
    '.tif'
  ),
  overwrite = T
)

norm_rast_merged_crop <- terra::crop(norm_rast_resamp, fsr_plots, mask = T)

norm_rast_merged_crop <- terra::mask(norm_rast_merged_crop, fsr_masks, inverse = T)

norm_rast_merged_crop <- terra::mask(norm_rast_merged_crop, fsr_ss_transect_mask, inverse = T)


terra::writeRaster(
  norm_rast_merged_crop,
  paste0('data/dsm_snow_depth/', prefix, '_', prj_name, '_normalised_resample_crop_mask.tif'),
  overwrite = T
)

# Compare survey data to LiDAR snow depth non-normalised ---- 

## Pull GNSS and DSM surface elevation ----

# survey$gnss_z_snow<-survey$z

# survey$lidar_dsm_z_snow<- terra::extract(post_rast_merged, survey_gnss_pts_vect, method = 'bilinear')[,2]

## Extract snow depth from dsm from survey coords ----

# bilinear for small resolution and simple for larger res
# survey$Hs_lidar <- terra::extract(SD, survey_gnss_pts_vect, method = 'bilinear')[,2]
survey$Hs_lidar_norm <- terra::extract(norm_rast_merged, survey_gnss_pts_vect, method = 'bilinear')[,2]
survey$Hs_lidar_resamp <- terra::extract(norm_rast_resamp, survey_gnss_pts_vect, method = 'simple')[,2]
# survey$bias <- survey$Hs_lidar - survey$Hs_insitu
survey$bias_norm <- survey$Hs_lidar_norm - survey$Hs_insitu
survey$bias_resamp <- survey$Hs_lidar_resamp - survey$Hs_insitu

ggplot2::ggplot(survey |> filter(Hs_lidar_resamp > 0), ggplot2::aes(Hs_insitu, Hs_lidar_resamp)) + 
  ggplot2::geom_point(aes(colour = canopy)) +
  ggplot2::geom_abline()  +
  ggpubr::stat_cor(aes(
    label = paste(
      ..rr.label..,
      if_else(
        readr::parse_number(..p.label..) < 0.001,
        "p<0.001",
        ..p.label..
      ),
      sep = "~`, `~"
    )),
    geom = "label",
    show.legend = F) +
  ylim(c(0, NA)) +
  xlim(c(0, NA)) +
  ylab('Resampled Lidar Snow Depth (m)') +
  xlab('In-situ Snow Depth (m)')
#plotly::ggplotly()

ggplot2::ggsave(
  paste0(
    'figs/lidar_snow_depth_analysis/pre_post_figs/',
    post_snow_id,
    '_',
    prj_name,
    '_snow_depth_Hs_insitu_vs_Hs_lidar_resamp.png'
  ),
  width = 6,
  height = 4, device = png
)

# normalised is slightly worse statistically but has more data under the canopy
# so going to use this from now on, compare the tifs in qgis to see

#error summary
survey_select<-survey |> 
  dplyr::filter(Identifier == post_snow_id) |> 
  mutate(prj_name = prj_name) |> 
  select(Identifier, prj_name, everything())
write.csv(survey_select, paste0('data/lidar_w_survey_hs/survey_data_pre_post_', post_snow_id, '_', prj_name, '.csv'))

errors <- survey_select |> 
  group_by(Identifier) |> 
  dplyr::summarise(
  prj_name = prj_name,
  lidar_insitu_Hs_RMSE=RMSE(Hs_insitu,Hs_lidar_resamp), #RMSE of survey vs lidar snow depth
  lidar_insitu_Hs_Bias=bias(Hs_insitu,Hs_lidar_resamp), #Bias of survey vs lidar snow depth
  lidar_insitu_Hs_r2=r2fun(Hs_insitu,Hs_lidar_resamp), #R2 of survey vs lidar snow depth
  # lidar_gnss_z_snow_RMSE=RMSE(gnss_z_snow,lidar_dsm_z_snow),#RMSE of survey vs lidar snow surface elevation 
  # lidar_gnss_z_snow_Bias=bias(gnss_z_snow,lidar_dsm_z_snow), #Bias of survey vs lidar snow surface elevation 
  # lidar_gnss_z_snow_r2=r2fun(gnss_z_snow,lidar_dsm_z_snow), #Bias of survey vs lidar snow surface elevation 
) |> distinct()

errors

write.csv(errors, paste0('data/error_summary/error_table_pre_post_', post_snow_id, '_', prj_name, '.csv'))

error_tbl_files <- list.files('data/error_summary/', pattern = 'error_table*', full.names = T)
all_err_tbls <- purrr::map_dfr(error_tbl_files, read.csv)
write.csv(all_err_tbls, 'data/error_summary/all_error_tbls.csv', row.names = F)