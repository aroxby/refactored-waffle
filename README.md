Kubernetes Scaling Assignment
===
Deploy a scalable server on AWS with Kubernetes

**To build:**
1. Fork the repo
2. Configure the Repository
   1. vars.DOCKERHUB_USERNAME should be your docker hub username
   2. secrets.DOCKERHUB_TOKEN should be your docker hub token
3. Push!

**To deploy**:
1. Fork the repo
2. Connect your repo to Terraform Cloud
3. Set the terraform working directory to "infrastructure"
4. Connect your AWS account to Terraform Cloud
5. Push!

Note: You can deploy WITHOUT building.  My images are public.

TODO:
 - The API endpoint should always remain available, regardless of the number of jobs in the queue.
   - [ ] Use `nodeAffinity` to assign nodes
 - The underlying compute nodes should be elastic and the compute capacity must tightly fit the actual load on the cluster. We do not want to see massively over-provisioned nodes.
   - [ ] Configure auto-scaling criteria
 - The Kubernetes stack must be hosted on AWS. You can use 3rd party tools for anything outside of the main cluster, including provisioning and deployment.
   - [x] Setup Docker Hub and Terraform Cloud
 - Deployment of the stack and code is to be automated, using the CI/CD platform of your choice.
   - [x] Setup Github actions
 - It must be a simple task to deploy your stack on another AWS account or region.
   - [x] Use parameters for account specific values
 - There must be a way to view and search stdout/err logs from active and terminated pods in the cluster.
   - [x] Configure Fluent Bit for CloudWatch logs
 - CPU-utilisation for all active nodes in the cluster
   - [x] EKS should not need additonal configuration to display these in the console
 - The total CPU-utilisation of the entire cluster.
   - [x] EKS should not need additonal configuration to display these in the console
