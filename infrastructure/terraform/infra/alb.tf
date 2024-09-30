resource "aws_lb" "this" {
  for_each = {
    for alb in local.albs :
    alb.name => alb
  }

  name               = each.value.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [local.alb_security_group_id]
  subnets            = local.public_subnets
}

# Target Group
resource "aws_lb_target_group" "this" {
  for_each = {
    for target_group in local.alb_target_groups :
    target_group.key => target_group
  }

  name     = each.value.name
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = module.network.vpc.id

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []

    content {
      path                = health_check.value.path
      interval            = health_check.value.interval
      timeout             = health_check.value.timeout
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }
}

# Listener for ALB
resource "aws_lb_listener" "this" {
  for_each = {
    for alb_listener in local.alb_listeners :
    alb_listener.key => alb_listener
  }

  load_balancer_arn = each.value.load_balancer_arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = {
    for alb_listener_rule in local.alb_listener_rules :
    alb_listener_rule.key => alb_listener_rule
  }

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }

  condition {

    path_pattern {
      values = [each.value.path_pattern]
    }
  }
}

resource "aws_lb_target_group_attachment" "alb_to_machine_attachment" {
  for_each = {
    for attachment in local.alb_target_groups_attachments :
    attachment.key => attachment
  }

  target_group_arn = aws_lb_target_group.this[each.value.target_group].arn
  target_id        = try(module.worker_servers[each.value.machine_ref].instance_id, 
                          module.master_servers[each.value.machine_ref].instance_id
                        )
}
