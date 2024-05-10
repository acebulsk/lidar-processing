#!/bin/bash

pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds_mergeclip"

# file="23_072_FT_new"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_test.shp"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_forest_plots_v_1_0_FSR_S.shp"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fortress_shops.shp"
# shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_clip.shp"
shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_forest_plots_v_1_0_FSR_S.shp"

out_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointcloudsclipped/"

/home/alex/bin/LAStools/bin/lasclip64 -i $pt_cld_path/*.las \
        -poly $shp_clip_new \
        -odir "$out_path" \
        -odix "_clip_frs_s" \
        -olas \
        -v