# Provision Kinesis Firehose Delivery Stream to S3 with Newline Delimiter Using Terraform

## 📌 Task Description

The **DevOps team** needs to create a real-time data ingestion pipeline using Amazon Kinesis Data Firehose to stream data directly into an Amazon S3 bucket. The Firehose delivery stream must assume an IAM role via STS, buffer incoming data, and append a newline delimiter (`\n`) to each record before delivering it to S3 for downstream analytics.

**Requirements:**

- Create an S3 bucket named **`datacenter-stream-bucket-423652191`**.
- Create an IAM role named **`firehose-sts-role`** with a trust policy allowing Kinesis Firehose (`firehose.amazonaws.com`) to assume the role via STS.
- Create and attach an IAM policy allowing Kinesis Firehose to perform necessary S3 actions (such as `s3:PutObject`, `s3:GetObject`, `s3:ListBucket`, `s3:AbortMultipartUpload`) on the bucket.
- Use **`depends_on`** in the Firehose delivery stream resource to ensure it waits for the IAM role policy attachment.
- Create a Firehose delivery stream named **`datacenter-firehose-stream`** targeting the S3 bucket with `extended_s3` destination.
- Configure buffering settings:
  - **Buffer Size**: 5 MB (`buffering_size = 5`)
  - **Buffer Interval**: 300 seconds (`buffering_interval = 300`)
- Enable record processing with processor type **`AppendDelimiterToRecord`** and parameter **`Delimiter`** set to **`\n`** (`"\\n"` in HCL).
- Use **`main.tf`** (do not create a separate `.tf` file) to provision the S3 bucket, IAM role/policy, and Firehose stream.
- Declare variables in **`variables.tf`**:
  - **`KKE_S3_BUCKET_NAME`**: Name of the bucket.
  - **`KKE_FIREHOSE_STREAM_NAME`**: Name of the firehose stream.
  - **`KKE_FIREHOSE_ROLE_NAME`**: Name of the firehose role.
- Assign values in **`terraform.tfvars`**.
- Export outputs in **`outputs.tf`**:
  - **`kke_firehose_stream_name`**: Name of the created Firehose stream.
  - **`kke_s3_bucket_name`**: Name of the created S3 bucket.
  - **`kke_firehose_role_arn`**: ARN of the created Firehose role.
- Send test records to the Firehose stream and verify that delivered S3 objects have newline delimiters appended to each record.
- The Terraform working directory is **`/home/bob/terraform`**.

👉 **Your task:** Configure `variables.tf`, assign values in `terraform.tfvars`, define the S3 bucket, IAM role/policy, and `aws_kinesis_firehose_delivery_stream` in `main.tf`, and export resource details in `outputs.tf`.

---

## 🔧 Infrastructure Overview

**Target Environment:** AWS Cloud  
**Provider:** AWS (Amazon Web Services)  
**Configuration Files & Structure:**

- **`variables.tf`**:
  - `KKE_S3_BUCKET_NAME` (string): Stores the S3 destination bucket name.
  - `KKE_FIREHOSE_STREAM_NAME` (string): Stores the Firehose stream name.
  - `KKE_FIREHOSE_ROLE_NAME` (string): Stores the IAM role name.
- **`terraform.tfvars`**:
  - `KKE_S3_BUCKET_NAME       = "datacenter-stream-bucket-423652191"`
  - `KKE_FIREHOSE_STREAM_NAME = "datacenter-firehose-stream"`
  - `KKE_FIREHOSE_ROLE_NAME   = "firehose-sts-role"`
- **`main.tf`**:
  - `aws_s3_bucket.firehose_bucket`: Destination bucket for streaming data.
  - `aws_iam_role.firehose_role`: Role assumed by `firehose.amazonaws.com` via `sts:AssumeRole`.
  - `aws_iam_role_policy.firehose_policy`: Inline policy granting S3 read/write/list permissions.
  - `aws_kinesis_firehose_delivery_stream.firehose_stream`: Configured with `destination = "extended_s3"`, 5MB/300s buffering, `AppendDelimiterToRecord` processor with `\n`, and explicit `depends_on = [aws_iam_role_policy.firehose_policy]`.
- **`outputs.tf`**:
  - `kke_firehose_stream_name`: Exposes `aws_kinesis_firehose_delivery_stream.firehose_stream.name`.
  - `kke_s3_bucket_name`: Exposes `aws_s3_bucket.firehose_bucket.bucket`.
  - `kke_firehose_role_arn`: Exposes `aws_iam_role.firehose_role.arn`.

**Working Directory:** `/home/bob/terraform`

---

## 💡 Background: Record Processing with `AppendDelimiterToRecord`

By default, Kinesis Firehose concatenates individual stream records into a single raw byte stream when delivering to S3 without separating them.

- Setting `processors` with `type = "AppendDelimiterToRecord"` and `Delimiter = "\n"` instructs Firehose to automatically append a newline character after every record payload.
- This ensures downstream consumers (such as Athena, EMR, or Big Data parsers) can process the output line-by-line as standard JSON Lines (JSONL) or delimited text without manual pre-processing.

---

## 🚀 Implementation Steps

To execute this task on the target system, follow these steps:

1. **Navigate to the Working Directory:**

   ```bash
   cd /home/bob/terraform
   ```

2. **Define Variables in `variables.tf`:**

   Declare the required variables:

   ```hcl
   variable "KKE_S3_BUCKET_NAME" {
     type        = string
     description = "Name of the S3 bucket for Firehose delivery"
   }

   variable "KKE_FIREHOSE_STREAM_NAME" {
     type        = string
     description = "Name of the Firehose delivery stream"
   }

   variable "KKE_FIREHOSE_ROLE_NAME" {
     type        = string
     description = "Name of the IAM role for Firehose"
   }
   ```

3. **Assign Variable Values in `terraform.tfvars`:**

   Specify the exact values:

   ```hcl
   KKE_S3_BUCKET_NAME       = "datacenter-stream-bucket-423652191"
   KKE_FIREHOSE_STREAM_NAME = "datacenter-firehose-stream"
   KKE_FIREHOSE_ROLE_NAME   = "firehose-sts-role"
   ```

4. **Configure S3 Bucket, IAM Role/Policy, and Firehose Stream in `main.tf`:**

   Define the destination bucket, assume role trust policy, S3 permissions policy, and delivery stream:

   ```hcl
   resource "aws_s3_bucket" "firehose_bucket" {
     bucket = var.KKE_S3_BUCKET_NAME
   }

   data "aws_iam_policy_document" "firehose_assume_role" {
     statement {
       effect  = "Allow"
       actions = ["sts:AssumeRole"]

       principals {
         type        = "Service"
         identifiers = ["firehose.amazonaws.com"]
       }
     }
   }

   resource "aws_iam_role" "firehose_role" {
     name               = var.KKE_FIREHOSE_ROLE_NAME
     assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
   }

   data "aws_iam_policy_document" "firehose_s3_policy" {
     statement {
       effect = "Allow"
       actions = [
         "s3:AbortMultipartUpload",
         "s3:GetBucketLocation",
         "s3:GetObject",
         "s3:ListBucket",
         "s3:ListBucketMultipartUploads",
         "s3:PutObject"
       ]
       resources = [
         aws_s3_bucket.firehose_bucket.arn,
         "${aws_s3_bucket.firehose_bucket.arn}/*"
       ]
     }
   }

   resource "aws_iam_role_policy" "firehose_policy" {
     name   = "firehose-s3-policy"
     role   = aws_iam_role.firehose_role.id
     policy = data.aws_iam_policy_document.firehose_s3_policy.json
   }

   resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
     name        = var.KKE_FIREHOSE_STREAM_NAME
     destination = "extended_s3"

     extended_s3_configuration {
       role_arn           = aws_iam_role.firehose_role.arn
       bucket_arn         = aws_s3_bucket.firehose_bucket.arn
       buffering_size     = 5
       buffering_interval = 300

       processing_configuration {
         enabled = true

         processors {
           type = "AppendDelimiterToRecord"

           parameters {
             parameter_name  = "Delimiter"
             parameter_value = "\\n"
           }
         }
       }
     }

     depends_on = [aws_iam_role_policy.firehose_policy]
   }
   ```

5. **Define Outputs in `outputs.tf`:**

   Export the created resource details:

   ```hcl
   output "kke_firehose_stream_name" {
     value       = aws_kinesis_firehose_delivery_stream.firehose_stream.name
     description = "Name of the firehose stream created"
   }

   output "kke_s3_bucket_name" {
     value       = aws_s3_bucket.firehose_bucket.bucket
     description = "Name of the bucket created"
   }

   output "kke_firehose_role_arn" {
     value       = aws_iam_role.firehose_role.arn
     description = "ARN of the created firehose role"
   }
   ```

6. **Initialize Terraform:**

   Initialize the working directory to download the AWS provider plugins:

   ```bash
   terraform init
   ```

7. **Validate Configuration & Review Execution Plan:**

   Validate syntax and inspect planned actions:

   ```bash
   terraform validate
   terraform plan
   ```

8. **Apply the Configuration:**

   Provision the S3 bucket, IAM role, and Firehose delivery stream:

   ```bash
   terraform apply -auto-approve
   ```

9. **Verify Outputs & Resources:**

   Check the Terraform output values:

   ```bash
   terraform output
   ```

   Verify the Firehose delivery stream status:

   ```bash
   aws firehose describe-delivery-stream \
     --delivery-stream-name datacenter-firehose-stream \
     --query "DeliveryStreamDescription.[DeliveryStreamName,DeliveryStreamStatus,Destinations[0].ExtendedS3DestinationDescription.BufferingHints]" \
     --output json
   ```

10. **Test Ingestion & Verify Newline Delimiter:**

    Send test records to the delivery stream:

    ```bash
    aws firehose put-record \
      --delivery-stream-name datacenter-firehose-stream \
      --record '{"Data":"eyJtZXNzYWdlIjogInJlY29yZCAxIn0="}'

    aws firehose put-record \
      --delivery-stream-name datacenter-firehose-stream \
      --record '{"Data":"eyJtZXNzYWdlIjogInJlY29yZCAyIn0="}'
    ```

    Once the buffer flush interval elapses (or buffer size is met), list and inspect the delivered objects in S3:

    ```bash
    aws s3 ls s3://datacenter-stream-bucket-423652191/ --recursive
    ```

    Download and inspect the file to verify each record ends with a newline:

    ```bash
    aws s3 cp s3://datacenter-stream-bucket-423652191/<file-path> delivered_data.txt
    cat delivered_data.txt
    ```
