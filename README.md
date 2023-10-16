# ArgoCD multi-tenancy example

## Create users

We need two users `userA` and `userB`. If you are using CodeReady Containers you can use this script

```bash
./scripts/createUsers.sh
```

#TODO ver si me cargo el user admin del cluster

Then we create per each user:
- Namespace for applications
- Namespace for ArgoCD instance
- Group
- Role Binding for each user as admin to their namespace

```bash
oc apply -f files/gitops-group-users.yaml
```

## Create Openshift GitOps subscription

- The Argo CD operator supports high availability through the mechanism described in the Argo CD documentation.
  - https://argocd-operator.readthedocs.io/en/latest/usage/ha/
  - https://argo-cd.readthedocs.io/en/stable/operator-manual/high_availability/
```yaml
spec:
  ha:
    enabled: true
```

- We are going to configure Openshift GitOps to do not create the default cluster-wide ArgoCD instance.
```yaml
spec:
  config:
    env:
    - name: DISABLE_DEFAULT_ARGOCD_INSTANCE
      value: "true"
```

- We are going to configure Openshift GitOps to create ArgoCD instance cluster-scope in the namespace `argocd-cluster-scope`.
```yaml
spec:
  config:
    env:
    - name: ARGOCD_CLUSTER_CONFIG_NAMESPACES
      value: argocd-cluster-scope
```

- We are going to configure Openshift GitOps to do not create link to default instance.
```yaml
spec:
  config:
    env:
    - name: DISABLE_DEFAULT_ARGOCD_CONSOLELINK
      value: 'true'
```

- We will also be able to create ArgoCD instance namespaces-scope.
- Create Openshift GitOps subscription
```bash
oc apply -f files/openshift-gitops-subscription.yaml
```

- Useful documentation:
  - https://developers.redhat.com/articles/2023/03/06/5-global-environment-variables-provided-openshift-gitops#customizing_with_environment_variables 
  - https://docs.openshift.com/gitops/1.9/declarative_clusterconfig/configuring-an-openshift-cluster-by-deploying-an-application-with-cluster-configurations.html 
  - https://argocd-operator.readthedocs.io/en/latest/usage/ha/

## Create ArgoCD instance cluster-scope

```bash
oc apply -f files/argocd-instance-cluster.yaml
```

### Configure RBAC cluster-scope


oc extract secret/openshift-gitops-cluster -n argocd-cluster-scope --to=-

kubeadmin no puede hacer nada, no tiene el role:admin
userA puede hacer login!!
## Create ArgoCD instance namespace-scope

oc apply -f files/argocd-instance-group-a.yaml

oc extract secret/openshift-gitops-group-a-cluster -n gitops-group-a --to=-


### Configure RBAC cluster-scope




- Useful documentation:
  - https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/
  - https://cloud.redhat.com/blog/a-guide-to-using-gitops-and-argocd-with-rbac