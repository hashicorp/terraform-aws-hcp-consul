module "acl-controller" {
  source  = "hashicorp/consul-ecs/aws//modules/acl-controller"
  version = "~> 0.5.0"

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "consul-acl-controller"
    }
  }

  consul_server_http_addr           = var.consul_url
  consul_bootstrap_token_secret_arn = aws_secretsmanager_secret.bootstrap_token.arn
  ecs_cluster_arn                   = aws_ecs_cluster.clients.arn
  region                            = var.region
  subnets                           = var.private_subnet_ids

  name_prefix = local.secret_prefix
}

resource "aws_iam_role" "frontend-task-role" {
  name = "frontend_${local.scope}_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "frontend-execution-role" {
  name = "frontend_${local.scope}_execution_role"
  path = "/ecs/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

module "frontend" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family         = "frontend"
  task_role      = aws_iam_role.frontend-task-role
  create_task_role = false
  execution_role = aws_iam_role.frontend-execution-role
  create_execution_role = false
  container_definitions = [
    {
      name      = "frontend"
      image     = "hashicorpdemoapp/frontend:v1.0.2"
      essential = true
      portMappings = [
        {
          containerPort = local.frontend_port
          hostPort      = local.frontend_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NEXT_PUBLIC_PUBLIC_API_URL"
          value = "/"
        }
      ]

      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "frontend"
    }
  }

  port = local.frontend_port

  retry_join        = var.client_retry_join
  consul_datacenter = var.datacenter
  consul_http_addr  = var.consul_url
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend"
  cluster         = aws_ecs_cluster.clients.arn
  task_definition = module.frontend.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = local.frontend_port
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

resource "aws_iam_role" "public-api-task-role" {
  name = "public_api_${local.scope}_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "public-api-execution-role" {
  name = "public_api_${local.scope}_execution_role"
  path = "/ecs/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

module "public-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family         = "public-api"
  task_role      = aws_iam_role.public-api-task-role
  create_task_role = false
  execution_role = aws_iam_role.public-api-execution-role
  create_execution_role = false
  container_definitions = [
    {
      name      = "public-api"
      image     = "hashicorpdemoapp/public-api:v0.0.6"
      essential = true
      portMappings = [
        {
          containerPort = local.public_api_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "BIND_ADDRESS",
          value = ":${local.public_api_port}"
        },
        {
          name  = "PRODUCT_API_URI"
          value = "http://localhost:${local.product_api_port}"
        },
        {
          name  = "PAYMENT_API_URI"
          value = "http://localhost:${local.payment_api_port}"
        }
      ]

      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "public-api"
        }
      }
    }
  ]

  upstreams = [
    {
      destinationName = "product-api"
      localBindPort   = local.product_api_port
    },
    {
      destinationName = "payment-api"
      localBindPort   = local.payment_api_port
    }
  ]


  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "public-api"
    }
  }

  port = local.public_api_port

  retry_join        = var.client_retry_join
  consul_datacenter = var.datacenter
  consul_http_addr  = var.consul_url
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
}

resource "aws_ecs_service" "public-api" {
  name            = "public-api"
  cluster         = aws_ecs_cluster.clients.arn
  task_definition = module.public-api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.public-api.arn
    container_name   = "public-api"
    container_port   = local.public_api_port
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

resource "aws_iam_role" "payment-api-task-role" {
  name = "payment_api_${local.scope}_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "payment-api-execution-role" {
  name = "payment_api_${local.scope}_execution_role"
  path = "/ecs/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

module "payment-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family         = "payment-api"
  task_role      = aws_iam_role.payment-api-task-role
  create_task_role = false
  execution_role = aws_iam_role.payment-api-execution-role
  create_execution_role = false
  container_definitions = [
    {
      name      = "payment-api"
      image     = "hashicorpdemoapp/payments:v0.0.16"
      essential = true
      portMappings = [
        {
          containerPort = local.payment_api_port
          protocol      = "tcp"
        }
      ]

      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "payment-api"
        }
      }
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "payment-api"
    }
  }

  port = local.payment_api_port

  retry_join        = var.client_retry_join
  consul_datacenter = var.datacenter
  consul_http_addr  = var.consul_url
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
}

resource "aws_ecs_service" "payment-api" {
  name            = "payment-api"
  cluster         = aws_ecs_cluster.clients.arn
  task_definition = module.payment-api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

resource "aws_iam_role" "product-api-task-role" {
  name = "product_api_${local.scope}_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "product-api-execution-role" {
  name = "product_api_${local.scope}_execution_role"
  path = "/ecs/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

module "product-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family         = "product-api"
  task_role      = aws_iam_role.product-api-task-role
  create_task_role = false
  execution_role = aws_iam_role.product-api-execution-role
  create_execution_role = false
  container_definitions = [
    {
      name      = "product-api"
      image     = "hashicorpdemoapp/product-api:v0.0.20"
      essential = true
      portMappings = [
        {
          containerPort = local.product_api_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_CONNECTION"
          value = "host=localhost port=${local.product_db_port} user=postgres password=password dbname=products sslmode=disable"
        },
        {
          name  = "BIND_ADDRESS"
          value = "localhost:${local.product_api_port}"
        },
      ]
      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "product-api"
        }
      }
    }
  ]

  upstreams = [
    {
      destinationName = "product-db"
      localBindPort   = local.product_db_port
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "product-api"
    }
  }

  port = local.product_api_port

  retry_join        = var.client_retry_join
  consul_datacenter = var.datacenter
  consul_http_addr  = var.consul_url
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
}

resource "aws_ecs_service" "product-api" {
  name            = "product-api"
  cluster         = aws_ecs_cluster.clients.arn
  task_definition = module.product-api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

resource "aws_iam_role" "product-db-task-role" {
  name = "product_db_${local.scope}_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "product-db-execution-role" {
  name = "product_db_${local.scope}_execution_role"
  path = "/ecs/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

module "product-db" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family         = "product-db"
  task_role      = aws_iam_role.product-db-task-role
  create_task_role = false
  execution_role = aws_iam_role.product-db-execution-role
  create_execution_role = false
  container_definitions = [
    {
      name      = "product-db"
      image     = "hashicorpdemoapp/product-api-db:v0.0.20"
      essential = true
      portMappings = [
        {
          containerPort = local.product_db_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "POSTGRES_DB"
          value = "products"
        },
        {
          name  = "POSTGRES_USER"
          value = "postgres"
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = "password"
        },
      ]
      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "product-db"
        }
      }
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "product-db"
    }
  }

  port = local.product_db_port

  retry_join        = var.client_retry_join
  consul_datacenter = var.datacenter
  consul_http_addr  = var.consul_url
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
}

resource "aws_ecs_service" "product-db" {
  name            = "product-db"
  cluster         = aws_ecs_cluster.clients.arn
  task_definition = module.product-db.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}
