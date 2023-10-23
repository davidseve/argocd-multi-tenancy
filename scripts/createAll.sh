oc apply -f files/namespaces-for-workloads.yaml
oc apply -f files/namespaces-for-argocd-instance.yaml
./scripts/createUsersCRC.sh
oc apply -f files/gitops-group-users.yaml
oc apply -f files/openshift-gitops-subscription.yaml
sleep 3m
oc apply -f files/argocd-instance-namespace-scope.yaml
oc apply -f files/argocd-projects.yaml

oc login -u userA -p userA https://api.crc.testing:6443
oc apply -f files/applications/application-example-wrong-namespace.yaml
oc apply -f files/applications/application-example-wrong-project.yaml
oc apply -f files/applications/application-example.yaml
