# Terraform Setup

This repository contains Terraform configurations for creating a Virtual Private Cloud (VPC) on AWS. The setup includes public and private subnets, an Internet Gateway, route tables, EC2 instances, Security Groups and Key pairs.

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
- **EC2 Instances**: Optional EC2 instances can be launched within the VPC using specified AMIs and instance types.
- **Key Pairs**: Key pairs are created to securely connect to your EC2 instances via SSH.
- **Security Groups**: Security groups are configured to control inbound and outbound traffic to the EC2 instances.

### Variables

The following variables can be customized in `variables.tf`:

- **`aws_region`**: The AWS region where the resources will be created. Default is `us-east-1`.
- **`vpc_cidr_block`**: The CIDR block for the VPC. Default is `10.0.0.0/16`.
- **`public_subnets`**: The number of public subnets to create. Default is `1`.
- **`private_subnets`**: The number of private subnets to create. Default is `1`.
- **`vpc_name`**: A prefix to identify the VPC and its resources. Default is `a04`.
- **`ec2_name`**: A prefix to identify each EC2 instance. Default is `a04`.
- **`golden_ami_id`**: The Amazon Machine Image (AMI) ID to use for the EC2 instance. Default is `ami-0b844a6a7aa2a3aff`.
- **`application_port`**: The port on which the Node.js application runs.
- **`incoming_traffic`**: The CIDR block for incoming traffic. Default allows all traffic (`0.0.0.0/0`).
- **`instance_type`**: The type of EC2 instance to launch (e.g., `t2.micro`). Default is `t2.micro`.
- **`public_key_path`**: The path to the SSH public key file used for accessing the EC2 instance. Default is `~/.ssh/my_key.pem.pub`.
- **`root_volume_size`**: The size of the root block device in GB. Default is `25`.
- **`root_volume_type`**: The type of the root block device. Default is `gp2`.
- **`root_volume_delete_on_termination`**: Whether to delete the root block device upon termination. Default is `true`.

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
4. **Validate the Configuration**: Ensure that Terraform configuration is valid.
   ```bash
    terraform validate
   ```
5. **Plan the Deployment**: Create an execution plan to see what actions Terraform will take to reach the desired state.
   ```bash
    terraform plan
   ```
6. **Apply the Configuration**: Apply the changes required to reach the desired state of the configuration.
   ```bash
    terraform apply
   ```
7. **Destroy the Infrastructure**: To remove all the resources created by Terraform, run:
   ```bash
    terraform destroy
   ```
## SSL
1. **Purchase SSL from name cheap**
2. **Genrate CSR** : On macOS (via Homebrew), instal openssl:

```bash
brew install openssl
```

Open a terminal/command prompt and navigate to the directory to store the CSR and private key files.
Run the following OpenSSL command to generate a private key and a CSR. The demo.srishti-ahirwar.me domain will be used in the CSR.

```bash
openssl req -new -newkey rsa:2048 -nodes -keyout demo.srishti-ahirwar.me.key -out demo.srishti-ahirwar.me.csr
```
- **req -new** Tells OpenSSL to create a new certificate request.
- **newkey rsa:2048**: Generates a new RSA private key with a size of 2048 bits.
- **nodes**: Tells OpenSSL to not encrypt the private key (so that it can be used without a passphrase).
- **keyout demo.srishti-ahirwar.me.key**: This specifies the filename where the private key will be saved.
- **out demo.srishti-ahirwar.me.csr**: This specifies the filename where the CSR will be saved.

Fill out the information when prompted: After running the command, OpenSSL will ask for information to generate the CSR. Enter the details as follows:

- **Country Name (2 letter code)**: US or IN
- **State or Province Name**: Massachusetts
- **Locality Name**: Boston
- **Organization Name**: (optional)
- **Organizational Unit Name** : (optional)
- **Common Name (domain name)** : demo.srishti-ahirwar.me (this is the most important part).
- **Email Address** : Enter your email address.
- **A challenge password: (optional)**

Private Key and CSR: After filling in the required information, OpenSSL will generate two files:
**demo.srishti-ahirwar.me.key**: This is the private key.
**demo.srishti-ahirwar.me.csr**: This is the CSR that one has to submit to Namecheap.

 3. **Submit the CSR to Namecheap** : Log in to Namecheap account and navigate to the SSL Certificates section.
- Open the demo.srishti-ahirwar.me.csr file generated before in plain text format.
- Copy the entire content of the CSR, starting from -----BEGIN CERTIFICATE REQUEST----- to -----END CERTIFICATE REQUEST-----.
- Paste it into the CSR input field during the SSL certificate generation process on Namecheap.
- Use DNS validate the domail, submit.

4. **Add CNAME DNS Record to Route53** : 
-  Navigate to Namecheap dashboard -> SSL Certificate -> Details -> Click on Get CNAME Record link-> Click on arrow next to Edit Methods -> Get Records
-  Add the CNAME record to route53 zone of demo account with TTL of 60 seconds.
-  Navigate to Namecheap dashboard -> SSL Certificate -> Details -> Click on Get CNAME Record link-> Click on Edit Methods -> click on Save changes/Retry Alt DCV
-  Check status on :  https://mxtoolbox.com/CnameLookup.aspx

5. **Download Certificate files from namecheap** : 
- Once certificate verified on namecheap, download and get the certificate bundle files: 
   **Primary Certificate** (e.g., demo_srishti-ahirwar_me.crt)
   **Intermediate Certificate(s)** (e.g., demo_srishti-ahirwar_me.ca-bundle)
   **Root Certificate** (e.g., demo_srishti-ahirwar_me.p7b)


6. **Import the files in ACM**
```bash
aws acm import-certificate \
--certificate fileb:///Users/srishti77/Desktop/NEU/CSYE-6225-Cloud/Assignments/A09/demo_srishti-ahirwar_me.crt \
--private-key fileb:///Users/srishti77/Desktop/NEU/CSYE-6225-Cloud/Assignments/A09/demo.srishti-ahirwar.me.key \
--certificate-chain fileb:///Users/srishti77/Desktop/NEU/CSYE-6225-Cloud/Assignments/A09/demo_srishti-ahirwar_me.ca-bundle
```

Output:
```bash
{
    "CertificateArn": "arn:aws:acm:us-east-1:664418960750:certificate/fda625bf-d3b8-4446-94cd-341500c739dd"
}
```