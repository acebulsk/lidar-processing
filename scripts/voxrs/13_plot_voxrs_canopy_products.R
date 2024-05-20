# bring in the data frames and make some plots

example_traj <- data.frame(
  wind_speed = seq(0,10,0.001),
  traj_angle = traj_angle_deg(seq(0,10,0.001),1) |> round(1))

plot_fs1 <- readRDS(paste0(grid_stats_path, event_ids[1], '.rds'))  |> 
  mutate(cc_nadir_round = round(cc_nadir, 2),
         event = event_ids[1])
plot_fs2 <- readRDS(paste0(grid_stats_path, event_ids[2], '.rds'))  |> 
  mutate(cc_nadir_round = round(cc_nadir, 2),
         event = event_ids[2]) 
plot_fs <- rbind(plot_fs1, plot_fs2)

mcn_df_paths <- list.files(paste0(data_dir, 'data/hemi_stats'), '*'))

mcn_df_out <- purrr::map_dfr(mcn_df_paths, readRDS) |> 
  mutate(traj_angle = phi_d - 90) |> 
  left_join(plot_fs, by = c('plot_name', 'event')) |> 
  left_join(example_traj, by = 'traj_angle',
            multiple = 'first') |> 
  mutate(cc = 1-tau,
         cc_perc_increase = cc-cc_nadir,
         cc_multiplier = cc/cc_nadir,
         cc_test = cc_multiplier*cc_nadir,
         plot_name = ifelse(plot_name == 'FSR_S', "FT", "PWL"),
         event = ifelse(event == '23_072', 'snow-off', 'snow-on')) 

# make plots 

mcn_df_out |> 
  rename(`Trajectory Angle (°)` = traj_angle,
         `Mid Canopy Wind Speed (m/s)` = wind_speed) |> 
  pivot_longer(c(`Trajectory Angle (°)`,
                 `Mid Canopy Wind Speed (m/s)`)) |> 
  mutate(name = factor(
    name,
    levels = c('Trajectory Angle (°)', 'Mid Canopy Wind Speed (m/s)')
  )) |>
  ggplot(aes(value, cc_perc_increase)) +
  geom_line(aes(colour = plot_name, linetype = event)) + 
  # geom_line(aes(y = mod_mcn_lm, linetype = 'lm')) +
  # geom_line(aes(y = mod_mcn_nls, linetype = 'nls')) +
  ylab('Increase in Canopy Coverage (-)') +
  xlab(element_blank()) +
  scale_color_viridis_d(option = 'F',
                        direction = -1,
                        end = .7, name = 'Plot Name') +
  facet_grid(cols = vars(name), scales = 'free_x')

ggsave(paste0(figs_path_out, phi_by, '_thetaby_', theta_by, '_cc_perc_inc.png'), device = png,
       width = 6.5, height = 3)

mcn_df_out |> 
  rename(`Trajectory Angle (°)` = traj_angle,
         `Mid Canopy Wind Speed (m/s)` = wind_speed) |> 
  pivot_longer(c(`Trajectory Angle (°)`,
                 `Mid Canopy Wind Speed (m/s)`)) |> 
  mutate(name = factor(
    name,
    levels = c('Trajectory Angle (°)', 'Mid Canopy Wind Speed (m/s)')
  )) |>
  ggplot(aes(value, mcn)) +
  geom_line(aes(colour = plot_name, linetype = event)) + 
  # geom_line(aes(y = mod_mcn_lm, linetype = 'lm')) +
  # geom_line(aes(y = mod_mcn_nls, linetype = 'nls')) +
  ylab('Mean Contact Number (-)') +
  xlab(element_blank()) +
  scale_color_viridis_d(option = 'F',
                        direction = -1,
                        end = .7, name = 'Plot Name') +
  facet_grid(cols = vars(name), scales = 'free_x')

ggsave(paste0(figs_path_out, phi_by, '_thetaby_', theta_by, '_mean_contact_number.png'), device = png,
       width = 6.5, height = 3)

mcn_df_out |> 
  rename(`Trajectory Angle (°)` = traj_angle,
         `Mid Canopy Wind Speed (m/s)` = wind_speed) |> 
  pivot_longer(c(`Trajectory Angle (°)`,
                 `Mid Canopy Wind Speed (m/s)`)) |> 
  mutate(name = factor(
    name,
    levels = c('Trajectory Angle (°)', 'Mid Canopy Wind Speed (m/s)')
  )) |>
  ggplot(aes(value, cc)) +
  geom_line(aes(colour = plot_name, linetype = event)) + 
  # geom_line(aes(y = mod_mcn_lm, linetype = 'lm')) +
  # geom_line(aes(y = mod_mcn_nls, linetype = 'nls')) +
  ylab('Apparent Canopy Coverage (-)') +
  xlab(element_blank())+
  scale_color_viridis_d(option = 'F',
                        direction = -1,
                        end = .7, name = 'Plot Name') +
  facet_grid(cols = vars(name), scales = 'free_x')

ggsave(paste0(figs_path_out, phi_by, '_thetaby_', theta_by, '_canopy_coverage.png'), device = png,
       width = 6.5, height = 3)


mcn_df_out |> 
#  filter(phi_d > 0) |> 
  ggplot(aes(phi_d, tau)) +
  geom_line(aes(colour = plot_name, linetype = event)) + 
  # geom_line(aes(y = mod_mcn_lm, linetype = 'lm')) +
  # geom_line(aes(y = mod_mcn_nls, linetype = 'nls')) +
  ylab('Radiation Transmittance (-)') +
  xlab('Hydrometeor Trajectory (deg. °)') +
  scale_color_viridis_d(option = 'F',
                        direction = -1,
                        end = .7, name = 'Plot Name')

ggsave(paste0(figs_path_out, phi_by, '_thetaby_', theta_by, '_tau.png'), device = png,
       width = 6, height = 5)
