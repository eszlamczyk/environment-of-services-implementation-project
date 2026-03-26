# Acronym: ARGO-CD
# Title: Argo workflow organization and observability

**Authors:** 
- Maciej Michoń 
- Jakub Rękas
- Piotr Rusak
- Ernest Szlamczyk

**Year:** 2026
**Group:** 5

## Contents list
1. [Introduction](#1-introduction)
2. [Theoretical background/technology stack](#2-theoretical-backgroundtechnology-stack)
3. [Case study concept description](#3-case-study-concept-description)
4. [Case study high level architecture](#4-case-study-high-level-architecture)
5. [Case study detailed architecture](#5-case-study-detailed-architecture)
6. [Environment configuration description](#6-environment-configuration-description)
7. [Installation method](#7-installation-method)
8. [Demo deployment steps](#8-demo-deployment-steps)
    * [Configuration set-up](#configuration-set-up)
    * [Data preparation](#data-preparation)
9. [Demo description](#9-demo-description)
    * [Execution procedure](#execution-procedure)
    * [Results presentation](#results-presentation)
10. [Summary - conclusions](#10-summary---conclusions)
11. [References](#11-references)

---

## 1. Introduction
The main objective of this project is to demonstrate modern continuous delivery workflow organization using `Argo CD`, enhanced by Large Language Models through the `Model Context Protocol (MCP)`, and fully monitored using `Prometheus` and `Grafana`. In modern DevOps, managing complex Kubernetes deployments can be challenging. This project aims to bridge the gap between (technical and non technical) human operators and deployment infrastructure by allowing natural language interactions with Argo CD via LLM assistants, while maintaining strict observability and visualization of the deployment states.

## 2. Theoretical background/technology stack
This project utilizes the "Type 1" project architecture model, integrating the following key technologies:

### 2.1. **ArgoCD**
Argo CD is a declarative `GitOps` `CD` (Continuous Delivery) tool for Kubernetes. This tool helps application definitions, configurations and environments to remain declarative and version controlled. Argo also allows application deployment and lifecycle management to be automated, auditable and easy to understand.

Argo follows `GitOps` patters of using Git repos as the source of truth for defining the desired application state. This is implemented as a Kubernetes controller which continuously monitors running applications and compares the current state against the desired git repo state. Deployed application whose live state deviates from the target state is considered `OutOfSync`. Argo then reports and visualizes the differences while providing tools to automatically or manually sync the state.

### 2.2 LLM and Promoting Interface
Large Language Models (e.g. Claude, Cursor, ChatGPT) act as the reasoning engine for the operator, transforming natural language intentions into API actions.

### 2.3 Model Context Protocol (MCP):
MCP (Model Context Protocol) is an open-source standard for connecting AI applications to external systems.

Using MCP, AI applications like Claude or ChatGPT can connect to data sources (e.g. local files, databases), tools (e.g. search engines, calculators) and workflows (e.g. specialized prompts)—enabling them to access key information and perform tasks.

We will use [Argo CD MCP Server](https://github.com/argoproj-labs/mcp-for-argocd). And implementation of the MCP standard for the ArgoCD, enabling integrations with `Visual Studio Code` and other MCP clients through `standard io` and `HTTP` stream transport protocols.

### 2.4 Observability - Prometheus

Prometheus is an open-source systems monitoring and alerting toolkit originally built at `SoundCloud`. Prometheus collects and stores its metrics as time series data, i.e. metrics information is stored with the timestamp at which it was recorded, alongside optional key-value pairs called labels.

#### What are metrics?
Metrics are numerical measurements in layperson terms. The term time series refers to the recording of changes over time. What users want to measure differs from application to application. For a web server, it could be request times; for a database, it could be the number of active connections or active queries, and so on.
Metrics are useful for tasks such as `auto-scaling`. For example, when the number of requests is high, the application may become slow. If the app has the request count metric, it can determine the cause and increase the number of servers to handle the load.

### 2.5 Visualization - Grafana:

Grafana is an open-source tool that enables querying, visualization and exploring of metrics, logs and traces whenever they're stored. Grafana data source plugins enables cooperation between itself and Prometheus. It allows creation of interactive dashboards based on the data itself, allowing operators to visually track the health and performance of the GitOps Workflows.


## 3. Case study concept description

The case study is designed to demonstrate a modernized, GitOps workflow. It simulates a realistic operational scenario where an administrator manages a Kubernetes application deployment not through traditional CLI commands or complex YAML editing, but through natural language interaction, while maintaining complete system observability. 

The concept is divided into three core pillars:

### 3.1 Application deployment & LLM Interaction
The core application workflow centers around a sample Kubernetes deployment whose desired state is stored in a Git repository. Argo CD is responsible for continuously monitoring this repository and ensuring the Kubernetes cluster matches the defined state.
Instead of interacting with Argo CD directly via its UI or CLI, the operator uses an AI agent. The Argo CD MCP server is helpful here'. When the operator types a prompt like, *"Check if the frontend application is out of sync and deploy the latest changes,"* the LLM translates this intent into specific tool calls via the MCP server. The MCP server then executes the corresponding Argo CD API commands to retrieve the status or trigger a synchronization.

### 3.2 Observability
To ensure the automated deployments are functioning correctly, strict observability is applied to the Argo CD infrastructure. Prometheus is configured to scrape metrics directly from Argo CD's built-in `/metrics` endpoints. 
The case study focuses on capturing critical GitOps metrics, including:
- Real-time data on whether the deployed application is `Synced`, `OutOfSync`, `Healthy`, or `Degraded`.
- How long it takes Argo CD to compare the Git repository state with the live cluster state.
- Tracking the volume of API requests, which is particularly important to monitor the frequency of actions triggered by the LLM via the MCP server.

### 3.3 Visualization
The raw time-series data collected by Prometheus is translated into actionable insights using Grafana. The case study will feature a Grafana dashboard tailored specifically for this LLM-enhanced GitOps pipeline. 

## 4. Case study high level architecture

The high-level architecture of this case study follows a closed-loop system where deployment, AI-driven management, and monitoring occur continuously. The architecture consists of the following interacting layers:

### 1. The Source of Truth
- Git repository hosts the declarative Kubernetes manifests, like YAML files, that define the desired state of the target application.

### 2. The Management & Execution Layer
- Argo CD is the central controller running within the Kubernetes cluster. It continuously polls the git repository, compares it against the live cluster state, and applies changes to synchronize them. It also exposes APIs for external control and metrics for monitoring.
- Target Kubernetes environment is the infrastructure where the application workloads are actually provisioned and run.

### 3. The AI Interaction Layer (MCP Stack)
- An AI agent is the user interface  where the user inputs natural language commands.
- Argo CD MCP server is the standard interface that sits between the LLM and Argo CD. It exposes Argo CD's capabilities as "tools" that the LLM can understand and execute via secure API calls.

### 4. The Observability Layer (Monitoring Stack)
- Prometheus operates within the cluster, utilizing a pull-based mechanism to periodically scrape metric data from Argo CD's endpoints and the target application.
- Grafana connects to Prometheus as its primary data source. It provides the visual dashboard layer, querying Prometheus to render the current and historical state of the deployment workflows in real-time.

### Data Flow Summary:
1. The user issues a natural language request to the AI agent.
2. The LLM uses the MCP server to query or command Argo CD.
3. Argo CD fetches the latest state from the git repository and updates the Kubernetes cluster.
4. Simultaneously, Prometheus scrapes operational metrics from Argo CD.
5. Grafana queries Prometheus to visualize the outcome of the actions triggered by the LLM and the overall health of the system.

## 5. Case study detailed architecture
[Treść sekcji 5...]

## 6. Environment configuration description
[Treść sekcji 6...]

## 7. Installation method
[Treść sekcji 7...]

## 8. Demo deployment steps

### Configuration set-up
[Treść...]

### Data preparation
[Treść...]

## 9. Demo description

### Execution procedure
[Treść...]

### Results presentation
[Treść...]

## 10. Summary - conclusions
[Treść sekcji 10...]

## 11. References
[Treść sekcji 11...]
