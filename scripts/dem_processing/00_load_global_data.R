# get data to use across scripts

library(dplyr)
library(purrr)
library(terra)
library(sf)
library(ggplot2)
library(ggpubr)

# input data paths ----

## copernicus ----

# bash code to copy data from copernicus
# rsync --progress -r -z zvd094@copernicus:/globalhome/zvd094/HPC/sym_link_gwf_prj/fortress/lidar-processing/data/processed/22_068/dsm_hs_normalised /media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/22_068/

las_proc_out_path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'

# local HDD ---- 
# las_proc_out_path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'

# Variables ----

prj_name <- 'params_v1.0.0'

# pre_post_ids <- c('22_066', '22_068')
# pre_post_ids <- c('23_072', '23_073')
pre_post_ids <- c('23_026', '23_027')
pre_snow_id = pre_post_ids[1]
post_snow_id = pre_post_ids[2]

dsm_res_custm <- 0.25 # to coarsen the lastools output dsm

# Masks ----

#subset clip area
# subset_clip <- read_sf('data/gis/shp/fsr_traj_extent_buff_20m.shp') # this is whats used in lastools and not needed again here
fsr_plots <- read_sf('data/gis/shp/fsr_forest_plots_v_1_0.shp') # six select forest plots
# fsr_plots <- read_sf('data/gis/shp/fsr_lidar_plots_v_2_0.shp') # updated to extend north
# fsr_plots <- read_sf('data/gis/shp/fsr_lidar_plots.shp') # original small ones
fsr_masks <- read_sf('data/gis/shp/fsr_snow_depth_mask_road_objects_etc.shp')
fsr_ss_transect_mask <- read_sf('data/gis/shp/fsr_snowsurvey_transect_trampled_30cm_buff.shp')

# functions ----
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