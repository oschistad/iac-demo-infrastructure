# Demonstration of VM creation on Azure using Terraform Enterprise

This is a simple demo of how Terraform manages infrastructure on Azure, using a VM and its dependencies as example.

## Prerequisites

This repository depends on certain key facts and secrets being present in the runtime environment. These variables can be
set using the included terraform.tfvars.demo or as workspace variables in Terraform Enterprise.

When using the rest of this demo, the master workspace will ensure that these have been setup.

