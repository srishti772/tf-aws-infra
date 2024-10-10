# Terraform VPC Setup

This repository contains Terraform configurations for creating a Virtual Private Cloud (VPC) on AWS. The setup includes public and private subnets, an Internet Gateway, route tables, and associated resources.

## Prerequisites

Before you begin, ensure you have the following:

- **Terraform**: Version 1.9.0 or later installed. You can download it from [Terraform's official website](https://www.terraform.io/downloads.html).
- **AWS Account**: An active AWS account with appropriate permissions to create VPCs, subnets, and related resources.

## Directory Structure

```plaintext
.
├── main.tf          # Main Terraform configuration file
├── variables.tf     # Variables used in the Terraform configuration
├── provider.tf      # AWS provider configuration
├── versions.tf      # Terraform version and provider constraints
├── data.tf          # AWS data configuration
└── README.md        # Project documentation
```

## Configuration Overview

### Main Resources

- **VPC**: A new VPC is created with the specified CIDR block.
- **Internet Gateway**: An Internet Gateway is created and attached to the VPC.
- **Public Subnets**: One or more public subnets are created based on the specified number of public subnets.
- **Route Tables**: Public route tables are created to allow outbound traffic from the public subnets.
- **Private Subnets**: One or more private subnets are created based on the specified number of private subnets.

### Variables

The following variables can be customized in `variables.tf`:

- `aws_region`: The AWS region where the resources will be created. Default is `us-east-1`.
- `vpc_cidr_block`: The CIDR block for the VPC. Default is `10.0.0.0/16`.
- `public_subnets`: The number of public subnets to create. Default is `1`.
- `private_subnets`: The number of private subnets to create. Default is `1`.
- `vpc_name`: A prefix to identify the VPC and its resources. Default is `a03`.

## Usage

1. **Clone the Repository**:
   ```bash
   git clone <your-repository-url>
   cd <repository-name>
   ```


2. **Initialize Terraform** : This command downloads the necessary provider plugins and initializes the backend.
   ```bash
    terraform init
    ```
3. **Format the Configuration (Optional)**: Format the Terraform configuration files.
   ```bash
    terraform fmt
    ```
4. **Validate the Configuration**: Ensure that  Terraform configuration is valid.
   ```bash
    terraform validate
5. **Plan the Deployment**: Create an execution plan to see what actions Terraform will take to reach the desired state.
   ```bash
    terraform plan
6. **Apply the Configuration**: Apply the changes required to reach the desired state of the configuration.
   ```bash
    terraform apply
7. **Destroy the Infrastructure**: To remove all the resources created by Terraform, run:
   ```bash
    terraform destroy
    ```

