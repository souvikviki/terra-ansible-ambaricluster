aws_profile = "superhero"
aws_region  = "ap-south-1"
vpc_cidr    = "10.0.0.0/16"

cidrs	= {
  public1  = "10.0.1.0/24"
  public2  = "10.0.2.0/24"
  public3  = "10.0.3.0/24"	
}

dev_instance_type = "t2.micro"
dev_ami	= "ami-03390cab5183cd3b8"
public_key_path	= "/root/.ssh/krypton.pub"
key_name = "krypton"
