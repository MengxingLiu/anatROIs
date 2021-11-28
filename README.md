[![Docker Pulls](https://img.shields.io/docker/pulls/scitran/freesurfer-recon-all.svg)](https://hub.docker.com/r/garikoitz/freesurfer-ROI/)
[![Docker Stars](https://img.shields.io/docker/stars/scitran/freesurfer-recon-all.svg)](https://hub.docker.com/r/garikoitz/freesurfer-ROI/)
# garikoitz/anatROIs


* You *MUST* read and agree to the license agreement and [register with MGH before you use the software](https://surfer.nmr.mgh.harvard.edu/registration.html).
* Once you get your license you can **edit the `manifest.json` file to include your license details before you build the container**. Without a license the execution of the code will fail.
* This image is built with the Matlab MCRv84 included. The MCR is required to run the optional Hippocampal Subfields and Brainstem Structures processing


### Configuration Options ###
Configuration for running the algorithm (and adding the license) are defined within `config.json`. 


### Example Local Usage ###
This Gear is designed to run within [Flywheel](https://flywheel.io), however you can run this Gear locally. To run ```recon-all``` from this image you can do the following:
```
# Update it to the actual call and for Singularity
docker run --rm -ti \
    -v </path/to/input/data>:/input/flywheel/v0/input/anatomical \
    -v </path/for/output/data>:/output \
    garikoitz/freesurfer-ROI:<version-tag>
```

#### Usage Notes ####
* You must mount the directory (using the `-v` flag) which contains your anatomical data (nifti or dicoms) in the container at `/input/flywheel/v0/input/anatomical` and also mount the directory where you want your output data stored at `/output`, see the example above.
* Configuration options (including the license key) must be set in the `manifest.json` file **before building** the container.



The documentation is in the wiki:
* [Installation](https://github.com/garikoitz/anatROIs/wiki/Installation)
* [Pipeline documentation](https://github.com/garikoitz/anatROIs/wiki/Pipeline-steps)
* [Parameter recommendations](https://github.com/garikoitz/anatROIs/wiki/Parameter-recommendations): differences in acquisition sequences or subject populations require to use different parameters, in this page we collect the parameters and pipeline versions we used for better results. 
* [Reporting and citation](reporting-citation) In this wiki page we include examples of how to report and cite RTP and all the included tools, it will change depending on the selected tools. 
* [TO-DO list](https://github.com/garikoitz/anatROIs/wiki/TO-DO)
