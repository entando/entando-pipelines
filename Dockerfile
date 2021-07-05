FROM ubuntu:21.04
WORKDIR /opt/ppl
ADD . /opt/ppl
RUN cd /opt/ppl && ls
CMD prj/run-tests.sh
