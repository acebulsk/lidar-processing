# plot hemisphere output from voxrs, there is a python function that handles
# this for the .tif outputs 

library(tidyverse)
cn_coef <- 0.38 # from VoxRS default, also see supplementary material for Staines & Pomeroy 2023

hemi_base_path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/voxrs/outputs/hemisphere_resampling/'

hemi_files <- list.files(hemi_base_path, pattern = "*.csv")

hemi_files <- hemi_files[!hemi_files == 'phi_theta_lookup.csv']
hemi_files <- hemi_files[!hemi_files == 'rshmetalog.csv']
files <- paste0(hemi_base_path, hemi_files)

hemi_plot_out_path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/voxrs/outputs/hemisphere_resampling/pngs/'

plot_hemi <- function(hemi_path) {
  file_name <- basename(hemi_path) |>  tools::file_path_sans_ext()
  # x / y index can be used to plot on catesian grid
  hemi <- read.csv(hemi_path) |>
    mutate(
      phi_d = phi * (180 / pi),
      theta_d = theta * (180 / pi),
      theta_d = if_else(theta_d == 360, 0, theta_d),
      contact_number = returns_mean * cn_coef,
      transmittance = exp(-contact_number)
    ) |>
    filter(returns_mean < 60)
  
  p_tile <-
    ggplot(hemi,
           aes(
             x = theta_d,
             y = phi_d,
             color = contact_number,
             fill = contact_number,
           )) +
    geom_point(size = 1e-12) +
    # geom_tile() +
    # geom_tile(height = 2,
    #           width = 2) +
    scale_fill_viridis_c(name = "Contact Number") +
    scale_color_viridis_c(name = "Contact Number") +
    coord_radial(
      theta = "x",
      start = 0,
      # end = 325*(pi/180),
      expand = F,
      direction = 1,
      # clip = "off",
      r_axis_inside = F,
      rotate_angle = FALSE,
      inner.radius = 0
    )  +
    ylab(element_blank()) +
    xlab(element_blank()) +
    scale_y_continuous(breaks = seq(0, 90, 15), labels = paste0(seq(0, 90, 15), '°')) +
    scale_x_continuous(breaks = seq(0, 270, 90),
                       labels = c('N', 'E', 'S', 'W')) +
    theme(
      panel.border = element_rect(color = 'grey', fill = NA),
      panel.background = element_blank(),
      panel.grid = element_line(color = 'lightgrey', linewidth = 0.2),
      panel.ontop = T,
      plot.background = element_rect(fill = "white")
      # axis.text.y = element_text(colour = "black")
    )
  
  ggsave(paste0(
    hemi_plot_out_path,
    file_name,
    '_contact_number.png'
  ),
  p_tile,
  width = 5,
  height = 4)
  
  p_tile <-
    ggplot(hemi,
           aes(
             x = theta_d,
             y = phi_d,
             color = transmittance,
             fill = transmittance,
           )) +
    geom_point(size = 1e-12) +
    # geom_tile() +
    # geom_tile(height = 2,
    #           width = 2) +
    scale_fill_viridis_c(name = "Transmittance") +
    scale_color_viridis_c(name = "Transmittance") +
    coord_radial(
      theta = "x",
      start = 0,
      # end = 325*(pi/180),
      expand = F,
      direction = 1,
      # clip = "off",
      r_axis_inside = F,
      rotate_angle = FALSE,
      inner.radius = 0
    )  +
    ylab(element_blank()) +
    xlab(element_blank()) +
    scale_y_continuous(breaks = seq(0, 90, 15), labels = paste0(seq(0, 90, 15), '°')) +
    scale_x_continuous(breaks = seq(0, 270, 90),
                       labels = c('N', 'E', 'S', 'W')) +
    theme(
      panel.border = element_rect(color = 'grey', fill = NA),
      panel.background = element_blank(),
      panel.grid = element_line(color = 'lightgrey', linewidth = 0.2),
      panel.ontop = T,
      plot.background = element_rect(fill = "white")
      # axis.text.y = element_text(colour = "black")
    )
  
  ggsave(paste0(
    hemi_plot_out_path,
    file_name,
    '_transmittance.png'
  ),
  p_tile,
  width = 5,
  height = 4)
  
}

lapply(files, plot_hemi)
