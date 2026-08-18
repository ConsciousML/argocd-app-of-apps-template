# namespaces

`Namespace` manifests, one file per namespace, carrying whatever cluster-wide labels apply to it.

Every namespace is labeled with [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) levels. EKS enables PSA by default but with no cluster-wide restrictive default, so a namespace stays on `privileged` until it's labeled otherwise here.
