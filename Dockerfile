FROM ubuntu:20.10
RUN apt update && apt install -y git jq xmlstarlet
WORKDIR /opt/ppl
ENV ENTANDO_OPT_SUDO="-"
ADD . /opt/ppl
RUN ./macro/install.sh
CMD prj/run-tests.sh
