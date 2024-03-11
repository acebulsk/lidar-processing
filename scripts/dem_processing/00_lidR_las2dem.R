#  construct a dsm from a folder of las files, typically the output of lasground

library(lidR)

survey_id <- '23_027'
las_proc_out_path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'
las_ground_tiles_path <- paste0(las_proc_out_path, survey_id, '/4_tiles_ground')
las_merge_path <- paste0(las_proc_out_path, survey_id, '/class_points')

ctg <- readLAScatalog(las_ground_tiles_path)
opt_chunk_buffer(ctg) <- 0
opt_chunk_size(ctg) <- 200
opt_chunk_alignment(ctg) <- c(275, 90)
opt_output_files(ctg) <- paste0(tempdir(), "/retile_{XLEFT}_{YBOTTOM}")
newctg = catalog_retile(ctg)
las_check(ctg)

plot(ctg, chunk = T)

dtm <- rasterize_terrain(ctg, 2, tin(), pkg = "terra")

LASfile <- system.file("extdata", "Megaplot.laz", package="lidR")
ctg = readLAScatalog(LASfile)
plot(ctg)

# Create a new set of 200 x 200 m.las files with first returns only
opt_chunk_buffer(ctg) <- 0
opt_chunk_size(ctg) <- 200
opt_filter(ctg) <- "-keep_first"
opt_chunk_alignment(ctg) <- c(275, 90)
opt_output_files(ctg) <- paste0(tempdir(), "/retile_{XLEFT}_{YBOTTOM}")
# preview the chunk pattern
plot(ctg, chunk = TRUE)

newctg = catalog_retile(ctg)

plot(newctg)
