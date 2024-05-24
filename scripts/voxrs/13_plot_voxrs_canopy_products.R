# bring in the data frames and make some plots
options(ggplot2.discrete.colour= palette.colors(palette = "R4"),
        ggplot2.discrete.fill = palette.colors(palette = "R4"))

example_traj <- data.frame(
  wind_speed = seq(0,10,0.001),
  traj_angle = traj_angle_deg(seq(0,10,0.001),0.9) |> round(1))

mcn_df_paths <- list.files(paste0(data_dir, 'data/hemi_stats'), '*', full.names = T)
mcn_df_paths <- mcn_df_paths[grep('phiby_2', mcn_df_paths)]

mcn_df_out <- purrr::map_dfr(mcn_df_paths, readRDS) |> 
  mutate(traj_angle = phi_d) |> 
  left_join(example_traj, by = 'traj_angle',
            multiple = 'first') |> 
  filter(event %in% c(c('23_026_072_snow_off'))) |>  # minimal influence of snow-on so just look at snow-off for now
  mutate(plot_name = ifelse(plot_name == 'FSR_S', "FT", "PWL"),
         snow = ifelse(event == '23_026_072_snow_off', 'snow-off', 'snow-on')
         ) 

nadir_cpy <- mcn_df_out |> 
  filter(name == 'tau', 
         phi_d == 0) |> 
  group_by(plot_name) |> 
  summarise(tau_nadir = mean(mean),
            lca_nadir = 1 - tau_nadir)

mcn_df_out_inc <- mcn_df_out |> 
  filter(name == 'tau') |> 
  left_join(nadir_cpy, by = 'plot_name') |> 
  mutate(
    lca = 1 - mean,
    lca_inc = lca - lca_nadir,
    lca_check = lca_nadir + lca_inc,
    lca_perc_inc = (lca_inc)/lca_nadir * 100)

mcn_df_out_inc_long <- mcn_df_out_inc |> 
    rename(`Hydrometeor Trajectory Angle (°)` = phi_d,
         `Mid Canopy Wind Speed (m/s)` = wind_speed) |> 
    pivot_longer(c(`Hydrometeor Trajectory Angle (°)`,
                 `Mid Canopy Wind Speed (m/s)`), names_to = 'xname', values_to = 'xvalues') 

stat_used <- '_mean_sd' # median removed all grids around the canopy for FT... so sticking with mean

# plot increase in leaf covered area ---- 

mcn_df_out_inc_long |> 
  ggplot(aes(xvalues, lca_inc)) +
  geom_line(aes(colour = plot_name)) + 
  # geom_ribbon(aes(ymin = mean-sd, ymax = mean+sd), alpha = 0.3) +
  # geom_vline(aes(xintercept = 30), linetype = 'dashed', alpha = 0.7)+
  ylab('Increase in Leaf Contact Area (-)') +
  xlab(element_blank()) +
  facet_grid(cols = vars(xname), scales = 'free_x') +
  labs(colour = 'Colour')

ggsave(
  paste0(
    figs_path_out,
    phi_by,
    '_thetaby_',
    theta_by,
    '_traj_angle_wind_speed_vs_fractional_inc_lca_snow_off',
    stat_used,
    '.png'
  ),
  device = png,
  width = 8,
  height = 3
)

# test some models ----

# HP98 snow-leaf contact area
leaf_covered_area <- function(horizontal_wind,
                              canopy_closure,
                              canopy_height,
                              forest_downwind,
                              fall_velocity) {
  leaf_plane_area_out <-
    canopy_closure/(1-(canopy_closure*horizontal_wind*canopy_height)/
                      (fall_velocity*forest_downwind))
  
  return(min(c(1, leaf_plane_area_out)))
}

forest_downwind <- 100 # in metres, for the canopy leaf plane area calculation
fall_velocity <- 0.9 # metres per second, for the canopy leaf plane area calc

lca_hp98_FT <- data.frame(
  wind_speed = seq(0,10,0.001),
  traj_angle = traj_angle_deg(seq(0,10,0.001),0.9),
    nadir_lca = nadir_cpy$lca_nadir[nadir_cpy$plot_name == 'FT'],
    canopy_height = 7,
    forest_downwind = 100,
    fall_velocity = 0.9,
    lca_hp98 = NA,
    lca_name = 'FT')

for (row_index in 1:nrow(lca_hp98_FT)) {
  lca_hp98_FT$lca_hp98[row_index] <-
    leaf_covered_area(lca_hp98_FT$wind_speed[row_index],
                      lca_hp98_FT$nadir_lca[row_index],
                      lca_hp98_FT$canopy_height[row_index],
                      lca_hp98_FT$forest_downwind[row_index],
                      lca_hp98_FT$fall_velocity[row_index])
}

lca_hp98_PWL <- data.frame(
  wind_speed = seq(0,10,0.001),
  traj_angle = traj_angle_deg(seq(0,10,0.001),0.9),
  nadir_lca = nadir_cpy$lca_nadir[nadir_cpy$plot_name == 'PWL'],
  canopy_height = 10.5,
  forest_downwind = 100,
  fall_velocity = 0.9,
  lca_hp98 = NA,
  lca_name = 'PWL')

for (row_index in 1:nrow(lca_hp98_PWL)) {
  lca_hp98_PWL$lca_hp98[row_index] <-
    leaf_covered_area(lca_hp98_PWL$wind_speed[row_index],
                      lca_hp98_PWL$nadir_lca[row_index],
                      lca_hp98_PWL$canopy_height[row_index],
                      lca_hp98_PWL$forest_downwind[row_index],
                      lca_hp98_PWL$fall_velocity[row_index])
}

lca_hp98 <- rbind(lca_hp98_FT, lca_hp98_PWL) |> 
  mutate(lca_inc = lca_hp98 - nadir_lca) |> 
  rename(
    `Hydrometeor Trajectory Angle (°)` = traj_angle,
    `Mid Canopy Wind Speed (m/s)` = wind_speed
  ) |>
  pivot_longer(
    c(`Hydrometeor Trajectory Angle (°)`, `Mid Canopy Wind Speed (m/s)`),
    names_to = 'xnames',
    values_to = 'xvalues'
  ) |> 
  select(xnames, xvalues, lca_name, lca_value = lca_inc) |> 
  mutate(group = 'HP98')

ggplot(lca_hp98, aes(xvalues, lca_value, colour = lca_name)) +
  geom_line() +
  facet_grid(~xnames, scales = 'free_x')

mod_data <- mcn_df_out_inc |> 
  select(lca_inc, traj_angle = phi_d)

# ## Fit a linear model ----

model_lm <- lm(lca_inc ~ traj_angle - 1, data = mod_data)
coefs <- coef(model_lm) |> as.numeric()

a_lm <- exp(coefs[1]) # to initiate nls, but didnt make a difference
b_lm <- coefs[2]

modelr::rsquare(model_lm, mod_data) # check is the same as our manually defined method

aic_lm <- AIC(model_lm)
bic_lm <- BIC(model_lm)

# Fit a non linear least squares model ----


# see here https://stats.stackexchange.com/questions/514788/logistic-growth-curve-with-r-nls
model_nls_logistic <- nls(lca_inc ~ SSlogis(traj_angle, Asym, xmid, scal),
                          data = mod_data)

# try to fit logistic through the origin 

logistic_origin <- function(x, Asym, xmid, scal) {
  Asym / (1 + exp((xmid - x) / scal)) - Asym / (1 + exp(xmid / scal))
}

# Fit the model
model_nls_logistic_origin <- nls(
  lca_inc ~ logistic_origin(traj_angle, Asym, xmid, scal),
  data = mod_data,
  start = list(Asym = 10, xmid = 5, scal = 1)
)

nls_coefs <- coef(model_nls_logistic_origin) 
aic_nls <- AIC(model_nls_logistic)
bic_nls <- BIC(model_nls_logistic)

# Compare AIC and BIC values
if (aic_lm < aic_nls) {
  cat("lm is preferred based on AIC.\n")
} else {
  cat("nls is preferred based on AIC.\n")
}

if (bic_lm < bic_nls) {
  cat("lm is preferred based on BIC.\n")
} else {
  cat("nls is preferred based on BIC.\n")
}

example_data <- data.frame(traj_angle = seq(0, 90, .25))

model_fit <- data.frame(
  traj_angle = example_data$traj_angle,
  # lm = predict(model_lm, newdata = example_data),
  # y_nls_logistic = predict(model_nls_logistic, newdata = example_data),
  nls = predict(model_nls_logistic_origin, newdata = example_data)
) |>
  mutate(nls_test = logistic_origin(traj_angle, nls_coefs['Asym'] |> as.numeric(), nls_coefs['xmid'] |> as.numeric(), nls_coefs['scal']  |> as.numeric())) |>
  left_join(example_traj) |>
  rename(
    `Hydrometeor Trajectory Angle (°)` = traj_angle,
    `Mid Canopy Wind Speed (m/s)` = wind_speed
  ) |>
  pivot_longer(
    c(`Hydrometeor Trajectory Angle (°)`, `Mid Canopy Wind Speed (m/s)`),
    names_to = 'xnames',
    values_to = 'xvalues'
  ) |>
  pivot_longer(c(nls, nls_test),
               names_to = 'lca_name',
               values_to = 'lca_value') 

model_fit |>
  ggplot(aes(xvalues, lca_value, colour = lca_name)) +
  geom_line() +
  # geom_point()+
  ylab('Increase in Leaf Contact Area (-)') +
  xlab(element_blank()) +
  facet_grid(~xnames, scales = 'free_x') 

model_fit_bind_obs <- mcn_df_out_inc |>
  select(
    traj_angle = phi_d,
    wind_speed,
    lca_name = plot_name,
    lca_value = lca_inc
  ) |>
  rename(
    `Hydrometeor Trajectory Angle (°)` = traj_angle,
    `Mid Canopy Wind Speed (m/s)` = wind_speed
  ) |>
  pivot_longer(
    c(`Hydrometeor Trajectory Angle (°)`, `Mid Canopy Wind Speed (m/s)`),
    names_to = 'xnames',
    values_to = 'xvalues'
  ) |> select(names(model_fit)) |> 
  rbind(model_fit)


model_fit_bind_obs |>
  mutate(lca_name = factor(lca_name, levels = c('FT', 'PWL', 'lm', 'nls')),
         group = ifelse(lca_name %in% c('FT', 'PWL'), 'obs', 'mod')) |> 
  ggplot() +
  geom_line(aes(xvalues, lca_value, colour = lca_name, linetype = group)) +
  # geom_ribbon(aes(ymin = mean-sd, ymax = mean+sd), alpha = 0.3) +
  # geom_vline(aes(xintercept = 30), linetype = 'dashed', alpha = 0.7)+
  scale_linetype_manual(values = c('obs' = 'solid', 'mod' = 'dashed')) +
  ylab('Increase in Leaf Contact Area (-)') +
  xlab(element_blank()) +
  facet_grid(cols = vars(xnames), scales = 'free_x') +
  labs(
    linetype = "Line Type",  # Naming the linetype legend
    colour = "Colour"    # Naming the color legend
  )

ggsave(
  paste0(
    figs_path_out,
    phi_by,
    '_thetaby_',
    theta_by,
    '_traj_angle_wind_speed_vs_fractional_inc_lca_snow_off_w_mods',
    stat_used,
    '.png'
  ),
  device = png,
  width = 8,
  height = 3
)

model_fit_bind_obs |> 
  mutate(group = ifelse(lca_name %in% c('FT', 'PWL'), 'obs', 'mod')) |> 
  rbind(lca_hp98) |>
  mutate(lca_name = factor(lca_name, levels = c('FT', 'PWL', 'lm', 'nls'))) |> 
  ggplot() +
  geom_line(aes(xvalues, lca_value, colour = lca_name, linetype = group)) +
  # geom_ribbon(aes(ymin = mean-sd, ymax = mean+sd), alpha = 0.3) +
  # geom_vline(aes(xintercept = 30), linetype = 'dashed', alpha = 0.7)+
  scale_linetype_manual(values = c('obs' = 'solid', 'mod' = 'dashed', 'HP98' = 'dotted')) +
  ylab('Increase in Leaf Contact Area (-)') +
  xlab(element_blank()) +
  facet_grid(cols = vars(xnames), scales = 'free_x') +
  labs(
    linetype = "Line Type",  # Naming the linetype legend
    colour = "Colour"    # Naming the color legend
  )

ggsave(
  paste0(
    figs_path_out,
    phi_by,
    '_thetaby_',
    theta_by,
    '_traj_angle_wind_speed_vs_fractional_inc_lca_snow_off_w_mods_hp98',
    stat_used,
    '.png'
  ),
  device = png,
  width = 8,
  height = 3
)

# 
# mcn_df_smry |> 
#   filter(
#     lca > 0,
#     `I/P` > 0) |> 
#   ggplot(aes(lca, `I/P`)) +
#   geom_point(alpha = 0.1) +
#   # stat_smooth(method = 'nls',
#   #             formula = y ~ a * log(x) + b,
#   #             # mapping = aes(colour = 'logarithmic'),
#   #             se = FALSE,
#   #             method.args = list(start = list(a=1,b=1))) +
#   geom_line(data = model_fit, aes(lca, y_nls_log), colour = 'red') +
#   stat_smooth(method = 'lm', formula = y ~ x - 1, se = F, colour = 'blue') +
#   ggpubr::stat_cor(method = 'spearman', cor.coef.name = 'rho', label.y.npc = .9) +
#   ggpubr::stat_cor(method = 'pearson', cor.coef.name = 'R', label.y.npc = 1) +
#   ylab('Interception Efficiency (-)') +
#   xlab('Mean Contact Number')
# 
# ggsave(paste0('figs/voxrs/scatter/',
#               plot, "_", 'mean_contact_number_vs_ip_phi_',
#               phi_from, '_', phi_to, '_theta_', theta_from, '_', theta_to, '.png'), width = 6, height = 5, device = png)


# plot actual values ---- 

mcn_df_out |> 
  filter(name == 'tau') |> 
  ggplot(aes(phi_d, mean)) +
  geom_line(aes()) + 
  # geom_ribbon(aes(ymin = mean-sd, ymax = mean+sd), alpha = 0.3) +
  geom_vline(aes(xintercept = 30), linetype = 'dashed', alpha = 0.7)+
  ylab('Radiation Transmittance (-)') +
  xlab('Hydrometeor Trajectory Angle (°)') +
  facet_grid(~plot_name) +
  theme(legend.title = element_blank())

ggsave(
  paste0(
    figs_path_out,
    phi_by,
    '_thetaby_',
    theta_by,
    '_tau_snow_off',
    stat_used,
    '.png'
  ),
  device = png,
  width = 8,
  height = 3
)

mcn_df_out |>
  filter(name == 'tau') |>
  mutate(cc = 1 - mean) |>
  ggplot(aes(phi_d, cc)) +
  geom_line(aes()) +
  geom_ribbon(aes(ymin = 1-(mean-sd), ymax = 1-(mean+sd)), alpha = 0.3) +
  geom_vline(aes(xintercept = 30), linetype = 'dashed', alpha = 0.7)+
  ylab('Leaf Contact Area (-)') +
  xlab('Hydrometeor Trajectory Angle (°)') +
  facet_grid(~plot_name) +
  theme(legend.title = element_blank())

ggsave(
  paste0(
    figs_path_out,
    phi_by,
    '_thetaby_',
    theta_by,
    '_canopy_coverage_snow_off',
    stat_used,
    '.png'
  ),
  device = png,
  width = 8,
  height = 3
)

# Show individual events ----

# make plots 
# mcn_df_out <- purrr::map_dfr(mcn_df_paths, readRDS) |> 
#   mutate(traj_angle = phi_d - 90) |> 
#   left_join(example_traj, by = 'traj_angle',
#             multiple = 'first') |> 
#   left_join(plot_fs, by = c('plot_name', 'event')) |> 
#   filter(event %in% c(c('23_026', '23_027', '23_072', '23_073'))) |> 
#   mutate(plot_name = ifelse(plot_name == 'FSR_S', "FT", "PWL"),
#          month = ifelse(event %in% c('23_026', '23_027'), 'January', 'March')
#   ) 
# 
# mcn_df_out |> 
#   filter(name == 'mcn') |> 
#   ggplot(aes(traj_angle, median)) +
#   geom_line(aes(colour = event, group = event)) + 
#   geom_ribbon(aes(ymin = low_iqr, ymax = upper_iqr, fill = event), alpha = 0.3) +
#   ylab('Mean Contact Number (-)') +
#   xlab('Hydrometeor Trajectory Angle (°)') +
#   facet_grid(month~plot_name)
# 
# 
# ggsave(paste0(figs_path_out, phi_by, '_thetaby_', theta_by, '_mean_contact_number_indiv_events.png'), device = png,
#        width = 6.5, height = 3)
# 
# mcn_df_out |> 
#   filter(name == 'tau') |> 
#   ggplot(aes(phi_d, median)) +
#   geom_ribbon(aes(ymin = low_iqr, ymax = upper_iqr, fill = event), alpha = 0.3) +
#   geom_line(aes(colour = event, group = event)) + 
#   ylab('Radiation Transmittance (-)') +
#   xlab('Hydrometeor Trajectory Angle (°)') +
#   facet_grid(month~plot_name)
# 
# ggsave(paste0(figs_path_out, phi_by, '_thetaby_', theta_by, '_tau_indiv_events.png'), device = png,
#        width = 6, height = 5)
# 
# mcn_df_out |> 
#   filter(name == 'tau') |> 
#   mutate(cc = 1 - median,
#          low_iqr = 1 - low_iqr,
#          upper_iqr = 1 - upper_iqr) |> 
#   ggplot(aes(phi_d, cc)) +
#   geom_line(aes(colour = event, group = event)) + 
#   geom_ribbon(aes(ymin = low_iqr, ymax = upper_iqr, fill = event), alpha = 0.3) +
#   ylab('Snow-leaf Contact Ratio (-)') +
#   xlab('Hydrometeor Trajectory Angle (°)') +
#   facet_grid(month~plot_name)
# 
# ggsave(paste0(figs_path_out, phi_by, '_thetaby_', theta_by, '_canopy_coverage_indiv_events.png'), device = png,
#        width = 6.5, height = 3)
# 
# mcn_df_out |> 
#   filter(name == 'tau',
#          event %in% c('23_072', '23_073')) |>  # dont have base numbers for jan event yet
#   mutate(cc = 1-median,
#          cc_perc_increase = cc-cc_nadir,
#          cc_multiplier = cc/cc_nadir,
#          cc_test = cc_multiplier*cc_nadir
#   ) |> 
#   ggplot(aes(traj_angle, cc_perc_increase)) +
#   geom_line(aes(colour = event, group = event)) + 
#   ylab('Increase in Canopy Coverage (-)') +
#   xlab('Hydrometeor Trajectory Angle (°)') +
#   # scale_color_viridis_d(option = 'F',
#   #                       direction = -1,
#   #                       end = .7, name = 'Plot Name') +
#   facet_grid(~plot_name)
# 
# ggsave(paste0(figs_path_out, phi_by, '_thetaby_', theta_by, '_cc_perc_inc_indiv_events.png'), device = png,
#        width = 6.5, height = 3)
# 
