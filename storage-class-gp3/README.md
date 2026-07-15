# storage-class-gp3

Defines the default `gp3` `StorageClass`, backed by the [EBS CSI driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html), used by any `PersistentVolumeClaim` that doesn't request a storage class explicitly.

## What's Inside

- **[storageclass.yaml](storageclass.yaml)**: uses `WaitForFirstConsumer` binding mode so the volume is provisioned in the same availability zone as the pod that claims it, instead of an arbitrary zone at claim time

## Upstream Dependencies

- **[`ebs_csi_driver`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/ebs_csi_driver)** (catalog): provisions the IAM role and installs the EBS CSI driver as an EKS managed addon. Without it healthy, this `StorageClass` exists but any `PersistentVolumeClaim` bound to it stays `Pending`, since there's no provisioner to satisfy the claim
