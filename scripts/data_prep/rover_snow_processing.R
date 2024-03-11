# combining GNSS rover txt files over all survey days
rm(list = ls())

library(dplyr)

# variables #######################################################

# UNCOMMENT PROPER DATASET/OUTPUT LOCATION TO USE

# paths for bare ground survey data
# snow_survey_path <- 'data/survey_data/FFR_snow_survey_db_qaqc_fsd.csv'
# survey_data_out_path <- 'data/survey_data/survey_points_FT.csv'

 # paths for prepost survey data
lidar_data_path <- '/media/alex/phd-data/local-usask/field-downloads/lidar-data/'
snow_survey_path <- '~/local-usask/analysis/snow-stats/data/processed/fresh_snow_densities_with_ground_partials.csv'
survey_data_out_path <- 'prepost_data/survey_data/survey_points_FT.csv'

#factor to convert in situ snow depth to meters (lidar snow depth unit)
Hs_conv_fact = 0.001

# functions #######################################################
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

gnss_file_paths <- list.files(paste0(lidar_data_path, "GNSS"), full.names = T)

no_data_days <- c(
  # no rov pts on this day as was bare ground
  "22_292",
  # bad in situ data
  "22_068",
  # no rtk solution on rov pts , drone dat seems ok 
  "22_168")

gnss_file_paths <- gnss_file_paths[!grepl(paste(no_data_days,
                                                collapse = "|"),
                                          gnss_file_paths)]

rover_pts_list <- lapply(gnss_file_paths, read.delim, header = F)

rover_pts_df <- do.call(rbind, rover_pts_list) |> 
  dplyr::select(c(1:5, 10)) |> 
  dplyr::rename(GNSS_point_id = V1,
         point_type = V2,
         lat_dms = V3,
         lon_dms = V4,
         ele_m = V5,
         datetime = V10) |>
  dplyr::filter(point_type == fixed_solution,
         !GNSS_point_id %in% bad_gnss_ids) |> 
  dplyr::mutate(GNSS_point_id = gsub('GS', x = GNSS_point_id, ''),
         GNSS_point_id = floor(as.numeric(GNSS_point_id)),
         datetime = as.POSIXct(datetime, format = '%m/%d/%Y %H:%M:%OS'),
         yy_ddd = paste0(format(datetime, "%y"), "_", format(datetime, "%j"))) |> 
  # need to remove bad pt ids 
  dplyr::filter(GNSS_point_id < high_lim_gnss_id)

snow_data <- read.csv(snow_survey_path) |>
  mutate(datetime = as.POSIXct(datetime)) |> 
  dplyr::select(datetime,
         GNSS_point_id = gps_id,
         transect,
         num,
         canopy,
         depth) |> 
  dplyr::filter(is.na(GNSS_point_id) != T) |> 
  dplyr::mutate(
    yy_ddd = paste0(format(datetime, "%y"), "_", format(datetime, "%j"))
  )

options(max.print=999999)

survey_data <- dplyr::left_join(rover_pts_df, 
                         snow_data, 
                         by = c("yy_ddd", "GNSS_point_id"),
                         multiple = "all")

survey_data$lat_dd = angle2dec(survey_data$lat_dms)
survey_data$lon_dd = angle2dec(survey_data$lon_dms)*-1

survey_data_out <- survey_data |> 
  dplyr::filter(is.na(depth) == F) |> 
  dplyr::select(
    Identifier = yy_ddd,
    datetime = datetime.x,
    GNSS_point_id = GNSS_point_id,
    Latitude = lat_dd,
    Longitude = lon_dd,
    transect,
    surv_id = num,
    canopy,
    z = ele_m,
    Hs_insitu = depth
  ) |> 
  mutate(datetime = as.Date(datetime, format="%Y-%m-%d")) |> 
  mutate(Hs_insitu = floor(as.numeric(Hs_insitu)),
         Hs_insitu = Hs_insitu * Hs_conv_fact)

survey_data_out_sf <- survey_data_out |> 
  st_as_sf(coords = c('Longitude', 'Latitude'), crs = 4326) 

coordinates <- st_coordinates(survey_data_out_sf)
survey_data_out_sf$Longitude <- coordinates[, "X"]
survey_data_out_sf$Latitude <- coordinates[, "Y"]


survey_data_out_sf_utm <- survey_data_out_sf |> 
  st_transform('EPSG:32611') 

coordinates <- st_coordinates(survey_data_out_sf_utm)
survey_data_out_sf_utm$easting_m <- coordinates[, "X"]
survey_data_out_sf_utm$northing_m <- coordinates[, "Y"]

write.csv(survey_data_out_sf_utm |> st_drop_geometry(), survey_data_out_path, row.names = F) 
for (id in survey_data_out_sf_utm$Identifier |> unique()) {
  fltr_pts <- survey_data_out_sf_utm |> 
    st_drop_geometry() |> 
    dplyr::filter(Identifier == id) |> 
    dplyr::mutate(id = paste0(transect, '_', surv_id, canopy)) |> 
    dplyr::select(id, easting_m, northing_m, elev_m = z)
  
  write.csv(fltr_pts,
            paste0('../lidar-processing/prepost_data/survey_data/', id, '_fsd_gnss_survey_points.csv'),
            row.names = F) 
}

st_write(survey_data_out_sf_utm, 'prepost_data/survey_data/survey_points_FT.gpkg', append = F)

