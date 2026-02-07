# Practice -2
### Terraform EC2 with Remote Backend (Simple Guide)

---

## 1. What We Are Building

* One EC2 instance
* Terraform state stored in **S3**
* State locking using **DynamoDB**

```mermaid
flowchart LR
User((User)) --> Terraform((Terraform))
Terraform --> AWS((AWS))
AWS --> EC2([EC2])

```

---

## 2️. Why Terraform Needs State

Terraform must remember:

* What it already created
* What must be changed
* What must be deleted

This memory = **terraform.tfstate**

```mermaid
flowchart LR
Terraform((Terraform))-->StateFile[(StateFile)]
StateFile[(StateFile)]-->AWS_Resources([AWS_Resources ])
```

---

## 3. Problem with Local State

Local state means:

* Stored on one laptop
* No sharing
* No locking
* Risk of overwrite

```mermaid
flowchart LR
User-1((User-1))-->LocalState
User-2((User-2))-->LocalState
LocalState[(LocalState)]-->Conflict([Conflict])
```

**Unsafe for teams**

---

## 4. Why We Use Backend File

Backend decides:

* Where state lives
* How state is locked
* Who can access it

We use:

* **S3** for storage
* **DynamoDB** for locking

```mermaid
flowchart LR
Terraform-->S3State
Terraform-->DynamoDBLock[(DynamoDBLock)]
```

---

## 5. Why S3 + DynamoDB

**S3**

* Durable
* Cheap
* Encrypted
* Shared

**DynamoDB**

* Prevents two applies at same time
* Avoids state corruption

```mermaid
flowchart LR
Terraform((Terraform))-->S3((S3))
Terraform-->DynamoDB
DynamoDB[(DynamoDB)]-->StateLock
```

---
## 6. Why Backend Is Separate

Terraform needs backend **before** it runs.

Order:

1. Read backend
2. Load state
3. Create resources

So backend **cannot be created inside same Terraform code**.

```mermaid
flowchart LR
Backend-->TerraformInit
TerraformInit-->State
State-->ResourceCreate
```

---

## 7. Folder Structure

```yaml
terraform-ec2/
├── backend.tf
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
```
---
## 8. Backend Configuration

```python
terraform {
  backend "s3" {
    bucket         = "arira-terraform-state"
    key            = "ec2/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
```

Meaning:

* `bucket` = where state is stored
* `key` = env path
* `dynamodb_table` = locking

---
## 9. Provider

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Tells Terraform **which cloud**.

---

## 10. EC2 Creation

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
}

resource "aws_instance" "demo" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = var.key_name
}
```

Why data source?

* Always latest AMI
* No hardcoding

---
## 11. Terraform Workflow

```mermaid
flowchart TD
    linkStyle default interpolate basis

    subgraph User_Action [Commands]
        A[terraform init]
        B[terraform plan]
        C[terraform apply]
        D[terraform destroy]
    end

    subgraph Internal_Engine [Management]
        S[(State File)]
        P[Provider Plugins]
    end

    subgraph Infrastructure [Cloud]
        AWS[AWS Resources]
    end

    %% Initialization
    A --> P
    
    %% Planning & State
    B <--> S
    B -.-> AWS
    
    %% Execution
    C --> AWS
    AWS -.->|Record ID| S
    
    %% Removal
    D --> AWS
    D -.->|Clear| S
```

---

## 12.  What Happens When Two People Apply

```mermaid
flowchart TD
    linkStyle default interpolate basis

    subgraph Engineers [Team Collaboration]
        U1[Engineer A]
        U2[Engineer B]
    end

    subgraph Locking_Mechanism [Governance]
        DDB{{"[DynamoDB] <br/> Lock Table"}}
        L["[Lock] State: BUSY"]
    end

    subgraph Storage [Source of Truth]
        S3[("[S3 Bucket] <br/> terraform.tfstate")]
    end

    %% Engineer A Flow
    U1 -->|1. terraform apply| DDB
    DDB -->|2. Acquire Lock| L
    L -->|3. Read/Write| S3
    
    %% Engineer B Flow
    U2 -->|1. terraform apply| DDB
    DDB -.->|4. Request Denied| U2
    U2 --- X["[Error] State Locked"]

```
