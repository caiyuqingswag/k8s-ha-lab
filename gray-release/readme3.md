export PATH=$PATH:/root/istio/istio-1.28.2/bin

#创建 Waypoint 使用l7
istioctl waypoint apply -n saas --name saas-waypoint

