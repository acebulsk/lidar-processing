#!/bin/bash

# a batch script for converting photogrammetry points into a
# number of products with a tile-based multi-core batch pipeline
# include LAStools in PATH to allow running script from anywhere:
# 	export PATH="/usr/local/lib:/home/alex/bin/LAStools/bin:/home/alex/bin/eddypro-engine/bin/linux:/home/alex/.local/bin:/home/alex/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:$PATH"
# 	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/home/alex/bin/LAStools/LASlib/lib:/usr/local/lib"
# 	export LAStoolsLicenseFile=/home/alex/bin/LAStools/bin/lastoolslicense.txt

cur_datetime=$(date +"%Y-%m-%d-%H-%M-%S")

#### las params ####
n_cores=6 # this works for functions that run on tiles but only if we run the functions from the absolute path for some reason
z_min=2060 # drop pts below this ele
z_max=2100 # drop pts above this ele
# rm_noise_step=3 # use a [n]x[n]x[n] uniform grid for finding isolated points  
# n_pts_isolated=10 # points are isolated when there is a total of less than [n] points in all neighhour cells  
ground_offset=0.1 # allows bulginess in ground classification
ground_step=2 # sensitivity analysis by AC 2024-03-12
ground_spike=0.1 # sensitivity analysis by AC 2024-03-12
ground_class=2
ground_thin_step=0.1
ground_thin_perc=50 # gets the median for each grid
#las2dem_ll=0.1 # not used
las2dem_step=0.1
las2dem_float_prec=0.00025 # as in staines 2023
las2dem_max_tin_edge=0.5 # should experiement with this if wanting to remove large areas that should not be interpolated.
tile_size=50
buffer=5

#### proj settings ####
las_path=/home/alex/bin/LAStools/bin
prj_dir=/media/alex/phd-data/local-usask/analysis/lidar-processing
shp_clip=${prj_dir}/data/shp/FT_initialClip.shp
# shp_clip=${prj_dir}/data/shp/fsr_las_clip_very_small.shp
file_list="23_072_FT_new 23_073_FT_new"
# file_list="23_026_FT_new 23_027_FT_new"
pre_sf_index=1
post_sf_index=2
# Convert the file list string into an array
read -r -a file_array <<< "$file_list"
# Extract elements based on indices
pre_sf="${file_array[$pre_sf_index - 1]}"
post_sf="${file_array[$post_sf_index - 1]}"

pt_cld_path="/media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds"

prj_name=gofst${ground_offset}_gstep${ground_step}_gspike${ground_spike} # for file name suffix
# prj_name='base_pars' # for prj dirs and file name suffix

out_path=${prj_dir}/data/processed
log_file=${prj_dir}/logs/lastools/${cur_datetime}_${prj_name}_lidar_pre_post_processing.log


echo "######################################################################" | tee -a $log_file
echo LAStools_process_prepost.sh script started at $cur_datetime under the project name $prj_name | tee -a $log_file
lastile64 -version 2>&1 | tee -a $log_file
echo "######################################################################" | tee -a $log_file
echo | tee -a $log_file

echo "######################################################################" | tee -a $log_file
echo "PARAMATERS SET FOR THIS RUN" | tee -a $log_file
echo "n_cores=$n_cores" | tee -a "$log_file"
echo "z_min=$z_min" | tee -a "$log_file"
echo "z_max=$z_max" | tee -a "$log_file"
# echo "rm_noise_step=$rm_noise_step" | tee -a "$log_file"
# echo "n_pts_isolated=$n_pts_isolated" | tee -a "$log_file"
echo "ground_offset=$ground_offset" | tee -a "$log_file"
echo "ground_step=$ground_step" | tee -a "$log_file"
echo "ground_spike=$ground_spike" | tee -a "$log_file"
echo "ground_class=$ground_class" | tee -a "$log_file"
echo "ground_thin_step=$ground_thin_step" | tee -a "$log_file"
echo "ground_thin_perc=$ground_thin_perc" | tee -a "$log_file"
# echo "las2dem_ll=$las2dem_ll" | tee -a "$log_file"
echo "las2dem_step=$las2dem_step" | tee -a "$log_file"
echo "las2dem_float_prec=$las2dem_float_prec" | tee -a "$log_file"
echo "las2dem_max_tin_edge=$las2dem_max_tin_edge" | tee -a "$log_file"
echo "tile_size=$tile_size" | tee -a "$log_file"
echo "buffer=$buffer" | tee -a "$log_file"
echo "######################################################################" | tee -a $log_file
echo | tee -a $log_file

echo Now entering lidar processing for-loop through the following LAS files $file_list. | tee -a $log_file
echo | tee -a $log_file

for A in $file_list; do

    prj_base_name="${A:0:6}"
    out_path_updt=${out_path}/${prj_base_name}

    echo starting lasclip64 on file: $A.
    mkdir -p $out_path_updt/clipped # mkdir if doesnt exist
    lasclip64 -i "$pt_cld_path/$A.las" \
            -drop_z_above $z_max \
            -drop_z_below $z_min \
            -poly "$shp_clip" \
             -o "$out_path_updt/clipped/${A}_clip_${prj_name}.las" -v
    
    echo finished lasclip64.
    echo 

    echo starting lasoptimize64 on file: $A.

    mkdir -p $out_path_updt/opt # mkdir if doesnt exist
    lasoptimize64 -i "$out_path_updt/clipped/${A}_clip_${prj_name}.las" \
             -o "$out_path_updt/opt/${A}_opt_${prj_name}.las" \
             # -cores $n_cores this is ingored since only one input file

    echo finished lasoptimize64.
    echo 

    # create temporary tile directory
    rm -rf $out_path_updt/1_tiles
    mkdir $out_path_updt/1_tiles
    
    echo starting lastile64 on file: $A.
    
    # create a temporary tiling with tile size and buffer 30
    lastile64 -i "$out_path_updt/opt/${A}_opt_${prj_name}.laz" \
             -set_classification 0 \
             -tile_size $tile_size -buffer $buffer -flag_as_withheld \
             -o $out_path_updt/1_tiles/tile.las \
             # -cores $n_cores not advised by lastools...

    echo finished lastile64.
    echo 

# commented out as currently not removing any points
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

    rm -rf $out_path_updt/3_tiles_sorted
    mkdir $out_path_updt/3_tiles_sorted
    
    echo starting lassort64 on file: $A.

    $las_path/lassort64 -i $out_path_updt/1_tiles/*.las \
            -odir $out_path_updt/3_tiles_sorted -olas \
            -cores $n_cores

    echo finished lassort64.
    echo 

    rm -rf $out_path_updt/4_tiles_ground
    mkdir $out_path_updt/4_tiles_ground
    
    echo starting lasground_new64 on file: $A.

    $las_path/lasground_new64 -i $out_path_updt/3_tiles_sorted/tile*.las \
                  -step $ground_step \
                  -offset $ground_offset \
                  -ultra_fine \
                  -spike $ground_spike \
                  -spike_down $ground_spike \
                  -ground_class $ground_class \
                  -odir $out_path_updt/4_tiles_ground \
                  -cores $n_cores

    echo finished lasground_new64.
    echo 

    rm -rf $out_path_updt/5_tiles_ground_thin
    mkdir $out_path_updt/5_tiles_ground_thin
    
    echo starting lasthin64 on file: $A.

    $las_path/lasthin64 -i $out_path_updt/4_tiles_ground/tile*.las \
                  -keep_class $ground_class \
                  -step $ground_thin_step \
                  -percentile $ground_thin_perc \
                  -odir $out_path_updt/5_tiles_ground_thin \
                  -cores $n_cores

    echo finished lasthin64.
    echo 

    # need merged output for the presnowfall surface the lasheight function
    # also merge the post flight for data vis

    # Create directory if it doesn't exist
    mkdir -p $out_path_updt/6_ground_thin_merge # mkdir if doesnt exist

    echo starting lasmerge64 on file: $A.

    $las_path/lasmerge64 -i $out_path_updt/5_tiles_ground_thin/tile*.las \
            -keep_class $ground_class \
            -drop_withheld \
            -o "$out_path_updt/6_ground_thin_merge/${A}_06_${prj_name}.las" -olas

    echo finished lasmerge64.
    echo

    # for the post flight we will normalise it to the pre flight using las height
    if [ "$A" = "$post_sf" ]; then
        mkdir -p $out_path_updt/07_post_sf_thin_normalised # mkdir if doesnt exist
        echo starting lasheight64 using:
        echo Pre SF: $pre_sf.
        echo Post SF: $post_sf.

        $las_path/lasheight64 -i $out_path_updt/5_tiles_ground_thin/tile*.las \
                        -keep_class $ground_class \
                        -replace_z \
                        -ground_points $out_path/${pre_sf:0:6}/6_ground_thin_merge/${pre_sf}_06_${prj_name}.las \
                        -odir $out_path_updt/07_post_sf_thin_normalised \
                        -cores $n_cores

        echo finished lasthin64.
        echo 

        echo starting lasmerge64 on file: $A.
        mkdir -p $out_path_updt/08_post_sf_thin_normalised_merge # mkdir if doesnt exist

        $las_path/lasmerge64 -i $out_path_updt/07_post_sf_thin_normalised/*.las \
                -keep_class $ground_class \
                -drop_withheld \
                -o "$out_path_updt/08_post_sf_thin_normalised_merge/${A}_08_${prj_name}.las" -olas

        echo finished lasmerge64.
        echo

        # use above to create dsm from normalised las which is essentially has elevation equal to height of snow for each point. This is instead of creating a dsm for each flight and subtracting later... not sure what is better.
        mkdir -p $out_path_updt/dsm_hs_normalised/$prj_name # mkdir if doesnt exist

        echo starting las2dem64 on file: $A which has been normalised to height of snow elevations.

        $las_path/las2dem64 -i $out_path_updt/07_post_sf_thin_normalised/*.las \
                -step $las2dem_step \
                -kill $las2dem_max_tin_edge \
                -keep_class 2 \
                -odir $out_path_updt/dsm_hs_normalised/$prj_name \
                -odix _$prj_name \
                -float_precision $las2dem_float_prec \
                -obil \
                -use_tile_bb \
                -vv \
                -cores $n_cores

        echo finished las2dem64.
        echo 

    fi

    mkdir -p $out_path_updt/dsm/$prj_name # mkdir if doesnt exist

    echo starting las2dem64 on file: $A.

    $las_path/las2dem64 -i $out_path_updt/5_tiles_ground_thin/tile*.las \
              -step $las2dem_step \
              -kill $las2dem_max_tin_edge \
              -keep_class 2 \
              -odir $out_path_updt/dsm/$prj_name \
              -odix _$prj_name \
              -float_precision $las2dem_float_prec \
              -obil \
              -use_tile_bb \
              -vv \
              -cores $n_cores

    echo finished las2dem64.
    echo

done 2>&1 | tee -a $log_file

echo | tee -a $log_file
echo reached end of lidar processing script. | tee -a $log_file