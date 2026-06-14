# Runbook: Service Down

## Symptoms

- `ServiceDown`
- Service endpoint count is zero.
- Deployment or StatefulSet pods are not ready.

## Diagnosis

1. Check workload rollout status.
2. Check Pods, Events, and container restart count.
3. Check Service selector and Endpoints.
4. Query recent application errors from Loki.
5. Query upstream and downstream traces from Tempo.

## Remediation

Low risk:

- Collect diagnostics.
- Check rollout status.

Medium risk:

- Restart stateless Deployment.
- Scale replicas.
- Roll back recent release.

High risk:

- Delete PVC.
- Modify production Secret.
- Change database state.
