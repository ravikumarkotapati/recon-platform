FROM eclipse-temurin:17-jre-alpine

RUN addgroup -S -g 10001 recon && adduser -S -u 10001 -G recon recon
WORKDIR /opt/recon

COPY target/recon-dashboard-api-*.jar app.jar

USER 10001
EXPOSE 8083

ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-XX:+ExitOnOutOfMemoryError", "-jar", "/opt/recon/app.jar"]


