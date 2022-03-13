# Orca Terraform
orca-terraform deploys new eks cluster, rds ,ecr and all its dependencies.

## Getting Started
These instructions will guide you with the deployment on AWS.

### Prerequisites
terraform - In order to deploy the environment

	sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
	sudo apt-get update && sudo apt-get install terraform

AWS Cli - Cli tool to communicate with AWS

	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install


AWS IAM Authenticator - Amazon EKS uses IAM to provide authentication to your Kubernetes cluster using that tool.

	curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/aws-iam-authenticator
	chmod +x ./aws-iam-authenticator
	mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin
	echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc


Kubectl - In order to control K8S cluster.

	cat <<EOF > /etc/yum.repos.d/kubernetes.repo
	[kubernetes]
	name=Kubernetes
	baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
	enabled=1
	gpgcheck=1
	repo_gpgcheck=1
	gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
	EOF
	yum install -y kubectl


### Provisioning
First step is to configure our aws cli, which is done by running:

	aws configure

Then we can start deploying our environment on AWS, by following these steps:
1. terraform init - Downloads all required modules.
2. terraform plan(optional) - Showing execution plan, showing everything that will create/change.
3. terraform apply - applying the changes, and deploying it. 

### Infra Deployment
Deploys these components:
* Configure new VPC and 9 subnets(3 Public, 3 Private and 3 for Database).
* Configure new SG's for workers and for DB
* Deploy new EKS-Cluster.
* Deploy new Postgresql - using RDS Multi-AZ
* Deploy new ECR
* Create new KMS and using it to encrypt k8s secrets, and ECR images
* Creates new node-group for EKS
* Configure kubernetes provider and deploy postgres connectionstring secret

In order to start working with the cluster, you must run that command:

	aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

It creates a new config in ~/.kube/config which allows us to contact with the cluster.

### Application Deployment
Afterwards, we need to build, push and deploy our app.
first we need to connect our ECR:

	aws ecr get-login-password --region $(terraform output -raw region) | docker login --username AWS --password-stdin $(terraform output -raw ecr_url)

In order to build our app image, run these commands:

	docker build ../orca_docker -t $(terraform output -raw ecr_url):latest
	docker push $(terraform output -raw ecr_url):latest

then, install the chart by these commands on k8s:

	helm install orca-app ../orca_chart/

which installs:
1. Deployment - with readiness & liveness probe(*** NOTE: I had to change app.py to listen in 0.0.0.0 instead of 127.0.0.1 in order to make it works ***)
2. Service - Type is LoadBalancer, in order to create internet-facing load balancer for the app
3. HPA - autoscaling for the application by cpu & memory

# Metrics Server:
EKS doesn't install metrics server by default - so we have to manually install that in order to use HPA, Run that command:
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml


# Task notes: 
1. K8S running on Public and Private with my router IP, in order to not configure any bastion or VPN - the entire cluster works privatly.
2. NAT Gateway has only single instance - for cost management - change that to false for HA: 'single_nat_gateway'
3. app.py using 127.0.0.1 and not 0.0.0.0 so it cannot be reached from outside, changed that to 0.0.0.0 to work:
	def main():
      app.run(host='0.0.0.0', port=5000)