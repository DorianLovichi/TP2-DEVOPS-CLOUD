# Gestionnaire de Campagnes Marketing

Ce projet est une application web complète pour la gestion des campagnes marketing. Il comprend un backend Flask, une interface utilisateur simple et un déploiement automatisé sur AWS EC2 avec surveillance Prometheus.

## Table des Matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation Locale](#installation-locale)
- [Développement](#développement)
- [Tests](#tests)
- [Déploiement](#déploiement)
- [CI/CD](#cicd)
- [Monitoring avec Prometheus](#monitoring-avec-prometheus)
- [Structure du Projet](#structure-du-projet)
- [API Backend](#api-backend)
- [Configuration AWS](#configuration-aws)
- [Dépannage](#dépannage)

## Architecture

L'application se compose de:

- **Frontend**: Interface utilisateur simple en HTML/CSS/JavaScript
- **Backend**: API RESTful développée avec Flask (Python)
- **Base de données**: AWS DynamoDB pour le stockage des campagnes
- **Infrastructure**: AWS EC2 pour l'hébergement de l'application
- **Monitoring**: Prometheus pour la surveillance des performances
- **CI/CD**: GitHub Actions pour l'intégration et le déploiement continus

![Architecture Système](https://via.placeholder.com/800x400?text=Architecture+du+Syst%C3%A8me)

## Prérequis

- Python 3.11+
- Docker et Docker Compose
- Compte AWS avec accès à EC2, ECR et DynamoDB
- Git
- AWS CLI configuré avec des identifiants valides

## Installation Locale

1. **Cloner le dépôt**:

   ```bash
   git clone [URL-DU-REPO]
   cd campaign-manager
   ```

2. **Créer un fichier .env** avec les variables d'environnement nécessaires:

   ```
   AWS_ACCESS_KEY_ID=votre_access_key
   AWS_SECRET_ACCESS_KEY=votre_secret_key
   ```

3. **Lancer l'application avec Docker Compose**:

   ```bash
   docker-compose up --build
   ```

4. **Accéder à l'application**:
   Ouvrez votre navigateur à l'adresse `http://localhost:80`

## Développement

### Configuration de l'environnement de développement

1. **Créer un environnement virtuel**:

   ```bash
   python -m venv venv
   source venv/bin/activate  # Sur Windows: venv\Scripts\activate
   ```

2. **Installer les dépendances**:

   ```bash
   pip install -r backend/requirements.txt
   pip install -r backend/test-requirements.txt
   ```

3. **Lancer le serveur de développement**:
   ```bash
   cd backend
   FLASK_APP=app.py FLASK_ENV=development flask run
   ```

### Structure du code

- Le backend est développé en Python avec Flask
- L'API communique avec AWS DynamoDB pour le stockage des données
- Le frontend est une application web simple en HTML/CSS/JavaScript

## Tests

### Tests Unitaires

```bash
cd backend
pytest
```

Ces tests utilisent Moto pour simuler les services AWS et tester l'API sans connexion réelle à AWS.

### Tests d'Intégration

Les tests d'intégration sont exécutés automatiquement dans le pipeline CI/CD.

## Déploiement

### Déploiement sur AWS EC2

1. **Configurer une instance EC2**:

   - Lancez une instance EC2 (Ubuntu recommandé)
   - Configurez les groupes de sécurité pour autoriser le trafic HTTP/HTTPS
   - Créez une paire de clés SSH pour l'accès

2. **Configuration manuelle initiale** (à faire une fois):

   ```bash
   # Se connecter à l'instance EC2
   ssh -i votre-cle.pem ubuntu@votre-ec2-ip

   # Installer Docker
   sudo apt-get update
   sudo apt-get install -y docker.io
   sudo systemctl start docker
   sudo usermod -aG docker ubuntu

   # Installer AWS CLI
   sudo apt-get install -y awscli
   aws configure
   ```

3. **Script de déploiement**:
   Utilisez le script `scripts/deploy.sh` pour déployer manuellement l'application.

### Déploiement automatisé via GitHub Actions

Le projet est configuré avec GitHub Actions pour le déploiement automatique. Chaque push sur la branche main déclenche:

1. Exécution des tests
2. Construction de l'image Docker
3. Push de l'image vers Amazon ECR
4. Déploiement sur l'instance EC2

Pour configurer ce workflow:

1. Ajoutez les secrets GitHub nécessaires:

   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `EC2_SSH_PRIVATE_KEY`

2. Mettez à jour l'ID de l'instance EC2 dans le fichier `.github/workflows/main.yaml`

## Monitoring avec Prometheus

### Installation de Prometheus sur EC2

1. **Installation**:

   ```bash
   # Se connecter à l'instance EC2
   ssh -i votre-cle.pem ubuntu@votre-ec2-ip

   # Télécharger Prometheus
   wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz

   # Extraire les fichiers
   tar xvfz prometheus-*.tar.gz
   cd prometheus-*

   # Créer un répertoire de configuration
   sudo mkdir -p /etc/prometheus
   sudo mkdir -p /var/lib/prometheus

   # Copier les binaires
   sudo cp prometheus /usr/local/bin/
   sudo cp promtool /usr/local/bin/

   # Copier les configurations
   sudo cp -r consoles/ /etc/prometheus
   sudo cp -r console_libraries/ /etc/prometheus
   ```

2. **Configuration**:
   Créez un fichier de configuration Prometheus (`/etc/prometheus/prometheus.yml`):

   ```yaml
   global:
     scrape_interval: 15s

   scrape_configs:
     - job_name: "campaign_manager"
       static_configs:
         - targets: ["localhost:5000"]

     - job_name: "node_exporter"
       static_configs:
         - targets: ["localhost:9100"]
   ```

3. **Créer un service systemd**:
   Créez un fichier `/etc/systemd/system/prometheus.service`:

   ```
   [Unit]
   Description=Prometheus
   Wants=network-online.target
   After=network-online.target

   [Service]
   User=ubuntu
   Group=ubuntu
   Type=simple
   ExecStart=/usr/local/bin/prometheus \
       --config.file /etc/prometheus/prometheus.yml \
       --storage.tsdb.path /var/lib/prometheus/ \
       --web.console.templates=/etc/prometheus/consoles \
       --web.console.libraries=/etc/prometheus/console_libraries

   [Install]
   WantedBy=multi-user.target
   ```

4. **Démarrer le service**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl start prometheus
   sudo systemctl enable prometheus
   ```

### Intégration de Prometheus avec l'application Flask

1. **Ajouter les dépendances**:
   Ajoutez `prometheus-flask-exporter` au fichier `backend/requirements.txt`

2. **Modifier le code Flask**:
   Modifiez `backend/app.py` pour intégrer Prometheus:

   ```python
   from flask import Flask, request, jsonify
   from flask_cors import CORS
   from prometheus_flask_exporter import PrometheusMetrics
   import boto3
   import os

   app = Flask(__name__)
   CORS(app)
   metrics = PrometheusMetrics(app)

   # Définir des métriques personnalisées
   campaigns_counter = metrics.counter(
       'campaign_creation_total', 'Total number of campaigns created'
   )

   # ... reste du code ...

   @app.route('/campaigns', methods=['POST'])
   @campaigns_counter
   def add_campaign():
       # ... code existant ...
   ```

3. **Accéder au dashboard Prometheus**:
   Ouvrez votre navigateur à l'adresse `http://votre-ec2-ip:9090`

## Structure du Projet

```
campaign-manager/
│
├── .github/
│   └── workflows/
│       └── main.yaml         # Configuration CI/CD GitHub Actions
│
├── backend/
│   ├── app.py                # Application Flask principale
│   ├── requirements.txt      # Dépendances Python
│   ├── test_app.py           # Tests unitaires
│   └── test-requirements.txt # Dépendances pour les tests
│
├── frontend/
│   ├── index.html            # Page HTML principale
│   ├── app.js                # Code JavaScript
│   └── styles.css            # Styles CSS
│
├── scripts/
│   ├── deploy.sh             # Script de déploiement
│   └── setup-prometheus.sh   # Script d'installation de Prometheus
│
├── docker-compose.yml        # Configuration Docker Compose
├── Dockerfile                # Instructions de build Docker
└── README.md                 # Ce fichier
```

## API Backend

### Endpoints disponibles

- **GET /campaigns**

  - Description: Récupère toutes les campagnes
  - Réponse: Liste des campagnes au format JSON

- **POST /campaigns**
  - Description: Crée une nouvelle campagne
  - Corps de la requête:
    ```json
    {
      "title": "Titre de la campagne",
      "description": "Description de la campagne",
      "start_date": "YYYY-MM-DD",
      "end_date": "YYYY-MM-DD"
    }
    ```
  - Réponse: Confirmation de création

## Configuration AWS

### DynamoDB

1. **Table**: `Campaigns`
2. **Clé primaire**: `id` (String)
3. **Autres attributs**:
   - `title` (String)
   - `description` (String)
   - `start_date` (String)
   - `end_date` (String)

### IAM

Créez un utilisateur IAM avec les politiques suivantes:

- `AmazonDynamoDBFullAccess`
- `AmazonEC2ContainerRegistryFullAccess`
- `AmazonEC2FullAccess`

### Amazon ECR

Le référentiel ECR est créé automatiquement par le pipeline CI/CD s'il n'existe pas.
