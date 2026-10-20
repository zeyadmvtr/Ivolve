# ==============================================================================
# Lab 3 - Part 2: Build Locally & Package with Java 17 Runtime
# ==============================================================================
# Base image: Official lightweight Java 17 JRE runtime image
FROM eclipse-temurin:17-jre

# Set working directory
WORKDIR /app

# Create a non-root group and user (security best practice)
RUN groupadd -r appuser && useradd -r -g appuser -u 1001 -m appuser

# Copy the locally compiled JAR from host target/ directory into the container
COPY target/calculator.jar /app/calculator.jar

# Change ownership of the JAR and directory to the non-root user
RUN chown -R appuser:appuser /app

# Switch to the non-root user
USER appuser

# Expose port 8080 as requested in lab instructions
EXPOSE 8080

# Run the pre-compiled JAR file
ENTRYPOINT ["java", "-jar", "/app/calculator.jar"]
