#!/bin/bash

# a batch script for converting photogrammetry points into a
# number of products with a tile-based multi-core batch pipeline
# include LAStools in PATH to allow running script from anywhere:
# 	export PATH="/usr/local/lib:/home/alex/bin/LAStools/bin:/home/alex/bin/eddypro-engine/bin/linux:/home/alex/.local/bin:/home/alex/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:$PATH"
# 	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/home/alex/bin/LAStools/LASlib/lib:/usr/local/lib"
# 	export LAStoolsLicenseFile=/home/alex/bin/LAStools/bin/lastoolslicense.txt

cur_datetime=$(date +"%Y-%m-%d-%H-%M-%S")

#### las params ####
z_min=2060 # drop pts below this ele
z_max=2100 # drop pts above this ele
rm_noise_step=1 # use a [n]x[n]x[n] uniform grid for finding isolated points  
n_pts_isolated=100 # points are isolated when there is a total of less than [n] points in all neighhour cells  
ground_step=3 # this is what maddie is using 2024-03
ground_spike=0.1 # maddie is using 0.05 but this removes almost all the points
ground_spike_down=0.1
ground_class=2
las2dem_step=0.1
tile_size=75
buffer=20

#### proj settings ####
las_path=/home/alex/bin/LAStools/bin
n_cores=6 # this works if we run the functions from the absolute path for some reason
prj_dir=/media/alex/phd-data/local-usask/analysis/lidar-processing
#shp_clip=${prj_dir}/data/shp/FT_initialClip.shp
shp_clip=${prj_dir}/data/shp/FT_initialClip.shp
# file_list="23_026_FT_new 23_027_FT_new"
file_list="23_026_FT_new"
pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds"

prj_name=denoise_${ground_spike}_${ground_spike_down} # for file name suffix

out_path=${prj_dir}/data/processed
log_file=${prj_dir}/logs/lastools/${cur_datetime}_${prj_name}_lidar_pre_post_processing.log

echo "######################################################################" | tee -a $log_file
echo LAStools_process_prepost.sh script started at $cur_datetime under the project name $prj_name | tee -a $log_file
lastile64 -version 2>&1 | tee -a $log_file
echo "######################################################################" | tee -a $log_file
echo | tee -a $log_file

echo entering lidar processing for-loop through the following LAS files $file_list. | tee -a $log_file
echo | tee -a $log_file

for A in $file_list; do

    prj_base_name="${A:0:6}"
    out_path_updt=${out_path}/${prj_base_name}

#     echo starting lasclip64 on file: $A.
#     mkdir -p $out_path_updt/clipped # mkdir if doesnt exist
#     lasclip64 -i "$pt_cld_path/$A.las" \
#             -drop_z_above $z_max \
#             -drop_z_below $z_min \
#             -poly "$shp_clip" \
#              -o "$out_path_updt/clipped/${A}_clip_${prj_name}.las" -v
    
#     echo finished lasclip64.
#     echo 

#     echo starting lasoptimize64 on file: $A.

#     mkdir -p $out_path_updt/opt # mkdir if doesnt exist
#     lasoptimize64 -i "$out_path_updt/clipped/${A}_clip_${prj_name}.las" \
#              -o "$out_path_updt/opt/${A}_opt_${prj_name}.las" \
#              # -cores $n_cores this is ingored since only one input file

#     echo finished lasoptimize64.
#     echo 

#     # create temporary tile directory
#     rm -rf $out_path_updt/1_tiles
#     mkdir $out_path_updt/1_tiles
    
#     echo starting lastile64 on file: $A.
    
#     # create a temporary tiling with tile size and buffer 30
#     lastile64 -i "$out_path_updt/opt/${A}_opt_${prj_name}.laz" \
#              -set_classification 0 \
#              -tile_size $tile_size -buffer $buffer -flag_as_withheld \
#              -o $out_path_updt/1_tiles/tile.las \
#              # -cores $n_cores not advised by lastools...

#     echo finished lastile64.
#     echo 

#     rm -rf $out_path_updt/2_tiles_denoised
#     mkdir $out_path_updt/2_tiles_denoised

#     echo starting lasnoise64 on file: $A.
    
#     $las_path/lasnoise64 -i $out_path_updt/1_tiles/tile*.las \
#              -step $rm_noise_step -isolated $n_pts_isolated \
#              -classify_as 31 \
#              -odir $out_path_updt/2_tiles_denoised \
#              -remove_noise \
#              -cores $n_cores

#     echo finished lasnoise64.
#     echo 

#     rm -rf $out_path_updt/3_tiles_sorted
#     mkdir $out_path_updt/3_tiles_sorted
    
#     echo starting lassort64 on file: $A.

#     $las_path/lassort64 -i $out_path_updt/2_tiles_denoised/*.las \
#             -odir $out_path_updt/3_tiles_sorted -olas \
#             -cores $n_cores

#     echo finished lassort64.
#     echo 

#     rm -rf $out_path_updt/4_tiles_ground
#     mkdir $out_path_updt/4_tiles_ground
    
#     echo starting lasground_new64 on file: $A.

#     $las_path/lasground_new64 -i $out_path_updt/3_tiles_sorted/tile*.las \
#                   -step $ground_step \
#                   -extra_fine \
#                   -spike $ground_spike \
#                   -spike_down $ground_spike_down \
#                   -ground_class $ground_class \
#                   -odir $out_path_updt/4_tiles_ground \
#                   -cores $n_cores

#     echo finished lasground_new64.
#     echo 

#     mkdir -p $out_path_updt/class_points # mkdir if doesnt exist

#     echo starting lasmerge64 on file: $A.

#     $las_path/lasmerge64 -i $out_path_updt/4_tiles_ground/tile*.las \
#              -drop_withheld \
#              -o "$out_path_updt/class_points/${A}_class_${prj_name}.las" -olas

#     echo finished lasmerge64.
#     echo 

    mkdir -p $out_path_updt/dsm # mkdir if doesnt exist

    echo starting las2dem64 on file: $A.

    $las_path/las2dem64 -i "$out_path_updt/class_points/${A}_class_${prj_name}.las" \
              -step $las2dem_step \
              -keep_class 2 \
              -o "$out_path_updt/dsm/${A}_${prj_name}.tif" \
              -vv
              # -cores $n_cores this is ignored since one file

    echo finished las2dem64.
    echo 

    rm -rf $out_path_updt/1_tiles $out_path_updt/2_tiles_denoised $out_path_updt/3_tiles_sorted $out_path_updt/4_tiles_ground
done 2>&1 | tee -a $log_file

echo | tee -a $log_file
echo reached end of lidar processing script. 