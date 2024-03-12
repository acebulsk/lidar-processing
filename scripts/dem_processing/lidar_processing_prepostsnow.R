#Lidar processing to generate DSM and snow depth maps from UAV-lidar
#Phillip Harder
#January  27, 2023
#Edited by Maddie Harasyn to only compare pre- and post- snowfall DSM layers
#More edits by alex do mod for linux processing and add some of cobs functions
# 
rm(list = ls())

#load libraries
library(dplyr)
library(purrr)
library(terra)
library(sf)
library(ggplot2)
library(ggpubr)

# paths ###########################################################
las_proc_out_path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'

# variables ###########################################################

# ofst0.1_gstep2_gspike0.1 seems to have the best aggreement with our field obs
prj_name <- 'gofst0.1_gstep2_gspike0.1'

#pre snowfall file name
pre_snow_id = "23_072"

#post snowfall file name
post_snow_id = "23_073"

#other variables ######################################################

#subset clip area
subset_clip <- read_sf('data/shp/FT_finalClip.shp')

#path to raw point clouds
# point_cloud_path = "/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds/"

#location of field data (output from rover_snow_processing.R) 
survey<-read.csv('data/survey_data/survey_points_FT.csv') |> 
  filter(Identifier == post_snow_id)
survey_gnss_pts_vect <- terra::vect(survey, geom=c("easting_m", "northing_m"), crs = "epsg:32611")

#output Hs_insitu filename
file_out = paste0(pre_snow_id, "_", post_snow_id, ".tif")

# functions ##########################################################
#error metric functions
#Root Mean Square Error
RMSE <- function(obs, est) {
  i<-which(!is.na(obs)&!is.na(est))
  sqrt(sum((est[i]-obs[i])^2)/length(est[i]))
}
#bias
bias<-function(obs,est){
  i<-which(!is.na(obs)&!is.na(est))
  sum(est[i]-obs[i])/length(est[i])
}  
#r^2 coefficient of determination
r2fun <- function(obs, pred){
  i<-which(!is.na(obs)&!is.na(pred))
  ((length(pred[i])*(sum(pred[i]*obs[i]))-sum(obs[i])*sum(pred[i]))/
      (((length(pred[i])*sum(obs[i]^2)-sum(obs[i])^2)^0.5)*((length(pred[i])*sum(pred[i]^2)-sum(pred[i])^2)^0.5)))^2
}

#convert long lat to UTM function
LongLatToUTM<-function(x,y,zone){
  xy <- data.frame(ID = 1:length(x), X = x, Y = y)
  coordinates(xy) <- c("X", "Y")
  proj4string(xy) <- CRS("+proj=longlat +datum=WGS84")  ## for example
  res <- spTransform(xy, CRS(paste("+proj=utm +zone=",zone," ellps=WGS84",sep='')))
  return(as.data.frame(res))
}

# Snow Depth Calculation by DSM subtraction ----

## merge PRE dsm outputs for each survey ----

pre_rast_tiles <-
  list.files(
    paste0(las_proc_out_path,
           pre_snow_id,
           "/dsm/", prj_name),
    pattern = '\\.bil$',
    full.names = T
  ) |> 
  map(terra::rast) 

pre_rast_merged <- do.call(terra::merge, pre_rast_tiles)

## merge POST dsm outputs for each survey ----

post_rast_tiles <-
  list.files(
    paste0(las_proc_out_path,
           post_snow_id,
           "/dsm/", prj_name),
    pattern = '\\.bil$',
    full.names = T
  ) |>
  map(terra::rast) 

post_rast_merged <- do.call(terra::merge, post_rast_tiles)

pre_post_dsm_stack <- c(pre_rast_merged, post_rast_merged)

pre_post_dsm_stack <- terra::crop(pre_post_dsm_stack, subset_clip)

# define the index of the pre and post snowfall layers
pre_index = 1
post_index = 2

#initialise snow depth raster stack
SD<-pre_post_dsm_stack[[post_index]]-pre_post_dsm_stack[[pre_index]]
SD <- SD |> 
  tidyterra::filter(tile_626850_5632000_gofst0.1_gstep2_gspike0.1> 0)

#output Hs_insitu rasters into data/Hs folder
terra::writeRaster(SD, paste0('data/dsm_snow_depth/', prj_name, '_', file_out), overwrite = T)

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

norm_rast_merged <- do.call(terra::merge, norm_rast_sd_tiles) |> 
  tidyterra::filter(tile_626850_5632000_gofst0.1_gstep2_gspike0.1 > 0)

terra::writeRaster(
  norm_rast_merged,
  paste0('data/dsm_snow_depth/', prj_name, '_normalised_', file_out),
  overwrite = T
)


# Compare survey data to LiDAR snow depth non-normalised ---- 

## Pull GNSS and DSM surface elevation ----

survey$gnss_z_snow<-survey$z

survey$lidar_dsm_z_snow<- terra::extract(post_rast_merged, survey_gnss_pts_vect, method = 'bilinear')[,2]

## Extract snow depth from dsm from survey coords ----

survey$Hs_lidar <- terra::extract(SD, survey_gnss_pts_vect, method = 'bilinear')[,2]
survey$Hs_lidar_norm <- terra::extract(norm_rast_merged, survey_gnss_pts_vect, method = 'bilinear')[,2]
survey$bias <- survey$Hs_lidar - survey$Hs_insitu
survey$bias_norm <- survey$Hs_lidar_norm - survey$Hs_insitu

ggplot2::ggplot(survey |> filter(Hs_lidar_norm > 0), ggplot2::aes(Hs_insitu, Hs_lidar_norm)) + 
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
  ylab('Normalised Lidar Snow Depth (m)') +
  xlab('In-situ Snow Depth (m)')
#plotly::ggplotly()

ggplot2::ggsave(
  paste0(
    'figs/lidar_snow_depth_analysis/pre_post_figs/',
    post_snow_id,
    '_',
    prj_name,
    '_snow_depth_Hs_insitu_vs_Hs_lidar_norm.png'
  ),
  width = 6,
  height = 4, device = png
)

ggplot2::ggplot(survey |> filter(Hs_lidar > 0), ggplot2::aes(Hs_insitu, Hs_lidar)) + 
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
  ylab('Lidar Snow Depth (m)') +
  xlab('In-situ Snow Depth (m)')
  #plotly::ggplotly()

ggplot2::ggsave(
  paste0(
    'figs/lidar_snow_depth_analysis/pre_post_figs/',
    post_snow_id,
    '_',
    prj_name,
    '_snow_depth_insitu_vs_lidar.png'
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
  lidar_insitu_Hs_RMSE=RMSE(Hs_insitu,Hs_lidar_norm), #RMSE of survey vs lidar snow depth
  lidar_insitu_Hs_Bias=bias(Hs_insitu,Hs_lidar_norm), #Bias of survey vs lidar snow depth
  lidar_insitu_Hs_r2=r2fun(Hs_insitu,Hs_lidar_norm), #R2 of survey vs lidar snow depth
  lidar_gnss_z_snow_RMSE=RMSE(gnss_z_snow,lidar_dsm_z_snow),#RMSE of survey vs lidar snow surface elevation 
  lidar_gnss_z_snow_Bias=bias(gnss_z_snow,lidar_dsm_z_snow), #Bias of survey vs lidar snow surface elevation 
  lidar_gnss_z_snow_r2=r2fun(gnss_z_snow,lidar_dsm_z_snow), #Bias of survey vs lidar snow surface elevation 
) |> distinct()

errors

write.csv(errors, paste0('data/error_summary/error_table_pre_post_', post_snow_id, '_', prj_name, '.csv'))

error_tbl_files <- list.files('data/error_summary/', pattern = 'error_table*', full.names = T)
all_err_tbls <- purrr::map_dfr(error_tbl_files, read.csv)
write.csv(all_err_tbls, 'data/error_summary/all_error_tbls.csv', row.names = F)