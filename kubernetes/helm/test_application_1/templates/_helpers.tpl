{{- define "test_application_1.labels" -}}
{{- if .Chart.AppVersion }}app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.labels }}
{{ $key }}: {{ $value }}
{{- end }}
{{- end -}}