# compute canopy heights for FSR S and PWL E

library(lidR)
library(sf)
library(tidyverse)
source('scripts/dem_processing/00_load_global_data.R')

lidR::set_lidr_threads(8)

las_id <- '23_072'

pt_cld_base_path <- 
  '/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointcloudsclipped/'

plots <- c('fsr_s', 'pwl_e')

for (plot in plots) {
  las_path <- paste0(
    pt_cld_base_path,
    las_id,
    '_sa_clip_',
    plot,
    '.las'
  )
  
  las <- readLAS(las_path)
  # scalar. The distance to the simulated cloth to classify a point cloud into ground and non-ground. The default is 0.5.
  ct <- 0.2
  # scalar. The distance between particles in the cloth. This is usually set to the average distance of the points in the point cloud. The default value is 0.5.
  cr <- 0.5
  algo <- csf(sloop_smooth = F, class_threshold = ct, cloth_resolution = cr, rigidness = 1)
  las <- classify_ground(las, algo)
  las <- normalize_height(las, tin())
  
  window_size <- 1
  min_height <- 4
  
  ttops <- locate_trees(las, lmf(ws = window_size, hmin = min_height))
  
  write_sf(ttops |> st_zm(), paste0('data/lidR_canopy_metrics/', plot, '_ttop_points.shp'))
  
  chm <- rasterize_canopy(las, 0.25, pitfree(subcircle = 0.2))
  
  chm <- terra::crop(chm, fsr_plots, mask = T)
  
  chm <- terra::mask(chm, fsr_masks, inverse = T)
  
  zlim <- c(0, 18)  # Replace min_value and max_value with your desired values
  # Save the plot for lidr_sd
  plot_stn <- gsub(' Plot', '',  fsr_plots$plot_name[fsr_plots$name == toupper(plot)])
  png(paste0(
    'figs/maps/',
    plot,
    '_canopy_height_lidR.png'
  ), width = 1000, height = 800, res = 200)
  plot(chm, main = paste0(plot_stn, ': Height (m)'), range = zlim)
  dev.off()
  
  # 2d vis
  # plot(chm, col = height.colors(50))
  # plot(sf::st_geometry(ttops), add = TRUE, pch = 3)
  mean_z <- mean(ttops$Z)
  
  saveRDS(mean_z,
          paste0(
            'data/lidR_canopy_metrics/',
            plot,
            '_mean_tree_height.rds'
          ))
  
  ggplot(ttops, aes(x =Z)) +
    geom_histogram(binwidth = 0.5, colour = "black", position = 'dodge') +
    geom_vline(xintercept = mean(ttops$Z), color = "red", linetype ="dashed", size = 1) + 
    labs(title = plot,
         y = "Frequency",
         x = "Tree Height (m)")
  
  ggsave(paste0('data/lidR_canopy_metrics/', plot, '_histogram_tree_heights.png'), width = 4, height = 3)
  
  
} 
