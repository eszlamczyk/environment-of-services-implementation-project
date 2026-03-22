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
[Treść sekcji 3...]

## 4. Case study high level architecture
[Treść sekcji 4...]

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
