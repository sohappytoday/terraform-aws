# -----------------------------------------------
# SSM IAM
# control-plane을 Private Subnet에 두고 SSH 없이 SSM Session Manager로
# 접근하려면, 인스턴스에 SSM 권한(IAM Role)이 instance profile로 연결돼야 한다.
# -----------------------------------------------

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ssm" {
  name               = "${var.cluster_name}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# AWS 관리형 정책: SSM Agent가 Session Manager로 동작하는 데 필요한 최소 권한
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.cluster_name}-ssm-profile"
  role = aws_iam_role.ssm.name
}
