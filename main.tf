provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}



#-------------VPC-----------

resource "aws_vpc" "wp_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "wp_vpc"
  }
}

#internet gateway

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  tags {
    Name = "wp_igw"
  }
}


# Route tables

resource "aws_route_table" "wp_public_rt" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp_internet_gateway.id}"
  }

  tags {
    Name = "wp_public"
  }
}

#subnet


resource "aws_subnet" "wp_public1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "wp_public1"
  }
}

resource "aws_subnet" "wp_public2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "wp_public2"
  }
}

resource "aws_subnet" "wp_public3_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public3"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "wp_public3"
  }
}  
# associate subnet with route tables


resource "aws_route_table_association" "wp_public_assoc" {
  subnet_id      = "${aws_subnet.wp_public1_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_public2_assoc" {
  subnet_id      = "${aws_subnet.wp_public2_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_public3_assoc" {
  subnet_id      = "${aws_subnet.wp_public3_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

#Security groups

resource "aws_security_group" "wp_dev_sg" {
  name        = "wp_dev_sg"
  description = "Used for access to the dev instance"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  #SSH
/*
  ingress {
    from_port   = 22  
    to_port     = 22  
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
*/
  #HTTP

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#key pair

resource "aws_key_pair" "wp_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#dev server

resource "aws_instance" "wp_dev" {
  instance_type = "t2.large"
  ami           = "${var.dev_ami}"		
  count = 1
  tags {
    Name = "wp_dev${count.index}"
  }

  key_name               = "${aws_key_pair.wp_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.wp_dev_sg.id}"]
  subnet_id              = "${aws_subnet.wp_public1_subnet.id}"
  
}

resource "aws_instance" "wp_dev1" {
  instance_type = "${var.dev_instance_type}"
  ami           = "${var.dev_ami}"		
  count = 1
  tags {
    Name = "wp_dev1${count.index}"
  }

  key_name               = "${aws_key_pair.wp_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.wp_dev_sg.id}"]
  subnet_id              = "${aws_subnet.wp_public2_subnet.id}"
  
}

resource "aws_instance" "wp_dev2" {
  instance_type = "${var.dev_instance_type}"
  ami           = "${var.dev_ami}"		
  count = 1
  tags {
    Name = "wp_dev2${count.index}"
  }

  key_name               = "${aws_key_pair.wp_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.wp_dev_sg.id}"]
  subnet_id              = "${aws_subnet.wp_public3_subnet.id}"
  
}

resource "null_resource" "ConfigureHosts" {
  provisioner "local-exec" {
    command ="echo [master-nodes] > aws_hosts"
  }
}

resource "null_resource" "RemotePublicIpToAnsibleHosts" {
  count = 1
  provisioner "local-exec" {
    command ="echo master01 ansible_host=${aws_instance.wp_dev.*.public_ip[count.index]}  >> aws_hosts" 
  }
}

resource "null_resource" "ConfigureHosts1" {
  provisioner "local-exec" {
    command ="echo [slave-nodes] | tee -a aws_hosts"
  }
  depends_on = ["null_resource.RemotePublicIpToAnsibleHosts"]

}

resource "null_resource" "RemotePublicIpToAnsibleHosts1" {
  count = 1
  provisioner "local-exec" {
    command ="echo 'slave01 ansible_host=${aws_instance.wp_dev1.*.public_ip[count.index]}'  >> aws_hosts"
  }
  depends_on = ["null_resource.ConfigureHosts1"]
}

resource "null_resource" "RemotePublicIpToAnsibleHosts2" {
  count = 1
  provisioner "local-exec" {
    command ="echo 'slave02 ansible_host=${aws_instance.wp_dev2.*.public_ip[count.index]}'  >> aws_hosts"
  }
  depends_on = ["null_resource.RemotePublicIpToAnsibleHosts1"]
}

resource "null_resource" "lastpart" {
  provisioner "local-exec" {
    command = <<EOD
    cat | tee -a aws_hosts << EOF 

[ranger-nodes]

[all-nodes:children]
master-nodes
slave-nodes

[all-nodes:vars]
ansible_user=centos
ansible_ssh_private_key_file=/home/souvik/krypton.pem

  EOF 
  EOD
  }
  depends_on = ["null_resource.RemotePublicIpToAnsibleHosts2"]

}

resource "null_resource" "ConfigureAnsible" {
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok  --profile superhero && ansible-playbook -i aws_hosts playbooks/hortonworks.yml" 
 }
}

  

