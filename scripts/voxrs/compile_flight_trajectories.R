# script to combine separate trajectory files output by Maddie
# also tidy cols to match voxrs specs

library(tidyverse)
library(sf)

# eventually loop through surveys of interest
surv_id <- '23_027'
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


write.csv(
  traj_out,
  paste0(
    '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/metadata/drone_trajectory/',
    surv_id,
    '_all_lidar_trajectory.txt'
  ),
  row.names = F
)

write.csv(traj_out,
          paste0('~/local-usask/analysis/lidar-processing/data/metadata/drone_trajectory/', surv_id, '_all_lidar_trajectory.txt'),
          row.names = F)

traj_out_sf <- traj_out |> 
  st_as_sf(coords = c('Easting[m]', 'Northing[m]'), crs = 32611)

traj_lines <- traj_out_sf |> 
  st_combine() |> 
  st_cast("LINESTRING") |> 
  st_simplify(dTolerance = 1)

write_sf(traj_out_sf,
          paste0('~/local-usask/analysis/lidar-processing/data/metadata/drone_trajectory/shp/', surv_id, '_all_lidar_trajectory_pts.gpkg'))
write_sf(traj_lines,
         paste0('~/local-usask/analysis/lidar-processing/data/metadata/drone_trajectory/shp/', surv_id, '_all_lidar_trajectory_lines.gpkg'))

# output extent of flight path

flight_extent <- st_bbox(traj_out_sf)

flight_extent_sf <- st_as_sfc(flight_extent)
flight_extent_sf_buf20 <- st_buffer(flight_extent_sf, 20, endcapStyle = 'SQUARE')
plot(flight_extent_sf_buf20)
write_sf(flight_extent_sf,
         paste0('~/local-usask/analysis/lidar-processing/data/metadata/drone_trajectory/shp/', surv_id, '_lidar_trajectory_extent_poly.shp'))
write_sf(flight_extent_sf_buf20,
         paste0('~/local-usask/analysis/lidar-processing/data/metadata/drone_trajectory/shp/', surv_id, '_lidar_trajectory_extent_poly_20m_buff.shp'))

