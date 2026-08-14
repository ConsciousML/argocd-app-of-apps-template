# network-policies/namespace

Per-namespace default-deny `CiliumNetworkPolicy`, one file per namespace, filename matches namespace name. Selects every pod in the namespace with no rules, so anything not covered by a more specific `CiliumNetworkPolicy` gets no traffic in either direction (`ingress`/`egress` rule sets from all policies selecting a pod are unioned, so this only restricts pods without their own allow rules).
