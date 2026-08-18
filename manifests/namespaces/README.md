# namespaces

`Namespace` manifests, one file per namespace, carrying whatever cluster-wide labels apply to it.

Every namespace is labeled with [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) levels. EKS enables PSA by default but with no cluster-wide restrictive default, so a namespace stays on `privileged` until it's labeled otherwise here.

Namespaces opted into `manifests/network-policies/cluster-wide` also carry `network-policy: default-deny`, mirrored by Cilium onto every pod's identity in that namespace.

`kube-system`, `monitoring`, and `tailscale` are kept on `privileged`: they run components (the VPC CNI, kube-proxy, `prometheus-node-exporter`, the Tailscale Connector's proxy pod) that need `hostNetwork`, `hostPID`, `hostPath`, or `NET_ADMIN`, none of which `baseline` allows.
