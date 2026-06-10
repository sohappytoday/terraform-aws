 ## Kubernetes HA 클러스터 인프라 구성

Lightsail(control-plane) + EC2(worker-node) 조합으로 Kubernetes 클러스터를 프로비저닝한다.

---

## 디렉토리 구조

```
templates/
├── provider.tf            # AWS provider 설정
├── variables.tf           # 루트 변수 선언 (EC2 + Lightsail)
├── outputs.tf             # 최종 출력값
├── ha-cluster.tf          # 모듈 호출 진입점
├── worker-node.tfvars     # 환경별 변수 값 파일
└── modules/
    ├── ec2/               # worker-node 모듈
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── lightsail/         # control-plane 모듈
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 파일별 설명

### provider.tf

사용할 클라우드 provider와 버전, 리전을 선언한다.

- `required_providers` — provider 출처(`hashicorp/aws`)와 버전 제약(`~> 6.0`)
- `region` — 리소스를 생성할 리전 (`ap-northeast-2`)

### variables.tf

하드코딩된 값을 변수로 분리해 재사용성과 유연성을 높인다. `tfvars`로 값을 주입받는 창구 역할을 한다.

**EC2 (worker-node) 변수**

| 변수 | 기본값 | 설명 |
|---|---|---|
| `instance_type` | `t3.micro` | EC2 인스턴스 타입 |
| `instance_name` | `test-ec2` | 인스턴스 이름 태그 |
| `root_volume_size` | `20` | 루트 볼륨 크기 (GB) |
| `root_volume_type` | `gp3` | 루트 볼륨 타입 |
| `key_pair_name` | 없음 | AWS에 등록할 키 페어 이름 |
| `public_key_path` | 없음 | 로컬 SSH 공개키(.pub) 경로 |
| `ssh_allowed_cidr` | 없음 | SSH 허용 CIDR 목록 |
| `ingress_rules` | HTTP/HTTPS | 추가 인바운드 규칙 목록 |

**Lightsail (control-plane) 변수**

| 변수 | 기본값 | 설명 |
|---|---|---|
| `lightsail_instance_name` | `control-plane` | 인스턴스 이름 |
| `lightsail_availability_zone` | `ap-northeast-2a` | 가용 영역 |
| `lightsail_blueprint_id` | `ubuntu_22_04` | OS 이미지 ID |
| `lightsail_bundle_id` | `small_3_0` | 사양 번들 (2GB RAM, 1vCPU) |
| `lightsail_ip_address_type` | `dualstack` | IP 주소 유형 |
| `lightsail_port_rules` | `[]` | 개방할 포트 규칙 목록 |

### ha-cluster.tf

모듈을 호출하는 진입점. 어떤 모듈을 어떤 값으로 실행할지 선언한다.

- `module "control_plane"` — `modules/lightsail` 모듈 호출
- `module "worker_node"` — `modules/ec2` 모듈 호출

### outputs.tf

모듈이 반환한 값을 최종 출력한다.

- `instance_id` — EC2 인스턴스 ID
- `public_ip` — 퍼블릭 IP
- `private_ip` — 프라이빗 IP
- `ami_id` — 실제 선택된 AMI ID

### worker-node.tfvars

환경별 변수 값을 정의하는 파일. `variables.tf`의 변수에 실제 값을 주입한다.

```shell
terraform apply -var-file=worker-node.tfvars
```

### modules/ec2/

**worker-node** EC2 인스턴스를 생성하는 모듈.

- `main.tf` — AMI data source 4종(Ubuntu 22/24, Rocky 9, Amazon Linux 2023), `aws_key_pair`, `aws_security_group`, `aws_instance` 리소스 정의
- `variables.tf` — 모듈 내부 변수 선언 (루트에서 넘긴 값을 받는 창구)
- `outputs.tf` — `instance_id`, `public_ip`, `private_ip`, `ami_id` 반환

`aws_security_group`은 SSH 고정 인바운드 + `dynamic "ingress"`로 추가 규칙을 순회한다.

### modules/lightsail/

**control-plane** Lightsail 인스턴스를 생성하는 모듈.

- `main.tf` — `aws_lightsail_key_pair`, `aws_lightsail_instance`, `aws_lightsail_instance_public_ports` 리소스 정의
- `variables.tf` — 모듈 내부 변수 선언
- `outputs.tf` — `instance_id`, `public_ip`, `private_ip` 반환

EC2의 `aws_security_group` 대신 `aws_lightsail_instance_public_ports`로 포트를 관리한다. `dynamic "port_info"`로 규칙 목록을 순회한다.

---

## 실행 흐름

`terraform apply -var-file=worker-node.tfvars` 실행 시 아래 순서로 파일을 읽는다.

```
1. provider.tf
   └─ AWS provider 설정, 리전 확인

2. variables.tf
   └─ 변수 목록 확인 (어떤 변수가 있는지 등록)

3. worker-node.tfvars
   └─ variables.tf의 변수에 실제 값 주입

4. ha-cluster.tf
   └─ module "control_plane" 발견 → modules/lightsail/ 로 이동
   └─ module "worker_node"   발견 → modules/ec2/       로 이동

5. modules/lightsail/variables.tf
   └─ ha-cluster.tf에서 넘긴 값 받음

6. modules/lightsail/main.tf
   └─ aws_lightsail_instance 등 리소스 정의 읽음

7. modules/lightsail/outputs.tf
   └─ 모듈이 반환할 값 정의

8. modules/ec2/variables.tf
   └─ ha-cluster.tf에서 넘긴 값 받음

9. modules/ec2/main.tf
   └─ aws_instance 등 리소스 정의 읽음

10. modules/ec2/outputs.tf
    └─ 모듈이 반환할 값 정의

11. outputs.tf
    └─ module.control_plane.xxx, module.worker_node.xxx 참조해 최종 출력
```

---

## Terraform CLI

### 포맷 정렬
```shell
terraform fmt
```

### 문법 확인
```shell
terraform validate
```

### 실행 계획 확인
```shell
terraform plan -var-file=worker-node.tfvars
```

### 인프라 생성
```shell
terraform apply -var-file=worker-node.tfvars
```

### 인프라 삭제
```shell
terraform destroy -var-file=worker-node.tfvars
```

### 모듈 초기화 (모듈 추가/변경 후 필수)
```shell
terraform init
```
