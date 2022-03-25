module "acl-controller" {
  source = "hashicorp/consul-ecs/aws//modules/acl-controller"

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

module "frontend" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.3.0"

  family = "frontend"
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
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
  consul_client_token_secret_arn = module.acl-controller.client_token_secret_arn
  acl_secret_name_prefix         = local.secret_prefix
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

module "public_api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.3.0"

  family = "public_api"
  container_definitions = [
    {
      name      = "public_api"
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
          awslogs-stream-prefix = "public_api"
        }
      }
    }
  ]

  upstreams = [
    {
      destinationName = "product_api"
      localBindPort   = local.product_api_port
    },
    {
      destinationName = "payment_api"
      localBindPort   = local.payment_api_port
    }
  ]


  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "public_api"
    }
  }

  port = local.public_api_port

  retry_join        = var.client_retry_join
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
  consul_client_token_secret_arn = module.acl-controller.client_token_secret_arn
  acl_secret_name_prefix         = local.secret_prefix
}

resource "aws_ecs_service" "public_api" {
  name            = "public_api"
  cluster         = aws_ecs_cluster.clients.arn
  task_definition = module.public_api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.public_api.arn
    container_name   = "public_api"
    container_port   = local.public_api_port
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

module "payment_api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.3.0"

  family = "payment_api"
  container_definitions = [
    {
      name      = "payment_api"
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
          awslogs-stream-prefix = "payment_api"
        }
      }
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "payment_api"
    }
  }

  port = local.payment_api_port

  retry_join        = var.client_retry_join
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
  consul_client_token_secret_arn = module.acl-controller.client_token_secret_arn
  acl_secret_name_prefix         = local.secret_prefix
}

resource "aws_ecs_service" "payment_api" {
  name            = "payment_api"
  cluster         = aws_ecs_cluster.clients.arn
  task_definition = module.payment_api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

module "product_api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.3.0"

  family = "product_api"
  container_definitions = [
    {
      name      = "product_api"
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
          awslogs-stream-prefix = "product_api"
        }
      }
    }
  ]

  upstreams = [
    {
      destinationName = "product_db"
      localBindPort   = local.product_db_port
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "product_api"
    }
  }

  port = local.product_api_port

  retry_join        = var.client_retry_join
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
  consul_client_token_secret_arn = module.acl-controller.client_token_secret_arn
  acl_secret_name_prefix         = local.secret_prefix
}

resource "aws_ecs_service" "product_api" {
  name            = "product_api"
  cluster         = aws_ecs_cluster.clients.arn
  task_definition = module.product_api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

module "product_db" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.3.0"

  family = "product_db"
  container_definitions = [
    {
      name      = "product_db"
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
          awslogs-stream-prefix = "product_db"
        }
      }
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "product_db"
    }
  }

  port = local.product_db_port

  retry_join        = var.client_retry_join
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                           = true
  consul_client_token_secret_arn = module.acl-controller.client_token_secret_arn
  acl_secret_name_prefix         = local.secret_prefix
}

resource "aws_ecs_service" "product_db" {
  name            = "product_db"
  cluster         = aws_ecs_cluster.clients.arn
  task_definition = module.product_db.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.security_group_id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}
