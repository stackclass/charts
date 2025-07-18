# StackClass Helm Charts

This repository hosts official [Helm](https://helm.sh) charts for
[StackClass](https://stackclass.dev). These charts are used to deploy
StackClass to Kubernetes.

[![Release Charts](https://github.com/stackclass/charts/actions/workflows/release.yml/badge.svg)](https://github.com/stackclass/charts/actions/workflows/release.yml)
[![License](https://img.shields.io/github/license/stackclass/charts)](https://github.com/stackclass/charts/blob/main/LICENSE)
[![GitHub contributors](https://img.shields.io/github/contributors/stackclass/charts)](https://github.com/stackclass/charts/graphs/charts)
[![GitHub issues](https://img.shields.io/github/issues/stackclass/charts)](https://github.com/stackclass/charts/issues)

## Usage

### Pre-requisites

- Kubernetes 1.19+
- Helm 3.9.0+
- PV provisioner support in the underlying infrastructure
- ReadWriteMany volumes for deployment scaling

### Add Helm Repository

```sh
helm repo add stackclass https://charts.stackclass.dev
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages. You can then run `helm search repo
stackclass` to see the charts.

### Install StackClass

> **Important Notes**: By default, this installs PostgreSQL (see [PostgreSQL
  config](#postgresql) for credentials). To customize (e.g., disable PostgreSQL
  or adjust storage), use `-f values.yaml` or `--set` after reviewing the
  [Configuration](#configuration) section.

To install StackClass for the first time with the release name `stackclass`:

```sh
helm install stackclass stackclass/stackclass --create-namespace -n=stackclass
```

This command deploys the StackClass API Server, frontend, and services on your
Kubernetes cluster with default configurations.

### Upgrade StackClass

To upgrade an existing StackClass deployment (e.g., after modifying `values.yaml`):

```sh
helm upgrade stackclass stackclass/stackclass -n=stackclass
```

**Optional Flags:**

- `--atomic`: Automatically rollback if the upgrade fails.
- `--wait`: Wait for all resources to be ready before marking the upgrade as complete.
- `-f values.yaml`: Override default values with a custom configuration file.

Example with atomic upgrade:

```sh
helm upgrade stackclass stackclass/stackclass -n=stackclass --atomic --wait
```

### Uninstall StackClass

To uninstall the chart and remove all associated Kubernetes resources:

```sh
helm uninstall stackclass -n=stackclass
```

## Configuration

### PostgreSQL

PostgreSQL is enabled by default (`postgresql.enabled=true`). It will be
automatically deployed with generated credentials.

**Using External PostgreSQL**:

1. Disable the built-in PostgreSQL:
  ```sh
  helm install stackclass stackclass/stackclass --set postgresql.enabled=false
  ```
2. Manually update these secrets:
  - `backend-secrets.yaml`: Replace `DATABASE_URL`
  - `frontend-secrets.yaml`: Replace `BETTER_DATABASE_URL`

### Application Configuration

This chart manages application settings through Kubernetes Secrets. By default, it creates:
- `{release-name}-backend-secrets`
- `{release-name}-frontend-secrets`

**Dynamic Secrets**
Some secrets are dynamically generated during installation or upgrade:

**BETTER_AUTH_SECRET`**: A 32-character random string is automatically generated
for authentication.

```yaml
BETTER_AUTH_SECRET: {{ randAlphaNum 32 | quote }}
```

**Customizable Secrets**:

Other secrets must be explicitly provided by the user:

- **`GITHUB_CLIENT_ID`**: Replace `<REPLACE_WITH_GITHUB_CLIENT_ID>` with your
  GitHub OAuth client ID.
- **`GITHUB_CLIENT_SECRET`**: Replace `<REPLACE_WITH_GITHUB_CLIENT_SECRET>` with
  your GitHub OAuth client secret.

1. **Before installation**:
  Modify `values.yaml` or use `--set` to override secret values. For example:

  ```yaml
  # Other options ...
  --set frontend.secrets.githubClientId="your-client-id" \
  --set frontend.secrets.githubClientSecret="your-client-secret"
  ```

2. **After installation**:
  Edit secrets directly (changes persist through upgrades):

  ```sh
  kubectl edit secret stackclass-backend-secrets -n stackclass
  kubectl edit secret stackclass-frontend-secrets -n stackclass
  ```

**Key Configuration Files**:
- Backend: Refer to `charts/stackclass/templates/secrets/backend-secrets.yaml`
- Frontend: Refer to `charts/stackclass/templates/secrets/frontend-secrets.yaml`
- Environment templates: Check each component's `.env.example` for available variables.

### Storage

This chart configures persistent storage for PostgreSQL and backend services.
All volumes use `ReadWriteOnce` access mode by default.

When left unspecified or set to an empty string (`storageClass: ""`), the chart
will automatically use your Kubernetes cluster's default StorageClass for
dynamic volume provisioning. If you need to use a specific storage backend
(e.g., AWS gp3, Azure managed-premium, or GCP standard), you can explicitly
specify the StorageClass name.

> 💡 Run `kubectl get storageclass` to see available classes in your cluster.

**PostgreSQL** uses 10Gi of storage with your cluster's default StorageClass.

```yaml
postgresql:
  primary:
    persistence:
      size: 10Gi
      storageClass: ""
```

**Backend** defaults to 10Gi with cluster-default storage.

```yaml
backend:
  persistence:
    size: 10Gi
    storageClass: ""
```

### Ingress

#### Ingress Class

By default, the Ingress resources will use the cluster's default Ingress
Controller (e.g., Traefik for k3s, ALB for EKS). Below is a table summarizing
the configurations for different platforms:

| Platform          | Ingress Class | Documentation |
|-------------------|---------------|---------------|
| **k3s (Traefik)** | `traefik`     | [Traefik Docs](https://doc.traefik.io/traefik/) |
| **AWS EKS (ALB)** | `alb`         | [AWS ALB Docs](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html) |
| **GKE (GCE)**     | `gce`         | [GKE Ingress Docs](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress) |
| **Standard**      | `nginx`       | [Nginx Ingress Docs](https://kubernetes.github.io/ingress-nginx/) |

**Notes:**

- If `className` is left empty, the cluster will use its default Ingress Controller.
- `annotations` are only required for overriding controller-specific behaviors.

#### Hostname

The default `host` values are configured for testing purposes:

- Frontend: `stackclass.local`
- Backend: `api.stackclass.local`

For production environments, you should override these values using `--set` or a
custom `values.yaml` file. For example:

```sh
# Other options ...
--set frontend.ingress.host=your-frontend-domain.com \
--set backend.ingress.host=your-backend-domain.com
```

#### TLS Support

To enable TLS for the Ingress resources, follow these steps:

**Enable TLS** in `values.yaml` or via `--set`:

```yaml
# Other options ...
--set frontend.ingress.tls.enabled=true \
--set backend.ingress.tls.enabled=true
```

##### **Using Your Own Certificates**:

If you already have TLS certificates (e.g., from your organization's CA or a
commercial provider), you can configure them directly:

```yaml
# Other options ...
--set frontend.ingress.tls.secretName="your-frontend-tls-secret" \
--set backend.ingress.tls.secretName="your-backend-tls-secret"
```

**Create TLS Secrets** (if not already present):

```yaml
kubectl create secret tls your-frontend-tls-secret \
    --cert=path/to/cert.crt \
    --key=path/to/cert.key \
    -n stackclass

kubectl create secret tls your-backend-tls-secret \
    --cert=path/to/cert.crt \
    --key=path/to/cert.key \
    -n stackclass
```

**Verify** the Ingress resources include TLS:

```sh
kubectl get ingress -n stackclass
```

**Notes**:
- Ensure the certificate's Common Name (CN) or Subject Alternative Names (SANs)
  match the configured `host` values.

##### Using Cert-Manager for Automatic TLS

To automate TLS certificate management using `cert-manager`, follow these steps:

**Enable Issuer** in `values.yaml` or via `--set`:

```yaml
# Other options ...
--set issuer.enabled=true \
--set issuer.email=your-email@example.com \
--set issuer.environment=staging  # or "prod" for production
```

**First-Time Installation**:

- **Install the Chart**:
  If this is the first time you are installing `cert-manager` in your cluster,
  you need to enable the installation of its Custom Resource Definitions
  (CRDs) by setting `cert-manager.crds.enabled=true`:

  ```yaml
  # Other options ...
  --set cert-manager.crds.enabled=true
  ```

- **Retaining CRDs**:
  If you want to retain the CRDs even after uninstalling the chart (e.g., for
  future installations), set `cert-manager.crds.keep=true`:

  ```yaml
  # Other options ...
  --set cert-manager.crds.enabled=true \
  --set cert-manager.crds.keep=true
  ```

**Notes**:

- Replace `your-email@example.com` with a valid email address for certificate
  notifications.
- Set `environment` to `prod` for production certificates (rate limits apply).
- Certificates will be automatically issued and renewed by `cert-manager`.

## Documentation

- All the helm chart source code will be committed to main branch, all the
  charts will be placed under `/charts` and each chart will be  separate with
  their own folder

- The `index.yaml` will be committed to `gh-pages` branch, which represent
  an accessible page. The helm repository required an `index.yaml` file to show
  its charts structure

- Github action is set to provide helm release automation when changes are
  committed to the main branch.

- Due to rapid churn in the Kubernetes ecosystem, charts in this repository
  assume a version of Kubernetes released in the last 12 months. This typically
  means one of the last four releases.

  Note: While these charts may work with versions of older versions of
  Kubernetes, only releases made in the last year are eligible for support.

## License

Copyright (c) The StackClass Authors. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
