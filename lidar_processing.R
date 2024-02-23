#Lidar processing to generate DSM and snow depth maps from UAV-lidar
#Phillip Harder
#January  27, 2023
rm(list = ls())
start.time <- Sys.time() #store start time of code

# load libraries
library(dplyr)
library(purrr)
library(raster)
library(rgdal)
library(sf)

# variables ###########################################################

#name of shapefile to clip ROI #CanRidge.shp fortress_extent.shp FortRidgeSouth.shp ForestTower_clip.sh
# make sure this isnt too small as the las clip function has weird behaviour we
# handle this by doing a secondary clip in R
shp_name<-"FT_initialClip"

#subset clip area
subset_clip <- read_sf('data/shp/FT_finalClip.shp')

#bare ground file name
bare_ground_las = "22_292.las"

#path to raw point clouds
point_cloud_path = "data/point_cloud/"

#resolution of output DEMs
RES_STEP = "0.1"

# #point cloud thinning step (EXTRA ANALYSIS, BAT FILE EDITDED TO ACCOMIDATE)
# THINSTEP = "0.2" ####MODIFY THIS LINE FOR POINT CLOUD RES

#location of field data (output from rover_snow_processing.R) 
surv_full<-read.csv('data/survey_data/survey_points_FT.csv')

#days with no field data
no_survey_days_list <- c("22_168", "22_243")

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
files<-list.files("data/point_cloud/", pattern="*.las",full.names = FALSE)
files<-tools::file_path_sans_ext(files)
# files <- files[!files %in% no_survey_days_list]

# LAS TOOLS ##########################################################
# AVOID RUNNING IF DATA ALREADY PROCESSED!!

#LAStools processing produces a DEM
#processes are organised in LAStools_process.bat file.
#update lastools .bat script
txt<-readLines('LAStools_process.bat')
#update list to process
txt[[13]]<-paste(c("set list=",files),collapse=" ")
#update working directory
txt[[14]]<-paste(c("set local_path=",gsub("/","\\\\",getwd())),collapse=" ")
#update clipping area with name of correct .shp file
txt[[15]]<-paste(c("set shp_name=", shp_name),collapse="")
#update resolution of DEMs
txt[[16]]<-paste(c("set STEP=", RES_STEP),collapse="")
# #update thinning step for point cloud (EXTRA ANALYSIS TO CHECK HOW THINNING AFFECTS BIAS)
# txt[[17]]<-paste(c("set THINSTEP=", THINSTEP),collapse="")
writeLines(txt, con = "LAStools_process.bat")
#run LASTools code from R
shell('LAStools_process.bat')

# main script ######################################################
#load generated DSM's to R
#search for filenames put into raw data fodler (data/point_clouds) to create search list for dsm files
tiffs <- list.files("data/point_cloud/", pattern="*.las$")
tiffs<-gsub('las', 'tif', tiffs)
DSM_stack<-raster(paste("data/dsm/",tiffs[1], sep=""))
DSM_stack <- crop(DSM_stack, subset_clip)

for(i in 2:length(tiffs)){
  DSM_temp<-raster(paste("data/dsm/",tiffs[i], sep=""))
  DSM_temp<- crop(DSM_temp, subset_clip)
  DSM_stack<-addLayer(DSM_stack, DSM_temp)
}


#identify which layers are snow covered (ie not the bare layer)
point_cloud_list = list.files(path = point_cloud_path, pattern="*.las$")
bare_index = which(point_cloud_list == bare_ground_las)

snow_index<-1:length(tiffs)
snow_index<-snow_index[snow_index!=bare_index]

#initialise snow depth raster stack
SD<-DSM_stack[[min(snow_index)]]-DSM_stack[[bare_index]]
names(SD)<-gsub("DSM","Hs_insitu",names(DSM_stack[[min(snow_index)]]))
if(length(snow_index)>1){
  for(i in snow_index[2:length(snow_index)]){
    SD_temp<-DSM_stack[[i]]-DSM_stack[[bare_index]]
    names(SD_temp)<-gsub("X","",names(DSM_stack[[i]]))
    terra::writeRaster(SD_temp, paste0('data/Hs/', gsub("X","",names(DSM_stack[[i]])), '.tif'),overwrite=TRUE) #output Hs rasters into data/Hs folder
    SD<-addLayer(SD,SD_temp)
  }
}

#remove 'E' survey points
survey <- surv_full %>% 
  filter(canopy %in% c('M', 'O'))

#add a column for survey point counter (T1 1 = 1)
survey$surveyIndx <- NA
for(i in 1:length(survey$Identifier)){
  if(survey[i, 'transect'] == 'T1'){
    survey[i, c('surveyIndx')]<- survey[i, 'surv_id'] }

  else{
    survey[i, c('surveyIndx')]<- survey[i, 'surv_id'] + 30 }

    }


#Convert lat long to UTM
survey$X_utm<-NA
survey$Y_utm<-NA
survey$zone<-11
for(i in 1:length(survey$Identifier)){
  survey[i,c('X_utm', 'Y_utm')]<-LongLatToUTM(survey$Longitude[i],survey$Latitude[i],survey$zone[i])[2:3]
}

#compute snow surface and ground surface elevations
survey$z_type<-'g'
survey$z_type[which(!is.na(survey$Hs_insitu)|survey$Hs_insitu!=0)]<-'s'
survey$gnss_z_snow<-survey$z
survey$z_soil<-survey$z
survey$z_soil[which(survey$z_type=='s')]<-survey$z[which(survey$z_type=='s')]-survey$Hs_insitu[which(survey$z_type=='s')] #z_soil = gnss snow height - in situ snow depth

#For loop to extract elevation data from UAV data corresponding to survey point data
#call for bare ground assessment
survey$DSM_z_soil<-raster::extract(DSM_stack[[bare_index]],SpatialPoints(cbind(survey$X_utm,  survey$Y_utm))) #DSM_z_soil = height of bare ground DSM (22_292) at survey points for snow survey date
#loop for snow surface assessment

survey$lidar_dsm_z_snow<-NA
for(i in snow_index){
  print(i)
  gsub("X", "",names(DSM_stack)[i])
  survey$lidar_dsm_z_snow[which(survey$Identifier==gsub("X", "",names(DSM_stack)[i]))]<- raster::extract(DSM_stack[[i]],SpatialPoints(cbind(survey$X_utm[which(survey$Identifier==gsub("X", "",names(DSM_stack)[i]))],
                                     survey$Y_utm[which(survey$Identifier==gsub("X", "",names(DSM_stack)[i]))])))
}


#loop for snow depth assessment
survey$Hs_lidar<-NA
for(i in names(SD)){
  survey$Hs_lidar[which(survey$Identifier==gsub("X", "",i))]<- raster::extract(SD[[i]],SpatialPoints(cbind(survey$X_utm[which(survey$Identifier==gsub("X", "",i))],
                                                                                                               survey$Y_utm[which(survey$Identifier==gsub("X", "",i))])))
}

#difference between in situ Hs and lidar Hs for each point, added as  anew column in survey
survey$insitu_minus_lidar <- survey$Hs_insitu - survey$Hs_lidar


#calculate statistics for each point location for all days (all stats averaged for 1M, 1E, etc)
surv_point_error <- survey %>%
  dplyr::filter(canopy %in% c('M', 'O')) %>%
  dplyr::group_by(transect, surv_id, canopy) %>% dplyr::summarise(
    lidar_insitu_Hs_RMSE_points=RMSE(Hs_insitu,Hs_lidar), #RMSE of survey vs lidar snow depth
    lidar_insitu_Hs_Bias_points=bias(Hs_insitu,Hs_lidar), #Bias of survey vs lidar snow depth
    lidar_insitu_Hs_r2_points=r2fun(Hs_insitu,Hs_lidar) #R2 of survey vs lidar snow depth
)


#error summarization including errors for 'M' and 'O' canopy
errors <- survey %>%
  dplyr::group_by(Identifier) %>% dplyr::summarise(
    lidar_insitu_Hs_RMSE=RMSE(Hs_insitu,Hs_lidar), #RMSE of survey vs lidar snow depth
    lidar_insitu_Hs_Bias=bias(Hs_insitu,Hs_lidar), #Bias of survey vs lidar snow depth
    lidar_insitu_Hs_r2=r2fun(Hs_insitu,Hs_lidar), #R2 of survey vs lidar snow depth
    lidar_gnss_z_snow_RMSE=RMSE(gnss_z_snow,lidar_dsm_z_snow),#RMSE of survey vs lidar snow surface elevation
    lidar_gnss_z_snow_Bias=bias(gnss_z_snow,lidar_dsm_z_snow), #Bias of survey vs lidar snow surface elevation
    lidar_gnss_z_snow_r2=r2fun(gnss_z_snow,lidar_dsm_z_snow), #Bias of survey vs lidar snow surface elevation
    z_bare_RMSE=RMSE(z_soil,DSM_z_soil),#RMSE of survey vs lidar bare surface elevation (assumes all survey points have snow depth observations)
    z_bare_Bias=bias(z_soil,DSM_z_soil), #Bias of survey vs lidar bare surface elevation (assumes all survey points have snow depth observations)
    z_bare_r2=r2fun(z_soil,DSM_z_soil)#R2 of survey vs lidar bare surface elevation (assumes all survey points have snow depth observations)
  )

surv_select_M <- survey %>%
  dplyr::group_by(Identifier) %>% dplyr::filter(canopy %in% c('M')) %>% dplyr::summarise(
  lidar_insitu_Hs_RMSE_M=RMSE(Hs_insitu,Hs_lidar), #RMSE of survey vs lidar snow depth
  lidar_insitu_Hs_Bias_M=bias(Hs_insitu,Hs_lidar), #Bias of survey vs lidar snow depth
  lidar_insitu_Hs_r2_M=r2fun(Hs_insitu,Hs_lidar), #R2 of survey vs lidar snow depth
  )

surv_select_O <- survey %>%
  dplyr::group_by(Identifier) %>% dplyr::filter(canopy %in% c('O')) %>% dplyr::summarise(
    lidar_insitu_Hs_RMSE_O=RMSE(Hs_insitu,Hs_lidar), #RMSE of survey vs lidar snow depth
    lidar_insitu_Hs_Bias_O=bias(Hs_insitu,Hs_lidar), #Bias of survey vs lidar snow depth
    lidar_insitu_Hs_r2_O=r2fun(Hs_insitu,Hs_lidar), #R2 of survey vs lidar snow depth
  )


errors_all <- cbind(errors, dplyr::select(surv_select_M, lidar_insitu_Hs_RMSE_M, lidar_insitu_Hs_Bias_M,lidar_insitu_Hs_r2_M), dplyr::select(surv_select_O, lidar_insitu_Hs_RMSE_O, lidar_insitu_Hs_Bias_O, lidar_insitu_Hs_r2_O))

# 
# write.csv(survey, 'data/error_summary/FT_survey_data.csv')
# write.csv(surv_point_error, 'data/error_summary/FT_point_error.csv')
# write.csv(errors_all, 'data/error_summary/error_summary.csv', row.names = F)
# 
# #print total processing time
# end.time <- Sys.time()
# time.taken <- end.time - start.time
# time.taken
