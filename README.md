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
├── control-plane.tfvars   # control-plane 변수 값 파일
├── worker-node.tfvars     # worker-node 변수 값 파일
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

모듈 변수에 default가 있으면 루트에도 동일한 default를 선언하고, default가 없으면 tfvars에 명시한다.

**EC2 (worker-node) 변수**

| 변수 | 기본값 | 설명 |
|---|---|---|
| `worker_nodes` | 없음 | worker-node 목록 (map) |
| `worker_key_pair_name` | 없음 | 모든 worker-node가 공유할 키 페어 이름 |
| `public_key_path` | 없음 | 로컬 SSH 공개키(.pub) 경로 |
| `ssh_allowed_cidr` | 없음 | SSH 허용 CIDR 목록 |
| `ingress_rules` | `[]` | 추가 인바운드 규칙 목록 (SSH 제외) |

**Lightsail (control-plane) 변수**

| 변수 | 기본값 | 설명 |
|---|---|---|
| `control_plane_key_pair_name` | 없음 | Lightsail 키 페어 이름 |
| `control_plane_instance_name` | 없음 | 인스턴스 이름 |
| `control_plane_availability_zone` | 없음 | 가용 영역 |
| `control_plane_blueprint_id` | `ubuntu_22_04` | OS 이미지 ID |
| `control_plane_bundle_id` | `small_3_0` | 사양 번들 (2GB RAM, 1vCPU) |
| `control_plane_ip_address_type` | `dualstack` | IP 주소 유형 |
| `control_plane_port_rules` | `[]` | 개방할 포트 규칙 목록 |

### ha-cluster.tf

모듈을 호출하는 진입점. 어떤 모듈을 어떤 값으로 실행할지 선언한다.

- `module "control_plane"` — `modules/lightsail` 모듈 호출
- `aws_key_pair "worker_node"` — 모든 worker-node가 공유할 키 페어를 루트에서 한 번만 생성
- `module "worker_node"` — `modules/ec2` 모듈을 `for_each`로 반복 호출 (`worker_nodes` map 크기만큼)

`aws_key_pair`를 모듈 밖에 선언하는 이유는 `for_each`로 인해 모듈이 여러 번 실행되더라도 키 페어는 한 번만 생성하기 위해서다.

### outputs.tf

모듈이 반환한 값을 최종 출력한다.

- `worker_node_instance_ids` — worker-node별 EC2 인스턴스 ID
- `worker_node_public_ips` — worker-node별 Public IP
- `worker_node_private_ips` — worker-node별 Private IP
- `control_plane_public_ip` — control-plane Public IP
- `control_plane_private_ip` — control-plane Private IP

### control-plane.tfvars

control-plane(Lightsail) 관련 변수 값을 정의한다.

- 키 페어 이름, 인스턴스 이름, 가용 영역
- 포트 규칙 (SSH는 특정 IP만 허용, HTTP/HTTPS는 전체 오픈)

### worker-node.tfvars

worker-node(EC2) 관련 변수 값을 정의한다.

- SSH 공개키 경로, 키 페어 이름, SSH 허용 CIDR
- 추가 인바운드 규칙 (HTTP, HTTPS, 8080)
- worker-node 목록 (인스턴스 타입, 이름, 볼륨 사양)

### modules/ec2/

**worker-node** EC2 인스턴스를 생성하는 모듈.

- `main.tf` — AMI data source 4종(Ubuntu 22/24, Rocky 9, Amazon Linux 2023), `aws_security_group`, `aws_instance` 리소스 정의
- `variables.tf` — 모듈 내부 변수 선언 (루트에서 넘긴 값을 받는 창구)
- `outputs.tf` — `instance_id`, `public_ip`, `private_ip`, `ami_id` 반환

`aws_security_group`은 SSH 고정 인바운드(`ssh_allowed_cidr`) + `dynamic "ingress"`로 추가 규칙을 순회한다.

### modules/lightsail/

**control-plane** Lightsail 인스턴스를 생성하는 모듈.

- `main.tf` — `aws_lightsail_key_pair`, `aws_lightsail_instance`, `aws_lightsail_instance_public_ports` 리소스 정의
- `variables.tf` — 모듈 내부 변수 선언
- `outputs.tf` — `instance_id`, `public_ip`, `private_ip` 반환

EC2의 `aws_security_group` 대신 `aws_lightsail_instance_public_ports`로 포트를 관리한다. `dynamic "port_info"`로 규칙 목록을 순회한다.

---

## 네트워크 구조

Lightsail과 EC2는 기본적으로 서로 다른 네트워크에 위치한다. 현재는 public IP를 통해 통신하며, 추후 VPC 피어링 또는 EC2 통합을 통해 private IP 통신으로 전환할 예정이다.

```
내 PC ──(public IP)──▶ control-plane (Lightsail)
                              │
                        (public IP)
                              │
                 ┌────────────┴────────────┐
             worker-1 (EC2)          worker-2 (EC2)
```

---

## 실행 흐름

`terraform apply -var-file=control-plane.tfvars -var-file=worker-node.tfvars` 실행 시 아래 순서로 파일을 읽는다.

```
1. provider.tf
   └─ AWS provider 설정, 리전 확인

2. variables.tf
   └─ 변수 목록 확인 (어떤 변수가 있는지 등록)

3. control-plane.tfvars + worker-node.tfvars
   └─ variables.tf의 변수에 실제 값 주입

4. ha-cluster.tf
   └─ module "control_plane" 발견 → modules/lightsail/ 로 이동
   └─ module "worker_node"   발견 → modules/ec2/       로 이동 (for_each)

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
terraform plan \
  -var-file="control-plane.tfvars" \
  -var-file="worker-node.tfvars"
```

### 인프라 생성
```shell
terraform apply \
  -var-file="control-plane.tfvars" \
  -var-file="worker-node.tfvars"
```

### 인프라 삭제
```shell
terraform destroy \
  -var-file="control-plane.tfvars" \
  -var-file="worker-node.tfvars"
```

### 모듈 초기화 (모듈 추가/변경 후 필수)
```shell
terraform init
```

---

## 버전 이력

| 버전 | 구성 | 네트워크 | 목적 |
|---|---|---|---|
| v1 | LightSail(control-plane) + EC2(worker-node) | Public IP 통신 | 기본 클러스터 프로비저닝 실습 |
| v2 | EC2(control-plane) + EC2(worker-node) | VPC 기반 private 통신 | VPC 구성 및 control-plane EC2 전환 |

---

## v1: LightSail + EC2 조합

LightSail과 EC2를 조합해 control-plane과 worker-node를 구성했다. LightSail은 EC2와 별개의 네트워크에 존재하기 때문에 노드 간 통신은 public IP를 통해 이루어진다.

---

## v2: EC2 전용 구성 + VPC (예정)

LightSail은 AWS VPC에 속하지 않아 worker-node(EC2)와 private IP로 통신할 수 없다. v2에서는 control-plane을 EC2로 전환하고, VPC와 서브넷을 직접 생성해 모든 노드를 동일 네트워크 안에 배치한다.
