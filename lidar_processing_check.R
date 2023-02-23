######################################################
#Lidar processing to generate DSM and snow depth maps from UAV-lidar
#Phillip Harder
#January  27, 2023

#load libraries
library(raster)
library(rgdal)
library(plyr)
library(dplyr)

######################################################################
#VARIABLES

#name of shapefile to clip ROI #CanRidge.shp fortress_extent.shp FortRidgeSouth.shp ForestTower_clip.sh
shp_name<-"ForestTower_clip"

#bare ground file name
bare_ground_las = "23_026.las"

#path to raw point clouds
point_cloud_path = "data/point_cloud/"

#resolution of output DEMs
RES_STEP = "0.1"

#location of field data (output from rover_snow_processing.R) 
#survey<-read.csv('data/survey_data/survey_points_FT.csv')

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
tiffs<-list.files("data/dsm/", pattern="*.tif")
DSM<-raster(paste("data/dsm/",tiffs[1], sep=""))
for(i in 2:length(tiffs)){
  DSM_temp<-raster(paste("data/dsm/",tiffs[i], sep=""))
  DSM<-addLayer(DSM, DSM_temp)
}

#identify which layers are snow covered (ie not the bare layer)
point_cloud_list = list.files(path = point_cloud_path)
bare_index = which(point_cloud_list == bare_ground_las)

snow_index<-1:length(tiffs)
snow_index<-snow_index[snow_index!=bare_index]

#initialise snow depth raster stack
SD<-DSM[[min(snow_index)]]-DSM[[bare_index]]
names(SD)<-gsub("DSM","Hs",names(DSM[[min(snow_index)]]))
if(length(snow_index)>1){
  for(i in snow_index[2:length(snow_index)]){
    SD_temp<-DSM[[i]]-DSM[[bare_index]]
    names(SD_temp)<-gsub("DSM","Hs",names(DSM[[i]]))
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
survey$DSM_z_soil<-extract(DSM[[bare_index]],SpatialPoints(cbind(survey$X_utm,  survey$Y_utm)))
#loop for snow surface assessment
survey$DSM_z_snow<-NA
for(i in snow_index){
  gsub("DSM_", "",names(DSM)[i])
  survey$DSM_z_snow[which(survey$Identifier==gsub("DSM_", "",names(DSM)[i]))]<- extract(DSM[[i]],SpatialPoints(cbind(survey$X_utm[which(survey$Identifier==gsub("DSM_", "",names(DSM)[i]))],  
                                                                                                                     survey$Y_utm[which(survey$Identifier==gsub("DSM_", "",names(DSM)[i]))])))
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
