## Kubernetes HA 클러스터 인프라 구성

EC2(control-plane) + EC2(worker-node) 조합으로 Kubernetes 클러스터를 프로비저닝한다.

### 버전 인덱스

- [v1: LightSail + EC2 조합 — 클러스터 구축을 위한 인스턴스 생성](#v1-lightsail--ec2-조합)
- [v2: EC2 전용 구성 + VPC](#v2-ec2-전용-구성--vpc)
- [v3: Reverse Proxy 기반 보안 강화 (예정)](#v3-reverse-proxy-기반-보안-강화-예정)

---

## 버전 이력

| 버전 | 구성 | 네트워크 | 목적 |
|---|---|---|---|
| v1 | LightSail(control-plane) + EC2(worker-node) | Public IP 통신 | 기본 클러스터 프로비저닝 실습 |
| v2 | EC2(control-plane) + EC2(worker-node) | VPC 기반 private 통신 | VPC 구성 및 control-plane EC2 전환 |
| v3 | EC2(reverse-proxy, public) + EC2(control-plane + worker-node, private) | Public/Private Subnet 분리, SSM 내부망 접근 | Reverse Proxy 도입 및 control-plane 폐쇄망 구성 |

---

## v1: LightSail + EC2 조합

LightSail과 EC2를 조합해 control-plane과 worker-node를 구성했다. LightSail은 EC2와 별개의 네트워크에 존재하기 때문에 노드 간 통신은 public IP를 통해 이루어진다.

### 디렉토리 구조

```
templates/
├── provider.tf            # AWS provider 설정
├── variables.tf           # 루트 변수 선언 (EC2 + Lightsail)
├── outputs.tf             # 최종 출력값
├── main.tf                # 모듈 호출 진입점
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

### 파일별 설명

#### provider.tf

사용할 클라우드 provider와 버전, 리전을 선언한다.

- `required_providers` — provider 출처(`hashicorp/aws`)와 버전 제약(`~> 6.0`)
- `region` — 리소스를 생성할 리전 (`ap-northeast-2`)

#### variables.tf

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

**EC2 (control-plane) 변수**

| 변수 | 기본값 | 설명 |
|---|---|---|
| `control_plane_instance_name` | 없음 | 인스턴스 이름 |
| `control_plane_instance_type` | `t3.medium` | EC2 인스턴스 타입 |
| `control_plane_root_volume_size` | `30` | 루트 볼륨 크기 (GB) |
| `control_plane_root_volume_type` | `gp3` | 루트 볼륨 타입 |
| `control_plane_ssh_allowed_cidr` | 없음 | SSH 허용 CIDR 목록 |
| `control_plane_ingress_rules` | `[]` | 추가 인바운드 규칙 목록 (SSH 제외) |

#### main.tf

모듈을 호출하는 진입점. 어떤 모듈을 어떤 값으로 실행할지 선언한다.

- `module "control_plane"` — `modules/ec2` 모듈 호출 (control-plane 단일 인스턴스)
- `aws_key_pair "worker_node"` — control-plane과 worker-node가 공유할 키 페어를 루트에서 한 번만 생성
- `module "worker_node"` — `modules/ec2` 모듈을 `for_each`로 반복 호출 (`worker_nodes` map 크기만큼)

`aws_key_pair`를 모듈 밖에 선언하는 이유는 `for_each`로 인해 모듈이 여러 번 실행되더라도 키 페어는 한 번만 생성하기 위해서다.

#### outputs.tf

모듈이 반환한 값을 최종 출력한다.

- `worker_node_instance_ids` — worker-node별 EC2 인스턴스 ID
- `worker_node_public_ips` — worker-node별 Public IP
- `worker_node_private_ips` — worker-node별 Private IP
- `control_plane_public_ip` — control-plane Public IP
- `control_plane_private_ip` — control-plane Private IP

#### control-plane.tfvars

control-plane(EC2) 관련 변수 값을 정의한다.

- 인스턴스 이름, 타입, 볼륨 사양
- SSH 허용 CIDR, 추가 인바운드 규칙 (HTTP/HTTPS)

#### worker-node.tfvars

worker-node(EC2) 관련 변수 값을 정의한다.

- SSH 공개키 경로, 키 페어 이름, SSH 허용 CIDR
- 추가 인바운드 규칙 (HTTP, HTTPS, 8080)
- worker-node 목록 (인스턴스 타입, 이름, 볼륨 사양)

#### modules/ec2/

**control-plane 및 worker-node** EC2 인스턴스를 생성하는 공용 모듈.

- `main.tf` — AMI data source 4종(Ubuntu 22/24, Rocky 9, Amazon Linux 2023), `aws_security_group`, `aws_instance` 리소스 정의
- `variables.tf` — 모듈 내부 변수 선언 (루트에서 넘긴 값을 받는 창구)
- `outputs.tf` — `instance_id`, `public_ip`, `private_ip`, `ami_id` 반환

`aws_security_group`은 SSH 고정 인바운드(`ssh_allowed_cidr`) + `dynamic "ingress"`로 추가 규칙을 순회한다.

#### modules/lightsail/

v1에서 **control-plane**으로 사용한 Lightsail 모듈. v2부터는 사용하지 않는다.

- `main.tf` — `aws_lightsail_key_pair`, `aws_lightsail_instance`, `aws_lightsail_instance_public_ports` 리소스 정의
- `variables.tf` — 모듈 내부 변수 선언
- `outputs.tf` — `instance_id`, `public_ip`, `private_ip` 반환

### 네트워크 구조

Lightsail과 EC2는 기본적으로 서로 다른 네트워크에 위치한다. 현재는 public IP를 통해 통신하며, 추후 VPC 피어링 또는 EC2 통합을 통해 private IP 통신으로 전환할 예정이다.

```
내 PC ──(public IP)──▶ control-plane (Lightsail)
                              │
                        (public IP)
                              │
                 ┌────────────┴────────────┐
             worker-1 (EC2)          worker-2 (EC2)
```

### 실행 흐름

`terraform apply -var-file=control-plane.tfvars -var-file=worker-node.tfvars` 실행 시 아래 순서로 파일을 읽는다.

```
1. provider.tf
   └─ AWS provider 설정, 리전 확인

2. variables.tf
   └─ 변수 목록 확인 (어떤 변수가 있는지 등록)

3. control-plane.tfvars + worker-node.tfvars
   └─ variables.tf의 변수에 실제 값 주입

4. main.tf
   └─ module "control_plane" 발견 → modules/ec2/ 로 이동
   └─ module "worker_node"   발견 → modules/ec2/ 로 이동 (for_each)

5. modules/ec2/variables.tf (control_plane)
   └─ main.tf에서 넘긴 값 받음

6. modules/ec2/main.tf (control_plane)
   └─ aws_instance 등 리소스 정의 읽음

7. modules/ec2/outputs.tf (control_plane)
   └─ 모듈이 반환할 값 정의

8. modules/ec2/variables.tf (worker_node)
   └─ main.tf에서 넘긴 값 받음

9. modules/ec2/main.tf (worker_node)
   └─ aws_instance 등 리소스 정의 읽음

10. modules/ec2/outputs.tf (worker_node)
    └─ 모듈이 반환할 값 정의

11. outputs.tf
    └─ module.control_plane.xxx, module.worker_node.xxx 참조해 최종 출력
```

### Terraform CLI

#### 포맷 정렬
```shell
terraform fmt
```

#### 문법 확인
```shell
terraform validate
```

#### 실행 계획 확인
```shell
terraform plan \
  -var-file="control-plane.tfvars" \
  -var-file="worker-node.tfvars"
```

#### 인프라 생성
```shell
terraform apply \
  -var-file="control-plane.tfvars" \
  -var-file="worker-node.tfvars"
```

#### 인프라 삭제
```shell
terraform destroy \
  -var-file="control-plane.tfvars" \
  -var-file="worker-node.tfvars"
```

#### 모듈 초기화 (모듈 추가/변경 후 필수)
```shell
terraform init
```

---

## v2: EC2 전용 구성 + VPC

Kubernetes의 kubelet, kube-proxy, API server 등 핵심 컴포넌트는 private IP를 기준으로 서로를 식별하고 통신한다. v1에서 public IP로 통신하면 트래픽이 인터넷을 경유하게 되어 보안 노출이 생기고, 불필요한 데이터 전송 비용도 발생한다.

LightSail은 AWS가 관리하는 별도의 내부 네트워크를 사용한다. EC2의 VPC와 연결하려면 VPC 피어링이 필요한데, LightSail이 피어링할 수 있는 대상은 default VPC로 제한된다. 따라서 커스텀 VPC를 사용하는 EC2 노드와는 private IP로 직접 통신할 수 없다.

이를 해결하기 위해 control-plane을 LightSail에서 EC2로 전환한다. 모든 노드를 EC2로 통일하면 동일한 커스텀 VPC 안에 배치할 수 있어 private IP 통신이 가능해진다.

default VPC를 사용하지 않고 커스텀 VPC를 직접 생성하는 이유는 다음과 같다.

- default VPC는 AWS 계정 생성 시 자동으로 만들어지며 CIDR(`172.31.0.0/16`)과 서브넷 구성이 고정되어 있어 변경하기 어렵다.
- 커스텀 VPC를 사용하면 IP 대역, 서브넷 분리, 라우팅 테이블을 처음부터 직접 설계할 수 있다.
- Kubernetes 클러스터에 맞는 네트워크 구조(control-plane / worker-node 서브넷 분리 등)를 갖추려면 커스텀 VPC가 필요하다.

### 서브넷 구성

control-plane은 Public Subnet에, worker-node는 Private Subnet에 배치한다.

worker-node는 실제 애플리케이션 파드를 실행하는 노드로, 외부에서 직접 접근할 이유가 없다. Private Subnet에 배치하면 Public IP 없이 VPC 내부에서만 통신하므로 불필요한 외부 노출을 줄일 수 있다.

control-plane은 SSH로 직접 접근해 클러스터를 관리해야 하기 때문에 Public IP가 필요하다. Public Subnet에 배치하고 SSH(22번 포트)를 내 IP에서만 허용하는 방식으로 외부 접근을 최소화한다. v3에서는 control-plane도 Private Subnet으로 이동하고 SSM Session Manager로 접근 방식을 전환할 예정이다.

### 인스턴스 사양 선택

실제 파드는 worker-node에서 실행되므로, worker-node의 CPU·메모리가 클러스터 성능을 결정한다. control-plane은 Kubernetes 컴포넌트만 돌리고 직접 워크로드를 받지 않기 때문에 worker-node보다 낮은 사양으로도 충분하다.

이상적으로는 worker-node를 `t3.medium` 이상으로 잡는 것이 좋지만, 비용 문제로 control-plane(`t3.small`) 포함 전 노드를 `t3.small`로 통일했다. 스토리지는 가격이 저렴해 worker-node는 30GiB, control-plane은 20GiB로 차등 적용했다.

| 노드 | 타입 | 스토리지 |
|---|---|---|
| control-plane | t3.small | 20GiB gp3 |
| worker-node × 2 | t3.small | 30GiB gp3 |

### Security Group 구성

**Control Plane SG (Public Subnet)**

| 방향 | 포트 | 출처 | 설명 |
|---|---|---|---|
| Inbound | 22 (SSH) | 내 IP | 외부 접근은 SSH만 허용 |
| Inbound | 80 (HTTP) | `0.0.0.0/0` | 실험용 HTTP 요청 수신 |
| Inbound | 443 (HTTPS) | `0.0.0.0/0` | 실험용 HTTPS 요청 수신 |
| Outbound | 전체 | `0.0.0.0/0` | 패키지 설치·이미지 pull 등 인터넷 접근 필요 |

**Worker Node SG (Private Subnet)**

| 방향 | 포트 | 출처 | 설명 |
|---|---|---|---|
| Inbound | 전체 | Control Plane SG | Control Plane에서 오는 트래픽만 허용 |
| Outbound | 전체 | `0.0.0.0/0` | 패키지 설치·이미지 pull 등 인터넷 접근 필요 |

Outbound를 `0.0.0.0/0`으로 열어둔 이유는 실습 단계에서 kubeadm, kubectl, 컨테이너 이미지 등을 노드 안에서 직접 설치·pull해야 하기 때문이다. Outbound를 Worker Node SG로만 제한하면 인터넷 접근이 막혀 패키지를 사전에 준비해야 하므로, 실습 편의를 위해 전체 허용을 유지한다.

Worker Node는 Private Subnet에 배치되어 Public IP가 없으므로, Outbound를 열어도 외부에서 Worker Node로 직접 들어오는 경로는 존재하지 않는다.

---

## v3: Reverse Proxy 기반 보안 강화 (예정)

v2의 control-plane은 Public IP를 가지고 있어 보안 그룹으로 접근을 제한하더라도 인터넷에 노출된 상태다. 보안 그룹이 방어막 역할을 하지만, 서버 자체가 공인 IP를 가진다는 것은 외부에서 직접 도달 가능한 경로가 존재한다는 의미다. 외부에서 직접 접근 가능한 서버를 Reverse Proxy 하나로 최소화하고, 나머지 노드는 모두 Private Subnet에 격리해 이 문제를 해결한다.

### 목표

- 외부에서 직접 접근 가능한 서버는 Reverse Proxy 역할의 EC2 하나만 둔다.
- control-plane과 worker-node는 모두 Private Subnet에 배치하고 Public IP를 할당하지 않는다.
- 외부 트래픽은 반드시 Reverse Proxy를 거쳐서만 Private EC2로 전달된다.
- control-plane 접근(kubectl)은 SSM Session Manager + VPC Endpoint로 인터넷 경로 없이 처리한다.

### 네트워크 구조

```
[개발자]
   ↓ SSM (VPC Endpoint, AWS 내부망)
[Control Plane EC2, Private Subnet]

[Internet]
   ↓ 80/443
[Reverse Proxy EC2 (Nginx), Public Subnet]
   ↓ Private IP
[Worker Node EC2, Private Subnet]
```

### 트래픽 흐름

**사용자 트래픽 (서비스 접근)**

```
외부 사용자
   │
   │ HTTP/HTTPS (80/443)
   ▼
Reverse Proxy EC2        ← Public Subnet, Public IP 보유
   │
   │ HTTP (8080, Private IP)
   ▼
Worker Node EC2          ← Private Subnet, Public IP 없음
   │
   │
   ▼
App Pod (컨테이너)
```

**관리자 트래픽 (kubectl 접근)**

```
개발자 PC
   │
   │ HTTPS (443, AWS 내부망)
   ▼
VPC Interface Endpoint   ← 인터넷 경유 없음
   │
   │
   ▼
Control Plane EC2        ← Private Subnet, Public IP 없음, 인바운드 포트 없음
   │
   │ 포트 포워딩 (6443)
   ▼
kubectl (로컬에서 localhost:6443으로 접근)
```

### Security Group 구성

**Reverse Proxy SG (Public Subnet)**

| 방향 | 포트 | 출처/대상 | 설명 |
|---|---|---|---|
| Inbound | 80 | 0.0.0.0/0 | HTTP |
| Inbound | 443 | 0.0.0.0/0 | HTTPS |
| Outbound | 8080 | Worker Node SG | Worker Node로만 포워딩 |

**Worker Node SG (Private Subnet)**

| 방향 | 포트 | 출처/대상 | 설명 |
|---|---|---|---|
| Inbound | 8080 | Reverse Proxy SG | Reverse Proxy에서 오는 트래픽만 허용 |
| Outbound | 443 | 0.0.0.0/0 | 컨테이너 이미지 pull 등 외부 통신 |

**Control Plane SG (Private Subnet)**

| 방향 | 포트 | 출처/대상 | 설명 |
|---|---|---|---|
| Inbound | 없음 | — | 인바운드 완전 차단 |
| Outbound | 443 | VPC Endpoint SG | SSM 통신 (AWS 내부망) |

### kubectl 접근 (SSM Session Manager + VPC Endpoint)

control-plane에 Public IP와 인바운드 포트를 열지 않고 SSM Session Manager로 접근한다. SSM Agent가 VPC Interface Endpoint를 통해 AWS 내부망으로만 통신하기 때문에 인터넷 경로가 필요 없다.

필요한 VPC Interface Endpoint 3개:

| Endpoint | 용도 |
|---|---|
| `com.amazonaws.region.ssm` | SSM 기본 연결 |
| `com.amazonaws.region.ssmmessages` | Session Manager 터널 |
| `com.amazonaws.region.ec2messages` | EC2 ↔ SSM 메시지 |

로컬에서 kubectl 사용 시 포트 포워딩:

```bash
aws ssm start-session \
  --target i-xxxxxxxxx \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["6443"],"localPortNumber":["6443"]}'
```
