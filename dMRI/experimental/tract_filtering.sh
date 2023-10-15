tckmap tracks.tck - | mrcalc - 0.001 -gt tdi_thresh.mif | tckedit tracks.tck roi.mif -include roi.mif

tckmap tracks.tck -template tpl.mif - | mrcalc - 0.001 -lt fr_mask.mif
tckedit tracks.tck -mask fr_mask.mif result.tck

tckmap whole_brain_10K.tck -template ../../../registration/dwi/meanb1000_brain.nii.gz  - | mrthreshold - -abs 0.001 -invert - | tckedit -exclude - whole_brain_10K.tck result_thresh.tck   -force

ORIG:
tckmap tracks.tck -vox 1.0 - | mrcalc - $(tckinfo tracks.tck | grep " count" | cut -d':' -f2 | tr -d '[:space:]') -div tdi_fractional.mifv

tckmap roi_brain_10K.tck -template ../../../registration/dwi/meanb1000_brain.nii.gz - | mrcalc - $(tckinfo roi_brain_10K.tck | grep " count" | cut -d':' -f2 | tr -d '[:space:]') -div tdi_fractional.mif

tracks2prob -template tpl.mif -fraction fr.mif  - | threshold -abs 0.001 -invert - | filter_tracks -exclude - fr.mif  result.mif