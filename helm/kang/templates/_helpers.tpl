{{- define "kang.name" -}}{{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- define "kang.fullname" -}}{{- if .Values.fullnameOverride -}}{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{- else -}}{{- $name := include "kang.name" . -}}{{- if contains $name .Release.Name -}}{{ .Release.Name | trunc 63 | trimSuffix "-" }}{{- else -}}{{ printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}{{- end -}}{{- end -}}{{- end -}}
{{- define "kang.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/name: {{ include "kang.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.commonLabels }}{{ toYaml . }}{{- end }}
{{- end -}}
{{- define "kang.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kang.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "kang.backendName" -}}{{ printf "%s-backend" (include "kang.fullname" .) | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- define "kang.frontendName" -}}{{ printf "%s-frontend" (include "kang.fullname" .) | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- define "kang.redisName" -}}{{ printf "%s-redis" (include "kang.fullname" .) | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- define "kang.metricsName" -}}{{ printf "%s-metrics" (include "kang.fullname" .) | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- define "kang.cnpgName" -}}{{ default (printf "%s-db" (include "kang.fullname" .)) .Values.cnpg.cluster.name | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- define "kang.serviceAccountName" -}}{{- if .Values.serviceAccount.create -}}{{ default (include "kang.fullname" .) .Values.serviceAccount.name }}{{- else -}}{{ default "default" .Values.serviceAccount.name }}{{- end -}}{{- end -}}
