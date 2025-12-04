#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
#!/bin/bash


export NS="mistral-ai-suite"
export OUTPUT_DIR="output_dir-$(date +%Y-%m-%d-%H-%M-%S)"
export SCOPE="all"
export ARCHIVE=true
export FROM_LAST_X_MINUTES="60"
export DEBUG=false


function usage()
{
    echo "This script aims to create, start, stop or delete a Cloudera Public Cloud Cluster"
    echo ""
    echo "Usage is the following : "
    echo ""
    echo "./get_k8s_info.sh"
    echo "  -h --help"
    echo ""
    echo "  --namespace=$NS : Where Mistral AI Suite is running"
    echo "  --output-dir=$OUTPUT_DIR : Where to store outputs"
    echo "  --scope=$SCOPE : A comma separated list of resources to gather info on. Can be"
    echo "                  all, logs, events, pods, cm, nodes, deployments, sts, ds, jobs, ing, services, pvc, pvs, sc, crds, sa, roles, clusterroles"
    echo "  --archive=$ARCHIVE : To compress in a single archive the output or not"
    echo "  --from-last-x-minutes=$FROM_LAST_X_MINUTES : Get logs from last X minutes foreach pod"
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
            NS=$VALUE
            ;;
        --output-dir)
            OUTPUT_DIR=$VALUE
            ;;
        --scope)
            SCOPE=$VALUE
            ;;
        --archive)
            ARCHIVE=$VALUE
            ;;
        --from-last-x-minutes)
            FROM_LAST_X_MINUTES=$VALUE
            ;;
        --debug)
            DEBUG=$VALUE
            ;;
        *)
            ;;
    esac
    shift
done

# Create directories
mkdir ${OUTPUT_DIR}
mkdir ${OUTPUT_DIR}/log
mkdir ${OUTPUT_DIR}/pod
mkdir ${OUTPUT_DIR}/cm
mkdir ${OUTPUT_DIR}/node
mkdir ${OUTPUT_DIR}/deployment
mkdir ${OUTPUT_DIR}/statefulset
mkdir ${OUTPUT_DIR}/job
mkdir ${OUTPUT_DIR}/ingress
mkdir ${OUTPUT_DIR}/service
mkdir ${OUTPUT_DIR}/pvc
mkdir ${OUTPUT_DIR}/persistentvolume
mkdir ${OUTPUT_DIR}/storageclass
mkdir ${OUTPUT_DIR}/serviceaccount
mkdir ${OUTPUT_DIR}/role
mkdir ${OUTPUT_DIR}/clusterrole
mkdir ${OUTPUT_DIR}/crds


# Setup scope
if [ "${SCOPE}" == "all" ] ; then
    export REAL_SCOPE="logs,pods,configmaps,nodes,deployments,sts,jobs,ingresses,services,pvc,persistentvolumes,storageclass,crds,serviceaccount,roles,clusterroles"
else
    export REAL_SCOPE="${SCOPE}"
fi

# env for debug
if [ "${DEBUG}" = true ] ; then
    env > ${OUTPUT_DIR}.env.vars
fi


if [[ ${REAL_SCOPE} == *"logs"* ]] || [[ ${REAL_SCOPE} == *"pods"* ]] ; then
    echo "################"
    echo "Getting info for all pods in namespace $NS"
    echo "################"

    pod_list=$(kubectl -n $NS get pods -o=jsonpath='{.items[*]..metadata.name}')

    for i in $pod_list; do
        if [[ ${REAL_SCOPE} == *"logs"* ]] ; then
            echo "****** Getting logs for $i"
            kubectl -n $NS logs $i --since=${FROM_LAST_X_MINUTES}m > ${OUTPUT_DIR}/log/$i.log
            echo "****** Done getting logs for $i"
        fi

        if [[ ${REAL_SCOPE} == *"pods"* ]] ; then
            echo "****** Getting definition for $i"
            kubectl -n $NS get pod $i -o yaml > ${OUTPUT_DIR}/pod/$i.yaml
            echo "****** Done getting definition for $i"
            echo "****** Getting events for $i"
            kubectl -n $NS events $i -o yaml > ${OUTPUT_DIR}/pod/$i.yaml
            echo "****** Done getting events for $i"
        fi   
    done    

    echo "################"
    echo "Finished to get info for all pods in namespace $NS"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"configmaps"* ]] ; then
    echo "################"
    echo "Getting all config maps in namespace $NS"
    echo "################"

    cm_list=$(kubectl -n $NS get cm -o=jsonpath='{.items[*]..metadata.name}')

    for i in $cm_list; do
        echo "****** Getting cm for $i"
        kubectl -n $NS get cm $i -o yaml > ${OUTPUT_DIR}/cm/$i.yaml
        echo "****** Done getting cm for $i"
    done

    echo "################"
    echo "Finished to get all config maps in namespace $NS"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"nodes"* ]] ; then
    echo "################"
    echo "Getting all nodes"
    echo "################"

    node_list=$(kubectl get nodes -o=jsonpath='{.items[*]..metadata.name}')

    for i in $node_list; do
        echo "****** Getting cm for $i"
        kubectl get node $i -o yaml > ${OUTPUT_DIR}/node/$i.yaml
        echo "****** Done getting cm for $i"
    done

    echo "################"
    echo "Finished to get all nodes"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"deployments"* ]] ; then
    echo "################"
    echo "Getting all deployments"
    echo "################"

    obj_list=$(kubectl get deployments -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting deployment for $i"
        kubectl get deployments $i -n $NS -o yaml > ${OUTPUT_DIR}/deployment/$i.yaml
        echo "****** Done getting deployment for $i"
    done

    echo "################"
    echo "Finished to get all deployments"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"sts"* ]] ; then
    echo "################"
    echo "Getting all statefulsets"
    echo "################"

    obj_list=$(kubectl get sts -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting sts for $i"
        kubectl get sts $i -n $NS -o yaml > ${OUTPUT_DIR}/statefulset/$i.yaml
        echo "****** Done getting sts for $i"
    done

    echo "################"
    echo "Finished to get all statefulsets"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"jobs"* ]] ; then
    echo "################"
    echo "Getting all jobs"
    echo "################"

    obj_list=$(kubectl get jobs -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting jobs for $i"
        kubectl get jobs $i -n $NS -o yaml > ${OUTPUT_DIR}/job/$i.yaml
        echo "****** Done getting jobs for $i"
    done

    echo "################"
    echo "Finished to get all jobs"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"ingress"* ]] ; then
    echo "################"
    echo "Getting all ingresses"
    echo "################"

    obj_list=$(kubectl get ingress -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting ingress for $i"
        kubectl get ingress $i -n $NS -o yaml > ${OUTPUT_DIR}/ingress/$i.yaml
        echo "****** Done getting ingress for $i"
    done

    echo "################"
    echo "Finished to get all ingresses"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"service"* ]] ; then
    echo "################"
    echo "Getting all services"
    echo "################"

    obj_list=$(kubectl get svc -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting service for $i"
        kubectl get svc $i -n $NS -o yaml > ${OUTPUT_DIR}/service/$i.yaml
        echo "****** Done getting service for $i"
    done

    echo "################"
    echo "Finished to get all service"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"pvc"* ]] ; then
    echo "################"
    echo "Getting all pvc"
    echo "################"

    obj_list=$(kubectl get pvc -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting pvc for $i"
        kubectl get pvc $i -n $NS -o yaml > ${OUTPUT_DIR}/pvc/$i.yaml
        echo "****** Done getting pvc for $i"
    done

    echo "################"
    echo "Finished to get all pvc"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"persistentvolumes"* ]] ; then
    echo "################"
    echo "Getting all persistentvolume"
    echo "################"

    obj_list=$(kubectl get pv -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting persistentvolume for $i"
        kubectl get pv $i -n $NS -o yaml > ${OUTPUT_DIR}/persistentvolume/$i.yaml
        echo "****** Done getting persistentvolume for $i"
    done

    echo "################"
    echo "Finished to get all persistentvolume"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"storageclass"* ]] ; then
    echo "################"
    echo "Getting all storageclass"
    echo "################"

    obj_list=$(kubectl get sc -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting storageclass for $i"
        kubectl get sc $i -o yaml > ${OUTPUT_DIR}/storageclass/$i.yaml
        echo "****** Done getting storageclass for $i"
    done

    echo "################"
    echo "Finished to get all storageclass"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"persistentvolume"* ]] ; then
    echo "################"
    echo "Getting all persistentvolume"
    echo "################"

    obj_list=$(kubectl get pv -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting persistentvolume for $i"
        kubectl get pv $i -n $NS -o yaml > ${OUTPUT_DIR}/persistentvolume/$i.yaml
        echo "****** Done getting persistentvolume for $i"
    done

    echo "################"
    echo "Finished to get all persistentvolume"
    echo "################"
fi



if [[ ${REAL_SCOPE} == *"serviceaccount"* ]] ; then
    echo "################"
    echo "Getting all serviceaccount"
    echo "################"

    obj_list=$(kubectl get sa -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting serviceaccount for $i"
        kubectl get sa $i -n $NS -o yaml > ${OUTPUT_DIR}/serviceaccount/$i.yaml
        echo "****** Done getting serviceaccount for $i"
    done

    echo "################"
    echo "Finished to get all serviceaccount"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"roles"* ]] ; then
    echo "################"
    echo "Getting all roles"
    echo "################"

    obj_list=$(kubectl get roles -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting roles for $i"
        kubectl get roles $i -n $NS -o yaml > ${OUTPUT_DIR}/role/$i.yaml
        echo "****** Done getting roles for $i"
    done

    obj_list=$(kubectl get rolebinding -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting roles binding for $i"
        kubectl get rolebinding $i -n $NS -o yaml > ${OUTPUT_DIR}/role/$i-binding.yaml
        echo "****** Done getting role binding for $i"
    done

    echo "################"
    echo "Finished to get all roles"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"clusterroles"* ]] ; then
    echo "################"
    echo "Getting all clusterroles"
    echo "################"

    obj_list=$(kubectl get clusterroles -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting clusterroles for $i"
        kubectl get clusterroles $i -n $NS -o yaml > ${OUTPUT_DIR}/clusterrole/$i.yaml
        echo "****** Done getting clusterroles for $i"
    done

    obj_list=$(kubectl get clusterrolebinding -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting clusterroles binding for $i"
        kubectl get clusterrolebinding $i -n $NS -o yaml > ${OUTPUT_DIR}/clusterrole/$i-binding.yaml
        echo "****** Done getting clusterroles binding for $i"
    done

    echo "################"
    echo "Finished to get all clusterroles"
    echo "################"
fi


if [[ ${REAL_SCOPE} == *"crds"* ]] ; then
    echo "################"
    echo "Getting all crds"
    echo "################"

    obj_list=$(kubectl get crd -n $NS -o=jsonpath='{.items[*]..metadata.name}')

    for i in $obj_list; do
        echo "****** Getting crds for $i"
        kubectl get crd $i -n $NS -o yaml > ${OUTPUT_DIR}/crds/$i.yaml
        echo "****** Done getting crd for $i"
    done

    echo "################"
    echo "Finished to get all crds"
    echo "################"
fi


if [ "${ARCHIVE}" = true ] ; then
    tar -czf ${OUTPUT_DIR}.tar.gz ${OUTPUT_DIR}/
fi