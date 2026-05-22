#!/bin/bash

# Prerequisites check
for cmd in jq tar kubectl helm; do
  if ! command -v $cmd &>/dev/null; then
    echo "❌ Required tool '$cmd' is not installed. Please install it and try again."
    exit 1
  fi
done

# Ask for namespace
read -p "Enter the Kubernetes namespace for ELMA365: " namespace
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
output_dir="elma365_report_$timestamp"
mkdir -p "$output_dir"

file_main="$output_dir/main_info.txt"
file_describe="$output_dir/describes.txt"
file_general="$output_dir/general_info.txt"

log_section() {
  local title=$1
  local command=$2
  local file=$3

  echo -e "\n### $title\n\$ $command" >> "$file"
  eval "$command" >> "$file" 2>&1 || echo "⚠️ Command failed: $command" >> "$file"
}

echo "📦 Collecting cluster data into $output_dir..."

# === MAIN FILE ===
log_section "All resources in namespace ($namespace)" "kubectl get all -n $namespace -o wide" "$file_main"

log_section "Horizontal Pod Autoscalers" "kubectl get hpa -n $namespace" "$file_main"
log_section "ReplicaSets" "kubectl get replicasets -n $namespace" "$file_main"

# Resource usage report
echo -e "\n### Container Resource Requests / Limits / Usage" >> "$file_main"
{
  declare -A cpu_usage mem_usage
  while read -r pod container cpu mem; do
    cpu_usage["$pod/$container"]=$cpu
    mem_usage["$pod/$container"]=$mem
  done < <(kubectl top pod -n "$namespace" --containers --no-headers 2>/dev/null)

  printf "%-40s %-20s %-10s %-10s %-10s %-10s %-10s %-10s\n" \
    "POD" "CONTAINER" "CPU_REQ" "MEM_REQ" "CPU_LIMIT" "MEM_LIMIT" "CPU_USED" "MEM_USED"

  echo "----------------------------------------------------------------------------------------------------------------------------------"

  kubectl get pods -n "$namespace" -o json 2>/dev/null | jq -r '
    .items[] | {name: .metadata.name, containers: .spec.containers} |
    .name as $podName |
    .containers[] |
    {
      pod: $podName,
      container: .name,
      cpu_req: (.resources.requests.cpu // "-"),
      mem_req: (.resources.requests.memory // "-"),
      cpu_limit: (.resources.limits.cpu // "-"),
      mem_limit: (.resources.limits.memory // "-")
    } |
    [.pod, .container, .cpu_req, .mem_req, .cpu_limit, .mem_limit] | @tsv
  ' | while IFS=$'\t' read -r pod container cpu_req mem_req cpu_limit mem_limit; do
    cpu_used="${cpu_usage["$pod/$container"]:-"-"}"
    mem_used="${mem_usage["$pod/$container"]:-"-"}"
    printf "%-40s %-20s %-10s %-10s %-10s %-10s %-10s %-10s\n" \
      "$pod" "$container" "$cpu_req" "$mem_req" "$cpu_limit" "$mem_limit" "$cpu_used" "$mem_used"
  done
} >> "$file_main"

log_section "Events sorted by date (newest last)" "kubectl get events -n $namespace --sort-by=.metadata.creationTimestamp" "$file_main"
log_section "ConfigMaps in namespace" "kubectl get configmap -n $namespace" "$file_main"

log_section "Migration state (v1)" "kubectl exec deploy/deploy -n $namespace -c deploy -- curl -i -H 'Accept: application/json' -H 'Content-Type: application/json' -X GET http://localhost:3000/migration/states" "$file_main"
log_section "Migration state (v2)" "kubectl exec deploy/deploy -n $namespace -c deploy -- curl -i -H 'Accept: application/json' -H 'Content-Type: application/json' -X GET http://localhost:3000/migration/state" "$file_main"

log_section "Migration state (v1 new version)" "IMAGE=\$(ctr -n k8s.io images ls 2>/dev/null | awk '/toolkit\/curl:8.2.1/ {print \$1; exit}'); kubectl run curl-get-migration-\$(date +%s) -n $namespace --image=\"\$IMAGE\" --image-pull-policy=Never --rm --attach=true --restart=Never --quiet -- /bin/sh -c 'curl -sS -i -H \"Accept: application/json\" -H \"Content-Type: application/json\" -X GET http://deploy:3000/migration/state'" "$file_main"
log_section "Migration state (v2 new version)" "IMAGE=\$(ctr -n k8s.io images ls 2>/dev/null | awk '/toolkit\/curl:8.2.1/ {print \$1; exit}'); kubectl run curl-get-migration-\$(date +%s) -n $namespace --image=\"\$IMAGE\" --image-pull-policy=Never --rm --attach=true --restart=Never --quiet -- /bin/sh -c 'curl -sS -i -H \"Accept: application/json\" -H \"Content-Type: application/json\" -X GET http://deploy:3000/migration/states'" "$file_main"


log_section "Last 30 lines of deployment logs" "kubectl logs deploy/deploy -n $namespace --tail=30" "$file_main"

log_section "Fatal logs in ELMA365 pods" "kubectl logs -n $namespace -l tier=elma365 --all-containers | grep '\"fatal\"'" "$file_main"
log_section "Error logs in ELMA365 pods" "kubectl logs -n $namespace -l tier=elma365 --all-containers | grep '\"error\"'" "$file_main"

log_section "Helm releases in namespace" "helm list -n $namespace" "$file_main"
log_section "Helm status for ELMA365" "helm status elma365 -n $namespace" "$file_main"
log_section "Helm history for ELMA365" "helm history elma365 -n $namespace" "$file_main"

# === DESCRIBE FILE ===
log_section "Node descriptions" "kubectl describe nodes" "$file_describe"
log_section "Pod descriptions in namespace" "kubectl describe pods -n $namespace" "$file_describe"

# === GENERAL FILE ===
log_section "All resources in all namespaces" "kubectl get all -A -o wide" "$file_general"
log_section "All ingresses" "kubectl get ingress -A" "$file_general"
log_section "All ConfigMaps" "kubectl get configmap -A" "$file_general"
log_section "All Secrets" "kubectl get secret -A" "$file_general"
log_section "All Namespaces" "kubectl get ns -A" "$file_general"

log_section "Node list" "kubectl get nodes -o wide" "$file_general"
log_section "Node metrics (top)" "kubectl top nodes" "$file_general"

log_section "Helm list (all namespaces)" "helm list -A" "$file_general"

# === POD LOGS COLLECTION ===
logs_dir="$output_dir/pod_logs"
mkdir -p "$logs_dir"

echo "📦 Collecting pod logs..."
kubectl get pods -n "$namespace" --no-headers -o custom-columns=":metadata.name" | while read -r pod; do
    containers=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[*].name}')
    for container in $containers; do
        log_file="$logs_dir/${pod}-${container}.log"
        echo "🔄 Collecting logs for $pod ($container)..."
        kubectl logs "$pod" -n "$namespace" -c "$container" --timestamps > "$log_file" 2>&1 || echo "⚠️ Failed to get logs for $pod/$container" >> "$log_file"
    done
done

# === ARCHIVE CREATION ===
archive_name="elma365-report-$timestamp.tar.gz"
tar -czf "$archive_name" "$output_dir" && echo "✅ Archive created: $archive_name" || echo "❌ Failed to create archive."

# Done
echo "✅ Report collection completed."
