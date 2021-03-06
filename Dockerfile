FROM nvidia/cuda:11.1-devel-ubuntu20.04

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV TZ=Europe/Helsinki

# Anaconda/Jupyter variables 
ENV user=anaconda
ENV group=anaconda
ENV UID=1234
ENV GID=1234
ENV JUPYTERPORT=8888

# Tensorboard variables
ENV TENSORBOARD_LOGDIR=/logs
ENV TENSORBOARD_PORT=6006
ENV TENSORBOARD_RELOAD_INTERVAL=5


ENV PATH /opt/conda/bin:$PATH


# Install OS packages
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update --fix-missing && apt-get install -y wget \
bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 ffmpeg libxrender1 git mercurial subversion \
cmake zlib1g-dev iproute2 sudo 

#COPY sudoers /etc/sudoers
#RUN chown root:root /etc/sudoers

# Create user and group
RUN groupadd --gid ${GID} ${group} && useradd -u ${UID} -g ${GID} -G sudo -d /home/${user} ${user} && mkdir -p /home/${user}
RUN echo ${user}:P4ssw0rd#1 | chpasswd


# Install Anaconda
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh -O ~/anaconda.sh && \
/bin/bash ~/anaconda.sh -b -p /opt/conda && rm ~/anaconda.sh && \
ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
echo ". /opt/conda/etc/profile.d/conda.sh" >> /home/${user}/.bashrc 
#conda install pytorch=1.7.0 torchvision cuda100 keras-gpu -c pytorch


# Python required packages 
RUN pip3 install torch==1.7.0+cu110 torchvision==0.8.1+cu110 torchaudio===0.7.0 -f https://download.pytorch.org/whl/torch_stable.html && \
	pip3 install gym atari-py opencv-python tensorboard pytorch-ignite tensorboardX tensorboard-plugin-profile ptan 

RUN conda install keras-gpu -c pytorch

# "Startup" script
COPY entrypoint.sh /


# Folder to keep jupyter notebooks and Tensorboards log directory
RUN mkdir -p /home/${user}/notebooks ${TENSORBOARD_LOGDIR}

# Include example notebook
COPY RecurrentNetworks.ipynb /home/${user}/notebooks

RUN echo "conda activate base" >> /home/${user}/.bashrc

RUN chown -R ${user}:${group} /home/${user} ${TENSORBOARD_LOGDIR}

USER ${user}:${group}

# Sources 
VOLUME ["/src"]

# Jupyter notebooks
WORKDIR /home/${user}/notebooks
EXPOSE ${JUPYTERPORT}

# Run Jupyter
# --NotebookApp.disable_check_xsrf=True
#ENTRYPOINT jupyter-notebook --ip `ip route list scope link | awk '{ print $7 }'` --port=${JUPYTERPORT} -y --no-browser --notebook-dir=/home/${user}/notebooks --log-level=INFO
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]




