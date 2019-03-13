# Example Terraform setup for provisioning Infrastructure in GCP

The Sample gcp-simple-environment.tf file will provision two VPC custom networks (one in US-East1 region and one in Europe-West1 region) each with their own submetworks. It will also provision 2 VM instances, one in each subnetwork and create Firewall rules to allow for SSH and ICMP (ping) connections between the two over the external network. Lastly, Terraform will also output the external and internal IPs of both servers to the console.

<strong>Note: </strong> If you are running the Terraform deployment from from inside GCP's Cloud Shell use the cloud-shell/gcp-cloudshell-demoenvironment.tf file as it has the provider section removed as it is not needed and will cause an error if included.

When running outside of cloud shell you should use the demo/gcp-simple-environment.tf file and will need a <strong>credentials.json</strong> file stored in the root directory of this repo. The Credentials file can be generated in the GCP console IAM section from any service account that has permission to provision VPC Networks, Subnetworks, and Compute Instances.


# Running the Terraform Deployment

1. Regardless of which one you pick (cloud-shell or demo) you will need to navigate into that folder and initialize Terraform so that it can download the required Google privider plugin
<br/>
<code>terraform init</code>

2. Once it has been initialized you will notice that a new .terraform directory has been created. Leave this folder alone as terraform will manage it on it's own. Next run the terraform plan file to review the changes
<br/>
<code>terraform plan --out test.plan </code>

This will also output the plan to a file. It is always good practice to run the apply command using a plan file in case the .tf file has been changed by someone else before you actually have applied to plan to your environment. Not using a plan file can lead to some unforseen consequences.

3. Apply the Terraform plan to your environment in GCP. If not using a plan file Terraform will prompt you to review and confirm the details before executing the deployment
<br/>
<code>terraform apply test.plan </code>

4. To tear down your environment after you are done with the test environment use the terraform destroy command
<br/>
<code>terraform destroy </code>


There are many more features that terraform offers, but this should be enough to get you started on using Terraform. Have fun!