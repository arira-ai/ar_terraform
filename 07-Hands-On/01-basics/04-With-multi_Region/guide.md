# Terraform Practice Session – Multi-Region

## Objective

Create a clean, extensible Terraform practice setup targeting **multiple AWS regions** with a structure that can later scale to **multiple environments (dev/prod)** without refactoring.

Current scope: **single environment**, **two regions**.
Future scope kept in design: **env-based isolation + module reuse**.

---

## Regions in Scope

* `us-east-1`
* `eu-central-1`

Each region is treated as an independent deployment unit driven by region-specific tfvars.

---

## Directory Structure

```yaml
terraform-practice/
│
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
│
├── module_ec2.tf
├── _common-data-link.tf
│
├── us-east-1.tfvars
├── eu-central-1.tfvars
│
├── _common-data-copy.auto.tfvars
│
└── README.md
```

Design intent:

* Flat structure now
* Drop-in compatibility with future `/env/dev` and `/env/prod` folders

---

## File Responsibilities (Short, Explicit)

### `main.tf`

Root orchestration. Wires variables, providers, and modules.

### `providers.tf`

Defines AWS providers with region injected from tfvars.

### `variables.tf`

Declares all input variables used across regions.

### `outputs.tf`

Exposes region-specific outputs (instance IDs, public IPs).

---

## Region tfvars

### `us-east-1.tfvars`

Provides values specific to **us-east-1**.

Example responsibility:

* region
* AMI
* instance count
* instance type

### `eu-central-1.tfvars`

Same schema as us-east-1.tfvars, different values.

Reason:

* Region parity
* Zero conditional logic in code

---

## `_common-data-copy.auto.tfvars`

Automatically loaded shared data.

Purpose:

* Values duplicated across all regions
* No explicit `-var-file` needed

Typical content:

* project_name
* owner
* default_tags

Why auto tfvars:

* Eliminates human error
* Enforces global consistency

---

## `_common-data-link.tf`

Defines shared locals and data sources.

Purpose:

* Central linking layer
* Prevents copy-paste across modules

Typical usage:

* `locals {}`
* shared naming conventions
* data sources like `aws_caller_identity`

---

## `module_ec2.tf`

Contains **only EC2 resource logic**.

Responsibilities:

* EC2 resource block
* Security group (if tightly coupled)
* Tag propagation

Design rule:

* No region logic
* No environment logic
* Pure infrastructure definition

---

## Execution Flow

### Init

```
terraform init
```

Initializes providers and backend.

### Plan (per region)

```
terraform plan -var-file=us-east-1.tfvars
```

Shows what will be created in the selected region.

### Apply (per region)

```
terraform apply -var-file=us-east-1.tfvars
```

Creates infrastructure only for that region.

Same commands apply to `eu-central-1.tfvars`.

---

## Why This Structure Works Long-Term

* Region isolation without branching logic
* Shared data centralized
* Modules remain environment-agnostic
* Easy migration to:

```
env/
├── dev/
│   ├── us-east-1.tfvars
│   └── eu-central-1.tfvars
└── prod/
    ├── us-east-1.tfvars
    └── eu-central-1.tfvars
```

No refactor required. Only relocation.

---

## Scope Boundary

This setup intentionally avoids:

* Remote backend
* State locking
* Environment folders

Those are deferred to the next iteration by design.

---

## Terraform Files – Filled Configuration

### `providers.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

---

### `variables.tf`

```hcl
variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances"
}

variable "ami_id" {
  type        = string
  description = "AMI ID per region"
}

variable "project_name" {
  type        = string
}

variable "owner" {
  type        = string
}

variable "default_tags" {
  type        = map(string)
}
```

---

### `_common-data-copy.auto.tfvars`

```hcl
project_name = "terraform-practice"
owner        = "platform-team"

default_tags = {
  ManagedBy = "Terraform"
  Purpose   = "Practice"
}
```

---

### `_common-data-link.tf`

```hcl
data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.aws_region}"
  common_tags = merge(
    var.default_tags,
    {
      Owner      = var.owner
      AccountId = data.aws_caller_identity.current.account_id
    }
  )
}
```

---

### `module_ec2.tf`

```hcl
resource "aws_instance" "this" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ec2-${count.index}"
    }
  )
}
```

---

### `main.tf`

```hcl
module "ec2" {
  source = "./"

  aws_region     = var.aws_region
  instance_type = var.instance_type
  instance_count = var.instance_count
  ami_id         = var.ami_id

  project_name = var.project_name
  owner        = var.owner
  default_tags = var.default_tags
}
```

---

### `outputs.tf`

```hcl
output "instance_ids" {
  value = aws_instance.this[*].id
}

output "public_ips" {
  value = aws_instance.this[*].public_ip
}
```

---

### `us-east-1.tfvars`

```hcl
aws_region     = "us-east-1"
instance_type = "t3.micro"
instance_count = 1
ami_id         = "ami-0abcdef1234567890"
```

---

### `eu-central-1.tfvars`

```hcl
aws_region     = "eu-central-1"
instance_type = "t3.micro"
instance_count = 1
ami_id         = "ami-0fedcba9876543210"
```

---

## Execution Summary (One Line Each)

* `terraform init` → initialize provider and workspace
* `terraform plan -var-file=<region>.tfvars` → preview region-specific changes
* `terraform apply -var-file=<region>.tfvars` → create EC2 in selected region

This layout is intentionally compatible with future `env/dev` and `env/prod` expansion without code changes.