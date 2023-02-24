######################################################
#Lidar processing to generate DSM and snow depth maps from UAV-lidar
#Phillip Harder
#January  27, 2023

#load libraries
library(raster)
library(rgdal)
library(plyr)
library(dplyr)
library(sf)

######################################################################
#VARIABLES

#NOTE: make sure nothing is in data/dsm folder when initiating script!!! (we should add a check to only include dsms that are input into the script aka. what is in data/point_cloud)

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

#location of field data (output from rover_snow_processing.R) 
survey<-read.csv('data/survey_data/survey_points_FT.csv')

######################################################################
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
###############################################
#convert long lat to UTM function
LongLatToUTM<-function(x,y,zone){
  xy <- data.frame(ID = 1:length(x), X = x, Y = y)
  coordinates(xy) <- c("X", "Y")
  proj4string(xy) <- CRS("+proj=longlat +datum=WGS84")  ## for example
  res <- spTransform(xy, CRS(paste("+proj=utm +zone=",zone," ellps=WGS84",sep='')))
  return(as.data.frame(res))
}
##################################################

#list point cloud .las files
files<-list.files("data/point_cloud/", pattern="*.las",full.names = FALSE)
files<-tools::file_path_sans_ext(files)

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
writeLines(txt, con = "LAStools_process.bat")
#run LASTools code from R
shell('LAStools_process.bat')



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
names(SD)<-gsub("DSM","Hs",names(DSM_stack[[min(snow_index)]]))
raster::writeRaster(SD_temp, paste0('data/Hs/', point_cloud_list[1], '.tif')) #output Hs rasters into data/Hs folder
if(length(snow_index)>1){
  for(i in snow_index[2:length(snow_index)]){
    print(i)
    SD_temp<-DSM_stack[[i]]-DSM_stack[[bare_index]]
    names(SD_temp)<-gsub("DSM","Hs",names(DSM_stack[[i]]))
    raster::writeRaster(SD_temp, paste0('data/Hs/', point_cloud_list[i], '.tif')) #output Hs rasters into data/Hs folder
    SD<-addLayer(SD,SD_temp)
  }
}


#Convert lat long to UTM
survey$X_utm<-NA
survey$Y_utm<-NA
survey$zone<-11
for(i in 1:length(survey$Identifier)){
  survey[i,7:8]<-LongLatToUTM(survey$Longitude[i],survey$Latitude[i],survey$zone[i])[2:3]  
}

#compute snow surface and ground surface elevations
survey$z_type<-'g'
survey$z_type[which(!is.na(survey$Hs)|survey$Hs!=0)]<-'s'
survey$z_snow<-survey$z
survey$z_soil<-survey$z
survey$z_soil[which(survey$z_type=='s')]<-survey$z[which(survey$z_type=='s')]-survey$Hs[which(survey$z_type=='s')]

#For loop to extract elevation data from UAV data corresponding to survey point data
#call for bare ground assessment
survey$DSM_z_soil<-extract(DSM_stack[[bare_index]],SpatialPoints(cbind(survey$X_utm,  survey$Y_utm)))
#loop for snow surface assessment
survey$DSM_z_snow<-NA
for(i in snow_index){
  gsub("DSM_", "",names(DSM_stack)[i])
  survey$DSM_z_snow[which(survey$Identifier==gsub("DSM_", "",names(DSM_stack)[i]))]<- extract(DSM_stack[[i]],SpatialPoints(cbind(survey$X_utm[which(survey$Identifier==gsub("DSM_", "",names(DSM_stack)[i]))],  
                                     survey$Y_utm[which(survey$Identifier==gsub("DSM_", "",names(DSM_stack)[i]))])))
}
#loop for snow depth assessment
survey$Hs_est<-NA
for(i in names(SD)){
  survey$Hs_est[which(survey$Identifier==gsub("Hs_", "",i))]<- extract(SD[[i]],SpatialPoints(cbind(survey$X_utm[which(survey$Identifier==gsub("Hs_", "",i))],  
                                                                                                               survey$Y_utm[which(survey$Identifier==gsub("Hs_", "",i))])))
}

#error summarization
errors<-survey %>% group_by(Identifier) %>% summarise(
                Hs_RMSE=RMSE(Hs,Hs_est), #RMSE of survey vs lidar snow depth
                Hs_Bias=bias(Hs,Hs_est), #Bias of survey vs lidar snow depth
                Hs_r2=r2fun(Hs,Hs_est), #R2 of survey vs lidar snow depth
                z_snow_RMSE=RMSE(z_snow,DSM_z_snow),#RMSE of survey vs lidar snow surface elevation 
                z_snow_Bias=bias(z_snow,DSM_z_snow), #Bias of survey vs lidar snow surface elevation 
                z_snow_r2=r2fun(z_snow,DSM_z_snow), #Bias of survey vs lidar snow surface elevation 
                z_bare_RMSE=RMSE(z_soil,DSM_z_soil),#RMSE of survey vs lidar bare surface elevation (assumes all survey points have snow depth observations)
                z_bare_Bias=bias(z_soil,DSM_z_soil), #Bias of survey vs lidar bare surface elevation (assumes all survey points have snow depth observations)
                z_bare_r2=r2fun(z_soil,DSM_z_soil)#R2 of survey vs lidar bare surface elevation (assumes all survey points have snow depth observations)
                
                 )

errors

write.csv(errors, 'deliverables/error_summary.csv', row.names = F)
