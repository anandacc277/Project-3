# EC2 CPU monitoring

Deploy the instance and alarm:

```powershell
terraform init
terraform apply
```

The CloudWatch alarm enters the ALARM state when average CPU utilization exceeds
25% for two consecutive five-minute periods. EC2 basic monitoring supplies
five-minute data. There is no email notification.

To generate a bounded CPU spike, run this from the project directory after
deploying the instance:

```powershell
.\spike_cpu.ps1
```

The script sends a 20-minute CPU load command to the instance from
`terraform output instance_id` using Systems Manager. The duration is bounded
to 10 to 20 minutes; the default is 20 minutes. It prompts before sending the
command. Requires Terraform, AWS CLI credentials with permission to send SSM
commands, and an instance registered as a Systems Manager managed node with
network access to the SSM endpoints. Wait for CloudWatch to receive and
evaluate the metrics, then check whether the alarm entered ALARM. AWS charges
may apply.

Publish the Terraform files, `.terraform.lock.hcl`, and this README to a repository
and submit its link. Do not publish Terraform state files.

When finished, run `terraform destroy`.
