#!/bin/bash
#SBATCH --time=6:00:00
#SBATCH --job-name=fortress-lidar
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8G
# for regular GIWS compute note --account=hpc_c_giws_clark
# for the large memory compute note --account=hpc_c_giws_mem_clark (100 TB and 80 cores)
#SBATCH --account=hpc_c_giws_prio_clark
#SBATCH --mail-user=zvd094@usask.ca
#SBATCH --mail-type=ALL
#SBATCH --error=/globalhome/zvd094/HPC/lidar-processing/scripts/lastools/slurm-logs/slurm_%A_%a.err
#SBATCH --out=/globalhome/zvd094/HPC/lidar-processing/scripts/lastools/slurm-logs/slurm_%A_%a.out

#module load gentoo/2020
module load singularity/3.9.2

export LAStoolsLicenseFile=/globalhome/zvd094/HPC/license/lastoolslicense.txt # add license to path so we can use funcitons
las_path="singularity exec -B /gpfs /opt/software/singularity-images/LAStools.sif /opt/lastools/bin"

shp_clip_new="/gpfs/tp/gwf/gwf_cmt/zvd094/fortress/lidar-processing/data/gis/shp/fsr_traj_extent_buff_20m.shp"
#shp_clip_new="/gpfs/tp/gwf/gwf_cmt/zvd094/fortress/lidar-processing/data/gis/shp/fsr_forest_plots_v_1_0_PWL_E_25m_buff.shp"
#shp_clip_new="/gpfs/tp/gwf/gwf_cmt/zvd094/fortress/lidar-processing/data/gis/shp/fsr_forest_plots_v_1_0_FSR_S_25m_buff.shp"
event_list=("23_026" "23_027" "23_072" "23_073")

for A in "${event_list[@]}"; do

    pt_cld_path="/gpfs/tp/gwf/gwf_cmt/zvd094/fortress/lidar-processing/data/pointclouds_stripalign/${A}"
    pt_cld_path_merge="/gpfs/tp/gwf/gwf_cmt/zvd094/fortress/lidar-processing/data/pointclouds_stripalign_merge" 
    pt_cld_path_mergeclip="/gpfs/tp/gwf/gwf_cmt/zvd094/fortress/lidar-processing/data/pointclouds_stripalign_clipmerge"

    # Merge LAS files
    $las_path/lasmerge64 -v -i $pt_cld_path/*.las \
        -o $pt_cld_path_merge/${A}_sa_mrg.las

    # Clip the merged LAS file
    $las_path/lasclip64 -v -i $pt_cld_path_merge/${A}_sa_mrg.las \
        -poly $shp_clip_new \
        -o $pt_cld_path_mergeclip/${A}_sa_mrg_clp.las

done
