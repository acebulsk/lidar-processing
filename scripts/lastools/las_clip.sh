#!/bin/bash

source $config_file
flight=2

pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds/23_072_FT_new_flight_lines_mh/raw_pt_clouds/flight${flight}"

# file="23_072_FT_new"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_test.shp"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_forest_plots_v_1_0_FSR_S.shp"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fortress_shops.shp"
shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_clip.shp"


out_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds/23_072_FT_new_flight_lines_mh/processed_ac/flight_${flight}/01_clip"

/home/alex/bin/LAStools/bin/lasclip64 -i $pt_cld_path/*.las \
        -poly $shp_clip_new \
        -odir "$out_path" \
        -odix "_clip_road"\
        -v