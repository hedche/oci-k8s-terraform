# OCI Kubernetes Cluster with Terraform

This repository contains Terraform configurations to create a Kubernetes cluster on Oracle Cloud Infrastructure (OCI) within the Always Free tier limits.

## Prerequisites

1. [Oracle Cloud Infrastructure (OCI) Account](https://www.oracle.com/cloud/free/)
2. [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
3. [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

### Provider Configuration
This configuration uses the official Oracle-maintained provider (`oracle/oci`) instead of the legacy HashiCorp-maintained provider (`hashicorp/oci`). The `versions.tf` file ensures the correct provider is used.

## Administrator Setup (Required First)

Before creating the Kubernetes cluster, an administrator must set up the required IAM resources. This can be done either manually through the OCI Console or using Terraform. Choose one of the following approaches:

### Option 1: Manual Setup via OCI Console

1. Create a new IAM group:
   - Navigate to Identity & Security → Groups
   - Click "Create Group"
   - Name: `k8s-admins` (or your preferred name)
   - Description: "Group for managing OKE cluster resources"

2. Add users to the group:
   - Click on the newly created group
   - Click "Add User to Group"
   - Select the users who will manage the K8s cluster

3. Create the required policies:
   - Navigate to Identity & Security → Policies
   - Click "Create Policy"
   - Name: "kubernetes-cluster-policy"
   - Description: "Policy for managing OKE cluster resources"
   - Add the following statements:
     ```
     allow group k8s-admins to manage virtual-network-family in compartment <compartment-name>
     allow group k8s-admins to manage cluster-family in compartment <compartment-name>
     allow group k8s-admins to manage compute-family in compartment <compartment-name>
     allow group k8s-admins to manage load-balancers in compartment <compartment-name>
     ```
   Replace `<compartment-name>` with your compartment name
   
   Note: For root compartment, use `in tenancy` instead of `in compartment <compartment-name>`

### Option 2: Terraform Setup (Recommended)

1. Copy the example IAM configuration:
   ```bash
   cp iam.tfvars.example iam.tfvars
   ```

2. Edit `iam.tfvars` with your settings:
   ```hcl
   iam_group_name   = "k8s-admins"              # Your preferred group name
   compartment_name = "my-k8s-compartment"      # Your compartment name
   user_ocid        = "ocid1.user.oc1..xxxxx"   # OCID of user to add to group (optional)
   ```

3. First, make sure you're using the latest Terraform and provider versions:
   ```bash
   terraform init -upgrade
   ```
   This will ensure you're using the official Oracle provider.

4. Plan and apply the IAM configuration:
   ```bash
   # First stage: Create IAM resources only
   terraform plan -var-file="iam.tfvars" -target=module.iam
   terraform apply -var-file="iam.tfvars" -target=module.iam
   ```

   Note: The `-target` warning is expected and correct in this case because:
   - IAM resources must exist before creating other resources
   - We need to wait for policy propagation
   - This is a legitimate use case for resource targeting

5. Wait for policy propagation (approximately 5-10 minutes)

6. After policies have propagated, you can remove the lock file and plan the full configuration:
   ```bash
   rm .terraform.lock.hcl  # Remove the old provider lock
   terraform init -upgrade # Reinitialize with the new provider
   terraform plan         # Plan all resources
   ```

Important Notes:
- The administrator running these steps must have permissions to manage groups and policies
- IAM changes can take up to 10 minutes to propagate
- Always follow the principle of least privilege when granting permissions
- Review all policy statements carefully before applying them
- The two-stage apply (IAM first, then rest) is intentional for proper permission propagation

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