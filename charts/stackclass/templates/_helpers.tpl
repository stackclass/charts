
{{/*
Expand the name of the chart.
*/}}
{{- define "stackclass.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "stackclass.fullname" -}}
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
{{- define "stackclass.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "stackclass.labels" -}}
helm.sh/chart: {{ include "stackclass.chart" . }}
{{ include "stackclass.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "stackclass.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stackclass.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "stackclass.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create -}}
    {{ default (include "stackclass.fullname" .) .Values.serviceAccount.name }}
  {{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
  {{- end -}}
{{- end -}}

{{/*
Generate a random password for PostgreSQL.
The password consists of 16 alphanumeric characters.
*/}}
{{- define "stackclass.postgresql.password" -}}
  {{- if not .Values.postgresql.password -}}
    {{- $password := randAlphaNum 16 -}}
  {{- $_ := set .Values "postgresql" (merge .Values.postgresql (dict "password" $password)) -}}
  {{- end -}}
  {{- .Values.postgresql.password -}}
{{- end -}}

{{/*
Generate PostgreSQL connection URL based on enabled status.
Usage: {{ include "stackclass.postgresql.url" . }}
*/}}
{{- define "stackclass.postgresql.url" -}}
  {{- if .Values.postgresql.enabled -}}
    {{- printf "postgresql://%s:%s@%s-postgresql/%s" .Values.postgresql.auth.username (include "stackclass.postgresql.password" .) .Release.Name .Values.postgresql.auth.database | quote -}}
  {{- else -}}
    "postgresql://<REPLACE_WITH_DB_USER>:<REPLACE_WITH_DB_PASS>@localhost/<REPLACE_WITH_DB_DATABASE>"
  {{- end -}}
{{- end -}}
