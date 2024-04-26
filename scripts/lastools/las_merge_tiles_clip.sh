#!/bin/bash

source $config_file

# pt_cld_path="/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072"
pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds/23_072_FT_new_flight_lines_mh"

file="23_072_FT_mh"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_test.shp"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_forest_plots_v_1_0_FSR_S.shp"
shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_clip.shp"

/home/alex/bin/LAStools/bin/lasmerge64 -i $pt_cld_path/raw_pt_clouds/flight2/*.las \
        -o "$pt_cld_path/processed_ac/${file}_flight2.las" -olas

/home/alex/bin/LAStools/bin/lasclip64 -i "$pt_cld_path/processed_ac/${file}_flight2.las" \
        -poly $shp_clip_new \
        -o "$pt_cld_path/processed_ac/${file}_clip_road_flight2.las" -v

