
#!/bin/bash

las_path="singularity exec -B /gpfs /opt/software/singularity-images/LAStools.sif /opt/lastools/bin"

shp_clip_new=/gpfs/tp/gwf/gwf_cmt/zvd094/fortress/lidar-processing/data/gis/shp/fsr_traj_extent_buff_20m.shp"

# pt_cld_path="/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072"

pt_cld_path="/globalhome/zvd094/HPC/sym_link_gwf_prj/fortress/lidar-processing/data/pointclouds_stripalign/23_072"
pt_cld_path_out="/globalhome/zvd094/HPC/sym_link_gwf_prj/fortress/lidar-processing/data/pointclouds_stripalign_clipmerge/23_072"

shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_clip.shp"

$las_path/lasmerge64 -i $pt_cld_path/*.las \
        -o "${pt_cld_path_out}/23_072_sa.las"

$las_path/lasclip64 "${pt_cld_path_out}/23_072_sa_mrg.las" \
        -poly $shp_clip_new \
        -o "${pt_cld_path_out}/23_072_sa_mrg_clp.las" -v

