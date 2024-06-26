# VoxRS helper functions for dealing with mass amount of vox rs data

# returns angle in degrees from zenith
traj_angle_deg <- function(wind_speed, velocity){
  slope <- wind_speed/velocity
  angle_deg <- atan(slope) * 180 / pi

  return(angle_deg)
}

build_phi_theta_pairs <- function(phi_from, phi_to, phi_by,
                                  theta_from, theta_to, theta_by){
  
  # construct list of phi / theta pairs over the hemisphere
  phi_list <- seq(phi_from, phi_to, by = phi_by)
  
  # Create theta_list
  theta_list <- seq(theta_from, theta_to, by = theta_by)
  
  # Create phi_theta list
  phi_theta_df <- expand.grid(phi_list, theta_list)
  names(phi_theta_df) <- c('phi_d', 'theta_d')
  phi_theta_list <- asplit(phi_theta_df, 1)
  
  return(phi_theta_list)
  
}

set_suffix <- function(theta) {
  ranges <-
    cut(
      theta,
      breaks = c(0, seq(14, 359, by = 15)),
      labels = paste0('t', seq(0, 345, by = 15), '_', seq(14, 359, by = 15)),
      include.lowest = T,
      right = T
    )
  suffix <- as.character(ranges)
  return(suffix)
}

#' Correlate VoxRS Canopy Products and Interception Efficiency over a grid area
#'
#' @param phi_theta_pairs list of phi and theta pairs
#' @param var String describing the var of interest 'cn' for contact number, i.e. the mean theoretical number of canopy contacts for a given ray, or 'tau' for light transmittance, or 'sca' for snow contact area which is canopy coverage shifted by trajectory angle
#' @param cn_coef coef to relate expected returns along a ray (voxrs default
#'   output) to contact number. 0.38 is the default from the VoxRS package, also
#'   see supplementary material for Staines & Pomeroy 2023
#'
#' @return 
#' @export
#'
#' @examples
regress_vox_metric_snow <- function(phi_theta_pairs, vox_metric, snow_vect, cn_coef = 0.38){
  
  phi <- phi_theta_pairs[1]
  theta <- phi_theta_pairs[2]
  
  suffix <- set_suffix(theta)
  
  h5filename <- paste0(h5_basename,
                       "_",
                       suffix,
                       '.h5')
  
  h5_dataset <- paste0('p', phi, '_', 't', theta)
  
  # creater pointer to h5 file w.o. reading into R memory, doesnt work with paralellisation
  # h5f <- H5Fopen(h5filename)
  # # h5_pointer <- h5f&h5_dataset 
  # H5Fclose(h5f)
  
  # # bring h5 into R memory
  # mcn <- h5_pointer[4,]
  # H5Dclose(h5_pointer)
  
  # direct to R memory, careful with large files.... 
  h5_data <- h5read(h5filename, h5_dataset) # same speed as `h5f$'p0_t0'`, the index arg slows this down, since files are small dont need to do this
  
  er <- h5_data[4,] # expected returns along a ray
  if (vox_metric == 'cn') {
    # calculate mean contact number
    vox_vect <- er * cn_coef
  }
  if (vox_metric == 'tau') {
    # calculate light transmittance
    vox_vect <- exp(-h5_data[4,] * cn_coef)
  }
  if (vox_metric == 'cc') {
    # calculate canopy coverage
    vox_vect <- 1 - exp(-h5_data[4,] * cn_coef)
  }
  
  # use this if our ncells do not match between IP and MCN
  # mcn_df <- data.frame(
  #   x = h5_data[1,],
  #   y = h5_data[2,],
  #   mcn = h5_data[4,])
  # mcn_ip <- left_join(mcn_df, ip_df, by = c('x', 'y'))
  
  h5closeAll()
  
  rp <- cor(vox_vect, snow_vect, method = 'pearson') # linear relationship
  rs <- cor(vox_vect, snow_vect, method = 'spearman') # ranked values better for non-linear
  
  phi_theta_pairs[3] <- rp
  phi_theta_pairs[4] <- rs
  
  return(phi_theta_pairs)
  
}

#' Compile Mean Contact Number over Range of Phi and Theta Pairs 
#'
#' @param phi_theta_pairs list of phi and theta pairs
#' @param df empty df to rbind to
#'
#' @return dataframe with phi, theta, and mean contact number
#' @export
#'
#' @examples
compile_mcn <- function(phi_theta_pairs, h5_basefilename, cn_coef = 0.38){
  phi <- phi_theta_pairs[1]
  theta <- phi_theta_pairs[2]
  
  suffix <- set_suffix(theta)
  
  h5filename <- paste0(h5_basefilename,
                       "_",
                       suffix,
                       '.h5')
  
  h5_dataset <- paste0('p', phi, '_', 't', theta)
  
  # direct to R memory, careful with large files.... 
  h5_data <- h5read(h5filename, h5_dataset) # same speed as `h5f$'p0_t0'`, the index arg slows this down, since files are small dont need to do this
  
  phi_theta_mcn <- data.frame(
    x = h5_data[1,],
    y = h5_data[2,],
    # er = h5_data[4,], # estimated returns along a ray (-/m)
    mcn = h5_data[4,] * cn_coef, # mean contact number (-)
    tau = exp(-h5_data[4,] * cn_coef),
    phi_d = as.numeric(phi),
    theta_d = as.numeric(theta)
)
  
  h5closeAll()
  
  return(phi_theta_mcn)
}


#' Rasterise VoxRS H5 Grid Output
#'
#' @param phi desired zenith angle
#' @param theta desired azimuth angle
#' @param h5_basename path to grid_resampling h5 file outputs
#'
#' @return
#' @export
#'
#' @examples
rasterise_vox_metric_from_h5 <- function(phi, theta, h5_basename, vox_metric){
  
  suffix <- set_suffix(theta)
  
  h5filename <- paste0(h5_basename,
                       "_",
                       suffix,
                       '.h5')
  
  h5_dataset <- paste0('p', phi, '_', 't', theta)
  
  # creater pointer to h5 file w.o. reading into R memory, doesnt work with paralellisation
  # h5f <- H5Fopen(h5filename)
  # # h5_pointer <- h5f&h5_dataset 
  # H5Fclose(h5f)
  
  # # bring h5 into R memory
  # mcn <- h5_pointer[4,]
  # H5Dclose(h5_pointer)
  
  # direct to R memory, careful with large files.... 
  h5_data <- h5read(h5filename, h5_dataset) # same speed as `h5f$'p0_t0'`, the index arg slows this down, since files are small dont need to do this
  
  # rhdf5::h5readAttributes(h5filename, h5_dataset)
  
  er_df <- data.frame(x = h5_data[1,],
                      y = h5_data[2,],
                      cn = h5_data[4,] * cn_coef) |> 
    mutate(tau = exp(-cn),
           cc = 1-tau)
  
  h5closeAll()
  
  
  
  er_vect <- vect(er_df, geom = c("x", "y"), crs = "epsg:32611")
  
  bbox <- terra::ext(er_vect)
  
  template_rast <- terra::rast(
    resolution = 0.25,
    bbox,
    vals = NA_real_,
    crs = "epsg:32611"
  )
  
  cc_rast <- rasterize(er_vect, template_rast, vox_metric)
  
  return(cc_rast)
  
}

#' Rasterise Dataframe of XY Pairs
#'
#' @param dataframe dataframe of equal spaced xy pairs usually the output from voxrs .h5 file which is really a tif converted to a df
#' @param resolution resolution of the input raster
#' @param var string referencing the column within the dataframe to be rasterised
#'
#' @return
#' @export
#'
#' @examples
rasterise_df <- function(dataframe, resolution, var){
  
  vect <- terra::vect(dataframe, geom = c("x", "y"), crs = "epsg:32611")
  
  bbox <- terra::ext(vect)
  
  template_rast <- terra::rast(
    resolution = resolution,
    bbox,
    vals = NA_real_,
    crs = "epsg:32611"
  )
  
  rast <- terra::rasterize(vect, template_rast, var)
  
  return(rast)
  
}

#' Resample Raster to Coarser Resolution
#'
#' @param raster input raster to be coarsened
#' @param resolution desired resolution in metres 
#' @param fun string referring the function to be used for aggregating ('med' for median, 'mean' for mean)
#'
#' @return
#' @export
#'
#' @examples
resample_rast <- function(raster, resolution, fun){
  bbox <- terra::ext(raster)
  
  # construct raster so cells match up with centre of dots
  template_rast <- terra::rast(
    resolution = resolution,
    bbox,
    vals = NA_real_,
    crs = "epsg:32611"
  )
  
  # take the median of the cells w/in out coarser template
  rsmpl <-
    terra::resample(raster, template_rast, method = fun)
}

