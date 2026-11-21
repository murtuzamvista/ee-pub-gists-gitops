# ee-pub-gists GitOps deployment

This repository contains a shared Kustomize base, dev, QA, and production
overlays, and Argo CD `Application` manifests for the
`murtaza1983/ee-pub-gists` image.

## Deploy and promote an image

On each successful push to the application's `develop` branch, its dev pipeline
builds and scans the image, publishes it to Docker Hub using the
`sha-<full Git commit SHA>` tag, and updates
`overlays/dev/kustomization.yaml` to that tag. The dev, QA, and production
overlays should use the same SHA tag when promoting an image, so each
environment runs the exact same tested image instead of rebuilding it.

QA and production promotion are performed separately after their respective
approvals. The base contains shared deployment and service settings. The dev
and QA overlays run one replica with the base resource requests and limits.
Production runs two replicas and uses higher resource requests and limits. The
overlays deploy into the `dev`, `qa`, and `production` namespaces, respectively.

## Configure Argo CD

The dev Argo CD `Application` is managed by Terraform in the
`ee-pub-gists-terraform/terraform/apps` root, which points to
this repository's `main` branch and `overlays/dev`. Apply the Terraform root
only after Argo CD has been installed and the dev overlay has a valid published
image tag.

QA and production Application definitions remain in `argocd/` for the
forthcoming promotion workflows; they are not managed by the dev Terraform
root. The dev deployment listens on port `8080`; its `ClusterIP` service is
also available on port `8080`. Startup and liveness probes use `/health/live`;
readiness uses `/health/ready`, which reports ready only after the application
has initialized its GitHub API client. These checks do not make requests to
GitHub.

## Render overlays locally

```sh
kubectl kustomize overlays/dev
kubectl kustomize overlays/qa
kubectl kustomize overlays/production
```

## Lint and validate changes

The GitHub Actions workflow lints all YAML files and renders the dev, QA, and
production Kustomize overlays, validating the rendered Kubernetes resources
against their schemas.
Configure this workflow's **Lint and validate manifests** check as required in
branch protection or a ruleset to block merging changes that fail validation.
GitHub Actions runs on pushes but cannot prevent a direct push by itself.

To run the same checks locally, install `kubectl`, Go, Python, and pre-commit,
then install the hooks:

```sh
python3 -m pip install pre-commit yamllint==1.37.1
go install github.com/yannh/kubeconform/cmd/kubeconform@v0.7.0
pre-commit install
pre-commit install --hook-type pre-push
```

Run all checks manually at any time:

```sh
pre-commit run --all-files
pre-commit run --hook-stage pre-push --all-files
```

The pre-push hook renders and schema-validates both overlays. The pre-commit
hooks check YAML formatting, syntax, whitespace, and merge-conflict markers.
