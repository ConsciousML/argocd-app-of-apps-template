<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/manifests/namespaces/. It is not meant to be read directly in this repository. -->

# `namespaces` Manifests Reference

The [`namespaces` manifests](./) define one `Namespace` per file, named after the namespace, carrying its cluster-wide labels.

## What's Inside

- **[*.yaml](./)**: each file sets the [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) `enforce`, `warn`, and `audit` labels. Namespaces running privileged pods use `privileged` for all three. The rest enforce `baseline`, and warn and audit at `restricted`

## Pod Security Admission Defaults

<!-- MIGRATE: explanation, move to the site's explanation docs -->
EKS enables PSA by default but with no cluster-wide restrictive default, so a namespace stays on `privileged` until it's labeled otherwise here.
