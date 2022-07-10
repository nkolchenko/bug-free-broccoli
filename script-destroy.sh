#!/bin/sh

for i in `ls -dr terraform-assets/*/ | grep -v -e 0[1,4]` # 01_tf-backend , 04_ecr
  do
    echo "----$i"
    terraform -chdir=./$i destroy --auto-approve -var-file="../common.tfvars"
  done


