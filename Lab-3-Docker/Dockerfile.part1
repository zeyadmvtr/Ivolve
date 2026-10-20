# ==============================================================================
# Lab 3 - Part 1: Build Inside Docker
# ==============================================================================
# Base image: Official Maven image with Java 17
FROM maven:3.9.6-eclipse-temurin-17

# Set working directory
WORKDIR /app

# Create a non-root group and user (security best practice)
RUN groupadd -r appuser && useradd -r -g appuser -u 1001 -m appuser

# Copy pom.xml and source code into the container
COPY pom.xml .
COPY src ./src

# Change ownership of the application directory to the non-root user
RUN chown -R appuser:appuser /app

# Switch to the non-root user
USER appuser

# Build the application using Maven package
RUN mvn clean package

# Expose port 8080 as requested in lab instructions
EXPOSE 8080

# Run the generated JAR file
ENTRYPOINT ["java", "-jar", "target/calculator.jar"]
