FROM openjdk:11

LABEL maintainer="riyenas0925 <riyenas0925@gmail.com>"

ARG JAR_FILE=build/libs/*.jar

COPY ${JAR_FILE} app.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","/app.jar"]