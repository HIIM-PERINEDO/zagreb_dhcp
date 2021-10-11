This folder contains scripts that uses [heudiconv](https://heudiconv.readthedocs.io/en/latest/) to convert DICOMs into [BIDS-format](https://bids-specification.readthedocs.io/en/stable/)

- DICOMs are expected to be in `$studyfolder"/dicomdir`
- Heuristics-files are located in code-subfolder `$codefolder/bids/heudiconv_heuristics`
- NIfTIs are written into a BIDS-organised folder `studyfolder"/rawdata`

BIDS format: https://bids-specification.readthedocs.io/en/stable/

Heudiconv: https://heudiconv.readthedocs.io/en/latest/
