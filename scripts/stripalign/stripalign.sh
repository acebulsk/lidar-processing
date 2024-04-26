#!/bin/bash

export RLMUSER="demo@univ_saskatchewan"

export RLMPW="9eb657bk3ojcgxc"

# runtag=gcp_check # if -gcp_check enabled
#runtag=gcp_outlier # if -gcp_out enabled, rejects gcp outliers (decided to use this after looking at 23_072 stats)

surv_id=23_027
pt_cld_path=/media/alex/phd-data/local-usask/field-downloads/lidar-data
#pos_file_path=/media/alex/phd-data/local-usask/field-downloads/lidar-data/metadata/traj_files_ac
pos_file_path=/media/alex/phd-data/local-usask/field-downloads/lidar-data/metadata/traj_files_select/$surv_id
mkdir -p /home/alex/local-usask/analysis/lidar-processing/data/stripalign_temp/$surv_id
tempdir=/home/alex/local-usask/analysis/lidar-processing/data/stripalign_temp/$surv_id # should be a ssd (so local machine)
gcpdir=/home/alex/local-usask/analysis/lidar-processing/data/survey_data/survey_points_FT_ixyz_$surv_id.csv


# below is an all in one function which may fail and has poor error messaging 

# -A 1 is for adjusted gps time (i.e. 1e9 minus 0h UTC (midnight) of January 5th to 6th 1980 (6. 0))
# ics_err 0 disables the incompatible geometry check, which was removing some strips
# gcp_check disables the use of gcps as control points and just checks the point cloud against the gcps
# -gcp_out disabled by default, when enabled (no argument) the GCP statistics become robust to outliers, which helps the entire correction become more robust to obstructed or displaced GCP
/home/alex/bin/stripalign/stripalign -align \
    -i $pt_cld_path/pointclouds_sep_flightlines/$surv_id/*/*.las \
    -o *_sa.las \
    -po $pos_file_path/*.txt\
    -T $tempdir \
    -O $pt_cld_path/pointclouds_stripalign/${surv_id} \
    -po_parse "twpkxyz" \
    -A 1 \
    -gcp $gcpdir \
    -gcp_out \
    -uav \
    -ics_err 0 \
    -ics

# could merge after but our lastools pipeline can handle multiple input files
# /home/alex/bin/LAStools/bin/lasmerge64 -i $pt_cld_path/pointclouds_stripalign/$surv_id/*.las \
#         -o $pt_cld_path/pointclouds_stripalign/$surv_id/${surv_id}_strip_align_merged -olas

# can run this sequentially for debugging... 
# /home/alex/bin/stripalign/stripalign -scan \
#     -i $pt_cld_path/combined/*.las \
#     -T $tempdir \
#     -O $pt_cld_path/strip_align 

# # 23_072 had inconsistent geometry warning, resolved by removing 230313_163229.las
# /home/alex/bin/stripalign/stripalign -scan \
#     -i $pt_cld_path/combined/*.las \
#     -T $tempdir \
#     -O $pt_cld_path/strip_align \
#     -po $pos_file_path/*.txt \
#     -po_parse "twpkxyz" \
#     -A 1 \
#     -ics

# /home/alex/bin/stripalign/stripalign \
#     -i $pt_cld_path/combined/*.las \
#     -T $tempdir \
#     -O $pt_cld_path/strip_align \
#     -gcp $gcpdir \
#     -smap -rmap -k

# /home/alex/bin/stripalign/stripalign -reg \
#     -i $pt_cld_path/combined/*.las \
#     -T $tempdir \
#     -O $pt_cld_path/strip_align \
#     -gcp $gcpdir \
#     -name test1

# /home/alex/bin/stripalign/stripalign -corr test1 \
#     -T $tempdir \
#     -O $pt_cld_path/strip_align \
#     -po $pos_file_path/*.txt \
#     -po_parse "twpkxyz" \
#     -name test2 \
#     -nil

# /home/alex/bin/stripalign/stripalign -corr mike \
#     -T $tempdir \
#     -O $pt_cld_path/strip_align \
#     -po $pos_file_path/*.txt \
#     -po_parse "twpkxyz" \
#     *.out -name final -o*_SA2.laz [options] -olax

# stripalign -fastqc -i *_fixed.laz -gcp points.txt -c
