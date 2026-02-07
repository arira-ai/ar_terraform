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

# Best Practices
#  Terraform State & Locking – Recovery and Edge Scenarios

Terraform state is **critical infrastructure metadata**.
The following scenarios explain **what can go wrong**, **why**, and **exactly what to do**.

---

## Scenario List (High → Low impact)

1. tfstate file deleted from S3 (resources still exist)
2. Terraform state is locked (DynamoDB lock not released)
3. S3–DynamoDB checksum mismatch
4. Partial state loss (some resources missing)
5. State drift (manual AWS changes)
6. Wrong backend or state key configured
7. Multiple users modifying same infra
8. Accidental resource recreation risk


```mermaid
flowchart TD
    linkStyle default interpolate basis

    subgraph Persistence_Issues [Storage Failures]
        A["[S3] State Deleted <br/> (Infra Orphaned)"]
        B["[Backend] Wrong Key/Path <br/> (Empty State)"]
        C["[S3] Version Mismatch <br/> (Corrupt Checksum)"]
    end

    subgraph Concurrency_Issues [Locking Failures]
        D["[DynamoDB] Stale Lock <br/> (Process Blocked)"]
        E["[Team] Multi-User Access <br/> (Race Condition)"]
    end

    subgraph Data_Consistency [State vs Reality]
        F["[Manual] Console Drift <br/> (Out-of-Sync)"]
        G["[Partial] Resource Loss <br/> (Partial Reality)"]
        H["[Risk] Re-create Collision <br/> (Existing ID Conflict)"]
    end
```

---

## 1. tfstate file deleted from S3 (resources still exist)

### What happened

* AWS resources still exist
* Terraform lost its state
* Terraform thinks infra does NOT exist

>Running `terraform apply` now can **duplicate resources**

---

###  Correct recovery steps

1. Reinitialize backend

```bash
terraform init -reconfigure
```

2. Identify existing AWS resources (example EC2)

```bash
aws ec2 describe-instances --query "Reservations[].Instances[].InstanceId" --output text
```

3. Import resources back into state

```bash
terraform import aws_instance.demo i-xxxxxxxx
```

4. Verify

```bash
terraform state list
terraform plan
```

---

### Flow diagram

```mermaid
flowchart TD
    linkStyle default interpolate basis

    subgraph Problem [Current Status]
        A[Cloud Resources Exist]
        B[State File Missing/Deleted]
    end

    subgraph Preparation [Code Setup]
        C[Write HCL Resource Block]
    end

    subgraph Action [The Bridge]
        D[terraform import]
    end

    subgraph Result [Sync Success]
        E[State File Rebuilt]
        F[Managed Status Restored]
    end

    %% Process Flow
    A & B --> C
    C --> D
    D --> E
    E --> F
```

---

### What NOT to do

* Do not run `terraform apply` before import
* Do not recreate infra manually
* Do not guess resource IDs

---

## 2. Terraform state is locked (DynamoDB lock not released)

### What happened

* Terraform crashed or was force-stopped
* DynamoDB lock entry still exists
* New Terraform runs are blocked

Typical error:

```text
Error acquiring the state lock
```

---

### Safe ways to release lock

1. Option A: Automatic (recommended)
2. Option B: Manual (console)

#### Option A: Automatic (recommended)

```bash
terraform force-unlock <LOCK_ID>
```

#### Option B: Manual (console)

* DynamoDB → `terraform-locks`
* Delete **only the lock item**
* Do NOT delete table

---

### Lock lifecycle

```mermaid
flowchart LR
A[terraform apply] --> B[DDB lock created]
B --> C[Apply running]
C --> D[Lock released]
```

---

### Important warning

Never force-unlock if:

* Another apply is running
* Another engineer is working

---

## 3. S3–DynamoDB checksum mismatch

### What happened

* tfstate deleted or modified in S3
* DynamoDB still stores old checksum
* Terraform detects corruption

Error:

```text
checksum calculated for the state does not match
```

---

### Fix procedure

Option 1 (preferred):

* DynamoDB → delete the **lock item only**

Option 2 (dev only):

* Delete and recreate DynamoDB table

Then:

```bash
terraform init -reconfigure
```

---

### Diagram

```mermaid
flowchart LR
A[S3 state deleted] --> B[DDB checksum exists]
B --> C[Checksum mismatch]
C --> D[Delete lock item]
D --> E[Backend works]
```

---

## 4. Partial state loss (some resources missing)

### What happened

* State file exists
* Some resources missing from state
* Infra partially managed

---

### Fix

1. List current state

```bash
terraform state list
```

2. Import missing resources

```bash
terraform import aws_security_group.demo sg-xxxx
```

3. Validate

```bash
terraform plan
```

---

### Diagram

```mermaid
flowchart LR
A[Partial state] --> B[terraform state list]
B --> C[terraform import]
C --> D[State corrected]
```

---

## 5. Terraform drift 

### What happened

* Infra modified via AWS Console / CLI
* Terraform state is outdated

---

### Detect and fix

```bash
terraform plan
```

If drift exists:

* Update Terraform code to match AWS
* OR revert AWS changes

---

### Diagram

```mermaid
flowchart LR
A[Manual AWS change] --> B[(State drift)]
B --> C[terraform plan]
C --> D[Code or infra fix]
```

---

## 6. Wrong backend or state key configured

### What happened

* Wrong S3 bucket
* Wrong `key` path
* Terraform creates a new empty state

---

### Fix

1. Verify backend config

```hcl
bucket = "ar-terraform-state"
key    = "ec2/dev/terraform.tfstate"
```

2. Reconfigure

```bash
terraform init -reconfigure
```

---

## 7. Multiple users modifying same infra

### What happened

* Same backend
* No locking OR locking bypassed
* Race conditions

---

### Prevention

* Always enable DynamoDB locking
* Never disable backend lock
* One apply at a time

---

### Diagram

```mermaid
flowchart LR
A[User1 apply] --> B[State locked]
C[User2 apply] --> D[Blocked]
```

---

## 8. Accidental resource recreation risk

### High-risk scenario

* Empty state
* Existing infra
* `terraform apply` executed

---

### Result

* Duplicate EC2s
* Broken networking
* Unexpected cost

---

### Golden rule

> **If state is missing — IMPORT FIRST**

---

## Best Practices Summary

* Enable **S3 versioning**
* Protect tfstate with IAM
* Never delete tfstate casually
* Use DynamoDB locking always
* Treat tfstate as **production data**
