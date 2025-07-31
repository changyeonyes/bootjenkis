# Dockerfile

# Stage 1: 빌드 단계 (Maven과 OpenJDK 11이 설치된 이미지 사용)
FROM maven:3-openjdk-11 AS build

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline

COPY src ./src

RUN mvn clean package -DskipTests

# Stage 2: 런타임 단계 (Tomcat이 포함된 OpenJDK 11 이미지 사용)
# Java 11과 호환되는 Tomcat 이미지 (예: tomcat:9-jdk11-openjdk)
FROM tomcat:9-jdk11-openjdk 
# <-- 이 라인에서 주석 '# 또는 tomcat:latest-jdk11 등'을 완전히 제거했습니다.

# Tomcat 웹앱 디렉토리에 WAR 파일 복사
COPY --from=build /app/target/BootMybatisTilesV3-0.0.1-SNAPSHOT.war ROOT.war

EXPOSE 8080

# CMD ["catalina.sh", "run"]