# syntax=docker/dockerfile:1.7

# Pinned JRE-only image on Ubuntu Noble - reproducible, small runtime footprint.
# Bump the digest when you intentionally move to a newer base.
FROM eclipse-temurin:21.0.5_11-jre-noble

# Non-root user for the app process.
RUN useradd --system --uid 10001 --home /app --shell /usr/sbin/nologin app

WORKDIR /app

# The jar produced by 'mvn verify' (executable Spring Boot jar).
# Copy the built artifact - not the source - to keep the image slim.
COPY --chown=app:app target/*.jar /app/app.jar

USER app

EXPOSE 8080

# Exec form so the JVM is PID 1 and receives SIGTERM directly.
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
