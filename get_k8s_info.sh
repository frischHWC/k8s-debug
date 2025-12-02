export NS="mistral-ai-suite"
export OUTPUT_LOG_DIR="output_dir-$(date +%Y-%m-%d-%H-%M-%S)/"

mkdir ${OUTPUT_LOG_DIR}
mkdir ${OUTPUT_LOG_DIR}/log
mkdir ${OUTPUT_LOG_DIR}/pod
mkdir ${OUTPUT_LOG_DIR}/cm
mkdir ${OUTPUT_LOG_DIR}/node


echo "################"
echo "Getting info for all pods in namespace $NS"
echo "################"

pod_list=$(kubectl -n $NS get pods -o=jsonpath='{.items[*]..metadata.name}')

for i in $pod_list; do
    echo "****** Getting definition for $i"
    kubectl -n $NS get pod $i -o yaml > ${OUTPUT_LOG_DIR}/pod/$i.yaml
    echo "****** Done getting definition for $i"
    echo "****** Getting logs for $i"
    kubectl -n $NS logs $i > ${OUTPUT_LOG_DIR}/log/$i.log
    echo "****** Done getting logs for $i"
    echo "****** Getting events for $i"
    kubectl -n $NS events $i -o yaml > ${OUTPUT_LOG_DIR}/pod/$i.yaml
    echo "****** Done getting events for $i"
done

echo "################"
echo "Finished to get logs for all pods in namespace $NS"
echo "################"




echo "################"
echo "Getting all config maps in namespace $NS"
echo "################"

cm_list=$(kubectl -n $NS get cm -o=jsonpath='{.items[*]..metadata.name}')

for i in $cm_list; do
    echo "****** Getting cm for $i"
    kubectl -n $NS get cm $i -o yaml > ${OUTPUT_LOG_DIR}/cm/$i.yaml
    echo "****** Done getting cm for $i"
done

echo "################"
echo "Finished to get all config maps in namespace $NS"
echo "################"




echo "################"
echo "Getting all nodes"
echo "################"

node_list=$(kubectl get nodes -o=jsonpath='{.items[*]..metadata.name}')

for i in $node_list; do
    echo "****** Getting cm for $i"
    kubectl get node $i -o yaml > ${OUTPUT_LOG_DIR}/node/$i.yaml
    echo "****** Done getting cm for $i"
done

echo "################"
echo "Finished to get all nodes"
echo "################"