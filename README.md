## EC2 생성하기

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