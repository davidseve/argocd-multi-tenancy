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
  - https://developers.redhat.com/articles/2021/08/03/managing-gitops-control-planes-secure-gitops-practices
  - https://argocd-operator.readthedocs.io/en/latest/usage/ha/


## Create ArgoCD instance namespace-scope

### Configure RBAC cluster-scope

- New ArgoCD role with no privileges and we set it as `defaultPolicy` 
```yaml
spec:
  rbac:
    defaultPolicy: 'role:none'
    policy: |-
      # Default policy with no privileges
      p, role:none, applications, get, */*, deny
      p, role:none, certificates, get, *, deny
      p, role:none, clusters, get, *, deny
      p, role:none, repositories, get, *, deny
      p, role:none, projects, get, *, deny
      p, role:none, accounts, get, *, deny
      p, role:none, gpgkeys, get, *, deny
```

- Configure our admin user wiht admin role
```yaml
spec:
  rbac:
    policy: |-
      # Admin privileges to admin user
      g, kubeadmin, role:admin
```

- New ArgoCD role for each group with access to the cluster. Later in the ArgoCD project we will add privileges to the new roles.

```yaml
spec:
  rbac:
    policy: |-
      #Privileges at project level
      g, group-a, role:group-a
      p, role:group-a, clusters, get, https://kubernetes.default.svc, allow

      g, group-b, role:group-b
      p, role:group-b, clusters, get, https://kubernetes.default.svc, allow

```

- Define the scopes for groups end names
```yaml
spec:
  rbac:
    scopes: '[groups,name]'
```

- Useful documentation:
  - https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/
  - https://cloud.redhat.com/blog/a-guide-to-using-gitops-and-argocd-with-rbac

### Single Sing On
You can log into the default Argo CD instance in the openshift-gitops namespace using the OpenShift or kubeadmin credentials. As an admin you can disable the Dex installation after the Operator is installed which will remove the Dex deployment from the openshift-gitops namespace.

```yaml
  sso:
    dex:
      openShiftOAuth: true
      resources:
        limits:
          cpu: 500m
          memory: 256Mi
        requests:
          cpu: 250m
          memory: 128Mi
    provider: dex
```
- Useful documentation:
  - https://github.com/redhat-developer/gitops-operator/blob/master/docs/OpenShift%20GitOps%20Usage%20Guide.md#working-with-dex


Seguir por aqui: https://github.com/redhat-developer/gitops-operator/blob/master/docs/OpenShift%20GitOps%20Usage%20Guide.md#setting-up-a-new-argo-cd-instance


### Controller
TODO
### Server
TODO
### Repo
TODO
### Redis
TODO
### Grafana
TODO
### Monitoring
TODO
### Prometheus
TODO
### Applications Set
TODO
### Resource Health Check
TODO
### Hing Availability
TODO
### Create instance
```bash
oc apply -f files/argocd-instance-group-a.yaml
```

## ArgoCD projects
TODO
## ArgoCD Notifications
TODO
## Create ArgoCD instance cluster-scope in not default namespace
TODO?


### Configure RBAC cluster-scope



kubeadmin no puede hacer nada, no tiene el role:admin
userA puede hacer login!!
puedo crear aplicaciones en otro namespace sin el label
puedo crear aplicaciones en otro namespace con el label

### Create instance
```bash
oc apply -f files/argocd-instance-cluster.yaml
```
