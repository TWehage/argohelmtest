Create deploy user:
```
kubectl -n settings-stage apply -f deploy-user.yml
```

Get user token name: (setstg-actions-deploy)
```
kubectl describe sa setstg-deploy-user -n settings-stage 
```

Get secret token:
```
kubectl describe secrets setstg-actions-deploy -n settings-stage
```

Create base64 encoded DEPLOY_ACCOUNT Secret:
```
cat kubeconfig.txt | base64
```
-> use in Repo->Settings->Secrets and variables->Actions->Repository Secrets (DEPLOY_ACCOUNT -> #TOKEN#)