# Example Terraform setup for provisioning Infrastructure in GCP

The Sample gcp-simple-environment.tf file will provision two VPC custom networks (one in US-East1 region and one in Europe-West1 region) each with their own submetworks. It will also provision 2 VM instances, one in each subnetwork and create Firewall rules to allow for SSH and ICMP (ping) connections between the two over the external network. Lastly, Terraform will also output the external and internal IPs of both servers to the console.

<strong>Note: </strong> If you are running the gcp-simple-environment.tf file from inside GCP's Cloud Shell you must comment out or remove the entire <strong>provider "google" {...} </strong>reference as it is not needed and will cause an error.
