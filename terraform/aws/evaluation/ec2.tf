resource "aws_instance" "sample" {
    ami = "ami-908a2f90"
    instance_type = "t2.micro"
    availability_zone = "ap-northeast-1a"
    tags {
      Name = "terraform_sample_2"
    }
    vpc_security_group_ids = ["${var.default_security_group}"]
    key_name = "${var.lc_key_name}"
}
