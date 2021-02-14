{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "coredns.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "coredns.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Generate the list of ports automatically from the server definitions
*/}}
{{- define "coredns.servicePorts" -}}
    {{/* Set ports to be an empty dict */}}
    {{- $ports := dict -}}
    {{/* Iterate through each of the server blocks */}}
    {{- range .Values.servers -}}
        {{/* Capture port to avoid scoping awkwardness */}}
        {{- $port := toString .port -}}

        {{/* If none of the server blocks has mentioned this port yet take note of it */}}
        {{- if not (hasKey $ports $port) -}}
            {{- $ports := set $ports $port (dict "istcp" false "isudp" false) -}}
        {{- end -}}
        {{/* Retrieve the inner dict that holds the protocols for a given port */}}
        {{- $innerdict := index $ports $port -}}

        {{/*
        Look at each of the zones and check which protocol they serve
        At the moment the following are supported by CoreDNS:
        UDP: dns://
        TCP: tls://, grpc://
        */}}
        {{- range .zones -}}
            {{- if has (default "" .scheme) (list "dns://") -}}
                {{/* Optionally enable tcp for this service as well */}}
                {{- if eq (default false .use_tcp) true }}
                    {{- $innerdict := set $innerdict "istcp" true -}}
                {{- end }}
                {{- $innerdict := set $innerdict "isudp" true -}}
            {{- end -}}

            {{- if has (default "" .scheme) (list "tls://" "grpc://") -}}
                {{- $innerdict := set $innerdict "istcp" true -}}
            {{- end -}}
        {{- end -}}

        {{/* If none of the zones specify scheme, default to dns:// on both tcp & udp */}}
        {{- if and (not (index $innerdict "istcp")) (not (index $innerdict "isudp")) -}}
            {{- $innerdict := set $innerdict "isudp" true -}}
            {{- $innerdict := set $innerdict "istcp" true -}}
        {{- end -}}

        {{/* Write the dict back into the outer dict */}}
        {{- $ports := set $ports $port $innerdict -}}
    {{- end -}}

    {{/* Write out the ports according to the info collected above */}}
    {{- range $port, $innerdict := $ports -}}
        {{- if index $innerdict "isudp" -}}
            {{- printf "- {port: %v, protocol: UDP, name: udp-%s}\n" $port $port -}}
        {{- end -}}
        {{- if index $innerdict "istcp" -}}
            {{- printf "- {port: %v, protocol: TCP, name: tcp-%s}\n" $port $port -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{/*
Generate the list of ports automatically from the server definitions
*/}}
{{- define "coredns.containerPorts" -}}
    {{/* Set ports to be an empty dict */}}
    {{- $ports := dict -}}
    {{/* Iterate through each of the server blocks */}}
    {{- range .Values.servers -}}
        {{/* Capture port to avoid scoping awkwardness */}}
        {{- $port := toString .port -}}

        {{/* If none of the server blocks has mentioned this port yet take note of it */}}
        {{- if not (hasKey $ports $port) -}}
            {{- $ports := set $ports $port (dict "istcp" false "isudp" false) -}}
        {{- end -}}
        {{/* Retrieve the inner dict that holds the protocols for a given port */}}
        {{- $innerdict := index $ports $port -}}

        {{/*
        Look at each of the zones and check which protocol they serve
        At the moment the following are supported by CoreDNS:
        UDP: dns://
        TCP: tls://, grpc://
        */}}
        {{- range .zones -}}
            {{- if has (default "" .scheme) (list "dns://") -}}
                {{/* Optionally enable tcp for this service as well */}}
                {{- if eq (default false .use_tcp) true }}
                    {{- $innerdict := set $innerdict "istcp" true -}}
                {{- end }}
                {{- $innerdict := set $innerdict "isudp" true -}}
            {{- end -}}

            {{- if has (default "" .scheme) (list "tls://" "grpc://") -}}
                {{- $innerdict := set $innerdict "istcp" true -}}
            {{- end -}}
        {{- end -}}

        {{/* If none of the zones specify scheme, default to dns:// on both tcp & udp */}}
        {{- if and (not (index $innerdict "istcp")) (not (index $innerdict "isudp")) -}}
            {{- $innerdict := set $innerdict "isudp" true -}}
            {{- $innerdict := set $innerdict "istcp" true -}}
        {{- end -}}

        {{/* Write the dict back into the outer dict */}}
        {{- $ports := set $ports $port $innerdict -}}
    {{- end -}}

    {{/* Write out the ports according to the info collected above */}}
    {{- range $port, $innerdict := $ports -}}
        {{- if index $innerdict "isudp" -}}
            {{- printf "- {containerPort: %v, protocol: UDP, name: udp-%s}\n" $port $port -}}
        {{- end -}}
        {{- if index $innerdict "istcp" -}}
            {{- printf "- {containerPort: %v, protocol: TCP, name: tcp-%s}\n" $port $port -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "coredns.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "coredns.labels" -}}
eks.amazonaws.com/component: {{ include "coredns.name" . }}
helm.sh/chart: {{ include "coredns.chart" . }}
{{- if .Values.isClusterService }}
kubernetes.io/name: "CoreDNS"
kubernetes.io/cluster-service: "true"
{{- end }}
{{ include "coredns.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "coredns.selectorLabels" -}}
app.kubernetes.io/name: {{ include "coredns.name" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- if .Values.isClusterService }}
k8s-app: {{ .Chart.Name | quote }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "coredns.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "coredns.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Choose the name of the repository to use from the region provided
*/}}
{{- define "coredns.repository" }}
{{- if eq .Values.region "me-south-1" }}
{{- default "558608220178.dkr.ecr.me-south-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "eu-south-1" }}
{{- default "590381155156.dkr.ecr.eu-south-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "ap-northeast-1" }}
{{- default "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "ap-northeast-2" }}
{{- default "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "ap-south-1" }}
{{- default "602401143452.dkr.ecr.ap-south-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "ap-southeast-1" }}
{{- default "602401143452.dkr.ecr.ap-southeast-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "ap-southeast-2" }}
{{- default "602401143452.dkr.ecr.ap-southeast-2.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "ca-central-1" }}
{{- default "602401143452.dkr.ecr.ca-central-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "eu-central-1" }}
{{- default "602401143452.dkr.ecr.eu-central-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "eu-north-1" }}
{{- default "602401143452.dkr.ecr.eu-north-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "eu-west-1" }}
{{- default "602401143452.dkr.ecr.eu-west-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "eu-west-2" }}
{{- default "602401143452.dkr.ecr.eu-west-2.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "eu-west-3" }}
{{- default "602401143452.dkr.ecr.eu-west-3.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "sa-east-1" }}
{{- default "602401143452.dkr.ecr.sa-east-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "us-east-1" }}
{{- default "602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "us-east-2" }}
{{- default "602401143452.dkr.ecr.us-east-2.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "us-west-1" }}
{{- default "602401143452.dkr.ecr.us-west-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "us-west-2" }}
{{- default "602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "ap-east-1" }}
{{- default "800184023465.dkr.ecr.ap-east-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "af-south-1" }}
{{- default "877085696533.dkr.ecr.af-south-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "us-gov-west-1" }}
{{- default "013241004608.dkr.ecr.us-gov-west-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "us-gov-east-1" }}
{{- default "151742754352.dkr.ecr.us-gov-east-1.amazonaws.com/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "cn-north-1" }}
{{- default "918309763551.dkr.ecr.cn-north-1.amazonaws.com.cn/eks/coredns" .Values.image.repository }}
{{- else if eq .Values.region "cn-northwest-1" }}
{{- default "961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn/eks/coredns" .Values.image.repository }}
{{- else }}
{{- $default := printf "%s.%s.%s" "602401143452.dkr.ecr" .Values.region "amazonaws.com/eks/coredns" }}
{{- default $default .Values.image.repository }}
{{- end }}
{{- end }}
