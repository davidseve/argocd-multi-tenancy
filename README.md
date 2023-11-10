# ArgoCD multi-tenancy example

## Create namespaces

- Namespaces for the workloads. As an administrative user, when you give Argo CD access to a namespace by using the `argocd.argoproj.io/managed-by`` label, it assumes namespace-admin privileges.
```bash
oc apply -f files/namespaces-for-workloads.yaml
```

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

Then we create per each user:
- Group
- Role Binding for each user as admin to their namespace

```bash
oc apply -f files/gitops-group-users.yaml
```

## Create Openshift GitOps subscription

- Configure Openshift GitOps to do not create the default cluster-wide ArgoCD instance.
```yaml
spec:
  config:
    env:
    - name: DISABLE_DEFAULT_ARGOCD_INSTANCE
      value: "true"
```

- Create Openshift GitOps subscription
```bash
oc apply -f files/openshift-gitops-subscription.yaml
```


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

- Configure our admin user with admin role
```yaml
spec:
  rbac:
    policy: |-
      # Admin privileges to admin user
      g, kubeadmin, role:admin # CRC Admin user
```

### Create instance
- Create the ArgoCD instance for all groups.
```bash
oc apply -f files/argocd-instance-namespace-scope.yaml
```

## ArgoCD projects
- Create project `group-a-p` and `group-b-p`, one for each group.
- For each group we define the destinations. In this example only its namespace:

```yaml
spec:
  destinations:
    - namespace: group-a-namespace
      server: https://kubernetes.default.svc 
```

- Finally we create the projects.
```bash
oc apply -f files/argocd-projects.yaml
```
## Create ArgoCD appofapps to validate privileges

Create the appOfApps in the user with the userA

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: group-a-app-of-apps
  namespace: argocd-instance
spec:
  destination:
    namespace: argocd-instance
    server: 'https://kubernetes.default.svc'
  project: group-a-p
  source:
    repoURL: https://github.com/davidseve/argocd-multi-tenancy.git
    path: files/applications
    targetRevision: deploy-in-forbidden-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

