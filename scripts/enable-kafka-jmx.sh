#!/bin/bash
set -e

NAMESPACE="confluent"
PROM_NS="monitoring"
KAFKA_CR="kafka"

echo "✅ Step 1: Patching Kafka CR to enable JMX exporter..."

kubectl patch kafka $KAFKA_CR -n $NAMESPACE --type merge -p '{
  "spec": {
    "metrics": {
      "jmxExporter": {
        "enabled": true,
        "port": 9104
      }
    }
  }
}' || echo "⚠ Kafka CR already patched or error ignored."

echo "✅ Step 2: Restarting Kafka pods to apply changes..."
kubectl rollout restart statefulset kafka -n $NAMESPACE

echo "⏳ Waiting for Kafka pods to be ready..."
kubectl wait --for=condition=Ready pod -l app=kafka -n $NAMESPACE --timeout=300s

echo "✅ Step 3: Creating ServiceMonitor for Kafka JMX metrics..."

cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kafka
  namespace: $PROM_NS
spec:
  namespaceSelector:
    matchNames:
      - $NAMESPACE
  selector:
    matchLabels:
      app: kafka
  endpoints:
    - port: jmx
      interval: 30s
EOF

echo "✅ Step 4: Verify Prometheus targets (should show Kafka pods)..."
kubectl get servicemonitor -n $PROM_NS
echo "Then check Prometheus UI: http://localhost:9090/targets"

echo "🎉 Kafka JMX metrics setup complete. Dashboard 18276 should now show data after Prometheus scrapes metrics."

➜  grafana-dashboards git:(master) ✗ 

