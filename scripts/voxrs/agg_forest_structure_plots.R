# aggregate forest structure of each plot
library(terra)
library(viridis)
library(rhdf5)

cn_coef <- 0.38 # from VoxRS default, also see supplementary material for Staines & Pomeroy 2023

n_cores <- 8
phi_from <- 0
phi_to <- 0
phi_by <- 1
theta_from <- 0
theta_to <- 0
theta_by <- 1

plot_names <- c('FSR_NW', 'FSR_NE', 'FSR_S', 'PWL_E', 'PWL_N', 'PWL_SW')

# event_ids <- c('23_026', '23_027')
event_ids <- c('23_072', '23_073')

voxrs_outputs <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'
las_prj_name <- 'params_v1.0.0'
vox_id <- event_ids[1] # which day do we want canopy metrics for?
vox_config_id <- paste0(vox_id, '_vox_len_0.25m_')


phi_theta_list <-
  build_phi_theta_pairs(phi_from, phi_to, phi_by, 
                        theta_from, theta_to, theta_by)

mcn_df_all <- data.frame()

for (plot in plot_names) {
  
  vox_runtag <- paste0('_gridgen_', plot)
  
  h5_basename <- paste0(voxrs_outputs,
                        vox_id,
                        '/voxrs/outputs/grid_resampling/',
                        'grid_resampled',
                        '_',
                        vox_config_id,
                        vox_runtag)
  
  mcn_list <- pbapply::pblapply(phi_theta_list, compile_mcn, cl = n_cores)
  
  mcn_df <- do.call(rbind, mcn_list) |> 
    mutate(plot_name = plot)
  
  mcn_df_all <- rbind(mcn_df_all, mcn_df)
  
}

avg_plot <- mcn_df_all |> 
  group_by(plot_name) |> 
  summarise(across(c(er:tau), mean)) |> 
  mutate(cc = 1-tau) |> 
  rename(er_nadir = er,
         mcn_nadir = mcn,
         tau_nadir = tau,
         cc_nadir = cc)

saveRDS(avg_plot, 'data/grid_stats/plot_avg_forest_metricts_nadir.rds')
