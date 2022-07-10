/* This file describes template used to provision EC2 instances for ECS cluster and allows to setup EC2 instance as needed.

- template_files for different stages
- template_cloudinit_config
*/

data "template_file" "ec2_user_data" {
  template = file("${path.module}/templates/user-data-ecs.sh")

  vars = {
    region       = var.region
    cluster_name = var.cluster_name
  }
}

data "template_file" "boothook" {
  template = file("${path.module}/templates/boothook.sh")
  vars     = {}
}

# to debug: obtain "user data" string from "Launch Configuration" via AWS console and run:
# echo -n "<user_data>" | base64 -d | gunzip
data "template_cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true

  # Part 1: "Apply pre-script" boothook for CloudInit if desired:
  part {
    content_type = "text/cloud-boothook"
    content      = data.template_file.boothook.rendered
  }

  # Part 2: "User Data":
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.ec2_user_data.rendered
  }
}
