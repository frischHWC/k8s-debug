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
export FROM_LAST_X_MINUTES="10"
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
mkdir ${OUTPUT_DIR}/jobs
mkdir ${OUTPUT_DIR}/ingress
mkdir ${OUTPUT_DIR}/service
mkdir ${OUTPUT_DIR}/pvc
mkdir ${OUTPUT_DIR}/persistentvolume
mkdir ${OUTPUT_DIR}/storageclass
mkdir ${OUTPUT_DIR}/serviceaccount
mkdir ${OUTPUT_DIR}/roles
mkdir ${OUTPUT_DIR}/clusterroles
mkdir ${OUTPUT_DIR}/crds


# Setup scope
if [ "${SCOPE}" == "all" ] ; then
    export REAL_SCOPE="logs,pods,configmaps,nodes,deployments,sts,jobs,ingresses,services,pvc,pvs,storageclass,crds,serviceaccount,roles,clusterroles"
else
    export REAL_SCOPE="${SCOPE}"
fi

# env for debug
if [ "${DEBUG}" = true ] ; then
    env > ${OUTPUT_DIR}.env.vars
fi


echo "################"
echo "Getting info for all pods in namespace $NS"
echo "################"

pod_list=$(kubectl -n $NS get pods -o=jsonpath='{.items[*]..metadata.name}')

for i in $pod_list; do
    if [[ ${REAL_SCOPE} == *"pods"* ]] ; then
        echo "****** Getting definition for $i"
        kubectl -n $NS get pod $i -o yaml > ${OUTPUT_DIR}/pod/$i.yaml
        echo "****** Done getting definition for $i"
        echo "****** Getting events for $i"
        kubectl -n $NS events $i -o yaml > ${OUTPUT_DIR}/pod/$i.yaml
        echo "****** Done getting events for $i"
    fi
    if [[ ${REAL_SCOPE} == *"logs"* ]] ; then
        echo "****** Getting logs for $i"
        kubectl -n $NS logs $i --since=${FROM_LAST_X_MINUTES}m > ${OUTPUT_DIR}/log/$i.log
        echo "****** Done getting logs for $i"
    fi
   
done

echo "################"
echo "Finished to get logs for all pods in namespace $NS"
echo "################"




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









if [ "${ARCHIVE}" = true ] ; then
    tar -cvzf ${OUTPUT_DIR}.tar.gz ${OUTPUT_DIR}/
fi