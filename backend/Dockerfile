# Multi-stage build for all Angi microservices.
# Pick the service to package with:  docker build --build-arg SERVICE=identity .
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY common/pom.xml common/pom.xml
COPY services/gateway/pom.xml services/gateway/pom.xml
COPY services/identity/pom.xml services/identity/pom.xml
COPY services/roulette/pom.xml services/roulette/pom.xml
COPY services/ranking/pom.xml services/ranking/pom.xml
COPY services/place/pom.xml services/place/pom.xml
COPY services/journal/pom.xml services/journal/pom.xml
RUN mvn -B -q -DskipTests dependency:go-offline || true
COPY common common
COPY services services
RUN mvn -B -q -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
ARG SERVICE=identity
COPY --from=build /app/services/${SERVICE}/target/angi-${SERVICE}-0.1.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
