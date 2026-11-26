FROM eclipse-temurin:21-jre

WORKDIR /app

COPY target/helloworld-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-Xmx256m", "-jar", "app.jar"]
