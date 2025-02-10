#!/bin/bash
# ~/.ssh/{devkey,devkey.pub} 파일 생성
# (-t: type, -N: No password, -f: filename)

ssh-keygen -t rsa -N '' -f ~/.ssh/devkey
[ $? -eq 0 ] \
  && echo "[  OK  ] Key pair" \
  || echo "[ FAIL ] Key pair"

cat << EOF

스크립트가 정상적으로 수행이 되었다면,
1) vscode 설치
  $ firefox https://code.visualstudio.com/download
2) vscode extension 설치 - Remote Development 설치
  vscode > 왼쪽 목록 > extension > "Remote Development" 검색 > 설치
3) 제공된 terraform 파일 실행
  $ terraform init
  $ terraform plan
  $ terraform apply -auto-approve

EOF
