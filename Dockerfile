FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y wget software-properties-common gnupg2 winbind curl dos2unix

# Install Python 3.8 and necessary tools
RUN apt-get update && \
    apt-get install -y python3.8 python3.8-venv python3.8-dev && \
    apt-get install -y python3-pip && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg2 winbind xvfb curl \
    wget \
    sudo \
    unzip \
    libgconf-2-4 \
    libxt6 \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install awslambdaric

RUN curl -Lo /usr/local/bin/aws-lambda-rie https://github.com/MecSimCalc/aws-lambda-runtime-interface-emulator/raw/msc-v1.13/bin/aws-lambda-rie && \
    chmod +x /usr/local/bin/aws-lambda-rie 

# Set LAMBDA_TASK_ROOT environment variable
ENV LAMBDA_TASK_ROOT=/var/task

# Set LAMBDA_RUNTIME_DIR environment variable
ENV LAMBDA_RUNTIME_DIR=/var/runtime

COPY inputFile.txt ${LAMBDA_TASK_ROOT}/
RUN mkdir /mcr-install && \
    mkdir /opt/mcr && \
    cd /mcr-install && \
    wget --no-check-certificate -q https://ssd.mathworks.com/supportfiles/downloads/R2024a/Release/4/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2024a_Update_4_glnxa64.zip && \
    unzip -q MATLAB_Runtime_R2024a_Update_4_glnxa64.zip && \
    rm -f MATLAB_Runtime_R2024a_Update_4_glnxa64.zip && \
    ./install -inputFile ${LAMBDA_TASK_ROOT}/inputFile.txt && \
    cd / && \
    rm -rf mcr-install  

# Install necessary packages
RUN apt-get update && \
    apt-get install -y \
    libxtst6 \
    libx11-6 \
    libxext6 \
    libxdamage1 \
    libxfixes3 \
    libxcomposite1 \
    libxrandr2 \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libnss3 \
    libnss3-tools \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libgbm1 \
    libasound2 \
    libatspi2.0-0

# Cleanup the apt cache to reduce image size
RUN rm -rf /var/lib/apt/lists/*

COPY app.py ${LAMBDA_TASK_ROOT}/ 
COPY lambda-entrypoint.sh /
RUN dos2unix /lambda-entrypoint.sh
COPY download_and_run.py ${LAMBDA_TASK_ROOT}/

COPY run_app.sh ${LAMBDA_TASK_ROOT}/run_app.sh
COPY run_appDetailed.sh ${LAMBDA_TASK_ROOT}/run_appDetailed.sh
RUN dos2unix /var/task/run_app.sh
RUN dos2unix /var/task/run_appDetailed.sh
COPY appDetailed ${LAMBDA_TASK_ROOT}/appDetailed
COPY app ${LAMBDA_TASK_ROOT}/app
COPY Eco-Env/ ${LAMBDA_TASK_ROOT}/Eco-Env/
COPY Info/ ${LAMBDA_TASK_ROOT}/Info/
COPY ["Load Data/", "${LAMBDA_TASK_ROOT}/Load Data/"]

RUN sudo chmod +x ${LAMBDA_TASK_ROOT}/run_app.sh
RUN sudo chmod +x ${LAMBDA_TASK_ROOT}/run_appDetailed.sh
RUN sudo chmod +x ${LAMBDA_TASK_ROOT}/app
RUN sudo chmod +x ${LAMBDA_TASK_ROOT}/appDetailed

RUN mkdir -p /var
RUN mkdir -p /var/adm
RUN mkdir -p /var/cache
RUN mkdir -p /var/db
RUN mkdir -p /var/empty
RUN mkdir -p /var/games
RUN mkdir -p /var/gopher
RUN mkdir -p /var/kerberos
RUN mkdir -p /var/lang/
RUN mkdir -p /var/lib
RUN mkdir -p /var/local
RUN mkdir -p /var/log
RUN mkdir -p /var/nis
RUN mkdir -p /var/opt
RUN mkdir -p /var/preserve
RUN mkdir -p /var/rapid
RUN mkdir -p /var/runtime
RUN mkdir -p /var/spool
RUN mkdir -p /var/task
RUN mkdir -p /var/telemetry
RUN mkdir -p /var/tmp
RUN mkdir -p /var/tracer
RUN mkdir -p /var/yp

COPY var/runtime/* /var/runtime/
COPY var/lang/ /var/lang/
COPY var/* /var/

RUN sudo chmod +x /var/runtime/bootstrap

ENTRYPOINT ["/lambda-entrypoint.sh"]
CMD ["app.handler"]


# WORKDIR as /tmp, which is the only writable directory
WORKDIR /var/task
# ENV Environment Variables
# - MPLCONFIGDIR to speed up the import of Matplotlib and better support multiprocessing.
ENV MPLCONFIGDIR=/tmp
# - TMPDIR to declare the temporary directory
ENV TMPDIR=/tmp
# - API_ACCESS_KEY is the SECRET key used to access the mecsimcalc private API 
ARG API_ACCESS_KEY
ENV API_ACCESS_KEY=$API_ACCESS_KEY
