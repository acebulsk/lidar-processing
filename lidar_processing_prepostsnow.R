#Lidar processing to generate DSM and snow depth maps from UAV-lidar
#Phillip Harder
#January  27, 2023
#Edited by Maddie Harasyn to only compare pre- and post- snowfall DSM layers
#More edits by alex do mod for linux processing
rm(list = ls())

#load libraries
library(dplyr)
library(purrr)
library(raster)
library(rgdal)
library(sf)


# variables ###########################################################

#pre snowfall file name
pre_snow_las = "23_026_FT_new"

#post snowfall file name
post_snow_las = "23_027_FT_new"

#other variables ######################################################
#name of shapefile to clip ROI
# make sure this isnt too small as the las clip function has weird behaviour we
# handle this by doing a secondary clip in R
# shp_name<-"FT_initialClip"

#subset clip area
subset_clip <- read_sf('prepost_data/shp/FT_finalClip.shp')

#path to raw point clouds
# point_cloud_path = "/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds/"

#resolution of output DEMs
RES_STEP = "0.1"

#location of field data (output from rover_snow_processing.R) 
survey<-read.csv('prepost_data/survey_data/survey_points_FT.csv')

#output Hs_insitu filename
file_out = paste0(substr(pre_snow_las, 1,6), "_", substr(post_snow_las, 4,6), ".tif")

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

#list point cloud .las files
#modified to only input pre and post files we want into LAS tools
files <- c(pre_snow_las, post_snow_las)
files<-tools::file_path_sans_ext(files)

# LAS TOOLS ##########################################################
# For now just running  the LAStools_process_prepost.sh script externally
# could update to edit params through R here.

#LAStools processing produces a DEM
#processes are organised in LAStools_process.bat file.
#update lastools .bat script
# txt<-readLines('LAStools_process_prepost.bat')
# #update list to process
# txt[[13]]<-paste(c("set list=",files),collapse=" ")
# #update working directory
# txt[[14]]<-paste(c("set local_path=",gsub("/","\\\\",getwd())),collapse=" ")
# #update clipping area with name of correct .shp file
# txt[[15]]<-paste(c("set shp_name=", shp_name),collapse="")
# #update resolution of DEMs
# txt[[16]]<-paste(c("set STEP=", RES_STEP),collapse="")
# writeLines(txt, con = "LAStools_process.bat")
# #run LASTools code from R
# shell('LAStools_process.bat')


# main script ######################################################
#load generated DSM's to R
#search for filenames put into raw data fodler (prepost_data/point_clouds) to create search list for dsm files
#modified so only dates of interested are pulled in, not ALL las files in 'point_cloud' folder
tiffs<-paste0(files, '.tif')
DSM_stack<-raster(paste("prepost_data/dsm/",tiffs[1], sep=""))
DSM_stack <- crop(DSM_stack, subset_clip)

for(i in 2:length(tiffs)){
  DSM_temp<-raster(paste("prepost_data/dsm/",tiffs[i], sep=""))
  DSM_temp<- crop(DSM_temp, subset_clip) 
  DSM_stack<-addLayer(DSM_stack, DSM_temp)
}

#identify which layers are snow covered (ie not the bare layer)
pre_index = 1
post_index = 2


#initialise snow depth raster stack
SD<-DSM_stack[[post_index]]-DSM_stack[[pre_index]]

#output Hs_insitu rasters into prepost_data/Hs folder
#raster::writeRaster(SD, paste0('prepost_data/Hs/', file_out), overwrite = T)


#Convert lat long to UTM
survey$X_utm<-NA
survey$Y_utm<-NA
survey$zone<-11
for(i in 1:length(survey$Identifier)){
  survey[i,c('X_utm', 'Y_utm')]<-LongLatToUTM(survey$Longitude[i],survey$Latitude[i],survey$zone[i])[2:3]  
}


#compute snow surface and ground surface elevations
survey$gnss_z_snow<-survey$z


#For loop to extract elevation data from UAV data corresponding to survey point data
#call for bare ground assessment
#survey$DSM_z_soil<-raster::extract(DSM_stack[[pre_index]],SpatialPoints(cbind(survey$X_utm,  survey$Y_utm)))
#loop for snow surface assessment
survey$lidar_dsm_z_snow<-NA

# do gnss to lidar raster surface elevation comparison
# gnss_z_snow is rover 
# lidar_dsm_z_snow is lidar raster estimate 
post_id <- gsub("_FT.las", "", post_snow_las)
survey$lidar_dsm_z_snow[which(survey$Identifier==post_id)]<- raster::extract(DSM_stack[[2]],SpatialPoints(cbind(survey$X_utm[which(survey$Identifier==post_id)],  
                                                                                                                     survey$Y_utm[which(survey$Identifier==post_id)])))
#loop for snow depth assessment
survey$Hs_lidar<-NA

survey$Hs_lidar[which(survey$Identifier==post_id)]<- raster::extract(SD,SpatialPoints(cbind(survey$X_utm[which(survey$Identifier==post_id)],  
                                                                                                   survey$Y_utm[which(survey$Identifier==post_id)])))


#error summarization
survey_select<-survey %>% 
  dplyr::filter(Identifier == post_id)
write.csv(survey_select, paste0('prepost_data/error_summary/survey_data_pre_post_', post_id, '.csv'))

errors <- survey_select %>% 
  dplyr::group_by(Identifier) %>% dplyr::summarise(
  lidar_insitu_Hs_RMSE=RMSE(Hs_insitu,Hs_lidar), #RMSE of survey vs lidar snow depth
  lidar_insitu_Hs_Bias=bias(Hs_insitu,Hs_lidar), #Bias of survey vs lidar snow depth
  lidar_insitu_Hs_r2=r2fun(Hs_insitu,Hs_lidar), #R2 of survey vs lidar snow depth
  lidar_gnss_z_snow_RMSE=RMSE(gnss_z_snow,lidar_dsm_z_snow),#RMSE of survey vs lidar snow surface elevation 
  lidar_gnss_z_snow_Bias=bias(gnss_z_snow,lidar_dsm_z_snow), #Bias of survey vs lidar snow surface elevation 
  lidar_gnss_z_snow_r2=r2fun(gnss_z_snow,lidar_dsm_z_snow), #Bias of survey vs lidar snow surface elevation 

)

errors

write.csv(errors, paste0('prepost_data/error_summary/error_table_pre_post_', post_id, '.csv'))

error_tbl_files <- list.files('prepost_data/error_summary/', pattern = 'error_table*', full.names = T)
all_err_tbls <- purrr::map_dfr(error_tbl_files, read.csv)
write.csv(all_err_tbls, 'prepost_data/error_summary/all_error_tbls.csv', row.names = F)
