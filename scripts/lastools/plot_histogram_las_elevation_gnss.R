library(lidR)
library(tidyverse)
library(sf)

gnss_pts <- sf::st_read('data/survey_data/survey_points_FT.gpkg') |> 
  filter(Identifier == '23_072') |> 
  st_drop_geometry()

las <-
  lidR::readLAS(
    '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/4_tiles_ground_merge/23_073_FT_new_ground_merge_clip_fsr_s.las')

# this doesn't work so did filtering in lastools
# ctg <- lidR::readLAScatalog('/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/4_tiles_ground')
# 
# ctg <- lasfilter(ctg, buffer == 0)  
# opt_filter(ctg) <- "-drop_withheld -keep_class 2"

# las_check(las)

# classify pts based on time 

f1_start <- 362758225.050455
f1_end <- 362759057.435455
f2_start <- 362759616.613943
f2_end <- 362760402.543943

flight_class_vect  <- ifelse(las@data$gpstime >= f2_start, 'Flight 2', 'Flight 1')

las <- add_attribute(las, flight_class_vect, 'flight_class')

las@data$Z[las@data$flight_class == 'Flight 1'] |> mean()
las@data$Z[las@data$flight_class == 'Flight 2'] |> mean()

x <- gnss_pts$easting_m
y <- gnss_pts$northing_m
radius <- 0.15

rois <- clip_circle(las, x, y, radius)

# plot(rois, bg = "white", size = 4)

for (pt in 1:nrow(gnss_pts)) {
  
  roi_z <- data.frame(z = rois[[pt]]$Z,
                      flight_class = rois[[pt]]$flight_class)
  
  gnss_z <- gnss_pts[pt, 'z']
  
  ggplot(roi_z, aes(x = z, fill = flight_class)) +
    geom_histogram(binwidth = 0.01, colour = "black", position = 'dodge') +
    geom_vline(xintercept = gnss_z, color = "red", linetype ="dashed", size = 1) + 
    labs(title = paste0("Histogram of: ", gnss_pts[pt, 'transect'], '-', gnss_pts[pt, 'surv_id']),
         y = "Frequency",
         x = "Elevation (m)")
  
  ggsave(
    paste0(
      'figs/raw_data_analysis/pt_cloud_offset_problem/histogram_elevation_lidr_w_gnss_',
      gnss_pts[pt, 'transect'], '-', gnss_pts[pt, 'surv_id'],
      '.png'
    ),
    width = 5,
    height = 4
  )
  
}
