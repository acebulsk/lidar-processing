# VoxRS helper functions for dealing with mass amount of vox rs data

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

#' Correlate VoxRS Mean Contact Number and Interception Efficiency over a grid area
#'
#' @param phi_theta_pairs list of phi and theta pairs
#' @param ip_df data frame with x, y and interception efficiency. XY must match with the voxrs h5 file outputs.
#'
#' @return 
#' @export
#'
#' @examples
regress_mcn_ip <- function(phi_theta_pairs, ip_df){
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
  
  mcn <- h5_data[4,]
  
  # use this if our ncells do not match between IP and MCN
  # mcn_df <- data.frame(
  #   x = h5_pointer[1,],
  #   y = h5_pointer[2,],
  #   mcn = h5_pointer[3,])
  # mcn_ip <- left_join(mcn_df, ip_df, by = c('x', 'y'))
  
  h5closeAll()
  
  rp <- cor(mcn, ip_pts_vect, method = 'pearson') # linear relationship
  rs <- cor(mcn, ip_pts_vect, method = 'spearman') # ranked values better for non-linear
  
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
compile_mcn <- function(phi_theta_pairs, h5_basefilename){
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
  
  mcn <- h5_data[4,]
  
  phi_theta_mcn <- data.frame(
    x = h5_data[1,],
    y = h5_data[2,],
    mcn = h5_data[4,],
    phi_d = as.numeric(phi),
    theta_d = as.numeric(theta)
)
  
  h5closeAll()
  
  return(phi_theta_mcn)
}
