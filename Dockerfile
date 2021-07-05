FROM ubuntu:20.10
WORKDIR /opt/ppl
ENV ENTANDO_OPT_SUDO="-"
ADD . /opt/ppl
CMD prj/run-tests.sh
