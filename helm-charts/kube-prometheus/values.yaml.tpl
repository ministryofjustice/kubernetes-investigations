# exporter-node configuration
deployExporterNode: true

# Grafana
deployGrafana: true

grafana:
  auth:
    anonymous:
      enabled: "false"

    adminUser: "${random_id}"
    adminPassword: "${random_id}"

  ingress:
    enabled: true
    hosts: 
    - "${grafana_ingress}"

  serverDashboardConfigmaps:
    - grafana-user-dashboards

  extraVars:
    - name: GF_SERVER_ROOT_URL
      value: "${grafana_root}"
    - name: GF_ANALYTICS_REPORTING_ENABLED
      value: "false"
    - name: GF_AUTH_DISABLE_LOGIN_FORM
      value: "true"
    - name: GF_USERS_ALLOW_SIGN_UP
      value: "false"
    - name: GF_USERS_AUTO_ASSIGN_ORG_ROLE
      value: "Viewer"
    - name: GF_USERS_VIEWERS_CAN_EDIT
      value: "true"
    - name: GF_AUTH_GITHUB_ENABLED
      value: "true"
    - name: GF_AUTH_GITHUB_ALLOW_SIGN_UP
      value: "true"
    - name: GF_AUTH_GITHUB_CLIENT_ID
      valueFrom:
        secretKeyRef:
          key: client-id
          name: grafana-auth-secret
    - name: GF_AUTH_GITHUB_CLIENT_SECRET
      valueFrom:
        secretKeyRef:
          key: client-secret
          name: grafana-auth-secret
    - name: GF_AUTH_GITHUB_ALLOWED_ORGANIZATIONS
      value: "ministryofjustice"
    - name: GF_SECURITY_SECRET_KEY
      valueFrom:
        secretKeyRef:
          key: cookie-secret
          name: grafana-auth-secret
    - name: GF_SMTP_ENABLED
      value: "false"

## If true, create & use RBAC resources resp. Pod Security Policies
##
global:
  rbacEnable: true
  pspEnable: true

# AlertManager
deployAlertManager: true

alertmanager:
  ## Alertmanager configuration directives
  ## Ref: https://prometheus.io/docs/alerting/configuration/
  ##
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'null'
      routes:
      - match:
          alertname: DeadMansSwitch
        receiver: 'null'
      - match:
          severity: critical
        receiver: pager-duty-high-priority
      - match:
          severity: warning
        receiver: slack-low-priority
    receivers:
    - name: 'null'
    # Add PagerDuty key to allow integration with a PD service.
    - name: 'pager-duty-high-priority'
      pagerduty_configs:
      - service_key: "${pagerduty_config}"
    # Add Slack webhook API URL and channel for integration with slack.
    - name: 'slack-low-priority'
      slack_configs:
      - api_url: "${slack_config}"
        channel: "#lower-priority-alarms"
        title: "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}"
        text: "{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}"
        send_resolved: True

  ## Alertmanager template files to include
  #
  templateFiles: {}


  ## External URL at which Alertmanager will be reachable
  ##
  externalUrl: "${alertmanager_ingress}"

  ## Alertmanager container image
  ##
  image:
    repository: quay.io/prometheus/alertmanager
    tag: v0.14.0

  ingress:
    ## If true, Alertmanager Ingress will be created
    ##
    enabled: false

    ## Annotations for Alertmanager Ingress
    ##
    annotations: {}
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"

    ## Labels to be added to the Ingress
    ##
    labels: {}

    ## Hostnames.
    ## Must be provided if Ingress is enabled.
    ##
    # hosts:
    #   - alertmanager.domain.com
    hosts: []

    ## TLS configuration for Alertmanager Ingress
    ## Secret must be manually created in the namespace
    ##
    tls: []
      # - secretName: alertmanager-general-tls
      #   hosts:
      #     - alertmanager.example.com

  ## Node labels for Alertmanager pod assignment
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector: {}

  ## If true, the Operator won't process any Alertmanager configuration changes
  ##
  paused: false

  ## Number of Alertmanager replicas desired
  ##
  replicaCount: 1

  ## Pod anti-affinity can prevent the scheduler from placing Alertmanager replicas on the same node.
  ## The default value "soft" means that the scheduler should *prefer* to not schedule two replica pods onto the same node but no guarantee is provided.
  ## The value "hard" means that the scheduler is *required* to not schedule two replica pods onto the same node.
  ## The value "" will disable pod anti-affinity so that no anti-affinity rules will be configured.
  podAntiAffinity: "soft"

  ## Resource limits & requests
  ## Ref: https://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}
    # requests:
    #   memory: 400Mi

  ## List of Secrets in the same namespace as the AlertManager
  ## object, which shall be mounted into the AlertManager Pods.
  ## Ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#alertmanagerspec
  ##
  secrets: []

  service:
    ## Annotations to be added to the Service
    ##
    annotations: {}

    ## Cluster-internal IP address for Alertmanager Service
    ##
    clusterIP: ""

    ## List of external IP addresses at which the Alertmanager Service will be available
    ##
    externalIPs: []

    ## External IP address to assign to Alertmanager Service
    ## Only used if service.type is 'LoadBalancer' and supported by cloud provider
    ##
    loadBalancerIP: ""

    ## List of client IPs allowed to access Alertmanager Service
    ## Only used if service.type is 'LoadBalancer' and supported by cloud provider
    ##
    loadBalancerSourceRanges: []

    ## Port to expose on each node
    ## Only used if service.type is 'NodePort'
    ##
    nodePort: 30903

    ## Service type
    ##
    type: ClusterIP

  ## Alertmanager StorageSpec for persistent data
  ## Ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/storage.md
  ##
  # storageSpec:
  #   volumeClaimTemplate:
  #     spec:
  #       storageClassName: prometheus-storage
  #       accessModes: ["ReadWriteOnce"]
  #       resources:
  #         requests:
  #           storage: 100Gi
  #     selector: {}

prometheus:
  ## Alertmanagers to which alerts will be sent
  ## Ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#alertmanagerendpoints
  ##
  alertingEndpoints: []
  #   - name: ""
  #     namespace: ""
  #     port: 9093
  #     scheme: http

  ## Prometheus configuration directives
  ## Ignored if serviceMonitors are defined
  ## Ref: https://prometheus.io/docs/operating/configuration/
  ##
  config:
    specifiedInValues: true
    value: {}

  ## External URL at which Prometheus will be reachable
  ##
  externalUrl: "${promtheus_ingress}"

  ## Prometheus container image
  ##
  image:
    repository: quay.io/prometheus/prometheus
    tag: v2.2.1

  ingress:
    ## If true, Prometheus Ingress will be created
    ##
    enabled: false

    ## Annotations for Prometheus Ingress
    ##
    annotations: {}
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"

    ## Labels to be added to the Ingress
    ##
    labels: {}

    ## Hostnames.
    ## Must be provided if Ingress is enabled.
    ##
    # hosts:
    #   - alertmanager.domain.com
    hosts: []

    ## TLS configuration for Prometheus Ingress
    ## Secret must be manually created in the namespace
    ##
    tls: []
      # - secretName: prometheus-k8s-tls
      #   hosts:
      #     - prometheus.example.com

  ## Node labels for Prometheus pod assignment
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector: {}

  ## If true, the Operator won't process any Prometheus configuration changes
  ##
  paused: false

  ## Number of Prometheus replicas desired
  ##
  replicaCount: 1

  ## Pod anti-affinity can prevent the scheduler from placing Prometheus replicas on the same node.
  ## The default value "soft" means that the scheduler should *prefer* to not schedule two replica pods onto the same node but no guarantee is provided.
  ## The value "hard" means that the scheduler is *required* to not schedule two replica pods onto the same node.
  ## The value "" will disable pod anti-affinity so that no anti-affinity rules will be configured.
  podAntiAffinity: "soft"

  ## Resource limits & requests
  ## Ref: https://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}
    # requests:
    #   memory: 400Mi

  ## List of Secrets in the same namespace as the Prometheus
  ## object, which shall be mounted into the Prometheus Pods.
  ## Ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusspec
  ##
  secrets: []

  ## How long to retain metrics
  ##
  retention: 30d

  ## Prefix used to register routes, overriding externalUrl route.
  ## Useful for proxies that rewrite URLs.
  ##
  routePrefix: /

  ## Rules configmap selector
  ## Ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/design.md
  ##
  ## 1. If `matchLabels` is used, `rules.additionalLabels` must contain all the labels from
  ##    `matchLabels` in order to be be matched by Prometheus
  ## 2. If `matchExpressions` is used `rules.additionalLabels` must contain at least one label
  ##    from `matchExpressions` in order to be matched by Prometheus
  ## Ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels
  rulesSelector: {}
   # rulesSelector: {
   #   matchExpressions: [{key: prometheus, operator: In, values: [example-rules, example-rules-2]}]
   # }
   ### OR
   # rulesSelector: {
   #   matchLabels: [{role: example-rules}]
   # }

  ## Prometheus alerting & recording rules
  ## Ref: https://prometheus.io/docs/querying/rules/
  ## Ref: https://prometheus.io/docs/alerting/rules/
  ##
  rules:
    specifiedInValues: true
    ## What additional rules to be added to the ConfigMap
    ## You can use this together with `rulesSelector`
    additionalLabels: {}
    #  prometheus: example-rules
    #  application: etcd
    value: {}

  service:
    ## Annotations to be added to the Service
    ##
    annotations: {}

    ## Cluster-internal IP address for Prometheus Service
    ##
    clusterIP: ""

    ## List of external IP addresses at which the Prometheus Service will be available
    ##
    externalIPs: []

    ## External IP address to assign to Prometheus Service
    ## Only used if service.type is 'LoadBalancer' and supported by cloud provider
    ##
    loadBalancerIP: ""

    ## List of client IPs allowed to access Prometheus Service
    ## Only used if service.type is 'LoadBalancer' and supported by cloud provider
    ##
    loadBalancerSourceRanges: []

    ## Port to expose on each node
    ## Only used if service.type is 'NodePort'
    ##
    nodePort: 30900

    ## Service type
    ##
    type: ClusterIP

  ## Service monitors selector
  ## Ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/design.md
  ##
  serviceMonitorsSelector:
    any: true

  serviceMonitorNamespaceSelector:
    any: true

  ## ServiceMonitor CRDs to create & be scraped by the Prometheus instance.
  ## Ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/service-monitor.md
  ##
  serviceMonitors: []
    ## Name of the ServiceMonitor to create
    ##
    # - name: ""

      ## Service label for use in assembling a job name of the form <label value>-<port>
      ## If no label is specified, the service name is used.
      ##
      # jobLabel: ""

      ## Label selector for services to which this ServiceMonitor applies
      ##
      # selector: {}

      ## Namespaces from which services are selected
      ##
      # namespaceSelector:
        ## Match any namespace
        ##
        # any: false

        ## Explicit list of namespace names to select
        ##
        # matchNames: []

      ## Endpoints of the selected service to be monitored
      ##
      # endpoints: []
        ## Name of the endpoint's service port
        ## Mutually exclusive with targetPort
        # - port: ""

        ## Name or number of the endpoint's target port
        ## Mutually exclusive with port
        # - targetPort: ""

        ## File containing bearer token to be used when scraping targets
        ##
        #   bearerTokenFile: ""

        ## Interval at which metrics should be scraped
        ##
        #   interval: 30s

        ## HTTP path to scrape for metrics
        ##
        #   path: /metrics

        ## HTTP scheme to use for scraping
        ##
        #   scheme: http

        ## TLS configuration to use when scraping the endpoint
        ##
        #   tlsConfig:

            ## Path to the CA file
            ##
            # caFile: ""

            ## Path to client certificate file
            ##
            # certFile: ""

            ## Skip certificate verification
            ##
            # insecureSkipVerify: false

            ## Path to client key file
            ##
            # keyFile: ""

            ## Server name used to verify host name
            ##
            # serverName: ""

  ## Prometheus StorageSpec for persistent data
  ## Ref: https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/storage.md
  ##
  storageSpec:
    volumeClaimTemplate:
      spec:
        storageClassName: prometheus-storage
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Gi
      selector: {}


# default rules are in templates/general.rules.yaml
prometheusRules: {}

# Select Deployed DNS Solution
deployCoreDNS: false
deployKubeDNS: true
deployKubeEtcd: true