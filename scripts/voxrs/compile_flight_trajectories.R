# script to combine separate trajectory files output by Maddie
# also tidy cols to match voxrs specs

library(tidyverse)

# eventually loop through surveys of interest
surv_id <- '23_072'
traj_path <- '/media/alex/phd-data/local-usask/field-downloads/lidar-data/metadata/trajectory_files/'

traj_paths <- 
  list.files(
    paste0(traj_path,
           surv_id),
             pattern = 'traj.txt',
             recursive = T)

traj_df <- purrr::map_dfr(paste0(traj_path, surv_id, '/',traj_paths), read.csv) 

traj_out <- traj_df |> 
  dplyr::select(`Time[s]` = Time.s.,
         `Easting[m]` = Easting.m., 
         `Northing[m]` = Northing.m.,
         `Height[m]` = Height.m.)

write.csv(traj_out,
          paste0('/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/',
                 surv_id, '/voxrs/metadata/', surv_id, '_all_lidar_trajectory.txt'),
          row.names = F)
