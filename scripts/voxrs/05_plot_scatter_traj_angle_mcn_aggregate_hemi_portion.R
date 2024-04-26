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
phi_by <- 2
theta_from <- 0
theta_to <- 359
theta_by <- 5

phi_theta_list <-
  build_phi_theta_pairs(phi_from, phi_to, phi_by, 
                        theta_from, theta_to, theta_by)

# data inputs ----

# mcn_list <- lapply(phi_theta_list, compile_mcn)
mcn_list <- pbapply::pblapply(phi_theta_list, compile_mcn, cl = n_cores)

mcn_df <- do.call(rbind, mcn_list) 

rm(mcn_list)
gc() # free unused memory

mcn_df_smry <- mcn_df |> 
  group_by(phi_d) |> 
  summarise(
    plot_name = plot,
    mcn = mean(mcn),
    tau = mean(tau)
  )

rm(mcn_df)
gc() # free unused memory

mcn_df_out <- rbind(mcn_df_out, mcn_df_smry)
rm(mcn_df_smry)

saveRDS(mcn_df_out,
        paste0(
          'data/hemi_stats/aggregate_hemi_stats_across_traj_angle_',
          phi_by,
          '_thetaby_',
          theta_by,
          '.png'
        ))
        
gc() # free unused memory

# plotting is done externally under 01_run_voxrs