# combining GNSS rover txt files over all survey days

library(dplyr)

snow_survey_path <- 'prepost_data/survey_data/fresh_snow_densities_db.csv'

# functions
angle2dec <- function(angle) {
  angle <- as.character(angle)
  x <- do.call(rbind, strsplit(angle, split=' '))
  x <- apply(x, 1L, function(y) {
    y <- as.numeric(y)
    y[1] + y[2]/60 + y[3]/3600
  })
  return(x)
}

# leicas terminology for good gnss solution .. 
fixed_solution <- 'GNSSPhaseMeasuredRTK'

bad_gnss_ids <- c('W')

high_lim_gnss_id <- 9999

surv_days <- list.files("../PointClouds/FT/Intensity") %>% 
  substr(start = 0, 6)

surv_dirs <- paste0("F:/Processing/", surv_days, "_processing/", surv_days, "_c/", surv_days, "/Exported Data/", surv_days, ".txt")

no_data_days <- c(
  # no rov pts on this day as was bare ground
  "F:/Processing/22_292_processing/22_292_c/22_292/Exported Data/22_292.txt",
  # no rtk solution on rov pts , drone dat seems ok 
  "F:/Processing/22_168_processing/22_168_c/22_168/Exported Data/22_168.txt")

surv_dirs <- surv_dirs[!surv_dirs %in% no_data_days]

rover_pts_list <- lapply(surv_dirs, read.delim, header = F)

rover_pts_df <- do.call(rbind, rover_pts_list) %>% 
  select(c(1:5, 10)) %>% 
  rename(Point_id = V1,
         point_type = V2,
         lat_dms = V3,
         lon_dms = V4,
         ele_m = V5,
         datetime = V10) %>%
  filter(point_type == fixed_solution,
         !Point_id %in% bad_gnss_ids) %>% 
  mutate(Point_id = gsub('GS', x = Point_id, ''),
         Point_id = floor(as.numeric(Point_id)),
         datetime = as.POSIXct(datetime, format = '%m/%d/%Y %H:%M:%OS'),
         yy_ddd = paste0(format(datetime, "%y"), "_", format(datetime, "%j"))) %>% 
  # need to remove bad pt ids 
  filter(Point_id < high_lim_gnss_id)

snow_data <- read.csv(snow_survey_path) %>%
  mutate(datetime = as.POSIXct(datetime)) %>% 
  select(datetime,
         Point_id = gps_id,
         depth) %>% 
  filter(is.na(Point_id) != T) %>% 
  mutate(
    yy_ddd = paste0(format(datetime, "%y"), "_", format(datetime, "%j"))
  )

options(max.print=999999)

survey_data <- left_join(rover_pts_df, 
                         snow_data, 
                         by = c("yy_ddd", "Point_id"),
                         multiple = "all")

survey_data$lat_dd = angle2dec(survey_data$lat_dms)
survey_data$lon_dd = angle2dec(survey_data$lon_dms)*-1

survey_data_out <- survey_data %>% 
  filter(is.na(depth) == F) %>% 
  select(
    Identifier = yy_ddd,
    Point_id = Point_id,
    Latitude = lat_dd,
    Longitude = lon_dd,
    z = ele_m,
    Hs = depth
  ) %>% 
  mutate(Hs = Hs * 0.001)


write.csv(survey_data_out, 'data/survey_data/survey_points_FT.csv', row.names = F) 
