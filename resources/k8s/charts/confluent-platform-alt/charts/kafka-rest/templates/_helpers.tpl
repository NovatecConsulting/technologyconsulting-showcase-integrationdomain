{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kafka-rest.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kafka-rest.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kafka-rest.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified zookeeper name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "kafka-rest.zookeeper.fullname" -}}
{{- $name := default "zookeeper" (index .Values "zookeeper" "nameOverride") -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Form the Zookeeper URL. If zookeeper is installed as part of this chart, use k8s service discovery,
else use user-provided URL
*/}}
{{- define "kafka-rest.zookeeper.service-name" }}
{{- if (index .Values "zookeeper" "url") -}}
{{- printf "%s" (index .Values "zookeeper" "url") }}
{{- else -}}
{{- $clientPort := default 2181 (index .Values "zookeeper" "clientPort") | int -}}
{{- printf "%s-headless:%d" (include "kafka-rest.zookeeper.fullname" .) $clientPort }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified schema registry name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "kafka-rest.schema-registry.fullname" -}}
{{- $name := default "schema-registry" (index .Values "schema-registry" "nameOverride") -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka-rest.schema-registry.service-name" -}}
{{- if (index .Values "schema-registry" "url") -}}
{{- printf "%s" (index .Values "schema-registry" "url") -}}
{{- else -}}
{{- printf "http://%s:8081" (include "kafka-rest.schema-registry.fullname" .) -}}
{{- end -}}
{{- end -}}
