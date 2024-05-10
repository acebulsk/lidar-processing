#!/bin/bash

source $config_file

# pt_cld_path="/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072"
pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data"

file="23_072"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_test.shp"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_forest_plots_v_1_0_FSR_S.shp"
shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_traj_extent_buff_20m.shp"

/home/alex/bin/LAStools/bin/lasmerge64 -i $pt_cld_path/pointclouds_stripalign/${file}/*.las \
        -o "$pt_cld_path/pointclouds_sa_mergeclip/${file}_sa.las" -olas

/home/alex/bin/LAStools/bin/lasclip64 -i "$pt_cld_path/pointclouds_sa_mergeclip/${file}_sa.las" \
        -poly $shp_clip_new \
        -o "$pt_cld_path/processed_ac/${file}_clip_road_flight2.las" -v

