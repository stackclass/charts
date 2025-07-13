# StackClass Helm Charts

This repository hosts official [Helm](https://helm.sh) charts for
[StackClass](https://stackclass.dev). These charts are used to deploy
StackClass to Kubernetes.

[![Release
Charts](https://github.com/stackclass/charts/actions/workflows/release.yml/badge.svg)](https://github.com/stackclass/charts/actions/workflows/release.yml)
[![License](https://img.shields.io/github/license/stackclass/charts)](https://github.com/stackclass/charts/blob/main/LICENSE)
[![GitHub
contributors](https://img.shields.io/github/contributors/stackclass/charts)](https://github.com/stackclass/charts/graphs/charts)
[![GitHub
issues](https://img.shields.io/github/issues/stackclass/charts)](https://github.com/stackclass/charts/issues)

## Usage

### Pre-requisites

- Kubernetes 1.19+
- Helm 3.9.0+
- PV provisioner support in the underlying infrastructure
- ReadWriteMany volumes for deployment scaling

### Once Helm has been set up correctly, add the repo as follows:

```sh
helm repo add stackclass https://stackclass.github.io/charts/
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
stackclass` to see the charts.

### To install the chart with the release name `stackclass`:

```sh
helm upgrade --install stackclass stackclass/stackclass --create-namespace -n=stackclass
```

The command deploys StackClass API Server, frontend and services on the
Kubernetes cluster in the default configuration.

### To uninstall the chart:

```sh
helm delete stackclass
```

The command removes all the Kubernetes components associated with the chart and
deletes the release.

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
