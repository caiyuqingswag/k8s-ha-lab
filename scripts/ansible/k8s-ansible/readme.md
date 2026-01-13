    ##顺序执行update
ansible-playbook -i inventory.ini site.yml --tags update -f 6  

    ##重启然后继续执行
ansible-playbook -i inventory.ini site.yml --tags common
ansible-playbook -i inventory.ini site.yml --tags lb





    ##一键执行
cd k8s-ansible
ansible -i inventory.ini all -m ping
ansible-playbook -i inventory.ini site.yml

    ##部署完成后在 master1 验证：
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl get nodes -o wide
kubectl get pods -A

    #后续新增节点则inventory.ini添加新节点的ip
ansible-playbook -i inventory.ini add-workers.yml --limit 172.16.15.57,172.16.15.58



