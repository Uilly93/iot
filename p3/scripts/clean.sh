#!/bin/bash
CLUSTER_NAME="p3"
PORT=8080
echo "Cleaning up everything..."
PID=$(lsof -t -i:$PORT 2>/dev/null || true)
if [ -n "$PID" ]; then
    echo "Killing port-forward on port $PORT (PID: $PID)..."
    kill -9 $PID
else
    echo "No port-forward found on port $PORT"
fi
if k3d cluster list 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    echo "Deleting k3d cluster '$CLUSTER_NAME'..."
    k3d cluster delete "$CLUSTER_NAME"
else
    echo "Cluster '$CLUSTER_NAME' not found"
fi
echo "------------------------------------------------------"
echo "Everything cleaned up."
echo "------------------------------------------------------"