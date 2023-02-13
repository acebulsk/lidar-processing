Lidar data processing workflow
Phillip Harder
January 27, 2023

The purpose of this workflow is to standardise the processing of UAV-lidar data from point cloud to DSM generation, to snow depth differencing, to error estimation from available GNSS survey data.

Dependencies
-Working/licensed LAStools 
-R with raster, rgdal, plyr, and dplyr libraries

Overall workflow:
1. put the raw point clouds of interest into the data/point_cloud/ directory. Name them in YY_JJJ.las format
2. Verify path to LAStools, number of cores, and tile size and buffers are appropriate/correct in the LAStools_process.bat file
3. In lidar_processing.R update the working directory to location of this file, update the shp file that bounds the area of interest in data/shp and update the name of the shapefile in the R script.  file names are organised numerically and if your bare surface reference is not the first in the list you will need to update the bare_index variable in the script so it know which DSM to use as the bare surface when it comes time for snow depth differencing.
4. Update the survey_points.csv file in data/survey_data/ directory with GNSS data appropriate to the survey data you are processing.
5. Run the R script and everything should run and resulting DSM 


Unless I'm missing something this should be all you need to update in the script. the various empty data/... directories will be populated with the respective data products.  Will provide an error summary in the R console and DSM and Hs rasters. 

The LAStools_process.bat implements a simple clipping, optimisation, noise removal, ground classificaiton, and DSM creation for each .las provided in the data/point_cloud/ directory.  Verify the output of lastools by visual examination of the DSM's in the a viewer such as QTreader.