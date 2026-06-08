## EC2 생성하기

### ec2.tf  

URL 참고
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

필수
- ami — 사용할 AMI ID
- instance_type — 인스턴스 사양

네트워크
- subnet_id — 배치할 서브넷
- vpc_security_group_ids — 보안 그룹
- associate_public_ip_address — 퍼블릭 IP 할당 여부
- private_ip — 고정 프라이빗 IP

스토리지
- root_block_device — 루트 볼륨 설정
- ebs_block_device — 추가 EBS 볼륨

접근/보안
- key_name — SSH 키페어
- iam_instance_profile — IAM 역할
- user_data — 인스턴스 시작 시 실행할 스크립트

운영
- monitoring — 상세 모니터링
- disable_api_termination — 실수로 삭제 방지
- tags — 태그

### variables.tf

하드코딩된 값을 변수로 분리시켜 재사용성과 유연성을 높인다.

URL 참고
https://developer.hashicorp.com/terraform/language/values/variables


기본 타입 (string)
- instance_type — "t2.micro"
- instance_name — "test-ec2"

선택적으로 뺄 수 있는 것들
- ami — 어떤 OS를 쓸지 (ubuntu_22, ubuntu_24, rocky_9 등)
- region — provider.tf의 "ap-northeast-2"

그리고 변수 블록에서 쓸 수 있는 옵션
- type — 타입 지정 (string, number, bool, list, map)
- default — 기본값
- description — 설명
- validation — 유효성 검사
- sensitive — 비밀번호 같은 민감한 값 숨김

### outputs.tf

리소스의 속성 값을 외부로 노출시켜 확인하거나 재사용할 수 있게 한다.

URL 참고
https://developer.hashicorp.com/terraform/language/values/outputs

노출하면 유용한 값들
- instance_id - 생성된 ec2의 ID
- public_ip - 인스턴스에 접속할 때 쓰는 퍼블릭 IP
- private_ip - VPC 내부 통신용 사설 IP
- ami_id - 실제로 선택된 AMI의 ID


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
