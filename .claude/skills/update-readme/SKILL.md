---
name: update-readme
description: 지금까지 작업한 내용을 기반으로 README.md를 최신 상태로 업데이트한다. 디렉토리 구조, 변수 목록, 파일 설명 등이 실제 코드와 달라졌을 때 사용한다.
disable-model-invocation: true
allowed-tools: Read Bash
---

## 동적 컨텍스트

최근 커밋 이력:
!`git log --oneline -20`

현재 파일 구조:
!`find templates/ -type f | sort`

## 작업 순서

1. 위 컨텍스트(git log, 파일 구조)를 바탕으로 변경 사항을 파악한다.
2. 주요 `.tf`, `.tfvars` 파일들을 읽어 현재 구현 상태를 확인한다.
3. 현재 `README.md`를 읽는다.
4. README.md에서 실제 코드와 다른 부분(디렉토리 구조, 변수 테이블, 파일 설명, 실행 흐름 등)을 찾는다.
5. 차이가 있는 부분만 수정한다. 있는 내용을 불필요하게 삭제하지 않는다.

## 주의사항

- 코드에 없는 내용을 추측해서 쓰지 않는다.
- 변수 테이블은 실제 `variables.tf` 기준으로 정확히 반영한다.
- 디렉토리 구조 tree는 실제 파일 기준으로 작성한다.
