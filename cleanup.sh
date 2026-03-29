#!/bin/bash

echo "Starting cluster cleanup..."

echo "Removing GitOps binding (phoenix-auth-system)..."
kubectl delete -f argo-app.yml --ignore-not-found

echo "Removing business application and database..."
kubectl delete -f k8s/ --ignore-not-found

echo "Removing Argo CD (this might take a while)..."
kubectl delete namespace argocd --ignore-not-found

echo "Removing image from minikube cache..."
minikube image rm auth-api:local

echo "Done"