set -x
set -e

ROOT_DIR=$(dirname "${BASH_SOURCE}")/..

REPO_NAMESPACE="${REPO_NAMESPACE:-"openshift"}"
OSE_IMAGE_TAG="${OSE_IMAGE_TAG:-"v4.2"}"
SOURCE_IMAGE_URL="${SOURCE_IMAGE_URL:-"registry-proxy.engineering.redhat.com"}"
SOURCE_IMAGE_NAMESPACE="${SOURCE_IMAGE_NAMESPACE:-"rh-osbs"}"
OUTPUT_IMAGE_URL="${OUTPUT_IMAGE_URL:-"$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')"}"
OUTPUT_IMAGE_NAMESPACE="${OUTPUT_IMAGE_NAMESPACE:-"$REPO_NAMESPACE"}"
SETUP_REGISTRY_AUTH="${SETUP_REGISTRY_AUTH:-"true"}"
PULL_IMAGES="${PULL_IMAGES:-"true"}"
PUSH_IMAGES="${PUSH_IMAGES:-"true"}"

if [ -z "$OUTPUT_IMAGE_URL" ]; then
    echo "Couldn't detect \$OUTPUT_IMAGE_URL or unset"
    exit 1
fi

# default to mirroring the $OSE_IMAGE_TAG for each, but allow overriding the tag to be mirrored per mirror
METERING_ANSIBLE_OPERATOR_IMAGE_TAG="${METERING_ANSIBLE_OPERATOR_IMAGE_TAG:-$OSE_IMAGE_TAG}"
METERING_REPORTING_OPERATOR_IMAGE_TAG="${METERING_REPORTING_OPERATOR_IMAGE_TAG:-$OSE_IMAGE_TAG}"
METERING_PRESTO_IMAGE_TAG="${METERING_PRESTO_IMAGE_TAG:-$OSE_IMAGE_TAG}"
METERING_HIVE_IMAGE_TAG="${METERING_HIVE_IMAGE_TAG:-$OSE_IMAGE_TAG}"
METERING_HADOOP_IMAGE_TAG="${METERING_HADOOP_IMAGE_TAG:-$OSE_IMAGE_TAG}"
GHOSTUNNEL_IMAGE_TAG="${GHOSTUNNEL_IMAGE_TAG:-$OSE_IMAGE_TAG}"
OAUTH_PROXY_IMAGE_TAG="${OAUTH_PROXY_IMAGE_TAG:-$OSE_IMAGE_TAG}"

# if the _IMAGE variable is set for any component, we assume it's got the $SOURCE_REGISTY_PREFIX and lives in the $SOURCE_IMAGE_NAMESPACE, so we remove those values to get the image digest or image tag value (including the `@sha256:` or `:`.
if [ -n "$METERING_ANSIBLE_OPERATOR_IMAGE" ]; then
    METERING_ANSIBLE_OPERATOR_IMAGE_TAG_OR_DIGEST="${METERING_ANSIBLE_OPERATOR_IMAGE##*/ose-metering-ansible-operator}"
else
    METERING_ANSIBLE_OPERATOR_IMAGE_TAG_OR_DIGEST=":$METERING_ANSIBLE_OPERATOR_IMAGE_TAG"
fi
if [ -n "$METERING_REPORTING_OPERATOR_IMAGE" ]; then
    METERING_REPORTING_OPERATOR_IMAGE_TAG_OR_DIGEST="${METERING_REPORTING_OPERATOR_IMAGE##*/ose-metering-reporting-operator}"
else
    METERING_REPORTING_OPERATOR_IMAGE_TAG_OR_DIGEST=":$METERING_REPORTING_OPERATOR_IMAGE_TAG"
fi
if [ -n "$METERING_PRESTO_IMAGE" ]; then
    METERING_PRESTO_IMAGE_TAG_OR_DIGEST="${METERING_PRESTO_IMAGE##*/ose-metering-presto}"
else
    METERING_PRESTO_IMAGE_TAG_OR_DIGEST=":$METERING_PRESTO_IMAGE_TAG"
fi
if [ -n "$METERING_HIVE_IMAGE" ]; then
    METERING_HIVE_IMAGE_TAG_OR_DIGEST="${METERING_HIVE_IMAGE##*/ose-metering-hive}"
else
    METERING_HIVE_IMAGE_TAG_OR_DIGEST=":$METERING_HIVE_IMAGE_TAG"
fi
if [ -n "$METERING_HADOOP_IMAGE" ]; then
    METERING_HADOOP_IMAGE_TAG_OR_DIGEST="${METERING_HADOOP_IMAGE##*/ose-metering-hadoop}"
else
    METERING_HADOOP_IMAGE_TAG_OR_DIGEST=":$METERING_HADOOP_IMAGE_TAG"
fi
if [ -n "$GHOSTUNNEL_IMAGE" ]; then
    GHOSTUNNEL_IMAGE_TAG_OR_DIGEST="${GHOSTUNNEL_IMAGE##*/ose-ghostunnel}"
else
    GHOSTUNNEL_IMAGE_TAG_OR_DIGEST=":$GHOSTUNNEL_IMAGE_TAG"
fi
if [ -n "$OAUTH_PROXY_IMAGE" ]; then
    OAUTH_PROXY_IMAGE_TAG_OR_DIGEST="${OAUTH_PROXY_IMAGE##*/ose-oauth-proxy}"
else
    OAUTH_PROXY_IMAGE_TAG_OR_DIGEST=":$OAUTH_PROXY_IMAGE_TAG"
fi

METERING_ANSIBLE_OPERATOR_SOURCE_IMAGE="${METERING_ANSIBLE_OPERATOR_SOURCE_IMAGE:-"$SOURCE_IMAGE_NAMESPACE/openshift-ose-metering-ansible-operator$METERING_ANSIBLE_OPERATOR_IMAGE_TAG_OR_DIGEST"}"
METERING_REPORTING_OPERATOR_SOURCE_IMAGE="${METERING_REPORTING_OPERATOR_SOURCE_IMAGE:-"$SOURCE_IMAGE_NAMESPACE/openshift-ose-metering-reporting-operator$METERING_REPORTING_OPERATOR_IMAGE_TAG_OR_DIGEST"}"
METERING_PRESTO_SOURCE_IMAGE="${METERING_PRESTO_SOURCE_IMAGE:-"$SOURCE_IMAGE_NAMESPACE/openshift-ose-metering-presto$METERING_PRESTO_IMAGE_TAG_OR_DIGEST"}"
METERING_HIVE_SOURCE_IMAGE="${METERING_HIVE_SOURCE_IMAGE:-"$SOURCE_IMAGE_NAMESPACE/openshift-ose-metering-hive$METERING_HIVE_IMAGE_TAG_OR_DIGEST"}"
METERING_HADOOP_SOURCE_IMAGE="${METERING_HADOOP_SOURCE_IMAGE:-"$SOURCE_IMAGE_NAMESPACE/openshift-ose-metering-hadoop$METERING_HADOOP_IMAGE_TAG_OR_DIGEST"}"
GHOSTUNNEL_SOURCE_IMAGE="${GHOSTUNNEL_SOURCE_IMAGE:-"$SOURCE_IMAGE_NAMESPACE/openshift-ose-ghostunnel$GHOSTUNNEL_IMAGE_TAG_OR_DIGEST"}"
OAUTH_PROXY_SOURCE_IMAGE="${OAUTH_PROXY_SOURCE_IMAGE:-"$SOURCE_IMAGE_NAMESPACE/openshift-ose-oauth-proxy$OAUTH_PROXY_IMAGE_TAG_OR_DIGEST"}"

# we use the tag as the output, even if the source is a digest, because we can't push digests, we have to push a tag when mirroring, that was tagged from the digest
METERING_ANSIBLE_OPERATOR_OUTPUT_IMAGE="${METERING_ANSIBLE_OPERATOR_OUTPUT_IMAGE:-"$OUTPUT_IMAGE_NAMESPACE/ose-metering-ansible-operator:$METERING_ANSIBLE_OPERATOR_IMAGE_TAG"}"
METERING_REPORTING_OPERATOR_OUTPUT_IMAGE="${METERING_REPORTING_OPERATOR_OUTPUT_IMAGE:-"$OUTPUT_IMAGE_NAMESPACE/ose-metering-reporting-operator:$METERING_REPORTING_OPERATOR_IMAGE_TAG"}"
METERING_PRESTO_OUTPUT_IMAGE="${METERING_PRESTO_OUTPUT_IMAGE:-"$OUTPUT_IMAGE_NAMESPACE/ose-metering-presto:$METERING_PRESTO_IMAGE_TAG"}"
METERING_HIVE_OUTPUT_IMAGE="${METERING_HIVE_OUTPUT_IMAGE:-"$OUTPUT_IMAGE_NAMESPACE/ose-metering-hive:$METERING_HIVE_IMAGE_TAG"}"
METERING_HADOOP_OUTPUT_IMAGE="${METERING_HADOOP_OUTPUT_IMAGE:-"$OUTPUT_IMAGE_NAMESPACE/ose-metering-hadoop:$METERING_HADOOP_IMAGE_TAG"}"
GHOSTUNNEL_OUTPUT_IMAGE="${GHOSTUNNEL_OUTPUT_IMAGE:-"$OUTPUT_IMAGE_NAMESPACE/ose-ghostunnel:$GHOSTUNNEL_IMAGE_TAG"}"
OAUTH_PROXY_OUTPUT_IMAGE="${OAUTH_PROXY_OUTPUT_IMAGE:-"$OUTPUT_IMAGE_NAMESPACE/ose-oauth-proxy:$OAUTH_PROXY_IMAGE_TAG"}"

: "${METERING_NAMESPACE:?"\$METERING_NAMESPACE must be set!"}"

if [ "$SETUP_REGISTRY_AUTH" == "true" ]; then
    echo "Creating namespace for images: $REPO_NAMESPACE"
    oc create namespace "$REPO_NAMESPACE" || true
    echo "Creating serviceaccount registry-editor in $REPO_NAMESPACE"
    oc create serviceaccount registry-editor -n "$REPO_NAMESPACE" || true
    echo "Granting registry-editor registry-editor permissions in $REPO_NAMESPACE"
    oc adm policy add-role-to-user registry-editor -z registry-editor -n "$REPO_NAMESPACE" || true
    echo "Performing docker login as registry-editor to $OUTPUT_IMAGE_URL"
    set +x
    docker login \
        "$OUTPUT_IMAGE_URL" \
        -u registry-editor \
        -p "$(oc sa get-token registry-editor -n "$REPO_NAMESPACE")"
    set -x
fi

echo "Ensuring namespace $REPO_NAMESPACE exists for images to be pushed into"
oc create namespace "$REPO_NAMESPACE" || true
echo "Pushing Metering OSE images to $OUTPUT_IMAGE_URL"

"$ROOT_DIR/hack/mirror-ose-image.sh" \
    "$SOURCE_IMAGE_URL/$METERING_ANSIBLE_OPERATOR_SOURCE_IMAGE" \
    "$OUTPUT_IMAGE_URL/$METERING_ANSIBLE_OPERATOR_OUTPUT_IMAGE"

"$ROOT_DIR/hack/mirror-ose-image.sh" \
    "$SOURCE_IMAGE_URL/$METERING_REPORTING_OPERATOR_SOURCE_IMAGE" \
    "$OUTPUT_IMAGE_URL/$METERING_REPORTING_OPERATOR_OUTPUT_IMAGE"

"$ROOT_DIR/hack/mirror-ose-image.sh" \
    "$SOURCE_IMAGE_URL/$METERING_PRESTO_SOURCE_IMAGE" \
    "$OUTPUT_IMAGE_URL/$METERING_PRESTO_OUTPUT_IMAGE"

"$ROOT_DIR/hack/mirror-ose-image.sh" \
    "$SOURCE_IMAGE_URL/$METERING_HIVE_SOURCE_IMAGE" \
    "$OUTPUT_IMAGE_URL/$METERING_HIVE_OUTPUT_IMAGE"

"$ROOT_DIR/hack/mirror-ose-image.sh" \
    "$SOURCE_IMAGE_URL/$METERING_HADOOP_SOURCE_IMAGE" \
    "$OUTPUT_IMAGE_URL/$METERING_HADOOP_OUTPUT_IMAGE"

"$ROOT_DIR/hack/mirror-ose-image.sh" \
    "$SOURCE_IMAGE_URL/$GHOSTUNNEL_SOURCE_IMAGE" \
    "$OUTPUT_IMAGE_URL/$GHOSTUNNEL_OUTPUT_IMAGE"

"$ROOT_DIR/hack/mirror-ose-image.sh" \
    "$SOURCE_IMAGE_URL/$OAUTH_PROXY_SOURCE_IMAGE" \
    "$OUTPUT_IMAGE_URL/$OAUTH_PROXY_OUTPUT_IMAGE"

echo "Granting access to pull images in $REPO_NAMESPACE to all serviceaccounts in \$METERING_NAMESPACE=$METERING_NAMESPACE"
oc -n "$REPO_NAMESPACE" policy add-role-to-group system:image-puller "system:serviceaccounts:$METERING_NAMESPACE" --rolebinding-name "$METERING_NAMESPACE-image-pullers"
