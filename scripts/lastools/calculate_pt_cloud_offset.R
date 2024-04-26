# script that calculates an offset on two point clouds based on the 50th
# percentile elevation of each. This was originally written to try and help with
# the vertical offset observed on flight 1 and 2 of 23_072.

library(lidR)
lidR::set_lidr_threads(6)

las <-
  lidR::readLAS(
    '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/4_tiles_ground_merge/23_072_FT_new_ground_merge_clip_fsr_road.las')

# classify pts based on time 

f1_start <- 362758225.050455
f1_end <- 362759057.435455
f2_start <- 362759616.613943
f2_end <- 362760402.543943

flight_class_vect  <- ifelse(las@data$gpstime >= f2_start, 'Flight 2', 'Flight 1')

las <- add_attribute(las, flight_class_vect, 'flight_class')

med_f1 <- las@data$Z[las@data$flight_class == 'Flight 1'] |> median()
med_f2 <- las@data$Z[las@data$flight_class == 'Flight 2'] |> median()

offset <- med_f2 - med_f1 # offset between 50th percentile of flight 1 and flight 2 in metres.

p1 <- c(626934.581,5632050.417)
p2 <- c(626947.779,5632038.821)

las_transect <- lidR::clip_transect(las, p1 = p1, p2 = p2, width = 0.1)

las_transect_df <- las_transect@data |> as.data.frame()

ggplot(las_transect_df, aes(X, Z, colour = flight_class)) + 
  geom_point()

las_transect_df$Z[las_transect_df$flight_class=='Flight 1'] |> mean()
las_transect_df$Z[las_transect_df$flight_class=='Flight 2'] |> mean()
