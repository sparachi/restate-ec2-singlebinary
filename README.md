# Intro
Minimal Restate single-node deployment (EC2 + EBS) for testing restate workflows

# Pre-configuration
Ensure you've aws cli installed and local setup works. AWS credentials were setup to run the aws cli commands to create/update/delete cloud resources. At least 2 public subnets (in a AWS region of your choice) were setup with an internet gateway to allow ingress/egress to Internet. (NOTE: Current CFT's do not cover this setup). 
This setup also places the ALB behind an existing personal domain. Alternatively you can choose to skip the ALB provisoning, subdomain setup. Open the EC2 security groups, and network ACL to your IP address for direct access to restate server using the EC2 IP address.

# Setup
`deploy.yaml` is an AWS CFT  to create a EC2+EBS instance that can run a restate binary as single node.
`deployALB.yaml` is an AWS CFT to create load balancer that fronts the EC2, and necessary certificates using AWS ACM. It automatically places behind a subdomain of your choice.
`restate-setup.sh` has the restate installation and initialization code. It assumes EC2 is able to reach to internet via an AWS internet gateway.
`deployparams.yaml` values needed to be supplied to cloud formation create command.

# Cost
Per-hour total ≈ $0.124
Per-day (24 hours) ≈ 0.124 × 24 ≈ $2.98/day

# check your IP address
```
curl https://checkip.amazonaws.com
```

# Create EC2 stack
```
aws cloudformation create-stack \
  --stack-name RestateEC2Stack \
  --template-file file://deploy.yaml \
  --parameter-overrides file:///<full filepath>/deployparams.json \
  --capabilities CAPABILITY_NAMED_IAM

```

# Create ALB stack
```
aws cloudformation deploy \
  --template-file deployALB.yaml \
  --stack-name RestateALBStack \
  --parameter-overrides file:///<full filepath>/deployALBParams.json \
  --capabilities CAPABILITY_NAMED_IAM

```

# Delete stack

```
aws cloudformation delete-stack --stack-name RestateEC2Stack
aws cloudformation delete-stack --stack-name RestateALBStack
```