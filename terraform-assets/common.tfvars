region = "ap-southeast-2"

app_name        = "servian-test"
cluster_name    = "servian-test"
app_environment = "servian-test"

container_port = 3000
#container_image = "public.ecr.aws/r6q7k4f1/hello-world-app:latest"
container_image = "public.ecr.aws/r6q7k4f1/servian-techchallengeapp:latest"

codestar_connector_arn = "arn:aws:codestar-connections:ap-southeast-2:792948579706:connection/5f810f90-7f70-4554-a77a-96095281339e"
dockerhub_credentials  = "arn:aws:secretsmanager:ap-southeast-2:792948579706:secret:codebuild/dockerhub-NcumTy"