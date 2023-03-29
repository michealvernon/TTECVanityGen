variable "admin_first_name" {
  type = string
  default = "Micheal"
}





variable "admin_password" {
  type = string
  default = "Micheal1234$"
}






provider "aws" {
  region = "us-east-1"
}



resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
}

resource "aws_iam_role" "react_app_role" {
  name = "react_app_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "react_app_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
  role       = aws_iam_role.react_app_role.name
}

resource "aws_cloudfront_origin_access_identity" "my_oai" {
  comment = "My OAI"
}


resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.react_app_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.my_oai.id}"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.react_app_bucket.arn}/*"
      }
    ]
  })
}









resource "aws_s3_bucket" "react_app_bucket" {
  bucket = "vanitygenttec${random_integer.three_digits.result}"
  acl    = "public-read"

}

resource "aws_s3_bucket_website_configuration" "react_app_bucket" {
  bucket = "vanitygenttec${random_integer.three_digits.result}"

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}



resource "aws_s3_bucket_object" "react_app_files" {
  for_each = fileset("${path.module}/frontend", "**/*")

  bucket = aws_s3_bucket.react_app_bucket.id
  key    = each.value
  source = "${path.module}/frontend/${each.value}"

}

resource "aws_cloudfront_distribution" "react_app_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.react_app_bucket.bucket_regional_domain_name}"
    origin_id   = "${aws_cloudfront_origin_access_identity.my_oai.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "React app distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]
    target_origin_id = "${aws_cloudfront_origin_access_identity.my_oai.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_All"
}

output "bucket_name" {
  value = "${aws_s3_bucket_website_configuration.react_app_bucket.id}"
}

output "distribution_domain_name" {
  value = "${aws_cloudfront_distribution.react_app_distribution.domain_name}"
}



# Create a zip file for the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/handler"
  output_path = "${path.module}/handler.zip"
}

# Create the Lambda function
resource "aws_lambda_function" "my_lambda" {
  filename         = "${path.module}/handler.zip"
  function_name    = "VanityGenerator"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda.lambda_handler"
  runtime          = "python3.8"
  timeout          = 60
  memory_size      = 1000
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256


  
  
  depends_on = [
    aws_iam_role_policy_attachment.lambda,
  ]
}

data "template_file" "jsonfile" {
  template = "${file("connect-config.json")}"

  vars = {
    lambda_arn = aws_lambda_function.my_lambda.arn
  }
}

resource "aws_connect_lambda_function_association" "lambda" {
  function_arn = aws_lambda_function.my_lambda.arn
  instance_id  = aws_connect_instance.ttec.id
}


# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach a policy to the IAM role that grants access to AWS Connect and DynamoDB
resource "aws_iam_role_policy_attachment" "lambda" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonConnect_FullAccess"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.lambda.name
}









resource "aws_connect_instance" "ttec" {
  instance_alias           = "ttecvanitygenerator${random_integer.three_digits.result}"
  inbound_calls_enabled    = true
  outbound_calls_enabled   = true
  identity_management_type = "CONNECT_MANAGED"

}

resource "random_integer" "three_digits" {
  min = 100
  max = 999
}
# Create an AWS Connect Hours of Operations
resource "aws_connect_hours_of_operation" "ttec" {
  name                = "data123"
  instance_id         = aws_connect_instance.ttec.id
  description         = "Example Hours of Operation"
  time_zone           = "EST"
  tags                = {
    Environment = "Production"
  }
 


   config {
    day = "MONDAY"

    end_time {
      hours   = 23
      minutes = 8
    }

    start_time {
      hours   = 8
      minutes = 0
    }
  }

  config {
    day = "TUESDAY"

    end_time {
      hours   = 23
      minutes = 0
    }

    start_time {
      hours   = 8
      minutes = 0
    }
  }


  config {
    day = "WEDNESDAY"

    end_time {
      hours   = 23
      minutes = 0
    }

    start_time {
      hours   = 8
      minutes = 0
    }
  }

  config {
    day = "THURSDAY"

    end_time {
      hours   = 23
      minutes = 0
    }

    start_time {
      hours   = 8
      minutes = 0
    }
  }

  config {
    day = "FRIDAY"

    end_time {
      hours   = 23
      minutes = 0
    }

    start_time {
      hours   = 8
      minutes = 0
    }
  }

  config {
    day = "SATURDAY"

    end_time {
      hours   = 23
      minutes = 0
    }

    start_time {
      hours   = 8
      minutes = 0
    }
  }

    config {
    day = "SUNDAY"

    end_time {
      hours   = 23
      minutes = 0
    }

    start_time {
      hours   = 8
      minutes = 0
    }
  }





  


  
  
}



resource "aws_connect_routing_profile" "ttec" {
  name              = "Example Routing Profile"
  description       = "Example Routing Profile Description"
  default_outbound_queue_id = aws_connect_queue.ttec.id
  instance_id       = aws_connect_instance.ttec.id
  tags              = {
    Name = "ttec-routing-profile"
  }
    media_concurrencies {
    concurrency = 5
      channel = "VOICE"

  }
}





resource "aws_connect_user" "ttec_admin" {
  instance_id = aws_connect_instance.ttec.id
  password    = var.admin_password
  routing_profile_id = aws_connect_routing_profile.ttec.id

  security_profile_ids = [aws_connect_security_profile.ttec.id]
    name = var.admin_first_name
phone_config{
  phone_type = "SOFT_PHONE"
}
  
}

resource "aws_connect_security_profile" "ttec" {
  name          = "Example Security Profile"
  instance_id   = aws_connect_instance.ttec.id
}




resource "aws_connect_contact_flow" "ttec" {
  name                 = "VanityGenerator"
  content              = data.template_file.jsonfile.rendered
  instance_id          = aws_connect_instance.ttec.id
  description          = "Vanity Contact Flow"
  type                 = "CONTACT_FLOW"

}


resource "aws_connect_queue" "ttec" {
  name             = "dataqueue"
  description      = "Example queue description "
  instance_id = aws_connect_instance.ttec.id
  hours_of_operation_id = aws_connect_hours_of_operation.ttec.id

}
