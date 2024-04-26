# script to check trajectory elevation as potential indicator of when faulty IMU
# data occurred which may be related to offset problems with point clouds

flights <- c('22_045', '22_047', '23_026', '23_027', '23_072', '23_073')

traj_path <- '/media/alex/phd-data/local-usask/field-downloads/lidar-data/metadata/trajectory_files/'

traj_folders <- paste0(
  traj_path,
  flights)

traj_files <- lapply(traj_folders, list.files, recursive = T, full.names = T) |> unlist()

all_traj <- data.frame()
for (file_i in traj_files) {
  traj_in <- read.csv(file_i)  
  
  traj_in$jday <- substr(file_i, 87, 92)
  traj_in$transect_start_time <- substr(file_i, 94, 106)
  all_traj <- rbind(traj_in, all_traj)
}


all_traj |> 
  ggplot(aes(Time.s., Height.m., colour = transect_start_time)) + 
    geom_line() + facet_wrap(~jday, scales = 'free', nrow = 3)

ggsave('figs/raw_data_analysis/lidar_traj_elevation_snowfall_events.png', width = 8.5, height = 6)

all_traj |> 
  filter(jday %in% tail(flights, n = 2)) |> 
  ggplot(aes(Time.s., Height.m., colour = transect_start_time)) + 
  geom_line() + facet_wrap(~jday, scales = 'free', nrow = 2)

ggsave('figs/raw_data_analysis/lidar_traj_elevation_23_072_73.png', width = 8.5, height = 6)
