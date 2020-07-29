#!/bin/sh

# This script will configure the loadbalancer with nginx to proxy traffic between all nodes.
echo $K8S_MASTERS > /k8s-masters.log