# script to merge lidar dsm outputs from lastools LAStools is set up to output
# multiple dsm tiles for each survey for performance and it doesnt have a method
# to combine them so we do it in R here
# INPUT: multiple dsm tiles (.bil) with values of heights above sea level
# OUTPUT: single dsm (.tif) with values above sea level
# WARNING: Make sure to match the masking of the SWE rasters to the masking here! So must run after script 02

# constants ---- 

dem_vert_ofst <- 0.25 # 1 m for 1 m voxels
surv_id <- '23_072'
dsm_type <- "dsm_interpolated"

# load data ----
fsr_plots <- read_sf('data/gis/shp/fsr_forest_plots_v_1_0.shp')
swe_tif <- rast(paste0(
  'data/dsm_swe/',
  pre_post_ids[1],
  '_',
  pre_post_ids[2],
  '_',
  prj_name,
  'swe_normalised_resample_',
  dsm_res_custm,
  '_crop_mask.tif'
))

# these are from here:
# rsync --progress -r -z zvd094@copernicus:/globalhome/zvd094/HPC/sym_link_gwf_prj/fortress/lidar-processing/data/processed/22_066/dsm_interpolated /media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/22_066/
dsm_tiles <-
  list.files(
    paste0(las_proc_out_path,
           surv_id, '/',
           dsm_type, '/', prj_name),
    pattern = '\\.bil$',
    full.names = T
  ) |> 
  map(terra::rast) 

dsmmerged <- do.call(terra::merge, dsm_tiles)

dsmmerged <- ifel(dsmmerged < 0, NA, dsmmerged)

terra::writeRaster(
  dsmmerged,
  paste0(
    'data/', dsm_type, '_elevation/',
    surv_id,
    '_',
    prj_name,
    "_dsm_elevation.tif"
  ), overwrite = T
)

# resample to 25 cm as in staines 2023

bbox <- terra::ext(dsmmerged)

# construct raster so cells match up with centre of dots
template_rast <- terra::rast(
  resolution = dsm_res_custm,
  xmin = bbox$xmin,
  xmax = bbox$xmax,
  ymin = bbox$ymin,
  ymax = bbox$ymax,
  vals = NA_real_,
  crs = "epsg:32611"
)

# take the median of the cells w/in out coarser template
norm_rast_resamp <-
  terra::resample(dsmmerged, template_rast, method = 'med')

terra::writeRaster(
  norm_rast_resamp,
  paste0(
    'data/', dsm_type, '_elevation/',
    surv_id,
    '_',
    prj_name,
    "_dsm_elevation_resamp.tif"
  ), overwrite = T
)

for(plot in 1:nrow(fsr_plots)){
  plot_mask_sf <- fsr_plots[plot, ]
  norm_rast_resamp_plot <- terra::crop(norm_rast_resamp + dem_vert_ofst, plot_mask_sf, mask = T)
  
  terra::writeRaster(
    norm_rast_resamp_plot,
    paste0(
      'data/', dsm_type, '_elevation/',
      surv_id,
      '_',
      prj_name,
      '_',
      plot_mask_sf$name,
      "_dsm_elevation_resamp_crop_plot_only_ofst_abv_grnd_", dem_vert_ofst, "m.tif"
    ),  overwrite = T
  )
  
}

dsmmerged_crop <- terra::crop(norm_rast_resamp, fsr_plots, mask = T)

dsmmerged_crop <- terra::mask(dsmmerged_crop, fsr_masks, inverse = T)

dsmmerged_crop <-
  terra::mask(dsmmerged_crop, fsr_ss_transect_mask, inverse = T)

# removes elevations where we do not have snow depths and thus do not need to calculate the voxrs stats
dsmmerged_crop <- 
  terra::mask(dsmmerged_crop, swe_tif)

terra::writeRaster(
  dsmmerged_crop,
  paste0(
    'data/', dsm_type, '_elevation/',
    surv_id,
    '_',
    prj_name,
    "_dsm_elevation_resamp_crop_mask.tif"
  ),  overwrite = T
)

dsmmerged_crop_ofst <- dsmmerged_crop + dem_vert_ofst

terra::writeRaster(
  dsmmerged_crop_ofst,
  paste0(
    'data/', dsm_type, '_elevation/',
    surv_id,
    '_',
    prj_name,
    "_dsm_elevation_resamp_crop_mask_ofst_abv_grnd_", dem_vert_ofst, "m.tif"
  ),  overwrite = T
)

# create separate raster for each feature

plot(dsmmerged_crop_ofst)

for(plot in 1:nrow(fsr_plots)){
  plot_mask_sf <- fsr_plots[plot, ]
  dsmmerged_crop_ofst_plot <- terra::crop(dsmmerged_crop_ofst, plot_mask_sf, mask = T)
  
  terra::writeRaster(
    dsmmerged_crop_ofst_plot,
    paste0(
      'data/', dsm_type, '_elevation/',
      surv_id,
      '_',
      prj_name,
      '_',
      plot_mask_sf$name,
      "_dsm_elevation_resamp_crop_mask_ofst_abv_grnd_", dem_vert_ofst, "m.tif"
    ),  overwrite = T
  )
  
}
