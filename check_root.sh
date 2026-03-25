#!/bin/bash

export NAMESPACE="mistral-ai-suite"
export DEBUG=false


function usage()
{
    echo "This script aims to check which pods are running with a root user on a k8s namespace"
    echo ""
    echo "Usage is the following : "
    echo ""
    echo "./get_k8s_info.sh"
    echo "  -h --help"
    echo ""
    echo "  --namespace=$NAMESPACE : Where Mistral AI Suite is running"
    echo "  --debug=$DEBUG : For debug purposes"
    echo ""
    echo ""
    echo ""
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --namespace)
            NAMESPACE=$VALUE
            ;;
        --debug)
            DEBUG=$VALUE
            ;;
        *)
            ;;
    esac
    shift
done


# Get all pods in the namespace
PODS=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

echo "Output will be: "
echo " POD_NAME ; CONTAINER_NAME ; USER_ID_FROM_COMMAND ; USER_ID_FROM_SECURITY_CONTEXT : ❌/✅"

# Check each pod
for POD in $PODS; do
    # Get the security context for each container in the pod
    CONTAINERS=$(kubectl get pod "$POD" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}')

    for CONTAINER in $CONTAINERS; do
        # Extract the runAsUser from the security context
        SECURITY_CONTEXT_USER_ID=$(kubectl get pod "$POD" -n "$NAMESPACE" -o jsonpath="{.spec.containers[?(@.name==\"$CONTAINER\")].securityContext.runAsUser}")

        # If runAsUser is not set, check the pod-level security context
        if [ -z "$SECURITY_CONTEXT_USER_ID" ]; then
            SECURITY_CONTEXT_USER_ID=$(kubectl get pod "$POD" -n "$NAMESPACE" -o jsonpath="{.spec.securityContext.runAsUser}")
        fi

        # If runAsUser is still not set, assume root (0)
        if [ -z "$SECURITY_CONTEXT_USER_ID" ]; then
            SECURITY_CONTEXT_USER_ID="Not set (default: root)"
        fi

        # Execute a command inside the pod to check the actual user ID
        ACTUAL_USER_ID=$(kubectl exec "$POD" -n "$NAMESPACE" -c "$CONTAINER" -- id -u 2>/dev/null)

        if [ $? -ne 0 ]; then
            if [ "$DEBUG" = "true" ] ; then
                echo "DEBUG: Not able to run command on pod: $POD in container: $CONTAINER"
            fi
            ACTUAL_USER_ID="NotFound"
        fi

        # Check if the actual user is root
        if [ "$ACTUAL_USER_ID" = "0" ] || [ "$SECURITY_CONTEXT_USER_ID" = "0" ] || [[ "$SECURITY_CONTEXT_USER_ID" =~ "root" ]]  ; then
            echo "$POD ; $CONTAINER ; $ACTUAL_USER_ID ; $SECURITY_CONTEXT_USER_ID : ❌"
        else
            echo "$POD ; $CONTAINER ; $ACTUAL_USER_ID ; $SECURITY_CONTEXT_USER_ID : ✅"
        fi
    done
done