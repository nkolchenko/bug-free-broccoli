#!/bin/sh

for i in `ls -d terraform-assets/*/ | grep -v 01`  # 01_tf-backend
  do
    echo "----$i"
    terraform -chdir=./$i apply -var-file="../common.tfvars"
  done


