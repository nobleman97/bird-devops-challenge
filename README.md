# Bird Aplication Solution

This is the bird Application! It was deployed on a `K3s` cluster and bootstrapped using Bash scripts.

## Architecture Diagram
<p text-align=center>
<img src=./infrastructure/lifi.drawio.svg width=90% >
</p>

## Headings:
- Running the Application
- Standing Up the Infrastructure
- Connecting to the Cluster
- [Accessing Applications](#accessing-applications)

## Running the Application
First,  I had to make a small change to the bird API `main.go`.

```go
func getBirdImage(birdName string) (string, error) {
	baseURL := os.Getenv("BIRD_API_URL")

	if baseURL == "" {
		baseURL = "http://localhost:4200"
	}

    res, err := http.Get(fmt.Sprintf("%s?birdName=%s", baseURL ,url.QueryEscape(birdName)))
    if err != nil {
        return "", err
    }
    body, err := io.ReadAll(res.Body)
    return string(body), err
}
```
This ensures that we can adjust the birdimage url if needed.

Next, after building the images, I ran the application...

```sh
# create a docker network
# I wrote an article about this here: https://dev.to/nobleman97/docker-networking-101-a-blueprint-for-seamless-container-connectivity-3i5b
docker network create lifi

# Next run the images
docker run -dit --name birdimage   --network lifi -p 4200:4200 birdimage:v1 
docker run -dit --name getbird -e BIRD_API_URL="http://birdimage:4200" --network lifi -p 4201:4201 bird:v2
```
Test it:
```sh
curl localhost:4201  | jq .
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   363  100   363    0     0    966      0 --:--:-- --:--:-- --:--:--   968
{
  "Name": "Toucan",
  "Description": "Toucans are brightly colored birds known for their large, colorful bills.",
  "Image": "\"https://images.unsplash.com/photo-1554729862-611715258df9?crop=entropy\\u0026cs=tinysrgb\\u0026fit=max\\u0026fm=jpg\\u0026ixid=M3w2Mzg4NzZ8MHwxfHNlYXJjaHwxfHxUb3VjYW58ZW58MHx8fHwxNzI2Njk1MTU0fDA\\u0026ixlib=rb-4.0.3\\u0026q=80\\u0026w=200\"\n"
}

# It Works!
```

## Standing Up The Infra
For the Infrastructure, I used:
- Terraform
- K3s (for Kubernetes)
- Helm (for Deployments and other automations)
- Bash (to automate repetitive tasks)

### Step 1: Run Terraform to Provision Master Node and other resources
All the terraform scripts are located in the [./infrastructure/terraform/](./infrastructure/terraform/)

To bring up control plane and jumpbox and and have it configured, the `machines` variable in the tfvars should first look like this:

```hcl
machines = {
  "machine_1" = {
    instance_type        = "t3.medium"
    instance_name        = "master"
    network_object_name  = "primary"
    subnet_object_name   = "AZ-1-priv_sub-1"
    sg_identifier        = "cluster_sg"
    iam_instance_profile = "KubernetesNodesInstanceProfile"
    volume_size          = 30
    volume_type          = "gp2"
    user_data            = "../scripts/k3s_master.sh"
  }

  "jumpbox" = {
    instance_type       = "t2.micro"
    instance_name       = "jumpbox"
    network_object_name = "primary"
    subnet_object_name  = "AZ-1-pub_sub-1"
    sg_identifier       = "bastion_sg"
    iam_instance_profile = "KubernetesNodesInstanceProfile"
    volume_size         = 30
    volume_type         = "gp2"
    user_data           = "../scripts/apt_update.sh"
  }
}
```
___

<br/>

> ### **P.S:** Before running any `terraform apply` command, I'd recommend you comment out every thing after: <br/>
> #### ######################## <br/>
> #### # Kubernetes <br/>
> #### ######################## <br/>
> ... in the [./infrastructure/terraform/main.tf](./infrastructure/terraform/main.tf) file. 
> ### This will prevent error which may arise because yo have not configured kubectl... **yet**

<br/>

___


Then run:
```sh
terraform plan
terraform apply
```

When this is run, the control plane runs the [../bird-devops-challenge/infrastructure/scripts/k3s_master.sh](../bird-devops-challenge/infrastructure/scripts/k3s_master.sh) script to configure itself and `push a configuration script to s3 for worker nodes configuration`.

### Step 2: Add worker nodes (That Automatically Join the Cluster)
To add a worker node, simply add another object to the  `machines` object in the tfvars file, like this:
```hcl
# ...

  "machine_2" = {
    instance_type        = "t3.medium"
    instance_name        = "slave_1"
    network_object_name  = "primary"
    subnet_object_name   = "AZ-1-priv_sub-2"
    sg_identifier        = "cluster_sg"
    iam_instance_profile = "KubernetesNodesInstanceProfile"
    volume_size          = 30
    volume_type          = "gp2"
    user_data            = "../scripts/k3s_worker.sh"
  }
# ...
```

### Step 3: Gain Kubectl Access to the Cluster
To ensure the dev PC can reach the Cluster via Kubectl, we will enable `SSH Tunneling` between our dev PC and the cluster.

I wrote a simple script for that.

```sh
# Ensure you are in the terraform folder
cd bird-devops-challenge/infrastructure/terraform

# Run the script
./../scripts/bastion.sh
```

You need to do one more thing before Kubectl works...

### Step 4: Get the KubeConfig file
To get the KubeConfig file...

```sh
# Ensure you are in the terraform folder
cd bird-devops-challenge/infrastructure/terraform

# Run the script
./../scripts/grab_token.sh

```

Grab the output and place it in in your local ~/kube/config file

> **P.S:** These scripts search your terraform output for specific machine names.
> In my example the search for the ip addresses of `master` and `jumpbox`.
> This means that if you change the machine names, you have to specify them in the scripts too
<br/>

<br/>

### Step 5: Confirm Your nodes in the cluster
`kubectl get nodes`

```sh
# Examnple Output
$ sudo kubectl get nodes
NAME             STATUS   ROLES                  AGE   VERSION
ip-10-0-20-160   Ready    control-plane,master   71m   v1.30.4+k3s1
ip-10-0-30-41    Ready    <none>                 5s    v1.30.4+k3s1
```

## Connecting To The Cluster
Now you can uncomment the Kubernetes & Monitoring section in your `main.tf` file and run `terraform apply`
This will install:
- Namespaces
- Bird and Birdimage helm charts (+Horizontal Pod AutoScaler for each deployment)
- Prometheus & Grafana
- Metric server (Actually installed with k3s)

> **P.S:** Always ensure your SSH tunnel is up when running `terraform apply`
> If the tunnel disconnects, run the script to bring it up again. <br/>
> Also , run the tunnel in one termminal, and run kubectl command from another

<br/>



<br/>



## Accessing Applications
> **P.S:** I experienced DNS resolution issues, but replacing CoreDNS with KubeDNS fixed the issue

## 1.) Bird API

<p text-align=center>
<img src=./assets/birdy.png width=90% >
</p>

## 2.) BirdImage API

<p text-align=center>
<img src=./assets/birdimage.png width=90% >
</p>

## 3.) Kibana (Log Monitoring Solution)
<p text-align=center>
<img src=./assets/kibana-logs.png width=90% >
</p>

## 4.) Grafana (Log Monitoring Solution)
<p text-align=center>
<img src=./assets/grafana-board.png width=90% >
</p>

## 5.) Grafana Alerts (Log Monitoring Solution)
<p text-align=center>
<img src=./assets/graf-alert.png width=90% >
</p>

## 5.) Prom Alerts (Log Monitoring Solution)
<p text-align=center>
<img src=./assets/prom-alerts.png width=90% >
</p>


<br/>

<br/>

## Extra Features
- **Pod Autoscaling:** Pod autoscaling was enabled for both APIs. I included it as part of the helm charts I created for each API. 
- **Security:** Access to servers was locked down to only my CIDR range. All nodes were placed in private subnets and access to application exposed via ingress.
- **Nodes Auto-Join Cluster:** Upon provisioning, worker nodes auto-join cluster. This process was automated using Bash scripts and s3 bucket.

<br/>

<br/>

## Challenges

### [ Resolved ]
- **Internal DNS not working:** This was due to CoreDNS in k3s. I replaced it with KubeDNS
- **Ingress not working:** K3s shipped with Traefik. I had to replace it with NGINX and handle DNS using CloudFlare
- **External DNS kept crashing:** I used Terraform to create the necessary DNS records instead 
- **Grafana & Prometheus Services not Reachable:** Fixed!!!


### [ Unresolved ]

- HTTPS for ingress not working yet.

(...most of these work just fine when I use EKS. But with some tinkering I should have all issues resolved soon.)


