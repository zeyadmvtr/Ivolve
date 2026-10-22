# ==============================================================================
# Multi-Stage Dockerfile for Spring Boot Application (image2)
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build Environment (Maven + JDK)
# ------------------------------------------------------------------------------
FROM maven:3.9.15-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copy pom.xml and source code
COPY pom.xml .
COPY src ./src

# Build and package the application into an executable JAR
RUN mvn clean package -DskipTests

# ------------------------------------------------------------------------------
# Stage 2: Minimal Production Runtime (JRE Only)
# ------------------------------------------------------------------------------
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Security best practice: Create non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only the compiled JAR from the builder stage
COPY --from=builder /app/target/demo-0.0.1-SNAPSHOT.jar app.jar

# Set appropriate ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root execution
USER appuser

# Expose application port
EXPOSE 8080

# Execute Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]
