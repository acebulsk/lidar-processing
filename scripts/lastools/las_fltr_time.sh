#!/bin/bash

source $config_file

pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds"
file="23_027_FT_new"
shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_test.shp"
out_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointcloudsclipped"

23_072_f1_start=362758225.050455
23_072_f1_end=362759057.435455
23_072_f2_start=362759616.613943
23_072_f2_end=362760402.543943

/home/alex/bin/LAStools/bin/las2las64 -i "$pt_cld_path/${file}.las" \
        -keep_gpstime_between $23_073_f1_start $23_073_f1_end \
        -o "$out_path/${file}_clip.las" -v