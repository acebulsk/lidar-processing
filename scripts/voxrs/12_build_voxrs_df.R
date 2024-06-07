# query the .h5 file outputs from VoxRS grid resampling to create some
# dataframes which will be used in plotting

# this script aggregates the contact number over a specified range of beam
# trajectories (aka portion of the hemisphere) this time plotting traj angle vs
# mean contact number. The idea here is that traj angle increases with wind
# speed and want to see the associated relationship with mean contact number

# INPUT: h5 files that contain voxrs step 2 outputs 
# OUTPUT: list of correlations (rho_s, rho_p) for each phi / theta pair (360*91)

# h5path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/voxrs/outputs/grid_resampling/grid_resampled_23_072_vox_len_0.25m__gridgen_FSR_NE_t0_14.h5'
# h5readAttributes(file = h5path, name = 'p1_t10')

# data inputs ----

# mcn_list <- lapply(phi_theta_list, 
#                    compile_mcn,
#                    h5_basefilename = h5_basefilename)
mcn_list <-
  pbapply::pblapply(phi_theta_list,
                    compile_mcn,
                    h5_basefilename = h5_basefilename,
                    cl = n_cores)

mcn_df <- do.call(rbind, mcn_list) 

rm(mcn_list)
gc() # free unused memory

mcn_df_smry <- mcn_df |> 
  pivot_longer(c(mcn, tau)) |>
  group_by(phi_d, name) |>
  summarise(
    event = event, 
    plot_name = plot,
    mean = mean(value),
    median = median(value),
    low_iqr = quantile(value, probs = 0.25),
    upper_iqr = quantile(value, probs = 0.75),
    sd = sd(value)	
  )

rm(mcn_df)
gc() # free unused memory

saveRDS(mcn_df_smry,
        paste0(
          voxrs_processed_outputs,
          vox_config_id,
	  '_',
	  plot,
          '_phiby_',
          phi_by,
          '_thetaby_',
          theta_by,
          '.rds'
        ))

rm(mcn_df_smry)
gc() # free unused memory
