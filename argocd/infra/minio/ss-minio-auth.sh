#!/usr/bin/env bash

ORIG_DIR="$(pwd)"
cd "$(dirname "$0")"
BIN_DIR="$(pwd)"

onExit() {
  cd "${ORIG_DIR}"
}

trap onExit EXIT

SECRET_NAME="minio-auth"
NAMESPACE="infra"

ROOT_USER="${1:-eoepca}"
ROOT_PASSWORD="${2:-changeme}"

secretYaml() {
  kubectl -n "${NAMESPACE}" create secret generic "${SECRET_NAME}" \
    --from-literal="rootUser=${ROOT_USER}" \
    --from-literal="rootPassword=${ROOT_PASSWORD}" \
    --dry-run=client -o yaml
}

# Create Secret and then pipe to kubeseal to create the SealedSecret
# secretYaml | kubeseal -o yaml --controller-name sealed-secrets --controller-namespace infra > templates/ss-${SECRET_NAME}.yaml
secretYaml \
  | kubeseal -o yaml --controller-name sealed-secrets --controller-namespace infra \
  | yq -r '"adminCredentials:\n  encryptedData:\n    rootPassword: \( .spec.encryptedData.rootPassword )\n    rootUser: \( .spec.encryptedData.rootUser )"' \
  > admin-credentials.yaml
