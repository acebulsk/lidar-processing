# plot transect of raw lidar data for offset analysis 
library(lidR)
lidR::set_lidr_threads(6)
# TODO not finished! 

ctg_f1 <- lidR::readLAScatalog('/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds/22_072_flights_time_offset/flight1/')
opt_output_files(ctg_f1) <- paste0(tempdir(), "/retile_{XLEFT}_{YBOTTOM}")

print(tempdir())

# this didnt work.. 
ctg_f1_rt <-  lidR::catalog_retile(ctg_f1)



ctg_f2 <- lidR::readLAScatalog('/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds/22_072_flights_time_offset/flight2/')

p1 <- c(626910.742,5631927.495)
p2 <- c(626922.838,5631943.905)

f1_transect <- lidR::clip_transect(ctg_f1, p1 = p1, p2 = p2, width = 0.1)
