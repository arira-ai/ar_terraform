# Terraform Advanced – Cheat Sheet

## 1. Terraform Basics

* Infrastructure as Code (IaC) tool for provisioning and managing cloud resources

```bash
terraform version                # Show Terraform version
terraform -help                  # Show Terraform help
terraform fmt                    # Format Terraform files
terraform validate               # Validate configuration
terraform providers              # List providers
terraform providers mirror ./providers  # Mirror providers locally
```

---

## 2. Initialization Commands

```bash
terraform init                   # Initialize working directory
terraform init -upgrade          # Upgrade provider plugins
terraform init -backend=false    # Skip backend initialization
terraform init -reconfigure      # Reconfigure backend
```

---

## 3. Planning & Apply

```bash
terraform plan                   # Show execution plan
terraform plan -out=tfplan       # Save execution plan
terraform apply                  # Apply infrastructure changes
terraform apply tfplan           # Apply saved plan
terraform apply -auto-approve    # Skip confirmation
terraform destroy                # Destroy infrastructure
terraform destroy -auto-approve  # Force destroy
```

---

## 4. State Management

```bash
terraform state list             # List resources in state
terraform state show <resource>  # Show resource details
terraform state mv old new       # Move resource in state
terraform state rm <resource>    # Remove resource from state
terraform refresh                # Refresh state file
terraform import aws_instance.web i-123456  # Import resource
```

---

## 5. Workspace Management

```bash
terraform workspace list         # List workspaces
terraform workspace new dev      # Create workspace
terraform workspace select dev   # Switch workspace
terraform workspace show         # Current workspace
terraform workspace delete dev   # Delete workspace
```

---

## 6. Variable Management

```bash
terraform plan -var="env=dev"   # Pass variable
terraform apply -var-file=prod.tfvars  # Use tfvars file
terraform output                 # Show outputs
terraform output instance_ip     # Specific output
```

### Sample variables.tf

```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}
```

### Sample terraform.tfvars

```hcl
region = "ap-south-1"
instance_type = "t2.micro"
```

---

## 7. Backend Configuration

### Local Backend

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

### S3 Remote Backend

```hcl
terraform {
  backend "s3" {
    bucket = "tf-state-bucket"
    key    = "dev/terraform.tfstate"
    region = "ap-south-1"
  }
}
```

---

## 8. Resource Commands

### Sample AWS EC2 Resource

```hcl
resource "aws_instance" "web" {
  ami           = "ami-123456"
  instance_type = "t2.micro"
}
```

### Resource Targeting

```bash
terraform apply -target=aws_instance.web  # Apply specific resource
terraform destroy -target=aws_instance.web  # Destroy specific resource
```

---

## 9. Module Management

```bash
terraform get                    # Download modules
terraform init                   # Initialize modules
```

### Sample Module Usage

```hcl
module "network" {
  source = "./modules/network"
  cidr   = "10.0.0.0/16"
}
```

---

## 10. Data Sources

### Sample Data Source

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

---

## 11. Provisioners

### Local Exec

```hcl
provisioner "local-exec" {
  command = "echo Hello"
}
```

### Remote Exec

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt update"
  ]
}
```

---

## 12. Functions & Expressions

```hcl
length(var.list)                 # Get list length
upper("hello")                  # Convert to uppercase
join(",", ["a", "b"])          # Join list values
lookup(var.map, "key", "default")  # Map lookup
```

---

## 13. Debugging & Troubleshooting

```bash
terraform validate               # Validate configuration
terraform fmt                    # Format files
terraform graph                  # Generate dependency graph
terraform taint aws_instance.web # Mark resource for recreation
terraform untaint aws_instance.web  # Remove taint
TF_LOG=DEBUG terraform apply     # Enable debug logs
```

---

## 14. Security Best Practices

```bash
terraform state pull             # Pull remote state
terraform state push             # Push state manually
terraform login                  # Login Terraform Cloud
```

### Security Recommendations

```text
Use remote state backend
Enable state locking
Store secrets in Vault/Secrets Manager
Do not commit terraform.tfstate
Use IAM least privilege access
```

---

## 15. Terraform Cloud Commands

```bash
terraform login                  # Login Terraform Cloud
terraform logout                 # Logout Terraform Cloud
terraform cloud                  # Terraform Cloud operations
```

---

## 16. Daily Must-Have Commands

```bash
terraform init                   # Initialize project
terraform fmt                    # Format code
terraform validate               # Validate configuration
terraform plan                   # Preview changes
terraform apply                  # Apply changes
terraform destroy                # Destroy infrastructure
terraform output                 # Show outputs
terraform state list             # State resources
```

---

## 17. Terraform File Structure

```text
project/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── provider.tf
├── backend.tf
├── modules/
│   └── network/
└── terraform.tfstate
```

---

## 18. Terraform Architecture

```text
User → Terraform CLI
Terraform CLI → Providers
Providers → Cloud APIs
Terraform CLI → State File
State File → Infrastructure Mapping
Terraform Modules → Reusable Components
Terraform Backend → Remote State Storage
```

---

### Tip

Mastering Terraform enables automated, repeatable, and scalable infrastructure provisioning.
