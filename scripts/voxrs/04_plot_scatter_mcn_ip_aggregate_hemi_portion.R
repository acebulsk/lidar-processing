# this script aggregates the contact number over a specified range of beam
# trajectories (aka portion of the hemisphere), the idea is to plot the
# correlation between mean contact number and I/P. This is instead of just using
# one beam we take the aggregate of a range of theta values

# INPUT: h5 files that contain voxrs step 2 outputs 
# OUTPUT: list of correlations (rho_s, rho_p) for each phi / theta pair (360*91)

library(terra)
library(sf)
library(purrr)
library(rhdf5)
library(dplyr)
library(tidyr)
library(ggplot2)

# h5path <- '/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072/voxrs/outputs/grid_resampling/grid_resampled_23_072_vox_len_0.25m__gridgen_FSR_NE_t0_14.h5'
# h5readAttributes(file = h5path, name = 'p1_t10')

phi_from <- 13
phi_to <- 16
phi_by <- 1
theta_from <- 186
theta_to <- 190
theta_by <- 1

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

# pull in IP raster, negatives have been set to 0
ip_rast <- rast(
  paste0(
    'data/dsm_ip/',
    event_ids[1],
    '_',
    event_ids[2],
    '_',
    las_prj_name,
    '_',
    plot,
    '_',
    'ip_normalised_resample_0.25_crop_mask.tif'
  )
)

# mean(values(ip_rast), na.rm = T)

ip_pts <- terra::as.points(ip_rast, na.rm = T) |> # removing the left join didnt save much time
  as.data.frame(geom="XY")

ip_pts_vect <- ip_pts$`I/P`

phi_theta_list <-
  build_phi_theta_pairs(phi_from, phi_to, phi_by, 
                        theta_from, theta_to, theta_by)

#mcn_list <- lapply(phi_theta_list, compile_mcn)
mcn_list <- pbapply::pblapply(phi_theta_list, compile_mcn, cl = 8)

mcn_df <- do.call(rbind, mcn_list) 

mcn_df_smry <- mcn_df |> 
  group_by(x, y) |> 
  summarise(
    mcn = mean(mcn)
  ) |> 
  left_join(ip_pts, by = c('x', 'y'))

mcn_df_smry |> 
  filter(
    mcn > 0,
    `I/P` > 0) |> 
  ggplot(aes(mcn, `I/P`)) +
  geom_point(alpha = 0.1) +
  stat_smooth(method = 'nls',
              formula = y ~ a * log(x)+b,
              mapping = aes(colour = 'nls'),
              se = FALSE,
              method.args = list(start = list(a=1,b=1))) + 
  stat_smooth(method = 'lm', formula = y ~ x -1 )

# facet all zenith angles
# mcn_df |> 
#   group_by(x, y, phi_d) |> 
#   summarise(
#     mcn = mean(mcn)
#   ) |>
#   left_join(ip_pts, by = c('x', 'y')) |> 
#   ggplot(aes(mcn, `I/P`)) +
#   geom_point(alpha = 0.1) +
#   facet_wrap(~phi_d)

# test some models ----

mcn_df_smry_fltr <- mcn_df_smry |> 
  filter(
    mcn > 0,
    `I/P` > 0)

## Fit a linear model ----

mcn_df_smry_fltr$log_mcn <- log(mcn_df_smry_fltr$mcn)

# plot(log(mcn_df_smry_fltr$mcn), mcn_df_smry_fltr$`I/P`)

model_lm <- lm(`I/P` ~ log10(mcn), data = mcn_df_smry_fltr)
coefs <- coef(model_lm) |> as.numeric()

a_lm <- exp(coefs[1]) # to initiate nls, but didnt make a difference
b_lm <- coefs[2]

modelr::rsquare(model_lm, mcn_df_smry_fltr) # check is the same as our manually defined method

aic_lm <- AIC(model_lm)
bic_lm <- BIC(model_lm)

# Fit a non linear least squares model ----

# use starting values from the linear model 
model_nls_log <- nls(`I/P` ~ a * log(mcn) + b, 
                     data = mcn_df_smry_fltr, 
                     start = list(a = 1, b = 1))
model_nls_tan <- nls(`I/P` ~ a * atan(mcn) + b, 
                 data = mcn_df_smry_fltr, 
                 start = list(a = 1, b = 1))
# see here https://stats.stackexchange.com/questions/514788/logistic-growth-curve-with-r-nls
model_nls_logistic <- nls(`I/P` ~ SSlogis(mcn, Asym, xmid, scal), 
                     data = mcn_df_smry_fltr)

example_data <- data.frame(mcn = seq(0, 55, .25))

aic_nls <- AIC(model_nls_log)
bic_nls <- BIC(model_nls_log)

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

model_fit <- data.frame(
  mcn = example_data$mcn,
  y_lm = predict(model_lm, newdata = example_data), # same as y_nls_log
  # y_nls_tan = coef(model_nls_tan)['a'] * atan(example_data$mcn) + coef(model_nls_tan)['b'],
  # # y_nls_log = coef(model_nls_log)['a'] * log(example_data$mcn) + coef(model_nls_log)['b'], # same as below
  y_nls_log = predict(model_nls_log, newdata = example_data),
  y_nls_logistic = predict(model_nls_logistic, newdata = example_data),
  y_nls_log_custom = 0.25 * log10(example_data$mcn) + 0.2
) 

model_fit |> 
  pivot_longer(!mcn) |> 
  ggplot(aes(mcn, value, colour = name)) + 
  geom_line() +
  geom_point()+
  ylab('Interception Efficiency (-)') +
  xlab('Mean Contact Number')

mcn_df_smry |> 
  filter(
    mcn > 0,
    `I/P` > 0) |> 
  ggplot(aes(mcn, `I/P`)) +
  geom_point(alpha = 0.1) +
  # stat_smooth(method = 'nls',
  #             formula = y ~ a * log(x) + b,
  #             # mapping = aes(colour = 'logarithmic'),
  #             se = FALSE,
  #             method.args = list(start = list(a=1,b=1))) +
  geom_line(data = model_fit, aes(mcn, y_nls_log), colour = 'red') +
  stat_smooth(method = 'lm', formula = y ~ x - 1, se = F, colour = 'blue') +
  ggpubr::stat_cor(method = 'spearman', cor.coef.name = 'rho', label.y.npc = .9) +
  ggpubr::stat_cor(method = 'pearson', cor.coef.name = 'R', label.y.npc = 1) +
  ylab('Interception Efficiency (-)') +
  xlab('Mean Contact Number')

ggsave(paste0('figs/voxrs/scatter/',
              plot, "_", 'mean_contact_number_vs_ip_phi_',
              phi_from, '_', phi_to, '_theta_', theta_from, '_', theta_to, '.png'), width = 6, height = 5, device = png)