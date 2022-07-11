### Prerequisites:

0. Clone this repo to your github account.
1. Create an AWS account (root account).
2. Create an Administrator user for further work (via IAM, grant admin permissions, download credentials, add credentials
to the operation system on your machine).
3. Setup the AWS Secrets Manager service and create a secret for your dockerhub credentials (it'll be used later to pull
the terraform image from https://hub.docker.com . It is possible to do that via Terraform, but we are limited in time here,
that's why doing it manually. Note the ARN of that secret and add it to `terraform-assets/common.tfvars`
4. Setup the Codestar connector to the repo from step 0 ( AWS Codepipeline - Settings - Connections). 
Create a new GH connection and install a new app). Note the connection ARN and add it to `terraform-assets/common.tfvars`
5. ECR or any other repo to pull the `TestChallengeApp` image (add it to `terraform-assets/common.tfvars`). 
Later it is possible to add additional entry into AWS Code Pipeline to build and push the image automatically. 


This solution is Terraform based. Usually, `tfstate` state file isn't stored locally, but remotely.
As the rest of the solution is based on AWS services, it is logical to store the `tfstate` on AWS S3. 
That is why it is needed to:
- create an S3 bucket to store the `tfstate` iself
- create some storage for `tflock`. In this example I'm using the DynamoDB.

### How to provision the solution and deploy the application.

1. proceed to `terraform-assets/01_tf-backend`, run `terraform init` and `terraform apply`. That will create S3 bucket that 
   is used to store `tfstate` and a DynamoDB for `tflock`.

   ```
   % cd terraform-assets/01_tf-backend
   % terraform init
   % terraform apply --var-file="../common.tfvars"
   ```
   
2. uncomment `terraform` block in `terraform-assets/01_tf-backend/main.tf` and re-run step 1.
   ```
   % terraform init
   % terraform apply --var-file="../common.tfvars"
   ```
   This will migrate local tf settings to cloud.

3. proceed to `terraform-assets/06_code-pipeline`, run `terraform init` and `terraform apply`. 
   ```
   % terraform init
   % terraform apply --var-file="../common.tfvars"
   ```

That will create an AWS CodePipeline resources as well as AWS Codebuild and will automatically deploy the whole solution
on AWS (vpc, multi-az, public/private subnets, internet gateway, nat gateways, load balancers, multy-az rds on ec2 in private subnets as well as ecs cluster on 
ec2 in private subnets, etc.)

I decided to separate my code into different folders (ecs, network, ecr). That allows me to split my tfstate for 
different layers. As a result it'll be easier to recover infrastructure if somehow the tfstate becomes inconsistent.
https://charity.wtf/2016/03/30/terraform-vpc-and-why-you-want-a-tfstate-file-per-env/ :-)

Repo structure:

```commandline
% tree
.
├── README.md
├── SUBMISSION.md
├── script-destroy.sh
└── terraform-assets
└── terraform-assets
    ├── 01_tf-backend
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── 02_network
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── sg.tf
    │   ├── tf-backend.tf
    │   └── variables.tf
    ├── 03_rds
    │   ├── data_source.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── tf-backend.tf
    │   └── variables.tf
    ├── 05_ecs
    │   ├── aws_ecs.tf
    │   ├── data_source.tf
    │   ├── ec2.tf
    │   ├── iam_ecs.tf
    │   ├── lb.tf
    │   ├── outputs.tf
    │   ├── templates
    │   │   ├── boothook.sh
    │   │   └── user-data-ecs.sh
    │   ├── tf-backend.tf
    │   ├── user_data.tf
    │   └── variables.tf
    ├── 06_code-pipeline
    │   ├── buildspec
    │   │   ├── apply-buildspec.yml
    │   │   └── plan-buildspec.yml
    │   ├── data_source.tf
    │   ├── iam.tf
    │   ├── outputs.tf
    │   ├── s3.tf
    │   ├── tf-backend.tf
    │   └── variables.tf
    └── common.tfvars
```

Despite it requires a bit more effort, I decided to proceed with the ECS instead of docker-compose solution. 
Mostly that is because that way I can build everything on top of AWS services.

During my work I've been trying to stick to ECS best practices. That is why ECS is on EC2 behind NAT_GW in private zone 
and LB in Public Zone plus IGW.

On top of that there is a redundancy (not one, but two availability zones, as a result ECS runs on top of 
2 EC2 Container Instances). This doesn't save from AWS Region outage, though, but still enough for most of the workloads.
That is configured via `terraform-assets/02_network/variables.tf`.

Load Balancer's security group allows receiving traffic from 0.0.0.0/0 and EC2 is allowed to receive traffic only from 
ALB and only on container's port. Additionally, there is SSH opened from VPC 10.0.0.0/16 (with private keys, so it is 
possible to use a bastion host). In my setup I'm using a bastion host, but it is not included here for the sake of clarity.

Parts of lb.tf about aws_lb_listener and aws_acm_certificate are commented out as I don't own any Domain Name at the moment,
so I won't be able to issue Certificate for HTTPS. But still configs are there.


### High level architecture (...a simple description of the architecture).
 
Everything is deployed with Terraform and Infrastructure is split int "layers". S3 and dynamoDB are used to store `tfstate`
and `tflock`.

This solution has bare minimum of AWS services ( "...minimum required to satisfy the key requirements...") and doesn't yet 
include Monitoring, Logging and Observability tools/elements, ECR, Bastion, Security features (though all that is listed
in "Improvements" part).

VPC is divided into public and private subnets for security reasons. 

Public Subnets are used for Loadbalancing (LB) and Nat Gateways. 
Private Subnets are used to host ECS EC2 instances (these are deployed from template by the Auto Scaling Group)and RDS 
instances (multy-az RDS with postgres). Workload is packed into containers that run on ECS. RDS runs in Private subnets 
and accepts connections only from ECS EC2 hosts (additional security). That behaviour is controlled via Security Groups (SG).

Additionally, there is an Internet Gateway to provide internet connectivity for VPC. There are some additional services 
as Secret Manager (to avoid storing of the most important credentials in plaintext).

Both Public and Private subnets spawn across several Availability Zones (AZ) within the same region. That provides redundancy.
This solution tolerates loss os one of AZ (as there is a multy-az RDS and ECS containers instances are spread between AZs).

LB receives traffic on LB domain name:80 and forwards it to the Target group that lists IP addresses of ECS containers.
ECS Containers allowed reaching RDS. Access is controlled with the SGs (later it is needed to have a FQDN and SSL cert, 
so tcp:80 is forwarded to tcp:443 and Route53 is used).

Solution is deployed through the AWS Code Pipeline. That creates a worker instance with the terraform image and runs `
terraform apply` for all the layers (everything is fetched from GitHub). AWS Code Pipeline was chosen instead of GitHub 
Actions because I tried to keep every service with the same provider (AWS).

### High level description of improvements (if any).

0. Tighten IAM policies (at the moment they are too open).
1. Add logging and monitoring (a separate trail in CloudTrail keeping API-logs indefinitely, CloudWatch dashboard
with top metrics, vpc flow logs, ALB access logs)
2. Add additional pipeline step to build and push image to repository. 
3. Add ECR to host custom images (and not fetch them from dockerhub, etc.)
4. Create SSL certificates and use own domain to send traffic to ALB listener. Right now only http is used.
5. Troubleshoot the `TestChallengeApp` so it is not trying to create the database in default tablespace. Similar case is
here (https://dba.stackexchange.com/questions/204807/why-do-i-get-a-postgresql-permission-error-when-specifying-a-tablespace-in-the)
6. Adjust the size of subnets (technically, I don't need that many addresses there).
7. Add WAF and a bastion host.
8. Make code more "DRY" so some repeated patterns are moved out.