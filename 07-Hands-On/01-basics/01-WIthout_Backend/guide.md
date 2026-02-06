# Practice -1 

In this session with basic Terraform Files we will get the idea of the
 * code to infra creation
 * drift of the resourses

### Minimal EC2 project folder

The list fo file present in the folder

```text
terraform-ec2/
├── .terraform/ (temporarily created by terraform init cmd)
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfstate   (auto-created)
```

---

## `main.tf` (Infrastructure Definition)


```python
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "terraform-ec2"
  }
}
```

 This file answers:

* **WHAT** to create (EC2)
* **WHERE** to create (AWS region)
* **HOW** to configure it

---

## `variables.tf` (Inputs)

```python
variable "region" {
  default = "us-east-1"
}

variable "ami_id" {
  default = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
  default = "t2.micro"
}
```

 Makes code reusable and clean

---

## `outputs.tf` 

```python
output "instance_id" {
  value = aws_instance.example.id
}

output "public_ip" {
  value = aws_instance.example.public_ip
}
```

---

# Terraform Workflow

### Step 1: Initialize

```bash
terraform init
```

* Downloads AWS provider
* Creates `.terraform/` directory

---

### Step 2: Plan

```bash
terraform plan
```

Terraform:

* Reads code
* Compares with **tfstate**
* Shows **what will change**

No infra created yet

---

### Step 3: Apply

```bash
terraform apply
```

* Calls AWS APIs
* Creates EC2
* Updates **tfstate**

---

### Step 4: Destroy

```bash
terraform destroy
```

* Deletes infra
* Updates **tfstate**

---

# What is `terraform.tfstate`

### Very simple explanation:

> **tfstate = Terraform’s memory**

Terraform **does NOT ask AWS everything every time**.
It relies on **tfstate** to know:

* What exists
* Resource IDs
* Current configuration

---

## What tfstate contains

* EC2 instance ID
* AMI used
* Instance type
* Tags
* Networking details

It may contain **sensitive data**

---

## Example (simplified)

```json
{
  "resources": [
    {
      "type": "aws_instance",
      "name": "example",
      "instances": [
        {
          "attributes": {
            "instance_type": "t2.micro",
            "id": "i-0123456789"
          }
        }
      ]
    }
  ]
}
```

---

## Important tfstate rules

* NEVER edit manually
* NEVER commit to Git
* Store remotely for teams (S3 + DynamoDB)

---

# How Code → Infra Works Internally

```mermaid
flowchart TD
    linkStyle default interpolate basis

    subgraph Development [Local Environment]
        A["[Code] Terraform Files <br/> .tf"]
        E["[Memory] State File <br/> terraform.tfstate"]
    end

    subgraph Logic [Execution Engine]
        B["[Plan] Dependency Graph <br/> & Delta Calculation"]
        F["[Apply] Resource Lifecycle <br/> Management"]
    end

    subgraph Infrastructure [Remote Cloud]
        C["[API] AWS Service Endpoints"]
        D["[Resource] Provisioned Infrastructure"]
    end

    %% The Core Flow
    A --> B
    E --> B
    B -->|Approval| F
    F --> C
    C --> D
    
    %% The State Update Sync
    D -.->|Update Metadata| E
```

---

# What is Drift

**Drift = Infra changed outside Terraform**

### Example:

* Terraform created EC2 as `t2.micro`
* Someone manually changes it to `t3.micro` in AWS Console

Terraform **does not know** until next plan.

---

## Drift Detection

```bash
terraform plan
```

Terraform:

* Reads tfstate
* Reads real AWS infra
* Finds mismatch

Example output:

```text
~ instance_type: "t3.micro" → "t2.micro"
```

---

## Drift Resolution Options

### Option 1️⃣ Revert AWS to code (most common)

```bash
terraform apply
```

Terraform enforces **code as source of truth**

---

### Option 2️⃣ Accept AWS change

Update code:

```hcl
instance_type = "t3.micro"
```

Then:

```bash
terraform apply
```

---

## Drift Flow Diagram

```mermaid
flowchart TD
    linkStyle default interpolate basis

    subgraph Managed_State [1. The Desired State]
        A[" Terraform Apply"] --> B[" State File <br/> (Current Truth)"]
    end

    subgraph Real_World [2. The Actual Reality]
        A --> C[" AWS Infrastructure"]
        C --> D[" Manual Change <br/> (Out-of-Band)"]
    end

    subgraph Conflict [3. Drift Detection]
        B -.->|Compare| E[" Terraform Plan"]
        D -.->|Identify| E
        E --> F{{" Drift Detected"}}
    end

    subgraph Resolution [4. Reconciliation]
        F --> G1[" Re-Apply <br/> (Overwrites Manual Change)"]
        F --> G2[" Update Code <br/> (Aligns with Change)"]
        G1 & G2 --> A
    end
```

---

# Best Practices for Beginners

### DO

* Use `terraform plan` before apply
* Use variables
* Destroy infra after practice
* Keep infra simple

### DON’T

* Don’t change infra manually
* Don’t edit tfstate
* Don’t hardcode credentials
* Don’t commit tfstate

---

## Final Mental Model

> **Terraform Code = Desired State**

> **AWS Infra = Actual State**

> **tfstate = Terraform Memory**

> **plan = Difference Detector**

> **apply = State Enforcer**