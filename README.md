# Spring Boot CI/CD to EKS (Azure DevOps + ECR + Helm + Cosign + AWS KMS)

## Overview

This repository implements a secure CI/CD pipeline for a Spring Boot
application deployed to multiple EKS clusters (Dev/Staging/Prod) using:

-   Azure DevOps Pipelines
-   Amazon ECR (central registry)
-   Amazon EKS (separate clusters per environment)
-   Helm
-   Trivy (container vulnerability scanning)
-   Cosign + AWS KMS (image signing + verification)
-   Digest-based deployments (repo@sha256)

Pipeline flow:

Build → Scan → Push → Sign → Deploy Dev → Deploy Staging → Deploy Prod

------------------------------------------------------------------------

## Architecture

-   Central ECR registry (single account)
-   Separate AWS accounts / roles per EKS environment
-   Immutable deployments using image digests
-   Signature verification before deployment

------------------------------------------------------------------------

## Pipeline Stages

### 1. Build_Scan_Push_Sign

-   Build Docker image
-   Run Trivy image scan
-   Push image to ECR
-   Extract image digest
-   Sign image using AWS KMS via Cosign
-   Publish image digest as artifact

### 2. Deploy (Dev / Staging / Prod)

Each deploy stage: - Downloads image digest artifact - Verifies
signature with AWS KMS - Updates kubeconfig for target EKS cluster -
Deploys using Helm - Waits for rollout completion

------------------------------------------------------------------------

## Cosign + AWS KMS

Only the KMS alias is defined in the pipeline:

cosignKmsAlias: cosign-key

At runtime, the pipeline builds:

awskms:///arn:aws:kms:`<region>`{=html}:`<account-id>`{=html}:alias/`<alias>`{=html}

Signing: cosign sign --key `<KMS_URI>`{=html} `<IMAGE_REF>`{=html}

Verification: cosign verify --key `<KMS_URI>`{=html}
`<IMAGE_REF>`{=html}

No private keys are stored in Azure DevOps.

------------------------------------------------------------------------

## IAM Roles & Permissions

### ECR Central Role

Required permissions:

ECR: - ecr:GetAuthorizationToken - ecr:BatchCheckLayerAvailability -
ecr:GetDownloadUrlForLayer - ecr:BatchGetImage - ecr:PutImage -
ecr:InitiateLayerUpload - ecr:UploadLayerPart - ecr:CompleteLayerUpload

KMS: - kms:Sign - kms:Verify - kms:GetPublicKey - kms:DescribeKey

------------------------------------------------------------------------

### EKS Environment Roles

Required: - eks:DescribeCluster

Plus Kubernetes RBAC access (via aws-auth ConfigMap or Access Entries).

------------------------------------------------------------------------

## Ingress with AWS Load Balancer Controller

If AWS Load Balancer Controller and ExternalDNS are installed:

-   Ingress automatically creates:
    -   ALB
    -   Listener rules
    -   Target Group
    -   Registers pod targets

Example annotations:

kubernetes.io/ingress.class: alb alb.ingress.kubernetes.io/scheme:
internet-facing external-dns.alpha.kubernetes.io/hostname:
app.example.com

ExternalDNS creates the Route53 record automatically.
 
 Example:

 ```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: springboot
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/group.name: springboot
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:eu-west-1:xxxxxxxxx:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "{{ health_interval }}"
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "{{ health_timeout }}"
    alb.ingress.kubernetes.io/healthy-threshold-count: "{{ healthy_threshold }}"
    alb.ingress.kubernetes.io/unhealthy-threshold-count: "{{ unhealthy_threshold }}"
    alb.ingress.kubernetes.io/success-codes: "200"
    external-dns.alpha.kubernetes.io/hostname: springboot-dev.example.com

spec:
  rules:
    - host: springboot-dev.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: springboot
                port:
                  number: 80

```

------------------------------------------------------------------------

## Security Features

-   Vulnerability scanning (Trivy)
-   Immutable digest deployments
-   Signed container images
-   Signature verification before deploy
-   Environment approvals in Azure DevOps

------------------------------------------------------------------------

## Summary

This pipeline demonstrates:

-   Secure multi-environment deployments
-   Centralized container registry
-   KMS-backed image signing
-   Promotion workflow with approval gates
-   Automated ALB + DNS exposure via Kubernetes Ingress