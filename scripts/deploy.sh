#!/bin/bash
set -e

# Configuration des variables d'environnement
export DYNAMODB_TABLE="Campaigns"
export AWS_REGION="us-east-1"

# Vérification que les variables AWS sont définies
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "Erreur: Les clés d'accès AWS ne sont pas définies."
  exit 1
fi

# Création de la table DynamoDB si elle n'existe pas
echo "Vérification/création de la table DynamoDB..."
aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $AWS_REGION > /dev/null 2>&1 || \
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region $AWS_REGION

echo "Table DynamoDB configurée avec succès!"

# Préparation du package de déploiement
echo "Préparation du package de déploiement..."
zip -r deploy.zip . -x "*.git*" "*.github*" "node_modules/*" "__pycache__/*" "*.pyc" "*.pyo" "*.pyd" "venv/*" "env/*"

echo "Package de déploiement créé avec succès!"

echo "Déploiement terminé!"