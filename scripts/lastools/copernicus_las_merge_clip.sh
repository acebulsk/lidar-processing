#!/bin/bash
#SBATCH --time=6:00:00
#SBATCH --job-name=fortress-lidar
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8G
# for regular GIWS compute note --account=hpc_c_giws_clark
# for the large memory compute note --account=hpc_c_giws_mem_clark (100 TB and 80 cores)
#SBATCH --account=hpc_c_giws_clark
#SBATCH --mail-user=zvd094@usask.ca
#SBATCH --mail-type=ALL
#SBATCH --error=/globalhome/zvd094/HPC/lidar-processing/scripts/lastools/slurm-logs/slurm_%A_%a.err
#SBATCH --out=/globalhome/zvd094/HPC/lidar-processing/scripts/lastools/slurm-logs/slurm_%A_%a.out

module load gentoo/2020
module load singularity/3.9.2

las_path="singularity exec -B /gpfs /opt/software/singularity-images/LAStools.sif /opt/lastools/bin"

shp_clip_new="/gpfs/tp/gwf/gwf_cmt/zvd094/fortress/lidar-processing/data/gis/shp/fsr_traj_extent_buff_20m.shp"

# pt_cld_path="/media/alex/phd-data/local-usask/analysis/lidar-processing/data/processed/23_072"
pt_cld_path="/globalhome/zvd094/HPC/sym_link_gwf_prj/fortress/lidar-processing/data/pointclouds_stripalign/23_072"
pt_cld_path_out="/globalhome/zvd094/HPC/sym_link_gwf_prj/fortress/lidar-processing/data/pointclouds_stripalign_clipmerge/23_072"

shp_clip_new="/home/alex/local-usask/analysis/lidar-processing/data/gis/shp/fsr_road_clip.shp"

$las_path/lasmerge64 -i $pt_cld_path/*.las \
        -o "${pt_cld_path_out}/23_072_sa.las"

$las_path/lasclip64 "${pt_cld_path_out}/23_072_sa_mrg.las" \
        -poly $shp_clip_new \
        -o "${pt_cld_path_out}/23_072_sa_mrg_clp.las" -v
