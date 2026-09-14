# 🌍 Terraform

## 📘 What is Terraform?

Terraform is HashiCorp's open-source **infrastructure as code (IaC)** tool that lets you define, provision, and manage cloud and on-prem resources using simple, declarative configuration files. Instead of clicking through consoles, you describe your desired infrastructure state in code (HCL), and Terraform figures out how to get there.

---

## 🙋‍♂️ Who Should Use Terraform?

- **DevOps Engineers**: Automate provisioning across cloud providers.
- **Cloud Architects**: Design reusable, version-controlled infrastructure.
- **SREs**: Manage infrastructure consistently and reduce configuration drift.
- **Developers**: Spin up environments (dev/staging/prod) on demand.
- **Tech Learners**: Experiment with AWS, Azure, GCP, and other providers safely.

---

## 🎯 Why Use Terraform?

- 📜 Infrastructure as code, version-controlled like any codebase
- ☁️ Multi-cloud and provider-agnostic (AWS, Azure, GCP, and 100+ providers)
- 🔁 Plan before you apply—see changes before they happen
- 🧩 Modular and reusable configurations
- 🤝 Team collaboration via remote state and locking

---
# 🌍 Top Terraform Commands Cheat Sheet

A handy, stylish list of the **most useful Terraform commands** you'll use for provisioning, managing, and destroying infrastructure. Perfect for beginners and pros alike!

---

## 🚀 Core Workflow

| Command | Description |
|--------|-------------|
| `terraform init` | ⚙️ Initialize a working directory (downloads providers/modules) |
| `terraform plan` | 📝 Preview changes before applying |
| `terraform apply` | ✅ Apply changes to reach desired state |
| `terraform apply -auto-approve` | ⚡ Apply without confirmation prompt |
| `terraform destroy` | 💣 Destroy all managed infrastructure |
| `terraform destroy -target=<resource>` | 🎯 Destroy a specific resource |
| `terraform validate` | ✔️ Check configuration syntax and internal consistency |
| `terraform fmt` | 🎨 Auto-format `.tf` files to canonical style |
| `terraform fmt -recursive` | 🎨 Format all files in subdirectories too |

---

## 📦 State Management

| Command | Description |
|--------|-------------|
| `terraform state list` | 📋 List all resources in the state file |
| `terraform state show <resource>` | 🔍 Show details of a resource in state |
| `terraform state mv <src> <dst>` | 🚚 Move/rename a resource in state |
| `terraform state rm <resource>` | 🧹 Remove a resource from state (without destroying it) |
| `terraform state pull` | ⬇️ Download and output the current state |
| `terraform state push` | ⬆️ Upload a local state file to remote backend |
| `terraform refresh` | 🔄 Reconcile state with real-world infrastructure |

---

## 🧩 Modules & Providers

| Command | Description |
|--------|-------------|
| `terraform get` | 📥 Download and update modules |
| `terraform providers` | 🔌 Show provider requirements for the configuration |
| `terraform providers lock` | 🔒 Lock provider versions (for cross-platform consistency) |
| `terraform init -upgrade` | ⬆️ Upgrade modules and providers to latest allowed versions |

---

## 🔍 Inspection & Debugging

| Command | Description |
|--------|-------------|
| `terraform show` | 👀 Show human-readable output of state or plan |
| `terraform output` | 📤 Show output values from state |
| `terraform output <name>` | 🎯 Show a specific output value |
| `terraform graph` | 🕸️ Generate a visual dependency graph (DOT format) |
| `terraform console` | 💻 Interactive console to test expressions |
| `TF_LOG=DEBUG terraform apply` | 🐛 Enable verbose debug logging |

---

## 🔐 Workspaces

| Command | Description |
|--------|-------------|
| `terraform workspace list` | 📋 List all workspaces |
| `terraform workspace new <name>` | 🆕 Create a new workspace |
| `terraform workspace select <name>` | 🔀 Switch to a workspace |
| `terraform workspace show` | 👀 Show current workspace |
| `terraform workspace delete <name>` | 🗑️ Delete a workspace |

---

## 🔒 Locking & Import

| Command | Description |
|--------|-------------|
| `terraform force-unlock <lock-id>` | 🔓 Manually unlock the state (use with caution) |
| `terraform import <resource> <id>` | 📥 Import existing infrastructure into state |
| `terraform taint <resource>` | ⚠️ Mark a resource for recreation on next apply (deprecated—use `-replace`) |
| `terraform apply -replace=<resource>` | 🔁 Force recreation of a specific resource |

---

## 🧪 Useful Flags

| Flag | Description |
|--------|-------------|
| `-var 'key=value'` | 🔑 Pass a single variable |
| `-var-file="file.tfvars"` | 📄 Load variables from a file |
| `-target=<resource>` | 🎯 Limit operation to a specific resource |
| `-out=plan.tfplan` | 💾 Save plan output to a file |
| `-lock=false` | 🔓 Disable state locking (use carefully) |

---

## 🧠 Tip

💡 Use `--help` with any Terraform command to learn more, e.g.:

```bash
terraform plan --help
```

---

> ✅ Keep this README as a reference for your Terraform journey. Contributions welcome!
> ⭐ Star this repo if you found it helpful!
