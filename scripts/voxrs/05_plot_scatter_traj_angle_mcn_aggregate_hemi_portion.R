# this script aggregates the contact number over a specified range of beam
# trajectories (aka portion of the hemisphere) this time plotting traj angle vs
# mean contact number. The idea here is that traj angle increases with wind
# speed and want to see the associated relationship with mean contact number

# INPUT: h5 files that contain voxrs step 2 outputs 
# OUTPUT: list of correlations (rho_s, rho_p) for each phi / theta pair (360*91)

# h5path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/voxrs/outputs/grid_resampling/grid_resampled_23_072_vox_len_0.25m__gridgen_FSR_NE_t0_14.h5'
# h5readAttributes(file = h5path, name = 'p1_t10')

phi_from <- 0
phi_to <- 90
phi_by <- 1
theta_from <- 0
theta_to <- 359
theta_by <- 5

mcn_df_out <- data.frame()

for (plot in plot_names) {

vox_runtag <- paste0('_gridgen_', plot)
las_prj_name <- 'params_v1.0.0'

voxrs_outputs <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/'
h5_basename <- paste0(voxrs_outputs,
                      vox_id,
                      '/voxrs/outputs/grid_resampling/',
                      'grid_resampled',
                      '_',
                      vox_config_id,
                      vox_runtag)

# data inputs ----

phi_theta_list <-
  build_phi_theta_pairs(phi_from, phi_to, phi_by, 
                        theta_from, theta_to, theta_by)

#mcn_list <- lapply(phi_theta_list, compile_mcn)
mcn_list <- pbapply::pblapply(phi_theta_list, compile_mcn, cl = n_cores)

mcn_df <- do.call(rbind, mcn_list) 

mcn_df_smry <- mcn_df |> 
  group_by(phi_d) |> 
  summarise(
    plot_name = plot,
    mcn = mean(mcn)
  )

mcn_df_out <- rbind(mcn_df_out, mcn_df_smry)
}

model_lm <- lm(log(mcn) ~ phi_d -1, data = mcn_df_out)

model_nls <- nls(mcn ~ a*exp(b*phi_d), 
                 start = list(a = 0.5, b = 0.2), data = mcn_df_out)

mcn_df_out$mod_mcn_lm <- exp(predict(model_lm, mcn_df_out))
mcn_df_out$mod_mcn_nls <- predict(model_nls, mcn_df_out)


mcn_df_out |> 
  filter(phi_d > 0) |> 
  ggplot(aes(phi_d - 90, mcn)) +
  geom_point(aes(colour = plot_name)) + 
  geom_line(aes(y = mod_mcn_lm, linetype = 'lm')) +
  geom_line(aes(y = mod_mcn_nls, linetype = 'nls')) +
  ylab('Mean Contact Number (Plot Wide)') +
  xlab('Hydrometeor Trajectory (deg. °)') 

ggsave(paste0('figs/voxrs_ip_regressions/traj_angle_vs_contact_number_thetaby_', theta_by, '.png'), device = png,
       width = 6, height = 5)
