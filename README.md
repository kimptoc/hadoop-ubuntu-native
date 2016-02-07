#Apache Hadoop 2.7.2 Docker image - hadoop and native libs built from scratch
```
# Build/share hadoop and native

$ docker build --tag=hadoop-ubuntu-native:2.7.2 .

$ docker run -it hadoop-ubuntu-native:2.7.2 /etc/bootstrap.sh -bash

# sshd not starting in runtime container... no service/centos7?

```
Based on the sequenceiq build - https://hub.docker.com/r/sequenceiq/hadoop-docker/
