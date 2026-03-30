# aws-infra

This repo manages Otto's AWS infrastructure using [OpenTofu](https://opentofu.org), the open-source Terraform fork maintained by the Linux Foundation.

## Purpose

Manage the core elements of Otto's AWS organization following AWS Organizations best practices.

## Tooling

- **OpenTofu**: IaC tool; HCL files (`.tf`); managed via home-manager
- **AWS CLI**: for auth, SSO login, account inspection
- **prek**: pre-commit hook manager; configured in `prek.toml`

## Region

Default region: **us-east-1**. All resources use this region unless there is an explicit reason to deviate.

## Account structure

```
Root (ojhermann-org)
├── Management account (324621155013)  — governance + operational tooling (jump box)
└── Workloads OU
    ├── SDLC OU
    │   ├── Dev account (916868258956)
    │   └── Stage account (039914330850)
    └── Prod OU
        └── Prod account (425924866611)
```

Within each workload account: one VPC per service.

## CLI profiles

| Profile | Account | Purpose |
|---------|---------|---------|
| `otto-management` | 324621155013 | Org governance, account creation |
| `otto-dev` | 916868258956 | Dev workloads |
| `otto-stage` | 039914330850 | Stage workloads |
| `otto-prod` | 425924866611 | Prod workloads |

## Identity and access

- **IAM Identity Center** (not IAM users) is the identity layer for human access
- User `otto` is a member of the `admins` group
- `admins` group has `AdministratorAccess` permission set assigned per account
- CLI auth via `aws sso login --profile <profile>`
- Root account credentials are not used after initial setup

### Jump box access

An EC2 instance (`shared-jump-box-management`) in the management account provides persistent multi-account CLI access without SSO browser auth. Access via SSM Session Manager:

```bash
aws ssm start-session --target <instance-id> --profile otto-management
```

The instance has an IAM instance profile (`shared-jump-box-management`) with:
- `AdministratorAccess` on the management account
- `sts:AssumeRole` into `shared-jump-box-role` in each member account

Sessions run as `ec2-user` and are logged to CloudWatch (`/ssm/jump-box-sessions`, 90-day retention).

Nix is installed at first launch (Determinate Systems installer, daemon mode, flakes enabled). Apply `ojhermann-org/home-manager` on first login to complete the environment setup.

Configure `~/.aws/config` on the jump box:

```ini
[profile otto-management]
credential_source = Ec2InstanceMetadata

[profile otto-dev]
role_arn = arn:aws:iam::916868258956:role/shared-jump-box-role
source_profile = otto-management

[profile otto-stage]
role_arn = arn:aws:iam::039914330850:role/shared-jump-box-role
source_profile = otto-management

[profile otto-prod]
role_arn = arn:aws:iam::425924866611:role/shared-jump-box-role
source_profile = otto-management
```

Then use `export AWS_PROFILE=otto-dev` (or direnv) to switch accounts within a session.

## State management

Remote state is stored in S3 with DynamoDB for locking. State is scoped per directory (one state file per account/layer).

| Resource | Name |
|----------|------|
| S3 bucket | `ojhermann-tofu-state` |
| DynamoDB table | `ojhermann-tofu-locks` |
| Region | `us-east-1` |

The `bootstrap/` directory uses **local state** to create the S3 bucket and DynamoDB table. All other directories use remote state.

## Directory structure

```
aws-infra/
├── bootstrap/       # S3 state bucket + DynamoDB lock table (local state, run once)
├── management/      # Management account resources (org, OUs, member accounts)
├── dev/             # Dev account workload resources
├── stage/           # Stage account workload resources
├── prod/            # Prod account workload resources
└── modules/         # Reusable OpenTofu modules
```

## Naming convention

Pattern: `{service}-{resource-type}-{env}`

Examples:
- `api-vpc-dev`, `api-vpc-prod`
- `frontend-sg-stage`
- `database-subnet-prod`
- `shared-igw-dev`

Use lowercase and hyphens throughout. The `shared` prefix is for resources not owned by a single service.

## Tagging convention

All AWS resources must be tagged consistently. Required tags:

| Key | Description | Example values |
|-----|-------------|----------------|
| `Name` | Human-readable resource name, follows naming convention | `api-vpc-dev`, `shared-igw-prod` |
| `env` | Environment | `management`, `dev`, `stage`, `prod` |
| `service` | Service or workload this resource belongs to | `api`, `frontend`, `database`, `shared` |
| `managed-by` | How the resource was created | `opentofu`, `manual` |

Guidelines:
- Use lowercase keys and values throughout
- Apply tags at creation time — retrofitting is painful
- The `managed-by=opentofu` tag makes it easy to distinguish IaC-managed resources from anything created manually
- The `service=shared` value is for resources that span multiple services (e.g., org-level resources, shared networking)
- Cost allocation reports in Cost Explorer use `env` and `service` to break down spend

## Conventions

- All changes on a branch, merged via PR — never commit directly to `main`
- One directory per account/layer — each has its own backend and state file
- Modules in `modules/` for anything used in more than one place
- Run `tofu fmt` before committing
- Update this file whenever conventions, structure, or account details change
- Keep CI in sync with the repo: when a new account directory is added, add it to the `plan` matrix in `.github/workflows/ci.yml`

## Bootstrap sequence

- [x] Enable IAM Identity Center in management account
- [x] Create Identity Center user `otto`, add to `admins` group
- [x] Assign `AdministratorAccess` permission set to `admins` group on management account
- [x] Verify CLI access (`aws sts get-caller-identity --profile otto-management`)
- [x] Confirm AWS Organization exists (`o-3b7bm2b2yf`), feature set ALL
- [x] Tag org root with `Name=ojhermann-org`
- [x] Set up AWS Budget alert on management account (created manually as `monthly-budget`; imported into `management/`)
- [x] Create S3 state bucket and DynamoDB lock table (`bootstrap/`)
- [x] Create OU structure (Workloads → SDLC, Prod) (`management/`)
- [x] Create member accounts (dev, stage, prod) (`management/`)
- [x] Assign `admins` group + `AdministratorAccess` to each member account
- [x] Configure CLI profiles for each member account
- [x] Import budget into `management/`
- [x] Deploy jump box EC2 in management account with SSM access (`management/`)
- [x] Create cross-account IAM roles in member accounts (`dev/`, `stage/`, `prod/`)
- [ ] Configure `~/.aws/config` on jump box (manual, see Identity and access section)
- [ ] Begin managing workload resources per account
