#Apache Hadoop 2.7.2 Docker image - hadoop and native libs built from scratch

Uses OpenJDK 7.

```
# Build hadoop and native libs
$ docker build --tag=hadoop-ubuntu-native:2.7.2 .
```

```
# Use it
$ docker run -it hadoop-ubuntu-native:2.7.2 /etc/bootstrap.sh -bash
```

```
# Test it

cd $HADOOP_PREFIX
# run the mapreduce
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.0.jar grep input output 'dfs[a-z.]+'

# check the output
bin/hdfs dfs -cat output/*
```

Based on the sequenceiq build - https://hub.docker.com/r/sequenceiq/hadoop-docker/
