FROM fedora:latest
WORKDIR /ps3linux

RUN dnf upgrade -y
RUN dnf install nano git -y
RUN git clone https://github.com/ModelCitizenPS3/ps3linux-releng.git /ps3linux

ENTRYPOINT ["./PS3LINUX_docker_script.sh"]
