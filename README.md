# Hello Project

This repository contains both the infrastructure as code (IaC) and a simple Python Flask application deployed on a Google Kubernetes Engine (GKE) cluster. The project demonstrates how to deploy and manage a containerized application using Kubernetes, ArgoCD, and various monitoring and security tools.

## Table of Contents

- [Project Overview](#project-overview)
- [Technologies Used](#technologies-used)
- [Infrastructure Components](#infrastructure-components)
- [Application Components](#application-components)
- [Repository Structure](#repository-structure)
- [Step-by-Step Deployment Guide](#step-by-step-deployment-guide)
  - [Step 1: Clone the Repository](#step-1-clone-the-repository)
  - [Step 2: Set Up the GKE Cluster](#step-2-set-up-the-gke-cluster)
  - [Step 3: Set Up ArgoCD](#step-3-set-up-argocd)
  - [Step 4: Deploy the Flask Application](#step-4-deploy-the-flask-application)
  - [Step 5: Set Up NGINX Ingress for HTTPS](#step-5-set-up-nginx-ingress-for-https)
  - [Step 6: Configure DNS for Your Domain](#step-6-configure-dns-for-your-domain)
  - [Step 7: Set Up Cert-manager and Obtain SSL Certificate via Terraform](#step-7-set-up-cert-manager-and-obtain-ssl-certificate-via-terraform)
  - [Step 8: Check SSL Certificate Status](#step-8-check-ssl-certificate-status)
  - [Step 9: Monitor the Application with Prometheus and Grafana](#step-9-monitor-the-application-with-prometheus-and-grafana)
  - [Step 10: Create a Grafana Dashboard](#step-10-create-a-grafana-dashboard)


## Project Overview

This project focuses on deploying a simple Flask web application in a cloud-native way. The infrastructure is managed entirely using Terraform, and the application is deployed using ArgoCD. The application is exposed to the internet using a LoadBalancer, secured with HTTPS using Let's Encrypt certificates, and monitored with Prometheus and Grafana.

## Technologies Used

- **Google Cloud Platform (GCP)**: Cloud provider hosting the Kubernetes cluster and DNS.
- **Kubernetes**: Container orchestration platform.
- **Terraform**: Infrastructure as code for provisioning resources.
- **ArgoCD**: GitOps tool for continuous deployment and synchronization of Kubernetes resources.
- **NGINX Ingress Controller**: Manages incoming traffic and enables SSL termination.
- **Cert-manager**: Manages SSL certificates with Let's Encrypt.
- **Prometheus**: Monitoring system and time-series database for Kubernetes metrics.
- **Grafana**: Data visualization tool used for monitoring.

## Infrastructure Components

The infrastructure consists of the following components, provisioned using Terraform:

- **GKE Cluster**: A Google Kubernetes Engine cluster with auto-scaling and preemptible nodes.
- **ArgoCD**: A GitOps tool for continuous deployment, installed on the GKE cluster.
- **Prometheus & Grafana**: Monitoring stack deployed on the cluster for tracking metrics.
- **NGINX Ingress Controller**: Handles HTTP and HTTPS traffic routing for the application.
- **Cert-manager**: Automatically provisions and renews Let's Encrypt SSL certificates.

## Application Components

The application is a simple Python Flask app that responds with the message `Hello, travelers!`. 

### Key files:

- `app.py`: The Python Flask application file.
- `Dockerfile`: Defines the container image for the Flask app.
- `deployment.yaml`: Kubernetes deployment manifest for the Flask app.
- `service.yaml`: Kubernetes service manifest to expose the app via a LoadBalancer.

## Repository Structure

```plaintext
hello-project/
├── hello-app/                 # Application source code and Kubernetes manifests
│   ├── k8s_manifests/
│   │   ├── deployment.yaml    # Kubernetes deployment for Flask app
│   │   ├── service.yaml       # Kubernetes service for exposing the app
│   └── app.py                 # Flask application
├── infrastructure/            # Infrastructure as code (Terraform)
│   ├── gcp/                   # GCP infrastructure (GKE cluster, VPC, etc.)
│   │   ├── main.tf            # Main Terraform file for GKE setup
│   ├── argocd/                # ArgoCD configuration
│   │   ├── main.tf            # Terraform file for ArgoCD deployment
│   ├── argocd-resources/      # ArgoCD resources (applications, projects, etc.)
│   │   ├── main.tf            # Terraform file for ArgoCD resources
│   ├── cert-manager/          # Cert-manager and NGINX Ingress configuration
│   │   ├── main.tf            # Terraform file for Cert-manager and NGINX
│   ├── externaldns/           # DNS configuration for managing DNS records
│   │   ├── main.tf            # Terraform file for ExternalDNS
│   ├── prometheus-grafana/    # Prometheus and Grafana setup
│   │   ├── main.tf            # Terraform file for monitoring tools
└── README.md                  # Project documentation (this file)
```

## Step-by-Step Deployment Guide

Follow these steps to deploy the project:

### Step 1: Clone the Repository
First, clone this repository to your local machine:

```bash
git clone https://github.com/LukaszAnti/hello-project.git
cd hello-project
```

### Step 2: Set Up the GKE Cluster
Navigate to the `infrastructure/gcp` folder and use Terraform to set up the Google Kubernetes Engine (GKE) cluster:

```bash
cd infrastructure/gcp
terraform init   # Initialize Terraform in this directory
terraform apply  # Apply the configuration to create the GKE cluster
```

This will provision:
- A GKE cluster with a node pool, autoscaling, and necessary network components.
- A VPC, subnet, and firewall rules for secure cluster communication.

> **Note:** If you have any custom variables in your Terraform configuration (e.g., project ID, region), make sure to replace them with your own values in the `variables.tf` file.

### Step 3: Set Up ArgoCD
After the GKE cluster is up and running, you need to set up ArgoCD for application deployment.

Navigate to the `infrastructure/argocd` folder:

```bash
cd ../argocd
terraform init   # Initialize Terraform in this directory
terraform apply  # Deploy ArgoCD on the GKE cluster
```

ArgoCD will be exposed via a LoadBalancer. You can access the ArgoCD dashboard using the external IP of the LoadBalancer:

```bash
kubectl get svc -n argocd
```

Find the `argocd-server` service and use the external IP to access the dashboard, for example, `http://<EXTERNAL-IP>`.

> **Note:** Replace `<EXTERNAL-IP>` with the actual IP from the `kubectl get svc` command output.

### Step 4: Deploy the Flask Application
Now that ArgoCD is running, it will automatically synchronize and deploy the Flask application based on the manifests located in the `hello-app/k8s_manifests/` directory.

To verify the deployment status:

```bash
kubectl get pods -n argocd
```

The app should be deployed in a pod running in the `argocd` namespace.

> **Note:** If you are using a different namespace for your application, replace `argocd` with your custom namespace.

### Step 5: Set Up NGINX Ingress for HTTPS
To handle HTTPS and routing, you need to set up the NGINX Ingress Controller. Navigate to the `infrastructure/cert-manager` folder:

```bash
cd ../cert-manager
terraform init   # Initialize Terraform in this directory
terraform apply  # Apply configuration to set up NGINX Ingress and Cert-manager
```

This will provision the NGINX Ingress controller, which will route HTTP and HTTPS traffic to your Flask app and automatically provision SSL certificates via Let's Encrypt.

### Step 6: Configure DNS for Your Domain
After deploying the Ingress, you'll need to update your DNS records to point to the external IP address of the Ingress. You can find the IP address using:

```bash
kubectl get svc -n ingress-nginx
```

Find the external IP of the `ingress-nginx-controller` service. Then, update the A record in your domain provider's dashboard (e.g., Google Domains or Squarespace) to point to this IP address.

> **Note:** Replace `ingress-nginx-controller` with the name of your Ingress service if it is different. Also, update the A record with the actual IP you retrieve from the `kubectl get svc` command.

### Step 7: Set Up Cert-manager and Obtain SSL Certificate via Terraform
The Cert-manager and certificate configuration are managed through Terraform. To set them up, navigate to the `cert_manager` directory and apply the Terraform configuration:

```bash
cd ../cert-manager
terraform init   # Initialize Terraform in this directory
terraform apply  # Apply the configuration to set up Cert-manager and obtain an SSL certificate
```

Terraform will configure Cert-manager to use Let's Encrypt for SSL certificate provisioning and will automatically issue a certificate for your domain.

> **Note:** If you have custom variables for the domain name or other configurations in the `cert_manager` module, make sure to replace them with your own values before applying Terraform.

### Step 8: Check SSL Certificate Status
After the certificate has been requested, you can check the status of the certificate by running the following command:

```bash
kubectl describe certificate <certificate-name> -n <namespace>
```

> **Note:** Replace `<certificate-name>` with the name of your certificate (e.g., `flask-app-cert`) and `<namespace>` with the namespace where your application is deployed (e.g., `argocd`). Make sure to use the actual names relevant to your setup.

### Step 9: Monitor the Application with Prometheus and Grafana
To monitor the application and the Kubernetes cluster, Prometheus and Grafana are deployed. Navigate to the `infrastructure/prometheus` directory:

```bash
cd ../prometheus
terraform init   # Initialize Terraform in this directory
terraform apply  # Apply configuration to set up Prometheus and Grafana
```

Grafana will be accessible via a LoadBalancer. You can find the external IP with:

```bash
kubectl get svc -n monitoring
```

Use this IP address to access Grafana in your browser.

### Step 10: Create a Grafana Dashboard
Once you have access to the Grafana interface, follow these steps to create a new dashboard:

1. **Login to Grafana**: Use the external IP of the Grafana LoadBalancer to access Grafana.
   
2. **Create a New Dashboard**:
   - In the Grafana UI, click on the "+" icon on the left panel and select "Dashboard."
   - Click on "Add new panel."

3. **Configure the Panel**:
   - Choose a data source (Prometheus should be pre-configured).
   - In the "Metrics" tab, write a PromQL query to fetch the desired metrics (e.g., for CPU usage: `node_cpu_seconds_total`).
   
4. **Customize the Panel**:
   - Configure the visualization type (e.g., graph, gauge, etc.).
   - Set any thresholds, legends, and time ranges according to your needs.

5. **Save the Dashboard**:
   - Once you're satisfied with the panel configuration, click "Apply."
   - You can add more panels to the same dashboard as needed.
   - Save the dashboard by clicking the "Save" icon and providing a name for your dashboard.

Now your Grafana dashboard is set up and displaying metrics from Prometheus!
