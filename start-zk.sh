#!/usr/bin/env bash

# Setup Zookeeper
sed -i -r 's|#(log4j.appender.ROLLINGFILE.MaxBackupIndex.*)|\1|g' $ZK_HOME/conf/log4j.properties
sed -i -r 's|#autopurge|autopurge|g' $ZK_HOME/conf/zoo.cfg

# Start sshd
/usr/sbin/sshd

# Start Zookeeper
/opt/zookeeper-3.4.13/bin/zkServer.sh start-foreground
