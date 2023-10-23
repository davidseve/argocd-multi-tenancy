# ArgoCD multi-tenancy example

## ArgoCD architecture
TODO

## Create namespaces

- Namespaces for the workloads. As an administrative user, when you give Argo CD access to a namespace by using the `argocd.argoproj.io/managed-by`` label, it assumes namespace-admin privileges.
```bash
oc apply -f files/namespaces-for-workloads.yaml
```

- Useful documentation:
  - https://github.com/redhat-developer/gitops-operator/blob/master/docs/OpenShift%20GitOps%20Usage%20Guide.md#deploy-resources-to-a-different-namespace-with-custom-role

- Namespace for the ArgoCD instance.
```bash
oc apply -f files/namespaces-for-argocd-instance.yaml
```

## Create users

We need two users `userA` and `userB`. 

- If you are using CodeReady Containers you can use this script:
```bash
./scripts/createUsersCRC.sh
```

- Else you can use this script:
```bash
./scripts/createUsersOCP.sh
```

Then we create per each user:
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

- Configure Openshift GitOps to do not create the default cluster-wide ArgoCD instance.
```yaml
spec:
  config:
    env:
    - name: DISABLE_DEFAULT_ARGOCD_INSTANCE
      value: "true"
```

- Configure Openshift GitOps to create ArgoCD instance cluster-scope in the namespace `argocd-cluster-scope`.
```yaml
spec:
  config:
    env:
    - name: ARGOCD_CLUSTER_CONFIG_NAMESPACES
      value: argocd-cluster-scope
```

- Configure Openshift GitOps to do not create link to default instance.
```yaml
spec:
  config:
    env:
    - name: DISABLE_DEFAULT_ARGOCD_CONSOLELINK
      value: 'true'
```

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

### Configure RBAC namespace-scope

- Create a ArgoCD role with no privileges and we set it as `defaultPolicy` 
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
TODO user admin en ocp no es admin

- Configure our admin user with admin role
```yaml
spec:
  rbac:
    policy: |-
      # Admin privileges to admin user
      g, kubeadmin, role:admin # CRC Admin user
      g, system:cluster-admins, role:admin
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
You can log into the default Argo CD instance using the OpenShift users or kubeadmin credentials. As an admin you can disable the Dex installation after the Operator is installed which will remove the Dex deployment from the openshift-gitops namespace.

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

https://docs.openshift.com/gitops/1.10/argocd_instance/argo-cd-cr-component-properties.html#argo-cd-properties_argo-cd-cr-component-properties

### Configure resource quota/requests for OpenShift GitOps workloads

- ArgoCD instance example:
```yaml
apiVersion: argoproj.io/v1beta1
kind: ArgoCD
metadata:
  name: example
spec:
  server:
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 125m
        memory: 128Mi
    route:
      enabled: true
  applicationSet:
    resources:
      limits:
        cpu: '2'
        memory: 1Gi
      requests:
        cpu: 250m
        memory: 512Mi
  repo:
    resources:
      limits:
        cpu: '1'
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
  sso:
    dex:
      resources:
        limits:
          cpu: 500m
          memory: 256Mi
        requests:
          cpu: 250m
          memory: 128Mi
  redis:
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 250m
        memory: 128Mi
  controller:
    resources:
      limits:
        cpu: '2'
        memory: 2Gi
      requests:
        cpu: 250m
        memory: 1Gi
```

- Useful documentation:
  - https://github.com/redhat-developer/gitops-operator/blob/master/docs/OpenShift%20GitOps%20Usage%20Guide.md#in-built-permissions-for-cluster-configuration
### Controller
TODO
### Server
TODO
```yaml
  server:
    route:
      enabled: true #creates an openshift route to access Argo CD UI
    autoscale:
      enabled: false
    grpc:
      ingress:
        enabled: false
    ingress:
      enabled: false
    service:
      type: ''
```
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
- Create the ArgoCD instance for all groups.
```bash
oc apply -f files/argocd-instance-namespace-scope.yaml
```

## ArgoCD projects
- Create project `group-a` and `group-b`, one for each group.
- For each group we define the destinations. In this example only its namespace:
```yaml
spec:
  destinations:
    - namespace: group-a
      server: https://kubernetes.default.svc 
```
- Define the roles and privileges for each project. In this example only for user that belongs to group-a.
```yaml
  roles:
    - description: Group to developers to deploy on DEV environment
      groups:
        - group-a
      name: developers
      policies:
        - >-
          p, proj:group-a:developers, applications, get,
          group-a/*, allow
        - >-
          p, proj:group-a:developers, applications, create,
          group-a/*, allow
        - >-
          p, proj:group-a:developers, applications, update,
          group-a/*, allow
        - >-
          p, proj:group-a:developers, applications, delete,
          group-a/*, allow
        - >-
          p, proj:group-a:developers, applications, sync,
          group-a/*, allow
        - >-
          p, proj:group-a:developers, applications, override,
          group-a/*, allow
```

- Finally we create the projects.
```bash
oc apply -f files/argocd-projects.yaml
```
## Create ArgoCD applications to validate privileges

### Wrong namespace
- Error if we create applications in a namespace that is not configure in the project.
```yaml
spec:
  destination:
    namespace: group-b
    server: 'https://kubernetes.default.svc'
  project: group-a
```
```bash
oc login -u userA -p userA
oc apply -f files/applications/application-example-wrong-namespace.yaml
```
### Wrong ArgoCD project
- Error if we create applications in a project that is not configure for this use.
```yaml
spec:
  destination:
    namespace: group-a
    server: 'https://kubernetes.default.svc'
  project: group-b
```
```bash
oc login -u userA -p userA
oc apply -f files/applications/application-example-wrong-project.yaml
```
### Right configuration
- Successfully application creation in the right project and namespace.
```yaml
spec:
  destination:
    namespace: group-a
    server: 'https://kubernetes.default.svc'
  project: group-a
```

```bash
oc login -u userA -p userA
oc apply -f files/applications/application-example.yaml
```
## ArgoCD Notifications
TODO

- Useful documentation:
  - https://argocd-notifications.readthedocs.io/en/stable/
## ArgoCD Monitoring
TODO

- Useful documentation:
  - https://github.com/redhat-developer/gitops-operator/blob/master/docs/OpenShift%20GitOps%20Usage%20Guide.md#monitoring