oc apply -f files/namespaces-for-workloads.yaml
oc apply -f files/namespaces-for-argocd-instance.yaml
./scripts/createUsersCRC.sh
oc apply -f files/gitops-group-users.yaml
oc apply -f files/argocd-controller-role-exclusions.yaml
oc apply -f files/openshift-gitops-subscription.yaml
sleep 3m
oc apply -f files/argocd-instance-cluster.yaml
oc apply -f files/argocd-projects.yaml


