{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "secret-duplicator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "secret-duplicator.serviceName" -}}
secret-duplicator-svc
{{- end }}

{{- define "secret-duplicator.certificateSecretName" -}}
{{ include "secret-duplicator.name" . }}-webhook-certs
{{- end }}

{{- define "secret-duplicator.lookupCaBundle" -}}
{{- /* Find the name of the secret corresponding to the default SA in the default namespace */ -}}
{{- /* Equivalent to `kubectl get sa -n default default -ojsonpath='{.secrets[0].name}'` */ -}}
{{- $defaultSecretName := ((lookup "v1" "ServiceAccount" "default" "default").secrets | first).name -}}
{{- /* Fetch the ca.crt from the default secret (still base64-encoded)*/ -}}
{{- /* Equivalent to `kubectl get secret -n default $defaultSecretName -ojsonpath='{.data.ca\.crt}'` */ -}}
{{- $caBundle := get (lookup "v1" "Secret" "default" $defaultSecretName ).data "ca.crt" -}}
{{- $caBundle -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "secret-duplicator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "secret-duplicator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "secret-duplicator.labels" -}}
helm.sh/chart: {{ include "secret-duplicator.chart" . }}
{{ include "secret-duplicator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "secret-duplicator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "secret-duplicator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "secret-duplicator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "secret-duplicator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
