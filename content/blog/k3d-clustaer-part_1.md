---
type: blog
title: "Home Services - Part 1 - Preparations"
draft: false
categories: it
date: 2025-03-21T11:13:00+02:00
---
## Task
The goal is to learn Kubernetes (k8s) usage and deliver services to users. In this first part of the article series, I’ll prepare my server to handle real workloads.

## Description:
I’m transforming an old HP notebook into a home server. It currently functions as a print server and scan station, leveraging its multifunction unit (MFU) printer. My aim is to migrate ScanserverJS (a scanning service) and Paperless-NGX (a document management solution) into a k3d cluster—a lightweight Kubernetes setup running in Docker. This project serves as a hands-on way to learn Kubernetes while enhancing service management on constrained hardware.

## Planing
- Create a separate Docker network for service isolation.
- Set up a k3d cluster using a custom configuration file.
- Expose the cluster to the local network via NAT.
- Deploy ScanserverJS and make it accessible.
- Deploy Paperless-NGX and make it accessible.
## Diagrams
### Network diagram in C4 notation

The diagram below illustrates the interactions between the local network, server, and Kubernetes components, showing how they collaborate to deliver services.

![Project 01](/files/project-01.png)

This diagram offers a high-level perspective on how users, services, and hardware interact within the local network. It emphasizes:
- The server’s role as the central host.
- The use of Docker and Kubernetes for containerized services.
- The integration of hardware (the printer) with software services (ScanserverJS).
#### **Relationships**
- **User ↔ Local Network**: The user accesses services (e.g., ScanserverJS, Paperless-NGX) over HTTP/HTTPS.
- **Administrator ↔ Local Network**: The administrator manages services (e.g., Docker, Kubernetes) via SSH or `kubectl`.
- **Local Network ↔ Server**: The server is part of the local network and hosts all services.    
- **Server ↔ Printer**: The printer is connected to the server via USB.    
- **Server ↔ Docker**: The server runs the Docker daemon, which manages the `k3d Cluster`.
* **ScanserverJS ↔ Printer**: The ScanserverJS service interacts with the printer via the host (USB connection).
#### **Key Components**
1. **Local Network Context**:
    - **Users**:
        - **User**: A local network user who accesses services via HTTP/HTTPS.
        - **Administrator**: A local network user who manages services through SSH or `kubectl`.
    - **Printer (MFU)**: A USB-connected multifunction unit (MFU) with an IP address (`192.168.0.42`) connected to the server.
    - **Local Network**: Represented as a cloud, it encompasses the `192.168.0.0/24` subnet where all components operate.
2. **Physical Host (Server)**:
    - The server (`192.168.0.42`) acts as the central host for running services.
    - It includes:
        - **Docker Engine**: A container engine that runs the `k3d Cluster`.
        - **k3d Cluster**: A lightweight Kubernetes cluster running on Docker. 
            - **ScanserverJS**: A service for scanning documents.
            - **Paperless-NGX**: A document management solution.
### Simple sequence diagram for typical usage

The sequence diagram below outlines the process when a user requests a document from Paperless-NGX. It traces the request’s journey through the local network, server, and containerized infrastructure, culminating in the document’s delivery back to the user.

This provides a clear view of service communication within the setup. Here’s the request flow:

![Project 02](/files/project-02.png)

#### **Flow Overview**

1. **User Request Initiation**:
    
    - The **User** sends an HTTP `GET` request to **paperless.local**.
    - This request is transmitted through the **Local Network (LAN)**.
2. **Request Routing**:
    
    - The **Local Network (LAN)** routes the request to the **Host (192.168.0.42)**.
    - The **Host** forwards the request to the **Docker** network (`10.0.0.0/16`).
3. **Ingress Processing**:
    
    - **Traefik**, the Ingress Controller, receives the request from Docker.
    - It examines the **Host header** (`paperless.local`) and routes the request to the **Paperless-NGX** service.
4. **Service Processing**:
    
    - **Paperless-NGX** processes the request by retrieving the requested document.
5. **Response Transmission**:
    
    - The response is sent back through the **same path** in **reverse order**:
        - **Paperless-NGX** → **Traefik** → **Docker Network** → **Host** → **Local Network** → **User**.

---

#### **Key Components**

1. **User**:    
    - The local network user who requests a document from **Paperless-NGX**.
2. **Local Network (LAN)**:
    - The **192.168.0.0/24** subnet that connects the user to the server (`192.168.0.42`).
3. **Host (192.168.0.42)**:
    - The **physical server** running all services.
    - It hosts **Docker**, which manages containerized applications.
4. **Docker Network (10.0.0.0/16)**:
    - A **virtual network** for Docker containers.
    - Ensures isolation and internal communication between services.
5. **Traefik (Ingress Controller)**:
    - Handles incoming HTTP/HTTPS traffic.
    - Routes requests based on **Ingress rules** (e.g., `Host: paperless.local`).
6. **Paperless-NGX**:    
    - A document management solution that processes user requests and retrieves documents.
## Conclusion

With a solid plan in place, it’s time to move to execution.

## Developing Project

### Preparing

I’ve previously managed services like Nginx and backends on bare-metal servers, but my focus here is mastering Kubernetes. Given the HP notebook’s limited CPU and RAM, k3d’s lightweight Kubernetes setup is a perfect fit compared to heavier alternatives. I’m using Ansible for automation, organized with playbooks, variables, and templates.

For a quick start, I created a helper script to set up this structure—available as a bash script on [GitHub](https://gist.github.com/stillru/6301c307cd96ab7472ee6d1d99e8ef1e).

```shell
.
├── ansible.cfg
├── group_vars
│   ├── k3d_servers.yml
│   └── local_servers.yml
├── host_vars
│   └── k3d.yaml
├── inventory.yaml
├── logfile.log
├── playbooks
│   ├── main.yaml
│   └── sections
│       ├── deploy-certmanager.yaml
│       ├── deploy-helm.yaml
│       ├── deploy-k3d.yaml
│       ├── deploy-local-path.yaml
│       ├── deploy-step-ca.yaml
│       └── prep_server.yaml
└── templates
    ├── cert-manager.yaml.j2
    ├── clusterissuer.yaml.j2
    ├── k3d-config.yaml.j2
    └── smallstep-values,yaml.j2

5 directories, 17 files
```

Let’s break down the deployment. The main playbook is `main.yaml`. First, I prepare the server.

At first i need prepare server:
```yaml linenos
# playbook/main.yaml
---
- name: Prepare k3d server for deployment (configure)
  hosts: k3d_servers
  tags: configure
  tasks:
    - name: Prepare host server
      include_tasks: ./sections/prep_server.yaml
      tags: configure

    - name: Run parts installation
      include_tasks: ./sections/deploy-helm.yaml
```

Now i have separate branch of tasks where i can prepare server for deployment:
```yaml linenos
# playbook/sections/prep_server.yaml
---
- name: Update /etc/hosts on localhost
  connection: local
  become: true
  blockinfile:
    path: /etc/hosts
    block: |
      {{ ansible_default_ipv4.address }} {{ common.hostname }}
    marker: "# {mark} ANSIBLE MANAGED BLOCK -- k3d network setup"

- name: Update /etc/hosts on localhost
  become: true
  blockinfile:
    path: /etc/hosts
    block: |
      127.0.0.1 {{ common.hostname }}
    marker: "# {mark} ANSIBLE MANAGED BLOCK -- k3d network setup"

- name: Ensure required packages are installed
  ansible.builtin.package:
    name:
      - iptables
      - curl
    state: present

- name: Enable IPv4 forwarding
  ansible.posix.sysctl:
    name: net.ipv4.ip_forward
    value: "1"
    state: present
    sysctl_set: true
    reload: true
```

Here, I ensure the server supports Docker networking and `Kubernetes` prerequisites like IP forwarding. These tasks:
- Confirm that both the `Ansible` controller and server recognize their IPs.
- Install essential packages on the server for debugging and configuration.
- Enable ip_forward on the server for `Kubernetes`.

Next, I install `Helm`, the package manager for `Kubernetes`. This involves downloading the official installation script and setting up the binary. We’ll use Helm later in other plays. This is `helm` installation tasks:
```yaml lineos
# playbook/sections/deploy-helm.yaml
---
- name: Download Helm installation script
  get_url:
    url: https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    dest: /tmp/get_helm.sh
    mode: '0755'

- name: Run Helm installation script
  command: /tmp/get_helm.sh
  args:
    creates: /usr/local/bin/helm
  register: helm_install_result
  changed_when: false

- name: Add /usr/local/bin to PATH
  lineinfile:
    path: ~/.bashrc
    line: 'export PATH=$PATH:/usr/local/bin'
  when: helm_install_result.rc == 0
```

Nothing extraordinary - download official installation script and install binary. We will use it later in other play's.

And this is used vars in this plays:
```yaml lineos
common:
  hostname: studystation.local                   # name of server
```

This is the simplest part of the process. The next steps get more interesting.
### Deploying k3d cluster

With the server ready, I move to deploying a k3d cluster to run my services. This involves installing the k3d binary, configuring the cluster with Ansible, and making it accessible from my local network. k3d’s lightweight nature suits my old HP notebook perfectly.

```yaml linenos
# playbook/main.yaml
- name: Deploy cluster
  hosts: k3d_servers
  tags: services
  tasks:
    - name: Run k3d installing
      include_tasks: ./sections/deploy-k3d.yaml

    - name: Register existing clusters
      command: "k3d cluster list -o json"
      register: cluster_list_output
      changed_when: false

    - name: Check if any clusters exist
      set_fact:
        has_clusters: "{{ (cluster_list_output.stdout | from_json | length) > 0 }}"

    - name: Set fact with cluster name if clusters exist
      set_fact:
        running_cluster: "{{ cluster_list_output.stdout | from_json | json_query('[0].name') }}"
      when: has_clusters == true

    - name: Destroy and recreate cluster if k3d.recreate is true
      when: k3d.recreate is true
      block:
        - name: Generate k3d config from template
          ansible.builtin.template:
            src: ../templates/k3d-config.yaml.j2
            dest: "{{ k3d.config_path }}"
            owner: "{{ ansible_user }}"
            mode: '0644'

        - name: Destroy cluster if it matches the configured name
          when: 
            - has_clusters and running_cluster == k3d.cluster_name 
          command: k3d cluster delete {{ running_cluster }}
          register: k3d_del_result
          changed_when: k3d_del_result.rc == 0
          
        - name: Deploy k3d cluster from config
          ansible.builtin.shell: 
            cmd: k3d cluster create --config {{ k3d.config_path }} --kubeconfig-update-default --kubeconfig-switch-context --wait
          register: k3d_create_result
          changed_when: k3d_create_result.rc == 0

        - name: Copy config to Ansible Controller
          fetch:
            src: ~/.kube/config
            dest: ~/.kube/config
            backup: yes
            flat: yes
          # Backs up existing config and enables local kubectl access
        
        - name: Wait 60 seconds for cluster stabilization
          ansible.builtin.wait_for:
            timeout: 60
          delegate_to: localhost
          # Ensures cluster is fully initialized
``` 

Here, I split the process into installing the `k3d` binary and creating the cluster. The cluster becomes accessible via `k3d`’s built-in load balancer, mapping ports to the host, with `studystation.local` resolved to 192.168.0.42 in my local /etc/hosts.

Let's look at preparation for deploy cluster - tasks for installing `k3d` itself:
```yaml lineos
# playbooks/sections/deploy-k3d.yaml
---
- name: Check if binary exists
  ansible.builtin.stat:
    path: "{{ k3d.k3d_bin_path }}"
  register: k3d_bin

- name: Get current version
  ansible.builtin.command: "{{ k3d.k3d_bin_path }} version"
  failed_when: false
  changed_when: false
  register: k3d_current_version

- name: Get latest version
  block:
    - name: Get latest version
      ansible.builtin.uri:
        url: "{{ k3d.k3d_version_url }}"
        return_content: true
        body_format: json
      register: k3d_latest_version

    - name: Set latest version fact
      ansible.builtin.set_fact:
        k3d_version: "{{ k3d_latest_version.json.tag_name | regex_replace('^v', '') }}"
  when: k3d.k3d_version == "latest"

- name: Download file
  block:
    - name: Ensure bin directory exists
      ansible.builtin.file:
        path: "{{ k3d.k3d_bin_dir }}"
        owner: "{{ k3d.k3d_owner }}"
        group: "{{ k3d.k3d_group }}"
        mode: "{{ k3d.k3d_bin_dir_mode }}"
        state: directory

    - name: Download file
      ansible.builtin.get_url:
        url: "{{ k3d.k3d_file_url }}"
        dest: "{{ k3d.k3d_bin_path }}"
        owner: "{{ k3d.k3d_owner }}"
        group: "{{ k3d.k3d_group }}"
        mode: "{{ k3d.k3d_mode }}"
        force: true
      register: k3d_download
  when: >
    not k3d_bin.stat.exists
	k3d.k3d_version not in k3d_current_version.stdout

- name: Create symlink
  ansible.builtin.file:
    src: "{{ k3d.k3d_bin_path }}"
    dest: "{{ k3d.k3d_link_path }}"
    owner: "{{ k3d.k3d_owner }}"
    group: "{{ k3d.k3d_group }}"
    mode: "{{ k3d.k3d_mode }}"
    force: true
    state: link
  when: k3d_download is changed

```

The preparation tasks check if the k3d binary exists on the server, verify its version, deploy a new version if needed, and make it usable. Most variables are defined in `host_vars/k3d.yaml` or `group_vars/k3d.yaml`, depending on the `inventory.yaml` file.

Used vars:
```yaml
common:
# The architecture map used to set the correct name according to the
# repository file names.
  k3d_architecture_map:
    {
    "aarch": "arm64",
    "aarch64": "arm64",
    "amd64": "amd64",
    "arm64": "arm64",
    "armhf": "armhf",
    "armv7l": "armhf",
    "ppc64le": "ppc64le",
    "s390x": "s390x",
    "x86_64": "amd64",
    }
k3d:
  k3d_os: "linux"                       # type of installation
  k3d_version: "latest"                 # The version of the binary. Example: "5.4.6". Usually used 'latest'
  k3d_owner: "root"                     # The owner of the installed binary.
  k3d_group: "root"                     # The group of the installed binary.
  k3d_mode: 0755                        # The permissions of the installed binary.
  k3d_bin_dir_mode: 0755                # The permissions of the binary directory.
  k3d_bin_dir: "/usr/local/share/k3d"   # The directory to install the binary in.
  k3d_bin_path: "{{ k3d_bin_dir }}/k3d" # The full path to the binary..
  k3d_link_path: "/usr/local/bin/k3d"   # The symlink path created to the binary
  k3d_repo_url: "https://github.com/k3d-io/k3d"
                                        # The URL to the repository.
  k3d_file_url: "{{ k3d_repo_url }}/releases/download/v{{ k3d_version }}/k3d-{{ k3d_os }}-{{ k3d_architecture }}"
                                        # The URL to the file.
  k3d_version_url: "https://api.github.com/repos/k3d-io/k3d/releases/latest"
                                        # The URL to fetch the latest version from.
  k3d_architecture: "{{ k3d_architecture_map[ansible_architecture] }}"
                                        # The architecture target for the binary.
```

Back to the main tasks:
- I check for existing clusters, verify if they match the defined name, destroy them if necessary, and create a new instance based on a template (k3d-config.yaml). 
- This requires a few files — `host_vars/k3d.yaml` for variables and `templates/k3d-config.yml.j2` for cluster configuration.
Used variables:
```yaml
common:
  hostname: studystation.local                     # name of server
  clustername: my-home                             # name of your cluster
k3d:
  config_path: "/tmp/k3d-config.yaml"              # path to generated config on server
  cluster_name: "{{ common.clustername }}"         # string for naming your cluster. Nested from common.clustername
  server_count: 1                                  # number of servers for control plane
  agent_count: 2                                   # number of nodes for workloads
  hostname: "{{ common.hostname}}"                 # to avoid recursion. use `common.hostname` key
  hostport: 6443                                   # port for control plane
  network_name: my-homenet                         # name of docker network for cluster
  volumes:
    path: /media/nfs/:/var/lib/rancher/k3s/storage # path:path - volumes to mount in the k3d cluster. In this example - all PVs will be created in /media/nfs
    nodefilters: list                              # selector on wich nodes this path should be mounted
     - server:0                                    # Example: mount on first server in control plane
     - agent:*                                     # Example: mount on all workload nodes
  cnames:                                          # list of hostnames which will be exported to /etc/hosts on all nodes in cluster
    - "{{ common.hostname }}"                      # Example: insert hostname of server itself
    - "registry.{{ common.clustername }}.local"    # Example: Generate cname for registry
  ports:
    port: 80:80                                    # port:port - mapping for ports to be mapped
    nodefilters:                                   # selector on wich nodes this ports will be mapped
      - loadbalancer                               # Example: same as all nodes
  rancher_version: "v1.32.2-k3s1"                  # Version of k3s to used in deployment
  recreate: true                                   # Conditional parameter - recreate or not existing cluster. I set this to ensure a fresh cluster for each deployment.
  registry:
    user: admin                                    # String for login to local registry in cluster. Default to "admin".
    pass: secret                                   # string for password to registry. Default to "secret".
```

And template:
```yaml lineos
# ./templates/k3d-config.yml.j2
---
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: {{ k3d.cluster_name }}
servers: {{ k3d.server_count }}
agents: {{ k3d.agent_count }}
kubeAPI:
  host: "{{ k3d.hostname }}"
  hostIP: "0.0.0.0"
  hostPort: "{{ k3d.hostport }}"
image: rancher/k3s:{{ k3d.rancher_version }}
network: "{{ k3d.network_name }}"
volumes:
{% for item in k3d.volumes %}
  - volume: {{ item.path }}
{% if item.nodefilters is defined and item.nodefilters %}
    nodeFilters:
{% for filter in item.nodefilters %}
      - {{ filter }}
{% endfor %}
{% endif %}
{% endfor %}
hostAliases:
  - ip: {{ ansible_default_ipv4.address }}
    hostnames:
{% for item in k3d.cnames %}
      - {{ item }}
{% endfor %}
ports:
{% for port_config in k3d.ports %}
  - port: {{ port_config.port }}
    nodeFilters:
{% for filter in port_config.nodefilters %}
     - {{ filter }}
{% endfor %}
{% endfor %}
registries:
  create:
    name: registry.{{ k3d.cluster_name }}.local
    host: "0.0.0.0"
    hostPort: "5000"
    volumes:
      - /media/nfs/registry:/var/lib/registry
  config: |
    mirrors:
      "registry.homelab.local":
        endpoint:
          - http://k3d-registry.homelab.local:5000
    configs:
      "registry.{{ common.clustername }}.local":
        auth:
          username: "{{ k3d.registry.user | default('admin') }}"
          password: "{{ k3d.registry.pass | default('secret') }}"
options:
  k3d:
    wait: true
    timeout: "300s"
    #loadbalancer:
    #  configOverrides:
    #  - settings.workerConnections=2048
    disableLoadbalancer: false
  k3s:
    extraArgs:
      - arg: --tls-san={{ k3d.cnames[0] }}
        nodeFilters:
          - server:*
      - arg: --tls-san={{ ansible_default_ipv4.address }}
        nodeFilters:
          - server:*
      - arg: --kubelet-arg=node-status-update-frequency=4s
        nodeFilters:
          - server:*
  kubeconfig:
    updateDefaultKubeconfig: true
    switchCurrentContext: true
```

At this stage, I have a running `k3d` cluster on my server, accessible from my Ansible controller via `kubectl`.

### Configure k8s cluster for workloads

Before deploying workloads, I configure the Kubernetes cluster for persistent storage and automatic certificate management. The `local-path-provisioner` offers simple storage by mapping host directories into pods — ideal for my small setup — while `cert-manager` with `step-ca` automates TLS certificates for secure services.

I begin with the `local-path-provisioner`, which k3d installs by default via `Helm`. I replace it to set `reclaimPolicy: Retain`, ensuring data persists even if a Persistent Volume Claim (PVC) is deleted.

```yaml lineos
- name: Deploy local path provisioner
  hosts: k3d_servers
  tags: localpath
  tasks:
    # Deploy local path provisioner
    - name: Deploy local
      include_tasks: ./sections/deploy-local-path.yaml
```

Here’s the implementation in `./sections/deploy-local-path.yaml`:
```yaml lineos
# playbook/sections/deploy-local-path.yaml
---
- name: Delete default operator
  connection: local
  kubernetes.core.k8s:
    kubeconfig: ~/.kube/config
    state: absent
    api_version: v1
    kind: Deployment
    namespace: kube-system
    name: local-path-provisioner

- name: Delete default storageclass
  connection: local
  kubernetes.core.k8s:
    kubeconfig: ~/.kube/config
    state: absent
    api_version: v1
    kind: StorageClass
    name: local-path

- name: Apply namespace first
  connection: local
  kubernetes.core.k8s:
    kubeconfig: ~/.kube/config
    state: present
    src: "/home/still/Projects/k3d-lab/local_storage/00-namespace.yaml"
  when: local_namespace_applied is not defined
  register: local_namespace_applied

- name: Find all Kubernetes manifest files in the directory (local-storage-operator)
  connection: local
  find:
    paths: "/home/still/Projects/k3d-lab/local_storage"
    patterns: "*.yaml"
    recurse: no
  register: local_manifest_files

- name: Create a Deployment by reading the definition from a local file (local-storage-operator)
  connection: local
  kubernetes.core.k8s:
    kubeconfig: ~/.kube/config
    state: present
    src: "{{ item.path }}"
  with_items: "{{ local_manifest_files.files }}"
  loop_control:
    label: "{{ item.path | basename }}"
  when: item.path != "~/Projects/k3d-lab/local_storage/00-namespace.yaml"
```

My custom manifests are stored in `~/Projects/k3d-lab/local_storage/`. For example, the `StorageClass` specifies `reclaimPolicy: Retain`:

```yaml lineos
# ~/Projects/k3d-lab/local_storage/01-storageclass.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path-retain
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```

Full deployment of this provisioner is not a topic for this article. Maybe next time :-).

Next, I install `cert-manager` and `step-ca` together, as my setup relies on both for certificate automation:
```yaml lineos
- name: Deploy cert-manager
  hosts: k3d_servers
  tags: certmanager
  tasks:
    # Deploy cert-manager for certificate management
    - name: Run cert-manager deploy
      include_tasks: ./sections/deploy-certmanager.yaml

    # Deploy Step CA for load balancing
    - name: Run step ca deploy
      include_tasks: ./sections/deploy-step-ca.yaml
```

I combine these tasks into one play since they’re interdependent. The `cert-manager` tasks configure the `Helm` repository, update the cache, install the package into the `Kubernetes` cluster, and verify deployment success. Some tasks run locally (via `delegate_to: localhost`) because `kubectl` and the Python `Kubernetes` libraries are installed only on my notebook, not the server.

Then, I configure cert-manager with a template that creates a self-signed CA for initial testing. Later, I’ll switch to step-ca as an ACME issuer for production certificates.

Content of `./sections/deploy-certmanager.yaml`:
```yaml lineos
# playbook/sections/deploy-certmanager.yaml
---
- name: Add cert-manager chart repo
  kubernetes.core.helm_repository:
    name: jetstack
    repo_url: "https://charts.jetstack.io"

- name: Update helm cache
  kubernetes.core.helm:
    name: dummy
    namespace: kube-system
    state: absent
    update_repo_cache: true

- name: Deploy cert-manager
  kubernetes.core.helm:
    name: cert-manager
    chart_ref: jetstack/cert-manager
    release_namespace: cert-manager
    create_namespace: true
    wait: true
    update_repo_cache: True
    values:
      crds: 
        enabled: true
      prometheus:
        enabled: false
      featureGates: ServerSideApply=true
  register: cert_manager

- name: Wait for cert-manager to be ready
  kubernetes.core.k8s_info:
    kind: Deployment
    name: cert-manager-webhook
    namespace: cert-manager
  register: cert_manager_webhook
  until: cert_manager_webhook.resources[0].status.readyReplicas == 1
  retries: 10
  delay: 10
  delegate_to: localhost

- name: Make configuration for cert-manager
  template:
    src: ../templates/cert-manager.yaml.j2
    dest: /tmp/cert-manager.yaml
  delegate_to: localhost

- name: Apply cert-manager configuration
  become_user: still
  kubernetes.core.k8s:
    src: /tmp/cert-manager.yaml
    state: present
    wait: true
    wait_timeout: 300
  delegate_to: localhost
```

First three tasks - configure `helm` repository, update helm cache and install package into `k8s` cluster. Next task - ensure that deployment is successful. 

You may have noticed that some tasks actually run from `localhost` by `delegate_to` instruction. This is because `kubectl` and `python-kubernatis` packages actually installed only on my notebook. Not on server.

Next task `"Wait for cert-manager to be ready"` use this packages - this task test `certmanager` deployment to be completed.

Then I create configuration for newly installed certmanager with template:
```yaml lineos
# templates/cert-manager.yaml.j2
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: {{ common.clustername }}-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: "{{ cert.common_name }}.local"
  secretName: root-secret
  privateKey:
    algorithm: ECDSA
    size: 256                  
  duration: 8760h              
  renewBefore: 720h            
  subject:                     
    organizations:
      - "{{ cert.organization_name }}"
    organizationalUnits:
      - "{{ cert.organizational_unit_name }}"
    countries:
      - "{{ cert.country_name }}"
    provinces:
      - "{{ cert.state_or_province_name }}"
    localities:
      - "{{ cert.locality_name }}"
    emailAddresses:
      - "{{ cert.email_address }}"
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: my-ca-issuer
spec:
  ca:
    secretName: root-secret
```

This template creates a self-signed CA for initial testing. Later, I’ll use step-ca as an ACME issuer for production certificates.

As we do before - let's explore used vars:
```yaml lineos
common:
  clustername: "homelab"
cert:
  country_name: "RS"                                  # Country for certificate subject
  state_or_province_name: "Belgrade"                  # State or province for certificate subject
  locality_name: "Belgrade-Zvezdara"                  # Locality for certificate subject
  organization_name: "Stepan Illichevskii PR Beograd" # Organization name
  organizational_unit_name: "IT Department"           # Organizational unit
  common_name: "{{ common.clustername }}.local"       # Common name for CA cert
  email_address: "still.ru@gmail.com"                 # Email for certificate
  password: "secret"                                  # Password for step-ca provisioner
```

Deploying `step-ca` was challenging but rewarding. These tasks automate its deployment and configuration in the `Kubernetes` cluster, including:
- Adding the Smallstep Helm repository.
- Deploying Step CA via Helm.
- Configuring the ACME provisioner.
- Restarting the Step CA pod.
- Retrieving and deploying CA certificates.
- Creating a ClusterIssuer for cert-manager.
- Ensuring CA certificates are available on target hosts.

```yaml lineos
# playbooks/sections/deploy-step-ca.yaml
---
- name: Add smallstep chart repo
  kubernetes.core.helm_repository:
    name: smallstep
    repo_url: "https://smallstep.github.io/helm-charts"

- name: Generate step ca config from template
  connection: local
  ansible.builtin.template:
    src: ../templates/smallstep-values.yaml.j2
    dest: /tmp/smallstep-values.yaml

- name: Deploy Step-ca
  kubernetes.core.helm:
    name: step-ca
    chart_ref: smallstep/step-certificates
    release_namespace: step-ca
    create_namespace: true
    wait: true
    update_repo_cache: True
    values: "{{ lookup('file', '/tmp/smallstep-values.yaml') | from_yaml }}"

- name: Update step-ca-step-certificates-config ConfigMap with ACME provisioner
  kubernetes.core.k8s:
    state: present
    definition:
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: step-ca-step-certificates-config
        namespace: "{{ cert.step_ca_namespace }}"
      data:
        ca.json: "{{ ca_config | to_json }}"
  vars:
    ca_config:
      address: ":9000"
      dnsNames:
        - "{{ cert.step_ca_service_name }}.{{ cert.step_ca_namespace }}.svc.cluster.local"
        - "step-ca-step-certificates.{{ cert.step_ca_namespace }}.svc.cluster.local"
        - "ca.{{ cert.step_ca_namespace }}.svc.cluster.local"
        - "ca.{{ common.clustername }}.local"
        - "127.0.0.1"
      db:
        type: "badgerv2"
        dataSource: "/home/step/db"
      authority:
        provisioners:
          - type: "ACME"
            name: "acme"
            forceCN: true
      root: "/home/step/certs/root_ca.crt"
      crt: "/home/step/certs/intermediate_ca.crt"
      key: "/home/step/secrets/intermediate_ca_key"
      tls:
        cipherSuites:
          - "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
          - "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        minVersion: 1.2
        maxVersion: 1.3
        renegotiation: false
      logger:
        format: "json"
  delegate_to: localhost
  become: false

- name: Restart step-ca pod to apply new configuration
  kubernetes.core.k8s:
    state: absent
    kind: Pod
    name: step-ca-step-certificates-0
    namespace: "{{ cert.step_ca_namespace }}"
  delegate_to: localhost
  become: false

- name: Get step-ca root CA certificate from ConfigMap
  kubernetes.core.k8s_info:
    api_version: v1
    kind: ConfigMap
    name: step-ca-step-certificates-certs
    namespace: "{{ cert.step_ca_namespace }}"
    kubeconfig: "~/.kube/config"
    validate_certs: false
  register: ca_cert_result
  delegate_to: localhost
  become: false

- name: Extract root CA certificate
  ansible.builtin.set_fact:
    ca_cert_output: "{{ ca_cert_result.resources[0].data['root_ca.crt'] }}"
    ca_intermediate_output: "{{ ca_cert_result.resources[0].data['intermediate_ca.crt'] }}"
  when: ca_cert_result.resources | length > 0 and 'root_ca.crt' in ca_cert_result.resources[0].data
  failed_when: ca_cert_output is not defined or ca_cert_output == ""
  delegate_to: localhost
  become: false

- name: Calculate CA fingerprint
  ansible.builtin.command:
    cmd: "openssl x509 -noout -fingerprint -sha256"
    stdin: "{{ ca_cert_output }}"
  register: ca_fingerprint_result
  changed_when: false
  failed_when: ca_fingerprint_result.rc != 0 or ca_fingerprint_result.stdout == ""
  become: false

- name: Extract fingerprint value
  ansible.builtin.set_fact:
    ca_fingerprint: "{{ ca_fingerprint_result.stdout.split('=')[1] | replace(':', '') }}"
  become: false

- name: Set fact for caBundle and fingerprint
  ansible.builtin.set_fact:
    ca_bundle: "{{ ca_cert_output | b64encode }}"
    ca_fingerprint: "{{ ca_fingerprint }}"
  become: false

- name: Generate step ca config from template
  delegate_to: localhost
  ansible.builtin.template:
    src: ../templates/clusterissuer.yaml.j2
    dest: /tmp/clusterissuer.yaml
  become: false

- name: Debug caBundle and fingerprint
  ansible.builtin.debug:
    msg: |
      ca_bundle: {{ ca_bundle | truncate(50, True, '...') }}
      ca_fingerprint: {{ ca_fingerprint }}
  become: false

- name: Deploy ClusterIssuer for step-ca
  delegate_to: localhost
  kubernetes.core.k8s:
    state: present
    definition: "{{ lookup('file', '/tmp/clusterissuer.yaml') | from_yaml }}"
  become: false

- name: Wait for ClusterIssuer to be ready
  delegate_to: localhost
  kubernetes.core.k8s_info:
    api_version: cert-manager.io/v1
    kind: ClusterIssuer
    name: "{{ cert.step_ca_namespace }}-issuer"
    kubeconfig: "~/.kube/config"  
    validate_certs: false 
  register: clusterissuer_status
  until: "clusterissuer_status.resources | length > 0 and 'True' in (clusterissuer_status.resources[0].status.conditions | selectattr('type', 'equalto', 'Ready') | map(attribute='status') | list)"
  retries: 30
  delay: 10
  become: false

- name: Copy CA certificate to target hosts
  connection: local
  copy:
    content: "{{ ca_cert_output }}"
    dest: /usr/local/share/ca-certificates/root_ca.crt
    mode: '0644'

- name: Copy intermediate CA certificate to target hosts
  connection: local
  copy:
    content: "{{ ca_intermediate_output }}"
    dest: /usr/local/share/ca-certificates/intermediate_ca.crt
    mode: '0644'

- name: Update CA certificates (Debian/Ubuntu)
  command: update-ca-certificates
  when: ansible_os_family == "Debian"
  connection: local
  become: true
  become_user: root
```

What content in templates:
```yaml lineos
# templates/smallstep-values.yaml.j2
---
image:
  repository: smallstep/step-ca
  tag: latest
service:
  type: ClusterIP
  port: 443
  targetPort: 9000
ca:
  name: "{{ cert.ca_name }}"
  password: "{{ cert.password }}"
  authority:
    provisioners:
      type: "ACME"
      name: "acme"
      forceCN: true
  db:
    enabled: true
    persistent: true
    storageClass: "local-path"
    size: 1Gi
bootstrap:
  enabled: true
  secrets: true
inject:
  enabled: false
  config:
    files:
      ca.json:
        address: ":9000"
        dnsNames:
          - "{{ cert.step_ca_service_name }}.{{ cert.step_ca_namespace }}.svc.cluster.local"
          - "ca.{{ cert.step_ca_namespace }}.svc.cluster.local"
          - "ca.{{ common.clustername }}.local"
          - "127.0.0.1"
        db:
          type: "badgerv2"
          dataSource: "/home/step/db"
        tls:
          cipherSuites:
            - "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
            - "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
          minVersion: 1.2
          maxVersion: 1.3
          renegotiation: false
        logger:
          format: "json"
  secrets:
    ca_password: "{{ cert.password | b64encode }}"
    x509:
      enabled: false
    ssh:
      enabled: false
    certificate_issuer:
      enabled: false
```

```yaml lineos
# templates/clusterissuer.yaml.j2
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: {{ cert.step_ca_namespace }}-issuer
spec:
  acme:
    server: https://{{ cert.step_ca_service_name }}.{{ cert.step_ca_namespace }}.svc.cluster.local/acme/acme/directory
    email: {{ cert.email_address }}
    privateKeySecretRef:
      name: {{ cert.step_ca_namespace }}-issuer-key
    caBundle: "{{ ca_bundle }}"
    solvers:
    - http01:
        ingress:
          class: traefik
```

Used vars:
```yaml
cert:
  ca_name: "my-organization-ca"                # Name of the Certificate Authority
  email_address: "admin@example.com"           # Email address associated with the CA
  step_ca_namespace: "step-ca"                 # Kubernetes namespace where the Step CA will be deployed
  step_ca_service_name: "step-ca-certificates" # Name of the Kubernetes service for the Step CA
                                               # BUG: working only with "step-ca-certificates"
```

Wow! That was tough, but I did it! Now I have a fully automated `CA` within my `k3d` cluster, ready for workloads.

For now, our cluster is ready for deploying workloads.

## Conclusions

At this point, our cluster is prepared to deploy workloads with persistent storage via the local path provisioner and automatic certificate handling.

Full list of used vars:
```yaml lineos
common:
  hostname: studystation.local                   # name of server
  clustername: my-home                           # name of your cluster
# The architecture map used to set the correct name according to the
# repository file names.
  k3d_architecture_map:
    {
    "aarch": "arm64",
    "aarch64": "arm64",
    "amd64": "amd64",
    "arm64": "arm64",
    "armhf": "armhf",
    "armv7l": "armhf",
    "ppc64le": "ppc64le",
    "s390x": "s390x",
    "x86_64": "amd64",
    }
k3d:
  k3d_os: "linux"                       # type of installation
  k3d_version: "latest"                 # The version of the binary. Example: "5.4.6". Usually used 'latest'
  k3d_owner: "root"                     # The owner of the installed binary.
  k3d_group: "root"                     # The group of the installed binary.
  k3d_mode: 0755                        # The permissions of the installed binary.
  k3d_bin_dir_mode: 0755                # The permissions of the binary directory.
  k3d_bin_dir: "/usr/local/share/k3d"   # The directory to install the binary in.
  k3d_bin_path: "{{ k3d_bin_dir }}/k3d" # The full path to the binary..
  k3d_link_path: "/usr/local/bin/k3d"   # The symlink path created to the binary
  k3d_repo_url: "https://github.com/k3d-io/k3d"
                                        # The URL to the repository.
  k3d_file_url: "{{ k3d_repo_url }}/releases/download/v{{ k3d_version }}/k3d-{{ k3d_os }}-{{ k3d_architecture }}"
                                        # The URL to the file.
  k3d_version_url: "https://api.github.com/repos/k3d-io/k3d/releases/latest"
                                        # The URL to fetch the latest version from.
  k3d_architecture: "{{ common.k3d_architecture_map[ansible_architecture] }}"
                                        # The architecture target for the binary. To avoid recursion. use `common.k3d_architecture_map` key
  config_path: "/tmp/k3d-config.yaml"        # path to generated config on server
  cluster_name: "{{ common.clustername }}"       # string for naming your cluster. Nested from common.clustername
  server_count: 1                                # number of servers for control plane
  agent_count: 2                                 # number of nodes for workloads
  hostname: "{{ common.hostname}}"               # to avoid recursion. use `common.hostname` key
  hostport: 6443                                 # port for control plane
  network_name: string                           # name of docker network for cluster
  volumes:                                       # List of connected volumes. Working Example:
    - path: /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket
      nodefilters:
        - server:0
        - agent:*
    - path: /media/nfs/:/var/lib/rancher/k3s/storage
      nodefilters:
        - all
    # path: ""                                   # path:path - volumes to mount in the k3d cluster
    # nodefilters:                               # selector on wich nodes this path should be mounted
    #  - server:0                                # Example: mount on first server in control plane
    #  - agent:*                                 # Example: mount on all workload nodes
  cnames:                                        # list of hostnames which will be exported to /etc/hosts on all nodes in cluster
    - "{{ common.hostname }}"                    # Example: insert hostname of server itself
    - "registry.{{ common.clustername }}.local"  # Example: Generate cname for registry
  ports:                                         # List of ports to expose in the k3d cluster. Working Example:
    - port: 80:80
      nodefilters:
       - loadbalancer
    - port: 443:443
      nodefilters:
       - loadbalancer
    - port: "30053:53"
      nodefilters:
       - server:0
       - agent:*
    # port: 80:80                                # port:port - mapping for ports to be mapped
    # nodefilters:                               # selector on wich nodes this ports will be mapped
    #   - loadbalancer                           # Example: same as all nodes
  rancher_version: "v1.32.2-k3s1"                # Version of k3s to used in deployment
  recreate: true                                 # Conditional parameter - recreate or not existing cluster. I set this to ensure a fresh cluster for each deployment.
  registry:
    user: still                                  # String for login to local registry in cluster. Default to "admin".
    pass: weare                                  # string for password to registry. Default to "secret".
cert:
  country_name: "RS"                                  # Country for certificate subject
  state_or_province_name: "Belgrade"                  # State or province for certificate subject
  locality_name: "Belgrade-Zvezdara"                  # Locality for certificate subject
  organization_name: "Stepan Illichevskii PR Beograd" # Organization name
  organizational_unit_name: "IT Department"           # Organizational unit
  common_name: "{{ common.clustername }}.local"       # Common name for CA cert
  email_address: "still.ru@gmail.com"                 # Email for certificate
  ca_name: "my-organization-ca"                       # Name of the Certificate Authority
  password: "MySecurePassword123!"                    # Password for securing the CA's private key and sensitive data
  step_ca_namespace: "step-ca"                        # Kubernetes namespace where the Step CA will be deployed
  step_ca_service_name: "step-ca-certificates"        # Name of the Kubernetes service for the Step CA
```

For those eager to test this on their own server, my [GitHub repo](https://github.com/stillru/k3d-cluster-part1) is open—any feedback on mistakes or issues is welcome.

In next part I will describe how to deploy two services - [ScanserverJS](https://sbs20.github.io/scanservjs/) and [PaperlessNGX](https://docs.paperless-ngx.com/) to `k8s` cluster. Stay tuned!