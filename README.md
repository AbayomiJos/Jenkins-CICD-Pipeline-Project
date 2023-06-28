# CICD-Project
# Complete Jenkins CICD Pipeline Project

```
Jenkins Pipeline Stages :-
  - Cloning Repository From GitHub To Jenkins Workspace Using Git Checkout
  - Building Artifact Using Maven
  - Code Quality Check Using SonarQube
  - Storing Artifact In AWS S3 Bucket
  - Pulling Artifact From AWS S3 Bucket to Build Dockerfile
  - Building Docker Image From Dockerfile
  - Pushing Docker Image To AWS ECR
  - Sending Kubernetes Manifest to an AWS EKS Cluster Agent
  - Taking SSH Of EKS Cluster Agent, Creating Cluster And Node Group, And Deploying K8S Manifest
  - Sending Continuous Reports Of Every Stage To A Slack Channel

```
```
Jenkins Plugins Used :-
  - Git
  - Maven
  - SSH Agent
  - Docker
  - Docker Pipeline
  - Pipeline: AWS Steps
  - SonarQube Scanner
  - Slack Notification
  - Kubernetes CLI

```
