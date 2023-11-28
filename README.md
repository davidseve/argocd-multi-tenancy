# ArgoCD multi-tenancy example

To achieve a multi-tenancy architecture it is very useful to use Applications in any namespace

## Applications in any namespace
When this documentation is done this feature is in Beta state.
Here we have the official documentation and the current status: 
https://argo-cd.readthedocs.io/en/stable/operator-manual/app-any-namespace/

We have to take into account that Applications in any namespace needs Cluster-scoped Argo CD installation.

There is already an issue to promote to stable this feature: https://github.com/argoproj/argo-cd/issues/16189

We have to take into account that there is a different feature to support ApplicationSet in any namespace.

## ApplicationSet in any namespace

When this documentation is done this feature is in Beta state.
Here we have the official documentation and the current status: 
https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Appset-Any-Namespace/

We have to take into account that ApplicationSet in any namespace needs Cluster-scoped Argo CD installation.

We have to take into account that this feature work in combination Applications with  in any namespace.

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
  - https://docs.openshift.com/gitops/1.10/argocd_instance/argo-cd-cr-component-properties.html#argo-cd-properties_argo-cd-cr-component-properties

## Create ArgoCD instance cluster-scope

### Configure RBAC cluster-scope

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

- Configure our admin user with admin role
```yaml
spec:
  rbac:
    policy: |-
      # Admin privileges to admin user
      g, kubeadmin, role:admin # CRC Admin user
```

- New ArgoCD role for each group with access to the cluster. Later in the ArgoCD project we will add privileges to the new roles.

```yaml
spec:
  rbac:
    policy: |-
      p, role:clusters-get, clusters, get, https://kubernetes.default.svc, allow
      g, group-all, role:clusters-get

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
      groups:
        - "group-all"
      openShiftOAuth: true
    provider: dex
```
- Useful documentation:
  - https://github.com/redhat-developer/gitops-operator/blob/master/docs/OpenShift%20GitOps%20Usage%20Guide.md#working-with-dex



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

### Create instance
- Create the ArgoCD instance for all groups.
```bash
oc apply -f files/argocd-instance-cluster.yaml
```

## ArgoCD projects
- Create project `group-a-p` and `group-b-p`, one for each group.
- For each group we define the destinations. In this example only its namespace:
```yaml
spec:
  destinations:
    - namespace: group-a-na
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
          p, proj:group-a-p:developers, applications, get,
          group-a/*, allow
        - >-
          p, proj:group-a-p:developers, applications, create,
          group-a/*, allow
        - >-
          p, proj:group-a-p:developers, applications, update,
          group-a/*, allow
        - >-
          p, proj:group-a-p:developers, applications, delete,
          group-a/*, allow
        - >-
          p, proj:group-a-p:developers, applications, sync,
          group-a/*, allow
        - >-
          p, proj:group-a-p:developers, applications, override,
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
kind: Application
metadata:
  name: group-a-wrong-namespace
  namespace: argocd-instance
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
    namespace: group-a-na
    server: 'https://kubernetes.default.svc'
  project: group-b-p
```
```bash
oc login -u userA -p userA
oc apply -f files/applications/application-example-wrong-project.yaml
```
Error message: application 'group-a-wrong-project' in namespace 'group-a-na' is not permitted to use project 'group-b-p'

### Right configuration
- Successfully application creation in the right project and namespace.
```yaml
spec:
  destination:
    namespace: group-a-na
    server: 'https://kubernetes.default.svc'
  project: group-a-p
```

```bash
oc login -u userA -p userA
oc apply -f files/applications/application-example.yaml
```


- Useful documentation:
  - https://argocd-notifications.readthedocs.io/en/stable/
## ArgoCD Monitoring

- Useful documentation:
  - https://github.com/redhat-developer/gitops-operator/blob/master/docs/OpenShift%20GitOps%20Usage%20Guide.md#monitoring

## How to configure ArgoCD at scale
https://aws.amazon.com/es/blogs/opensource/argo-cd-application-controller-scalability-testing-on-amazon-eks/