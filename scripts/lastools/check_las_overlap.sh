#!/bin/bash

source $config_file

pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointcloudsclipped"

files=("23_026_FT_new_clip_road.las" "23_027_FT_new_clip_road.las" "23_072_FT_new_clip_road.las" "23_073_FT_new_clip_road.las")

for file in "${files[@]}"; do
    /home/alex/bin/LAStools/bin/lasoverlap64 -i "$pt_cld_path/${file}" \
        -step 0.1 \
        -min_diff 0.04 \
        -max_diff 0.5 \
        -o "$pt_cld_path/check_overlap_pngs/${file}_check_overlap.png" \
        -recover_flightlines
done