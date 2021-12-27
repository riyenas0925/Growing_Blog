#!/bin/bash

echo "> 현재 실행중인 Container 확인"
RUNNING_CONTAINER=$(docker ps -a | grep growing_spring)

if [ -z "$RUNNING_CONTAINER" ]
then
        echo -e "\n> 현재 실행중인 Container가 없으므로 종료하지 않습니다."
else
        echo -e "\n> 현재 실행중인 Conatiner를 종료합니다."
        docker rm -f growing_spring

        echo -e "\n> 기존의 Docker Image를 삭제합니다."
        docker rmi riyenas0925/growing_spring:latest
fi

echo -e "\n> 최신 버전의 컨테이너로 배포합니다."
docker run -d -p 8080:8080 --name growing_spring riyenas0925/growing_spring:latest