# This Dockerfile constructs a docker image, based on the vistalab/freesurfer
# docker image to execute recon-all as a Flywheel Gear.
#
# Example build:
#   docker build --no-cache --tag scitran/freesurfer-recon-all `pwd`
#
# Example usage:
#   docker run -v /path/to/your/subject:/input scitran/freesurfer-recon-all
#
FROM ubuntu:xenial

# Make directory for flywheel spec (v0)
ENV FLYWHEEL /flywheel/v0
RUN mkdir -p ${FLYWHEEL}
WORKDIR ${FLYWHEEL}
RUN mkdir /flywheel/v0/templates/



# Install dependencies
RUN apt-get update --fix-missing \
 && apt-get install -y wget bzip2 ca-certificates \
      libglib2.0-0 \
      libxext6 \
      libsm6 \
      libxrender1 \
      git \
      mercurial \
      subversion \
      curl \
      grep \
      sed \
      dpkg \
      gcc \
      g++ \
      libeigen3-dev \
      zlib1g-dev \
      libqt4-opengl-dev \
      libgl1-mesa-dev \
      libfftw3-dev \
      libtiff5-dev
RUN apt-get install -y \
      libxt6 \
      libxcomposite1 \
      libfontconfig1 \
      libasound2 \
      bc \
      tar \
      zip \
      unzip \
      tcsh \
      libgomp1 \
      python-pip \
      perl-modules

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    xvfb \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-cyrillic \
    python \
    imagemagick \
    wget \
    subversion\
    vim \
    bsdtar


# Download Freesurfer dev from MGH and untar to /opt
RUN wget -N -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.2.0/freesurfer-linux-centos6_x86_64-7.2.0.tar.gz | tar -xz -C /opt && chown -R root:root /opt/freesurfer && chmod -R a+rx /opt/freesurfer

###########################
# Configure neurodebian (https://github.com/neurodebian/dockerfiles/blob/master/dockerfiles/xenial-non-free/Dockerfile)
RUN set -x \
    && apt-get update \
    && { \
        which gpg \
        || apt-get install -y --no-install-recommends gnupg \
    ; } \
    && { \
        gpg --version | grep -q '^gpg (GnuPG) 1\.' \
        || apt-get install -y --no-install-recommends dirmngr \
    ; } \
    && rm -rf /var/lib/apt/lists/*

# The keyserver is failing, doing this to avoid future problems
# RUN sh -x && for server in ha.pool.sks-keyservers.net \
#                      hkp://p80.pool.sks-keyservers.net:80 \
#                      keyserver.ubuntu.com \
#                      hkp://keyserver.ubuntu.com:80 \
#                      pgp.mit.edu; do set -x gpg --keyserver "$server" --recv-keys DD95CC430502E37EF840ACEEA5D32F012649A5A9 && break || echo "Trying new server..."; done 
# ENV server "hkp://p80.pool.sks-keyservers.net:80" 
# ENV server "ha.pool.sks-keyservers.net" 
ENV server "keyserver.ubuntu.com" 

RUN set -x \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver "${server}" --recv-keys DD95CC430502E37EF840ACEEA5D32F012649A5A9 \
    && gpg --export DD95CC430502E37EF840ACEEA5D32F012649A5A9 > /etc/apt/trusted.gpg.d/neurodebian.gpg \
    && rm -rf "$GNUPGHOME" \
    && apt-key list | grep neurodebian

RUN { \
    echo 'deb http://neuro.debian.net/debian xenial main'; \
    echo 'deb http://neuro.debian.net/debian data main'; \
    echo '#deb-src http://neuro.debian.net/debian-devel xenial main'; \
} > /etc/apt/sources.list.d/neurodebian.sources.list

RUN sed -i -e 's,main *$,main contrib non-free,g' /etc/apt/sources.list.d/neurodebian.sources.list; grep -q 'deb .* multiverse$' /etc/apt/sources.list || sed -i -e 's,universe *$,universe multiverse,g' /etc/apt/sources.list


############################
# Install andts, it seems it is not installed before neurodebian
RUN apt-get update -y && apt-get install -y ants

# The brainstem and hippocampal subfield modules in FreeSurfer-dev require the Matlab R2014b runtime
RUN apt-get install -y libxt-dev libxmu-dev
ENV FREESURFER_HOME /opt/freesurfer
ENV FREESURFER /opt/freesurfer

RUN wget -N -qO- "https://surfer.nmr.mgh.harvard.edu/fswiki/MatlabRuntime?action=AttachFile&do=get&target=runtime2014bLinux.tar.gz" | tar -xz -C $FREESURFER_HOME && chown -R root:root /opt/freesurfer/MCRv84 && chmod -R a+rx /opt/freesurfer/MCRv84

# Install neuropythy
# (here it comes the update to python 3 for Neuropythy)
# Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
     /bin/bash ~/miniconda.sh -b -p /opt/conda

# Put conda in path so we can use conda activate
ENV PATH=$CONDA_DIR/bin:$PATH
# (think about fixing the conda version as well)
RUN conda update -n base -c defaults conda

# install conda env
COPY conda_config/scientific.yml .
RUN conda env create -f scientific.yml


# Remove neuropyth install from here, it is in the scientific.yml
# ENV neuropythyCOMMIT=4dd300aca611bbc11a461f4c39d8548d7678d96c
# RUN curl -#L https://github.com/noahbenson/neuropythy/archive/$neuropythyCOMMIT.zip | bsdtar -xf- -C /usr/lib
# WORKDIR /usr/lib/
# RUN mv neuropythy-$neuropythyCOMMIT neuropythy
# RUN chmod -R +rwx /usr/lib/neuropythy
# RUN pip install --upgrade pip && \
#   pip2.7 install numpy && \
#   pip2.7 install nibabel && \
#   pip2.7 install scipy && \
#   pip2.7 install -e /usr/lib/neuropythy
# RUN wget  https://bootstrap.pypa.io/pip/2.7/get-pip.py && python get-pip.py
# RUN pip2 install numpy && \
#   pip2 install nibabel && \
#   pip2 install scipy && \
#   pip2 install -e /usr/lib/neuropythy



# Download and copy Cerebellum atlas
# see ref:https://afni.nimh.nih.gov/afni/community/board/read.php?1,142026
RUN cd $WORKDIR
RUN wget http://afni.nimh.nih.gov/pub/dist/atlases/SUIT_Cerebellum//SUIT_2.6_1/AFNI_SUITCerebellum.tgz
RUN tar -xf AFNI_SUITCerebellum.tgz --directory /flywheel/v0/templates/


# Download the MORI ROIs 
# New files with the cerebellar peduncles from Lisa Brucket, and new eye ROIs
# RUN echo "${PWD}"
# RUN ls -lahtr
RUN wget --retry-connrefused --waitretry=5 --read-timeout=20 --timeout=15 -t 0 --no-check-certificate -O "${FLYWHEEL}/MORI_ROIs.zip" "https://osf.io/4bq7g/download" \
  && mkdir /flywheel/v0/templates/MNI_JHU_tracts_ROIs/ \
  && unzip "${FLYWHEEL}/MORI_ROIs.zip" -d /flywheel/v0/templates/MNI_JHU_tracts_ROIs/ \
  && rm "${FLYWHEEL}/MORI_ROIs.zip"

# Add Thalamus FS LUT
COPY FreesurferColorLUT_THALAMUS.txt /flywheel/v0/templates/FreesurferColorLUT_THALAMUS.txt

## Add HCP Atlas and LUT
# Download LUT
RUN wget --retry-connrefused --waitretry=5 --read-timeout=20 --timeout=15 -t 0  --no-check-certificate -O LUT_HCP.txt "https://osf.io/rdvfk/download"
RUN cp LUT_HCP.txt /flywheel/v0/templates/LUT_HCP.txt

RUN wget --retry-connrefused --waitretry=5 --read-timeout=20 --timeout=15 -t 0  --no-check-certificate -O MNI_Glasser_HCP_v1.0.nii.gz "https://osf.io/7vjz9/download"
RUN cp MNI_Glasser_HCP_v1.0.nii.gz /flywheel/v0/templates/MNI_Glasser_HCP_v1.0.nii.gz

## setup ants SyN.sh
COPY antsRegistrationSyN.sh /usr/bin/antsRegistrationSyN.sh
RUN echo "export ANTSPATH=/usr/bin/" >> ~/.bashrc

## setup 3dcalc from AFNI
COPY bin/3dcalc bin/libf2c.so bin/libmri.so /usr/bin/
RUN echo "export PATH=/usr/bin/:$PATH" >> ~/.bashrc

## setup fixAllSegmentations 
COPY compiled/fixAllSegmentations /usr/bin/fixAllSegmentations
RUN chmod +x /usr/bin/fixAllSegmentations
# There is a check in the sh for wmparc and other files, which are not working in infantFS, 
# I copied the file and removed those lines as said by Eugenio and checking the whole thing now
COPY compiled/segmentThalamicNuclei.sh /opt/freesurfer/bin/segmentThalamicNuclei.sh

COPY bin/run \
      bin/run.py \
      bin/parse_config.py \
      bin/separateROIs.py \
      bin/fix_aseg_if_infant.py \
      bin/srf2obj \
      manifest.json \
      ${FLYWHEEL}/

# Handle file properties for execution
RUN chmod +x \
      ${FLYWHEEL}/run \
      ${FLYWHEEL}/parse_config.py \
      ${FLYWHEEL}/run.py \
      ${FLYWHEEL}/separateROIs.py \
      ${FLYWHEEL}/fix_aseg_if_infant.py \
      ${FLYWHEEL}/srf2obj \
      ${FLYWHEEL}/manifest.json
WORKDIR ${FLYWHEEL}
# Run the run.sh script on entry.
ENTRYPOINT ["/flywheel/v0/run"]

#make it work under singularity 
# RUN ldconfig: it fails in BCBL, check Stanford 
#https://wiki.ubuntu.com/DashAsBinSh 
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
