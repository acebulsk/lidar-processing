#!/bin/bash

# a batch script for converting photogrammetry points into a
# number of products with a tile-based multi-core batch pipeline
# include LAStools in PATH to allow running script from anywhere:
# 	export PATH="/usr/local/lib:/home/alex/bin/LAStools/bin:/home/alex/bin/eddypro-engine/bin/linux:/home/alex/.local/bin:/home/alex/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:$PATH"
# 	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/home/alex/bin/LAStools/LASlib/lib:/usr/local/lib"
# 	export LAStoolsLicenseFile=/home/alex/bin/LAStools/bin/lastoolslicense.txt

cur_datetime=$(date +"%Y-%m-%d-%H-%M-%S")

# Check if the config file argument is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <config_file> <run_id>"
    exit 1
fi

# Get the config file path from the command line argument
config_file="$1"

# Check if the config file exists
if [ ! -f "$config_file" ]; then
    echo "Error: File $config_file not found."
    exit 1
fi

# Get the run id argument, this id is used to define the set of flights
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <config_file> <run_id>"
    echo "<run_id> corresponds to the index of flight pairs we have defined within the config file."
    exit 1
fi

run_id=$2 # run id is passed to the config file which selects the event... this is how we lazy parallelize this

source $config_file

#### las params ####
z_min=2020 # drop pts below this ele
z_max=2100 # drop pts above this ele
# rm_noise_step=3 # use a [n]x[n]x[n] uniform grid for finding isolated points  
# n_pts_isolated=10 # points are isolated when there is a total of less than [n] points in all neighhour cells  
ground_bulge=0.1 # bulges the initial ground TIN
ground_offset=0.1 # amount that points can be above bulged ground TIN and still become ground (default=0.05) 
ground_step=2 # sensitivity analysis by AC 2024-03-12
ground_sub=8 # instead of definine the -fine/ultrafine etc, used to divide the step by to get the ground patch, -extra_coarse sub = 3 -coarse sub = 4 -fine sub = 6 -extra_fine sub = 7 -ultra_fine sub = 8 -hyper_fine sub = 9
ground_spike=0.1 # sensitivity analysis by AC 2024-03-12
# ground_stdev=0.025 # this option has been discontinued in lastools
ground_class=2
ground_thin_step=0.05 #  as in staines 2023
ground_thin_perc=50 # gets the median for each grid
#las2dem_ll=0.1 # not used
las2dem_step=0.05 # as in staines 2023
las2dem_float_prec=0.00025 # as in staines 2023
las2dem_max_tin_edge=0.1 # as in staines 2023
las2dem_max_tin_edge_interp=20 # fill all gaps so we have continuous surface for voxrs
tile_size=50
buffer=5

echo "######################################################################" | tee -a $log_file
echo LAStools_process_prepost.sh script started at $cur_datetime under the project name $prj_name | tee -a $log_file
echo "Using flight pair: ${event_list[@]}"
$las_path/lastile64 -version 2>&1 | tee -a $log_file
echo "######################################################################" | tee -a $log_file
echo | tee -a $log_file

echo "######################################################################" | tee -a $log_file
echo "PARAMATERS SET FOR THIS RUN" | tee -a $log_file
echo "n_cores=$n_cores" | tee -a "$log_file"
echo "z_min=$z_min" | tee -a "$log_file"
echo "z_max=$z_max" | tee -a "$log_file"
# echo "rm_noise_step=$rm_noise_step" | tee -a "$log_file"
# echo "n_pts_isolated=$n_pts_isolated" | tee -a "$log_file"
echo "ground_bulge=$ground_bulge" | tee -a "$log_file"
echo "ground_offset=$ground_offset" | tee -a "$log_file"
echo "ground_step=$ground_step" | tee -a "$log_file"
echo "ground_sub=$ground_sub" | tee -a "$log_file"
echo "ground_spike=$ground_spike" | tee -a "$log_file"
echo "ground_stdev=$ground_stdev" | tee -a "$log_file"
echo "ground_class=$ground_class" | tee -a "$log_file"
echo "ground_thin_step=$ground_thin_step" | tee -a "$log_file"
echo "ground_thin_perc=$ground_thin_perc" | tee -a "$log_file"
# echo "las2dem_ll=$las2dem_ll" | tee -a "$log_file"
echo "las2dem_step=$las2dem_step" | tee -a "$log_file"
echo "las2dem_float_prec=$las2dem_float_prec" | tee -a "$log_file"
echo "las2dem_max_tin_edge=$las2dem_max_tin_edge" | tee -a "$log_file"
echo "las2dem_max_tin_edge_interp=$las2dem_max_tin_edge_interp" | tee -a "$log_file"
echo "tile_size=$tile_size" | tee -a "$log_file"
echo "buffer=$buffer" | tee -a "$log_file"
echo "######################################################################" | tee -a $log_file
echo | tee -a $log_file

echo "Now entering lidar processing for-loop through the following LAS files ${event_list[@]}." | tee -a $log_file
echo | tee -a $log_file

for A in "${event_list[@]}"; do

    out_path_updt=${out_path}/${A}

    # echo starting lasclip64 on event: $A.
    
    # rm -rf $out_path_updt/clipped
    # mkdir -p $out_path_updt/clipped # mkdir if doesnt exist

    # $las_path/lasclip64 -i $pt_cld_path/$A/*.las \
    #         -drop_z_above $z_max \
    #         -drop_z_below $z_min \
    #         -poly "$shp_clip" \
    #         -odir $out_path_updt/clipped \
    #         -odix _clip \
    #         -olas \
    #         -cores $n_cores \
    #         -v
    
    # echo finished lasclip64.
    # echo 

    # echo starting lasmerge64 on event: $A. Need this for voxrs.

    $las_path/lasmerge64 -i $out_path_updt/clipped/*.las \
            -o /media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds_sa_mergeclip/${A}_sa.las \
            -v
    
    echo finished lasmerge64.
    echo 

    echo starting lasmerge64 on event: $A. Need this for voxrs.

    $las_path/lasmerge64 -i $out_path_updt/clipped/*.las \
            -o /media/alex/phd-data/local-usask/field-downloads/lidar-data/pointclouds_sa_mergeclip/${A}_sa.las \
            -v
    
    echo finished lasmerge64.
    echo 

#     echo starting lasoptimize64 on event: $A.

#     rm -rf $out_path_updt/opt
#     mkdir -p $out_path_updt/opt # mkdir if doesnt exist

#     $las_path/lasoptimize64 -i $out_path_updt/clipped/*_clip.las \
#              -odir $out_path_updt/opt/ \
#              -odix _opt \
#              -olas \
#              -cores $n_cores # this is ingored if only one input file

#     echo finished lasoptimize64.
#     echo 

#     # create temporary tile directory
#     rm -rf $out_path_updt/1_tiles
#     mkdir $out_path_updt/1_tiles
    
#     echo starting lastile64 on event: $A.
    
#     # create a temporary tiling with tile size and buffer 30
#     $las_path/lastile64 -i $out_path_updt/opt/*_opt.las \
#              -set_classification 0 \
#              -tile_size $tile_size -buffer $buffer -flag_as_withheld \
#              -o $out_path_updt/1_tiles/tile.las \
#              # -cores $n_cores not advised by lastools...

#     echo finished lastile64.
#     echo 

# # commented out as currently not removing any points
# #     rm -rf $out_path_updt/2_tiles_denoised
# #     mkdir $out_path_updt/2_tiles_denoised

# #     echo starting lasnoise64 on event: $A.
    
# #     $las_path/lasnoise64 -i $out_path_updt/1_tiles/tile*.las \
# #              -step $rm_noise_step -isolated $n_pts_isolated \
# #              -classify_as 31 \
# #              -odir $out_path_updt/2_tiles_denoised \
# #              -remove_noise \
# #              -cores $n_cores

# #     echo finished lasnoise64.
# #     echo 
    
#     echo starting lassort64 on event: $A.

#     rm -rf $out_path_updt/3_tiles_sorted
#     mkdir $out_path_updt/3_tiles_sorted

#     $las_path/lassort64 -i $out_path_updt/1_tiles/*.las \
#             -odir $out_path_updt/3_tiles_sorted -olas \
#             -cores $n_cores

#     echo finished lassort64.
#     echo 

#     rm -rf $out_path_updt/4_tiles_ground
#     mkdir $out_path_updt/4_tiles_ground
    
#     echo starting lasground_new64 on event: $A.

#     $las_path/lasground_new64 -i $out_path_updt/3_tiles_sorted/tile*.las \
#                   -step $ground_step \
#                   -sub $ground_sub \
#                   -bulge $ground_bulge \
#                   -offset $ground_offset \
#                   -spike $ground_spike \
#                   -spike_down $ground_spike \
#                   -ground_class $ground_class \
#                   -odir $out_path_updt/4_tiles_ground \
#                   -cores $n_cores

#     echo finished lasground_new64.
#     echo 

#     echo starting lasmerge64 on event: $A.

#     rm -rf $out_path_updt/4_ground_merge
#     mkdir $out_path_updt/4_ground_merge

#     $las_path/lasmerge64 -i $out_path_updt/4_tiles_ground/tile*.las \
#             -keep_class $ground_class \
#             -drop_withheld \
#             -o "$out_path_updt/4_ground_merge/${A}_04_${prj_name}.las" -olas

#     echo finished lasmerge64.
#     echo

#     rm -rf $out_path_updt/5_tiles_ground_thin
#     mkdir $out_path_updt/5_tiles_ground_thin
    
#     echo starting lasthin64 on event: $A.

#     $las_path/lasthin64 -i $out_path_updt/4_tiles_ground/tile*.las \
#                   -keep_class $ground_class \
#                   -step $ground_thin_step \
#                   -percentile $ground_thin_perc \
#                   -odir $out_path_updt/5_tiles_ground_thin \
#                   -drop_withheld \
#                   -cores $n_cores

#     echo finished lasthin64.
#     echo 

#     # need merged output for the presnowfall surface the lasheight function
#     # also merge the post flight for data vis

#     # Create directory if it doesn't exist
#     mkdir -p $out_path_updt/6_ground_thin_merge # mkdir if doesnt exist

#     echo starting lasmerge64 on event: $A.

#     $las_path/lasmerge64 -i $out_path_updt/5_tiles_ground_thin/tile*.las \
#             -keep_class $ground_class \
#             -drop_withheld \
#             -o "$out_path_updt/6_ground_thin_merge/${A}_06_${prj_name}.las" -olas

#     echo finished lasmerge64.
#     echo

#     # for the post flight we will normalise it to the pre flight using las height
#     if [ "$A" = "$post_sf" ]; then
#         rm -rf $out_path_updt/07_post_sf_thin_normalised
#         mkdir $out_path_updt/07_post_sf_thin_normalised # mkdir if doesnt exist
#         echo starting lasheight64 using:
#         echo Pre SF: $pre_sf.
#         echo Post SF: $post_sf.

#         $las_path/lasheight64 -i $out_path_updt/5_tiles_ground_thin/tile*.las \
#                         -keep_class $ground_class \
#                         -replace_z \
#                         -ground_points $out_path/${pre_sf}/6_ground_thin_merge/${pre_sf}_06_${prj_name}.las \
#                         -odir $out_path_updt/07_post_sf_thin_normalised \
#                         -cores $n_cores

#         echo finished lasthin64.
#         echo 

#         echo starting lasmerge64 on event: $A.
#         mkdir -p $out_path_updt/08_post_sf_thin_normalised_merge # mkdir if doesnt exist

#         $las_path/lasmerge64 -i $out_path_updt/07_post_sf_thin_normalised/*.las \
#                 -keep_class $ground_class \
#                 -drop_withheld \
#                 -o "$out_path_updt/08_post_sf_thin_normalised_merge/${A}_08_${prj_name}.las" -olas

#         echo finished lasmerge64.
#         echo

#         # use above to create dsm from normalised las which is essentially has elevation equal to height of snow for each point. This is instead of creating a dsm for each flight and subtracting later... not sure what is better.
#         mkdir -p $out_path_updt/dsm_hs_normalised/$prj_name # mkdir if doesnt exist

#         echo starting las2dem64 on event: $A which has been normalised to height of snow elevations.

#         $las_path/las2dem64 -i $out_path_updt/07_post_sf_thin_normalised/*.las \
#                 -step $las2dem_step \
#                 -kill $las2dem_max_tin_edge \
#                 -keep_class 2 \
#                 -odir $out_path_updt/dsm_hs_normalised/$prj_name \
#                 -odix _$prj_name \
#                 -float_precision $las2dem_float_prec \
#                 -obil \
#                 -use_tile_bb \
#                 -vv \
#                 -cores $n_cores

#         echo finished las2dem64.
#         echo 

#     fi

#     mkdir -p $out_path_updt/dsm/$prj_name # mkdir if doesnt exist

#     echo starting las2dem64 on event: $A.

#     $las_path/las2dem64 -i $out_path_updt/5_tiles_ground_thin/tile*.las \
#               -step $las2dem_step \
#               -kill $las2dem_max_tin_edge \
#               -keep_class 2 \
#               -odir $out_path_updt/dsm/$prj_name \
#               -odix _$prj_name \
#               -float_precision $las2dem_float_prec \
#               -obil \
#               -use_tile_bb \
#               -vv \
#               -cores $n_cores

#     echo finished las2dem64.
#     echo

#     mkdir -p $out_path_updt/dsm_interpolated/$prj_name # mkdir if doesnt exist

#     echo starting las2dem64 with full interpolation on event: $A.

#     $las_path/las2dem64 -i $out_path_updt/5_tiles_ground_thin/tile*.las \
#               -step $las2dem_step \
#               -kill $las2dem_max_tin_edge_interp \
#               -keep_class 2 \
#               -odir $out_path_updt/dsm_interpolated/$prj_name \
#               -odix _$prj_name \
#               -float_precision $las2dem_float_prec \
#               -obil \
#               -use_tile_bb \
#               -vv \
#               -cores $n_cores

#     echo finished las2dem64 with full interpolation.
#     echo

done 2>&1 | tee -a $log_file

echo | tee -a $log_file
echo reached end of lidar processing script. | tee -a $log_file
notify-send "LAStools Processing Bash Script:" "Finished processing files: $pre_sf and $post_sf \n under the project name: $prj_name."