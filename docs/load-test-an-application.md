{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

# How to Load Test an Application

This guide shows you how to send load to an app with [k6](https://grafana.com/docs/k6/latest/), from inside the cluster, and watch how it scales. You need it when you want to check an app's autoscaling or capacity before real traffic does (e.g. before a release). It assumes you've created a branch in your app of apps fork, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch).

If you're new to load testing in EKS Forge, read [How Load Testing Works](/docs/applications/load-testing/how-load-testing-works/) first.

Every file below goes next to your app's files: in `manifests/<name>/` for plain manifests, or in `templates/` for a Helm chart.

## Add an HPA

If your app must scale its pods with the load and has no HPA yet, add a [`HorizontalPodAutoscaler`](https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/) that targets your app's `Deployment`, with its range of replicas and the CPU usage to hold. For example, [`manifests/podinfo/podinfo-hpa.yaml`](../manifests/podinfo/podinfo-hpa.yaml):
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: podinfo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: podinfo
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  ...
```

Then, in the `Deployment`:
- Remove `replicas`. The HPA sets it, and ArgoCD would revert it to the manifest's value on every sync.
- Set a CPU `requests` on every container, since the HPA measures usage as a share of it (see [Right-Size a Workload](/docs/compute/right-size-a-workload/)).

To scale on a custom metric instead (e.g. the length of a queue), see [KEDA](https://keda.sh/), which EKS Forge doesn't deploy.

## Write the k6 Script

Add a `ConfigMap` named `k6-loadtest-script`, holding the script under its `script.js` key. In the script, set:
- The URL of your app's `Service`, as `http://<service>.<namespace>.svc.cluster.local:<port>/`, with the `Service` port.
- The `stages`: each one ramps the number of virtual users to its `target`, over its `duration`.

For example, [`manifests/podinfo/k6-loadtest-script.yaml`](../manifests/podinfo/k6-loadtest-script.yaml) ramps up to 50 virtual users, then back down:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: k6-loadtest-script
data:
  script.js: |
    import http from 'k6/http';

    export const options = {
      scenarios: {
        gaussian_load: {
          executor: 'ramping-vus',
          startVUs: 0,
          stages: [
            { duration: '45s', target: 2 },
            ...
            { duration: '45s', target: 50 },
            ...
            { duration: '45s', target: 2 },
          ],
          gracefulRampDown: '15s',
        },
      },
    };

    export default function () {
      http.get('http://podinfo.podinfo.svc.cluster.local:9898/');
    }
```

For another load shape, see k6's [Executors](https://grafana.com/docs/k6/latest/using-k6/scenarios/executors/).

## Add the CronJob

Copy [`manifests/podinfo/k6-loadtest-cronjob.yaml`](../manifests/podinfo/k6-loadtest-cronjob.yaml) next to your app's files, unchanged. It's suspended, so it never runs on its own, and it mounts the `k6-loadtest-script` `ConfigMap`:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: k6-loadtest
spec:
  schedule: "0 0 1 1 *"
  suspend: true
  jobTemplate:
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels:
            app.kubernetes.io/name: k6-loadtest
        spec:
          ...
          containers:
            - name: k6
              image: grafana/k6
              command: ["k6", "run", "/script/script.js"]
              ...
          volumes:
            - name: script
              configMap:
                name: k6-loadtest-script
            ...
```

For its other fields, see Kubernetes' [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) docs.

It runs k6 on the `elastic` NodePool. To place it elsewhere, see [Schedule Pods](/docs/compute/schedule-pods/).

## Allow the Traffic

Your namespace denies all traffic by default, so allow k6's requests at both ends. If your app has no network policy yet, follow [Write Network Policies](/docs/security/write-network-policies/) first.

Copy [`manifests/podinfo/k6-loadtest-network-policy.yaml`](../manifests/podinfo/k6-loadtest-network-policy.yaml) next to your app's files. Under `egress`, set your app's pod labels and its container port, not the `Service` port:
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: k6-loadtest
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: k6-loadtest
  egress:
    - toEndpoints:
        - matchLabels:
            app: podinfo
      toPorts:
        - ports:
            - port: "9898"
              protocol: TCP
```

Then, in your app's own policy, allow ingress from k6 on the same port. For example, in [`manifests/podinfo/podinfo-network-policy.yaml`](../manifests/podinfo/podinfo-network-policy.yaml):
```yaml
  ingress:
    ...
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: k6-loadtest
      toPorts:
        - ports:
            - port: "9898"
              protocol: TCP
```

## Deploy to Dev

Deploy your change to `dev` by following [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev), up to the sync. Then check that the `CronJob` exists, with `True` in its `SUSPEND` column, replacing `<namespace>` with your app's namespace:
```bash
kubectl get cronjob k6-loadtest -n <namespace>
```

## Run the Load Test

Create a `Job` from the `CronJob`, replacing `<job>` with a name for this run (e.g. `k6-loadtest-1`):
```bash
kubectl create job --from=cronjob/k6-loadtest <job> -n <namespace>
```

Each run needs a new name, unless you delete the previous `Job` first (see [Clean Up](#clean-up)).

## Watch the App Scale

Follow k6's output. It ends with a summary of the run, including the share of failed requests (`http_req_failed`) and the response times (`http_req_duration`):
```bash
kubectl logs -f job/<job> -n <namespace>
```

In another terminal, watch the HPA add replicas as the load grows, then remove them:
```bash
kubectl get hpa -n <namespace> -w
```

If its `TARGETS` column still shows `<unknown>` after a minute, the HPA can't read the CPU usage. Its events say why, most often a container with no CPU `requests` (see [Add an HPA](#add-an-hpa)):
```bash
kubectl describe hpa -n <namespace>
```

If every request fails, a network policy is dropping them. See [Find Dropped Traffic](/docs/security/write-network-policies/#find-dropped-traffic).

## Clean Up

Delete the `Job` once you've read its output:
```bash
kubectl delete job <job> -n <namespace>
```

To try another load, edit the `stages`, then push, sync, and run again.

Then open a pull request and merge it, as in [Open a Pull Request](/docs/applications/add-edit-or-remove-an-app/#open-a-pull-request). The `CronJob` ships to `staging` and `prod` with your next release, and stays suspended there until someone triggers it.
