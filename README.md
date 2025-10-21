# OCI Kubernetes Cluster with Terraform

This repository contains Terraform configurations to create a Kubernetes cluster on Oracle Cloud Infrastructure (OCI) within the Always Free tier limits.

## Prerequisites

1. [Oracle Cloud Infrastructure (OCI) Account](https://www.oracle.com/cloud/free/)
2. [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
3. [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

## OCI Configuration

1. Generate an API signing key:
```bash
mkdir ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
chmod 600 ~/.oci/oci_api_key.pem
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```

2. Upload the public key to OCI:
   - Log in to your OCI Console
   - Click on your Profile icon and select "User Settings"
   - Click "API Keys" and then "Add API Key"
   - Upload the generated public key (`oci_api_key_public.pem`)
   - Copy the generated configuration file content

3. Create OCI config file:
```bash
mkdir -p ~/.oci
vi ~/.oci/config
```
Paste the configuration content copied from OCI Console.

## Required Information

Before applying the Terraform configuration, you'll need:

- Tenancy OCID
- User OCID
- Region
- Compartment OCID
- API Key fingerprint
- Path to your private API key

## Usage

1. Clone this repository:
```bash
git clone https://github.com/hedche/oci-k8s-terraform.git
cd oci-k8s-terraform
```

2. Initialize Terraform:
```bash
terraform init
```

3. Update the `terraform.tfvars` file with your OCI credentials and configuration.

4. Review the planned changes:
```bash
terraform plan
```

5. Apply the configuration:
```bash
terraform destroy
```

## Resources Created

This Terraform configuration will create:
- VCN with required subnets
- Internet Gateway
- Route Table
- Security List
- Kubernetes cluster with 2 nodes (within Always Free tier limits)
  - Shape: VM.Standard.A1.Flex (ARM-based)
  - OCPUs per node: 2
  - Memory per node: 12GB

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Notes

- This configuration uses ARM-based compute shapes (VM.Standard.A1.Flex) which are eligible for the Always Free tier
- The Always Free tier includes:
  - 2 AMD-based Compute VMs with 1/8 OCPU and 1 GB memory each
  - 4 ARM-based Compute VMs with 24 GB memory total
  - 2 Block Volumes (200 GB total)
  - 10 GB Object Storage
  - 10 Gbps networking
- Ensure you stay within these limits to avoid charges

## Important

Always review the resources and their specifications before applying the configuration to ensure they fall within the Free Tier limits. Monitor your OCI console regularly to verify resource usage.