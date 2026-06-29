# -----------------------------------------------
# 내부(internal) Network Load Balancer — apiserver(6443) 단일 엔드포인트
# -----------------------------------------------
# control-plane HA 구성에서 worker join·노드 내부 통신·로컬 kubectl이 "어느 CP로
# 갈지" 고정된 단일 엔드포인트가 필요하다. keepalived VIP는 AWS에서 VRRP/임의 IP
# 문제로 까다로우므로 AWS 관리형 내부 NLB로 처리한다. apiserver는 인터넷에 노출하지
# 않고(scheme=internal) VPC 안에서만 접근한다.
resource "aws_lb" "this" {
  name               = "${var.name}-apiserver-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  # 단일 AZ에 타겟이 몰려도 모든 NLB 노드가 모든 타겟으로 분산하도록 켠다.
  # 멀티-AZ 확장 시 AZ 간 균등 분산을 보장한다.
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.name}-apiserver-nlb"
  }
}

resource "aws_lb_target_group" "apiserver" {
  name        = "${var.name}-apiserver-tg"
  port        = var.apiserver_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  # NLB는 헤어핀(loopback)을 지원하지 않는다. client IP 보존이 켜져 있으면(TCP 기본값)
  # 타겟으로 등록된 CP 인스턴스가 자신이 등록된 NLB로 접속할 때 자기 자신으로
  # 라우팅되면 실패한다(예: master-1의 `kubeadm token create`, CP kubelet→apiserver).
  # 보존을 끄면 소스 IP가 NLB 노드로 치환되어 self-routing이 정상 동작한다.
  preserve_client_ip = false

  # apiserver는 TLS 종료를 직접 하므로 L4(TCP)로 그대로 통과시킨다.
  # health check도 6443 TCP 연결 가능 여부로 판단한다.
  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
  }

  tags = {
    Name = "${var.name}-apiserver-tg"
  }
}

resource "aws_lb_listener" "apiserver" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.apiserver_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apiserver.arn
  }
}

# control-plane 인스턴스들을 Target Group에 등록한다. HA 확장 시 instance_ids
# 맵에 항목이 늘면 자동으로 타겟이 추가된다.
resource "aws_lb_target_group_attachment" "cp" {
  for_each = var.instance_ids

  target_group_arn = aws_lb_target_group.apiserver.arn
  target_id        = each.value
  port             = var.apiserver_port
}
