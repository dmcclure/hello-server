# hello-server

## Setting up infrastructure in the primary AWS region

**hello-server**'s primary AWS region is **us-west-1**. The following steps will setup infrastructure in this region from scratch, including

* Creating a CI/CD pipeline, and
* Creating test, staging and production environments.

### Prerequisites

* AWS CLI is installed
* Terraform CLI is installed

### Steps

1. Create an S3 bucket to store Terraform state

   ```bash
   aws s3api create-bucket --region us-west-1 --create-bucket-configuration LocationConstraint=us-west-1 --acl private --bucket hello-server-terraform-artifacts
   ```

2. Enable versioning on the bucket

   ```bash
   aws s3api put-bucket-versioning --bucket hello-server-terraform-artifacts --versioning-configuration Status=Enabled
   ```

3. Run terraform in the `base` directory.

4. Run terraform in each environment directory (`test1`, `staging` and `production`).

5. Generate a GitHub access token so CodePipeline can access the source repository (GitHub has an article explaining how to do this [here](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/))

6. Store the GitHub access token in parameter store

   ```bash
   aws ssm put-parameter --region us-west-1 --name "/hello-server/github_token" --value "GITHUB_TOKEN_HERE" --type "SecureString"
   ```

7. Store configuration data in parameter store. There will be a separate set of config for each environment (test, staging and production)

   ```bash
   aws ssm put-parameter --region us-west-1 --name "/hello-server/test/database_dsn" --value "DATABASE_DSN_HERE" --type "SecureString"
   ```

## Setting up infrastructure in a secondary AWS region

The following steps will setup a regional instance of `hello-server` in a non-primary AWS region (for example, sa-east-1 or eu-west-1).
