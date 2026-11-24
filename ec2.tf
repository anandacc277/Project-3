# Find latest Amazon Linux AMI

data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {

    name = "name"

    values = ["amzn2-ami-hvm-*"]

  }

}

# Create EC2 Instance

resource "aws_instance" "monitor_server" {

  ami = data.aws_ami.amazon_linux.id

  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.monitor_server.name

  tags = {

    Name = "cloudwatch-monitor-server"

  }
}

resource "aws_iam_role" "monitor_server" {
  name = "cloudwatch-monitor-server-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.monitor_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "monitor_server" {
  name = "cloudwatch-monitor-server-ssm"
  role = aws_iam_role.monitor_server.name
}