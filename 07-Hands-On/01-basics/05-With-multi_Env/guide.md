# Terraform Multi-Environment Practice Guide (Dev + Prod)

Objective:
Operate one codebase across multiple environments using isolated state and variable injection.

---

# Phase 1 — Create Project Structure

```
terraform-ec2/
├── main.tf
├── variables.tf
├── _common-data-link.tf
├── _common-data-copy.auto.tfvars
├── backend.tf
├── backend-dev.hcl
├── backend-prod.hcl
├── provider.tf
├── dev.tfvars
└── prod.tfvars
```

---

# Phase 2 — Core Files

## provider.tf

```hcl
provider "aws" {
  region = var.aws_region
}
```

---

## backend.tf

```hcl
terraform {
  backend "s3" {
    bucket         = "ar-terraform-state"
    key            = "ec2/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

```

Backend config injected dynamically.

---

## variables.tf

```hcl
variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "owner" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "ami_name_pattern" {
  type = string
}
```

---

## _common-data-link.tf

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }
}

locals {
  common_tags = {
    Project = var.project_name
    Owner   = var.owner
    Env     = var.environment
  }
}
```

---

## _common-data-copy.auto.tfvars

```hcl
aws_region       = "us-east-1"
project_name     = "tf-ec2-demo"
owner            = "platform-team"
ami_name_pattern = "amzn2-ami-hvm-*-x86_64-gp2"
```

Auto-loaded by Terraform.

---

## main.tf

```hcl
resource "aws_instance" "demo" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = merge(
    local.common_tags,
    {
      Name = "tf-simple-ec2"
    }
  )
}
```

---

# Phase 3 — Environment Files

## dev.tfvars

```hcl
environment   = "dev"
instance_type = "t2.micro"
key_name      = "dev-keypair"
```

---

## prod.tfvars

```hcl
environment   = "prod"
instance_type = "t3.medium"
key_name      = "prod-keypair"
```

---

# Phase 4 — Backend Config Files

## backend-dev.hcl

```hcl
bucket         = "ar-terraform-state"
key            = "ec2/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
```

---

## backend-prod.hcl

```hcl
bucket         = "ar-terraform-state"
key            = "ec2/prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
```

Separate state per environment.

---

# Phase 5 — Execution Workflow

## 1. Deploy DEV

```bash
terraform init -backend-config=backend-dev.hcl
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

Verify:

```bash
aws ec2 describe-instances --filters Name=tag:Env,Values=dev
```

---

## 2. Deploy PROD

```bash
terraform init -reconfigure -backend-config=backend-prod.hcl
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

Verify:

```bash
aws ec2 describe-instances --filters Name=tag:Env,Values=prod
```

---

# Phase 6 — Validate State Isolation

Check S3 bucket:

```
ec2/dev/terraform.tfstate
ec2/prod/terraform.tfstate
```

States must be separate.

---

# Phase 7 — Destroy Safely

Destroy DEV only:

```bash
terraform init -backend-config=backend-dev.hcl
terraform destroy -var-file=dev.tfvars
```

Destroy PROD separately:

```bash
terraform init -backend-config=backend-prod.hcl
terraform destroy -var-file=prod.tfvars
```

Isolation prevents cross-environment damage.

---

# Phase 8 — Mental Model

Environment = Input + State
Code = Constant

Never duplicate code.
Only change:

* Backend config
* tfvars file

Infrastructure becomes deterministic and repeatable.

---

# Advanced Practice

Extend this exercise:

1. Add `stage.tfvars`
2. Add autoscaling group for prod only
3. Add conditional logic:

```hcl
count = var.environment == "prod" ? 1 : 0
```

4. Convert EC2 to module
5. Introduce workspaces and compare pattern differences

---

# Expected Learning Outcome

After this practice you should understand:

* Remote state isolation
* Variable injection hierarchy
* Auto tfvars behavior
* Backend reconfiguration
* Environment-driven infrastructure
* Safe multi-environment deployments

No duplication.
No branching.
Only controlled parameterization.
