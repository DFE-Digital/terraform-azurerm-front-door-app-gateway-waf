# <REPLACE WITH USEFUL TERRAFORM DESCRIPTION>

[![Terraform CI](./actions/workflows/continuous-integration-terraform.yml/badge.svg?branch=main)](./actions/workflows/continuous-integration-terraform.yml?branch=main)
[![GitHub release](./releases)](./releases)

This <module/project> creates and manages <REPLACE WITH MAIN RESOURCE NAMES/URLS>.

## Usage

Example module usage:

```hcl
module "<MODULE NAME>" {
  source  = "github.com/<ORG>/<MODULE NAME>?ref=v<VERSION>"

  environment = "dev/staging/test/pre-prod/prod/post-prod"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_environment"></a> [environment](#output\_environment) | n/a |
<!-- END_TF_DOCS -->
