## EC2 생성하기

### provider.tf

사용할 클라우드 provider와 버전, 리전을 선언한다.

URL 참고
https://registry.terraform.io/providers/hashicorp/aws/latest/docs

- required_providers — provider 출처(`hashicorp/aws`)와 버전 제약(`~> 6.0`)
- region — 리소스를 생성할 리전 ("ap-northeast-2")

### ec2.tf

URL 참고
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

`data "aws_ami"` — 운영체제별 최신 AMI를 동적으로 조회
- ubuntu_22 — Ubuntu 22.04 (Canonical, owners = "099720109477")
- ubuntu_24 — Ubuntu 24.04 (Canonical)
- rocky_9 — Rocky Linux 9.7 (owners = "792107900819")
- amazon_linux_2023 — Amazon Linux 2023 (owners = "amazon")

각 데이터 소스는 `most_recent`, AMI 이름 패턴(`name` 필터), `virtualization-type`(hvm) 조건으로 최신 AMI ID를 가져온다.

`resource "aws_instance" "my_ec2"`
- ami — `data.aws_ami.ubuntu_24.id` 사용
- instance_type — var.instance_type
- key_name — aws_key_pair.this.key_name (security.tf에서 생성한 키 페어)
- vpc_security_group_ids — aws_security_group.this.id (security.tf에서 생성한 보안 그룹)
- root_block_device — 루트 볼륨 크기/타입 (var.root_volume_size, var.root_volume_type)
- tags — Name = var.instance_name

### security.tf

SSH 접속 및 인바운드 트래픽을 위한 키 페어와 보안 그룹을 정의한다.

URL 참고
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

`resource "aws_key_pair" "this"`
- key_name — var.key_pair_name
- public_key — `file(var.public_key_path)`로 로컬 공개키 파일을 읽어 등록

`resource "aws_security_group" "this"`
- name / tags — `${var.instance_name}-sg`
- ingress (SSH) — var.ssh_allowed_cidr 대역에서 22번 포트 허용
- dynamic "ingress" — var.ingress_rules 목록을 순회하며 추가 인바운드 규칙(HTTP, HTTPS 등) 생성
- egress — 모든 아웃바운드 트래픽 허용 (0.0.0.0/0)

### variables.tf

하드코딩된 값을 변수로 분리시켜 재사용성과 유연성을 높인다.

URL 참고
https://developer.hashicorp.com/terraform/language/values/variables

기본값이 있는 변수
- instance_type — "t3.micro"
- instance_name — "test-ec2"
- root_volume_size — 20 (GB)
- root_volume_type — "gp3"
- ingress_rules — HTTP(80), HTTPS(443) 인바운드 규칙 목록 (object 리스트)

값을 반드시 입력해야 하는 변수 (default 없음, tfvars로 지정)
- key_pair_name — AWS에 등록할 키 페어 이름
- public_key_path — 로컬 SSH 공개키(.pub) 파일 경로
- ssh_allowed_cidr — SSH(22번 포트) 접속을 허용할 CIDR 대역 목록 (list(string))

변수 블록에서 쓸 수 있는 옵션
- type — 타입 지정 (string, number, bool, list, object, map ...)
- default — 기본값
- description — 설명
- validation — 유효성 검사
- sensitive — 비밀번호 같은 민감한 값 숨김

### outputs.tf

리소스의 속성 값을 외부로 노출시켜 확인하거나 재사용할 수 있게 한다.

URL 참고
https://developer.hashicorp.com/terraform/language/values/outputs

- instance_id — 생성된 EC2 인스턴스 ID
- public_ip — 인스턴스에 접속할 때 쓰는 퍼블릭 IP
- private_ip — VPC 내부 통신용 사설 IP
- ami_id — 실제로 선택된 AMI의 ID

### tfvars

`templates/control-plane.tfvars` 파일에 환경별 변수 값(키 페어 이름, 공개키 경로, 허용 CIDR 등)을 정의하고, 아래처럼 `-var-file` 옵션으로 지정해 plan/apply/destroy를 실행한다.

```shell
terraform plan -var-file=control-plane.tfvars
terraform apply -var-file=control-plane.tfvars
terraform destroy -var-file=control-plane.tfvars
```

## Terraform CLI

### terraform 정렬
```shell
terraform fmt
```

### terraform 문법 확인
```shell
terraform validate
```

### terraform 인스턴스 확인
```shell
terraform plan
```

### terraform 인스턴스 생성
```shell
terraform apply
```

### terraform 인스턴스 종료
```shell
terraform destroy
```

---
