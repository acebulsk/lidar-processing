# run the voxrs product sequence

library(terra)
library(sf)
library(purrr)
library(rhdf5)
library(tidyverse)
library(modelr)

n_cores <- 4

source('scripts/voxrs/voxrs_helper_fns.R')

plot_names <-
  c(#'FSR_NW',
    #'FSR_NE',
    'FSR_S',
    'PWL_E')
   # 'PWL_N',
    #'PWL_SW')

# plot <- 'PWL_E'

# event_ids <- c('23_026', '23_027')
event_ids <- c('23_072', '23_073')

# WARNING: Need to match the voxrs output with the same las_prj_name used as the grid elevation surface (needs the same number of cells)
voxrs_outputs <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'
las_prj_name <- 'v2.0.0_sa'
vox_id <- event_ids[1] # which day do we want canopy metrics for?
# vox_config_id <- paste0(vox_id, '_vox_len_0.25m_')
# barely noticble change after changing to strip align and corresponding new snow depth liadar measurements
vox_config_id <- paste0(vox_id, '_vox_len_0.25m_sa_gridgen_v2.0.0_sa')


mcn_df_out <- data.frame()

for (plot in plot_names) {

  h5_basename <- paste0(voxrs_outputs,
                        vox_id,
                        '/voxrs/outputs/grid_resampling/',
                        'grid_resampled',
                        '_',
                        vox_config_id,
                        "_",
                        plot)

  # source('scripts/voxrs/02_construct_hemi_from_grids.R')
  # source('scripts/voxrs/03_plot_hemi_correlation.R')
  # source('scripts/voxrs/04_plot_scatter_mcn_ip_aggregate_hemi_portion.R')
  source('scripts/voxrs/05_plot_scatter_traj_angle_mcn_aggregate_hemi_portion.R')

}


traj_angle_deg <- function(wind_speed, velocity){
  slope <- -velocity/wind_speed
  angle_deg <- atan(slope) * 180 / pi
  
  return(angle_deg)
}

example_traj <- data.frame(
  wind_speed = seq(0,10,0.001),
  traj_angle = traj_angle_deg(seq(0,10,0.001),1) |> round(1))

plot_fs1 <- readRDS(paste0('data/grid_stats/plot_avg_forest_metricts_nadir_', event_ids[1], '.rds'))  |> 
  mutate(cc_nadir_round = round(cc_nadir, 2),
         event = event_ids[1])
plot_fs2 <- readRDS(paste0('data/grid_stats/plot_avg_forest_metricts_nadir_', event_ids[2], '.rds'))  |> 
  mutate(cc_nadir_round = round(cc_nadir, 2),
         event = event_ids[2]) 
plot_fs <- rbind(plot_fs1, plot_fs2)

mcn_df_out1 <- readRDS(paste0(
  'data/hemi_stats/aggregate_hemi_stats_across_traj_angle_',
  event_ids[1],
  '_phiby_',
  phi_by,
  '_thetaby_',
  theta_by,
  '.rds'
)) |> mutate(event = event_ids[1])
mcn_df_out2 <- readRDS(paste0(
  'data/hemi_stats/aggregate_hemi_stats_across_traj_angle_',
  event_ids[2],
  '_phiby_',
  phi_by,
  '_thetaby_',
  theta_by,
  '.rds'
)) |> mutate(event = event_ids[2])

mcn_df_out <- rbind(mcn_df_out1, mcn_df_out2) |> 
  mutate(traj_angle = phi_d - 90) |> 
  left_join(plot_fs, by = c('plot_name', 'event')) |> 
  left_join(example_traj, by = 'traj_angle',
            multiple = 'first') |> 
  mutate(cc = 1-tau,
         cc_perc_increase = cc-cc_nadir,
         cc_multiplier = cc/cc_nadir,
         cc_test = cc_multiplier*cc_nadir,
         plot_name = ifelse(plot_name == 'FSR_S', "FT", "PWL")) 

mcn_nadir_smry <- mcn_df_out |> 
  filter(phi_d == 0) |> 
  group_by(plot_name, event) |> 
  summarise(across(c(cc, tau), mean)) |> 
  mutate(cc = 1-tau) |> 
  rename(tau_nadir = tau,
         cc_nadir = cc)

# grab some select stats for the manuscript
mcn_df_select_stats <- mcn_df_out |> 
  filter(wind_speed == 0 | (wind_speed > 1.45 & wind_speed < 1.51) | (wind_speed > 1.99 & wind_speed < 2.1))

saveRDS(mcn_df_select_stats, 'data/hemi_stats/aggregate_hemi_stats_select_cc_wind_for_manuscript.rds')

model_lm <- lm(log(mcn) ~ phi_d, data = mcn_df_out) # -1 forces through the origin

model_nls <- nls(mcn ~ a*exp(b*phi_d), 
                 start = list(a = 0.5, b = 0.2), data = mcn_df_out, control = nls.control(maxiter = 1000))

mcn_df_out$mod_mcn_lm <- exp(predict(model_lm, mcn_df_out))
mcn_df_out$mod_mcn_nls <- predict(model_nls, mcn_df_out)

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
  geom_point(aes(colour = plot_name, shape = event)) + 
  # geom_line(aes(y = mod_mcn_lm, linetype = 'lm')) +
  # geom_line(aes(y = mod_mcn_nls, linetype = 'nls')) +
  ylab('Increase in Canopy Coverage (-)') +
  xlab(element_blank()) +
  scale_color_viridis_d(option = 'F',
                        direction = -1,
                        end = .7, name = 'Nadir Canopy\nCoverage (-)') +
  facet_grid(cols = vars(name), scales = 'free_x')

ggsave(paste0('figs/voxrs/scatter/traj_angle_and_wind_vs_inc_canopy_cover_phiby_', phi_by, '_thetaby_', theta_by, '.png'), device = png,
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
  geom_point(aes(colour = plot_name, shape = event)) + 
  # geom_line(aes(y = mod_mcn_lm, linetype = 'lm')) +
  # geom_line(aes(y = mod_mcn_nls, linetype = 'nls')) +
  ylab('Mean Contact Number (-)') +
  xlab(element_blank()) +
  scale_color_viridis_d(option = 'F',
                        direction = -1,
                        end = .7, name = 'Plot Name') +
  facet_grid(cols = vars(name), scales = 'free_x')

ggsave(paste0('figs/voxrs/scatter/traj_angle_and_wind_vs_contact_number_phiby_', phi_by, '_thetaby_', theta_by, '.png'), device = png,
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
  geom_point(aes(colour = plot_name, shape = event)) + 
  # geom_line(aes(y = mod_mcn_lm, linetype = 'lm')) +
  # geom_line(aes(y = mod_mcn_nls, linetype = 'nls')) +
  ylab('Apparent Canopy Coverage (-)') +
  xlab(element_blank())+
  scale_color_viridis_d(option = 'F',
                        direction = -1,
                        end = .7, name = 'Plot Name') +
  facet_grid(cols = vars(name), scales = 'free_x')

ggsave(paste0('figs/voxrs/scatter/traj_angle_and_wind_vs_canopy_coverage_phiby_', phi_by, '_thetaby_', theta_by, '.png'), device = png,
       width = 6.5, height = 3)


mcn_df_out |> 
  filter(phi_d > 0) |> 
  ggplot(aes(phi_d, tau)) +
  geom_line(aes(colour = plot_name, linetype = event)) + 
  # geom_line(aes(y = mod_mcn_lm, linetype = 'lm')) +
  # geom_line(aes(y = mod_mcn_nls, linetype = 'nls')) +
  ylab('Radiation Transmittance (-)') +
  xlab('Hydrometeor Trajectory (deg. °)') +
  scale_color_viridis_d(option = 'F',
                        direction = -1,
                        end = .7, name = 'Plot Name') 

ggsave(paste0('figs/voxrs/scatter/traj_angle_vs_transmittance_phiby_', phi_by, '_thetaby_', theta_by, '.png'), device = png,
       width = 6, height = 5)


###  make one model across all plots ---
model_lm <- lm(log(tau) ~ phi_d, data = mcn_df_out)

# model_nls_log <- nls(tau ~ a * log(phi_d) + b,
#                      data = mcn_df_out,
#                      start = list(a = 1, b = 1))

model_nls_logistic <- nls(tau ~ SSlogis(phi_d, Asym, xmid, scal), 
    data = mcn_df_out)

asym <- coef(model_nls_logistic)['Asym']
xmid <- coef(model_nls_logistic)['xmid']
scal <- coef(model_nls_logistic)['scal']


mcn_df_out$mod_cc_lm <- 1-exp(predict(model_lm, mcn_df_out))
# mcn_df_out$mod_cc_nls <- predict(model_nls, mcn_df_out)
mcn_df_out$mod_cc_logis <- 1-predict(model_nls_logistic, mcn_df_out)

# recreate what predict is doing... 
manual <-  1-(asym / (1 + exp((xmid-mcn_df_out$phi_d)/scal)))
sslogi <-  1-SSlogis(mcn_df_out$phi_d, Asym = asym, xmid = xmid, scal = scal)
stopifnot(all.equal(mcn_df_out$mod_cc_logis |> as.vector(), manual))
stopifnot(all.equal(mcn_df_out$mod_cc_logis |> as.vector(), sslogi |> as.vector()))
stopifnot(all.equal(manual, sslogi |> as.vector()))

### model for each forest plot ---

# see updated many models here: https://www.tmwr.org/workflow-sets

model_tibble <- mcn_df_out |> 
  group_by(plot_name) |> 
  do(model = nls(tau ~ SSlogis(phi_d, Asym, xmid, scal), data = .)) |> 
  nest() |> 
  mutate(preds = map2(data, model, add_predictions))

build_nls_model <- function(df) {
  nls(tau ~ SSlogis(phi_d, Asym, xmid, scal), 
      data = df)
}

model_nest <- mcn_df_out |> 
  group_by(plot_name) |> 
  nest()  |> 
  mutate(model = map(data, build_nls_model),
         resids = map2(data, model, add_residuals),
         preds = map2(data, model, add_predictions))

resids <- unnest(model_nest, resids)

resids %>% 
  ggplot(aes(phi_d, resid, colour = plot_name)) +
  geom_point(aes(group = plot_name), alpha = 1 / 3) + 
  geom_smooth(se = FALSE)

preds <- unnest(model_nest, preds)
options(ggplot2.discrete.colour= palette.colors(palette = "R4"))

preds %>% 
  ggplot() +
  geom_line(aes(phi_d, pred, colour = plot_name)) +
  geom_point(aes(phi_d, tau, colour = plot_name)) +
  ylab('Light Transmittance (-)') +
  xlab('Zenith Angle (deg. °)')   +
  labs(colour = 'Plot Name')

ggsave(paste0('figs/voxrs/scatter/zenith_angle_vs_lighttransmit_', phi_by, '_thetaby_', theta_by, '.png'), device = png,
       width = 6, height = 5)

preds %>% 
  ggplot() +
  # geom_line(aes(phi_d-90, 1-pred, colour = plot_name)) +
  geom_point(aes(phi_d-90, 1-tau, colour = plot_name)) +
  ylab('Canopy Coverage (-)') +
  xlab('Hydrometeor Trajectory (deg. °)')  +
  labs(colour = 'Plot Name')

ggsave(paste0('figs/voxrs/scatter/traj_angle_vs_canopycover_', phi_by, '_thetaby_', theta_by, '.png'), device = png,
       width = 6, height = 5)

preds <- preds |>
  mutate(traj_angle = phi_d - 90) |>
  left_join(example_traj, by = 'traj_angle',
            multiple = 'first')

preds %>% 
  ggplot() +
  # geom_line(aes(win, 1-pred, colour = plot_name)) +
  geom_point(aes(wind_speed, 1-tau, colour = plot_name)) +
  ylab('Canopy Coverage (-)') +
  xlab('Wind Speed (m/s)') +
  labs(colour = 'Plot Name')

ggsave(paste0('figs/voxrs/scatter/wind_vs_canopycover_', phi_by, '_thetaby_', theta_by, '.png'), device = png,
       width = 6, height = 5)

glance <- model_nest |> 
  mutate(glance = map(model, broom::glance)) %>% 
  unnest(glance)

