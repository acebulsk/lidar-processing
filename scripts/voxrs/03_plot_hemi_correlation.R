

hemi_list <- readRDS(paste0('data/hemi_stats/full_hemi_correlation_grid_resampled_',
                            vox_config_id,
                            "_",
                            plot,
                            '.rds'))

hemi_df <- do.call(rbind, hemi_list)
hemi_df <- data.frame(apply(hemi_df, 2, as.numeric))

colnames(hemi_df) <- c('phi_d',
                       'theta_d',
                       'rp',
                       'rs')

upper2_5 <- hemi_df$rp |> quantile(0.975)

hemi_high_cor <-  hemi_df |> 
  filter(rp > upper2_5)

plot_theta_high_cor <- hemi_high_cor |> 
  pull(theta_d) |> 
  mean()

plot_phi_high_cor <- hemi_high_cor |> 
  pull(phi_d) |> 
  mean()

plot_high_cor <- data.frame(phi = plot_phi_high_cor, theta = plot_theta_high_cor)

saveRDS(plot_high_cor,
        paste0('data/hemi_stats/hemi_avg_theta_phi_for_rho_s_upper_2_5th_percentile_',
                            vox_config_id,
                            "_",
                            plot,
                            '.rds')
               )

# hemi_df$id <- row.names(hemi_df) |> as.numeric()

# SPEARMAN'S CORRELATION ----
# for geom_tile(), map both fill and color to avoid drawing artifacts
p_tile <-
  ggplot(hemi_df, aes(
    x = theta_d,
    y = phi_d,
    color = rs,
    fill = rs,
  )) +
  # geom_point() +
  geom_tile() +
  # geom_tile(height = 1,
  #           width = 0.1) +
  scale_fill_viridis_c(name = expression(rho[s])) +
  scale_color_viridis_c(name = expression(rho[s])) + 
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
  ylab(element_blank())+
  xlab(element_blank()) +
  scale_y_continuous(breaks = seq(0, 90, 15), labels = paste0(seq(0, 90, 15), '°')) +
  scale_x_continuous(breaks = seq(0, 270, 90), labels = c('N', 'E', 'S', 'W')) +
  theme(panel.border = element_rect(color = 'grey', fill = NA),
        panel.background = element_blank(),
        panel.grid = element_line(color = 'lightgrey', linewidth = 0.2),
        panel.ontop = T,
        plot.background = element_rect(fill = "white")
        # axis.text.y = element_text(colour = "black")
        )

# p_tile

ggsave(paste0('figs/voxrs/hemis/cor_cn_ip/full_hemi_rho_s_cor_lca_ip_',
              vox_config_id,
              "_",
              plot,
              '.png'),
       p_tile,
       width = 4, height = 3, device = png)

# PEARSON CORELLATION ----
# for geom_tile(), map both fill and color to avoid drawing artifacts
p_tile <-
  ggplot(hemi_df, aes(
    x = theta_d,
    y = phi_d,
    color = rp,
    fill = rp,
  )) +
  # geom_point() +
  geom_tile() +
  # geom_tile(height = 1,
  #           width = 0.1) +
  scale_fill_viridis_c(name = expression(rho[p])) +
  scale_color_viridis_c(name = expression(rho[p])) + 
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
  ylab(element_blank())+
  xlab(element_blank()) +
  scale_y_continuous(breaks = seq(0, 90, 15), labels = paste0(seq(0, 90, 15), '°')) +
  scale_x_continuous(breaks = seq(0, 270, 90), labels = c('N', 'E', 'S', 'W')) +
  theme(panel.border = element_rect(color = 'grey', fill = NA),
        panel.background = element_blank(),
        panel.grid = element_line(color = 'lightgrey', linewidth = 0.2),
        panel.ontop = T,
        plot.background = element_rect(fill = "white")
        # axis.text.y = element_text(colour = "black")
  )

# p_tile

ggsave(paste0('figs/voxrs/hemis/cor_cn_ip/full_hemi_rho_p_cor_lca_ip_',
              vox_config_id,
               "_",
               plot,
              '.png'),
       p_tile,
       width = 4, height = 3, device = png)

# Other plotting 

# # A partial polar plot
# ggplot(mtcars, aes(disp, mpg)) +
#   geom_point() +
#   coord_radial(start = -0.4 * pi, end = 0.4 * pi, inner.radius = 0.3)
# 
# # use plotly since ggplot doesnt allow changing angle of r axis
# 
# library(plotly)
# # 
# # 
# plot_ly(
#   hemi_df,
#   type = 'scatterpolargl',
#   mode = 'markers'
# ) |>
#   # layout(
#   #   xaxis = list(showgrid = FALSE,
#   #                showticklabels = 'none'),
#   #   yaxis = list(showgrid = FALSE),
#   #   polar = list(
#   #     radialaxis = list(
#   #       nticks = 7,
#   #       angle = 45,
#   #       tickangle = 45,
#   #       ticksuffix = "%",
#   #       tickfont = list(
# #         color = 'rgb(0,0,0)',
# #         size = 16
# #       )
# #     ),
# #     angularaxis = list(
# #       tickmode = "array",
# #       tickvals = c(0 , 45, 90, 135, 180, 225, 270, 315),
# #       ticktext = paste0('<b>', c("N", "NE", "E", "SE", "S", "SW", "W", "NW"), "</b>"),
# #       direction = "clockwise",
# #       tickfont = list(size=16),
# #       showline = TRUE, # Add angular axis line
# #       linecolor = 'black' # Color of the angular axis line
# #     )
# #   ),
# #   xaxis = list(
# #     title = c("N", "NE", "E", "SE", "S", "SW", "W", "NW")
# #   )
# # ) |>
# add_trace(  r = ~phi_d,
#             theta = ~theta_d,
#             color = ~rs,
#             opacity = 0.2)
