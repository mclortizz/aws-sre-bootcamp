#Provider Connection
provider "aws" {
    region = "us-east-1"

    ## Forma 1 Autenticação
    #access_key = ""
    #secret_key = ""

    ## Forma 2 Autenticação
    # export AWS_SECRET_ACCESS_KEY=
    # export AWS_ACCESS_KEY_ID=

    ## Forma 3 Autenticação
    # Instalar o AWS CLI
    # AWS configure

}

#Security Group Configuration
resource "aws_security_group" "scale_web_sg_test" {
    name = "Scale-Group-Security-Group-Test"
    description = "Security Group to Scale Practice"

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "ALL Output"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#Elastic Load Balancer Configuration
resource "aws_elb" "scale_web_lb_test" {
    name = "Scale-Web-Load-Balancer-Test"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
    security_groups = [aws_security_group.scale_web_sg_test.id]

    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }

    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        target = "HTTP:80/"
        interval = 30
    }  

    cross_zone_load_balancing = true
    idle_timeout = 400
    connection_draining = true
    connection_draining_timeout = 400
}

#Auto Scaling Launch Configuration
resource "aws_launch_configuration" "scale_web_lc_test" {
    name = "Scale-Web-LC-Test"
    image_id = "ami-0cff7528ff583bf9a"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.scale_web_sg_test.id]
    key_name = "virginia"
    user_data = "${file("bootstrap.sh")}"
}

#Auto Scaling Groups Configuration
resource "aws_autoscaling_group" "scale_web_autoscaling_group_test" {
    name = "Scale-Autoscaling-group-test"
    launch_configuration = aws_launch_configuration.scale_web_lc_test.name
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
    min_size = 2
    desired_capacity = 2
    max_size = 5
    load_balancers = [aws_elb.scale_web_lb_test.name]
    health_check_type = "ELB"

    tags = [
      {
        key = "name"
        value = "autoscaling-true"
      },
    ]
}

#Auto Scaling Plan Configuration
resource "aws_autoscalingplans_scaling_plan" "scale_autoscaling_plan_test" {
    name = "Autoscaling-Plan"
    
    application_source {
      tag_filter {
        key = "name"
        values = ["autoscaling-true"]
      }
    }

    scaling_instruction {
      max_capacity = 5
      min_capacity = 2

      resource_id = format("autoScalingGroup/%s",aws_autoscaling_group.scale_web_autoscaling_group_test.name)

      scalable_dimension = "autoscaling:autoScalingGroup:DesiredCapacity"
      service_namespace  = "autoscaling"

      target_tracking_configuration {
        predefined_scaling_metric_specification {
          predefined_scaling_metric_type = "ASGAverageCPUUtilization"
          }

          target_value = 70
       }
    }
}