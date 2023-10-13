# ArgoCD multi-tenancy example

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
    - name: ARGOCD_CLUSTER_CONFIG_NAMESPACES
      value: argocd-cluster-scope
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

### Configure RBAC cluster-scope

## Create ArgoCD instance namespace-scope

### Configure RBAC cluster-scope