#!/usr/bin/env groovy

/**
 * Shared Library: BuildApp
 * Performs unit testing and application packaging using Maven.
 *
 * @param config Map containing optional parameters:
 *               - skipTests: boolean (default: false)
 */
def call(Map config = [:]) {
    boolean skipTests = config.get('skipTests', false)

    echo "=========================================================="
    echo ">>> [Shared Library: BuildApp] Starting Build Process"
    echo "=========================================================="

    stage('Unit Tests') {
        if (!skipTests) {
            echo ">>> Running unit test suite with Maven..."
            sh 'mvn test'
        } else {
            echo ">>> Skipping unit tests as requested."
        }
    }

    stage('Package Application') {
        echo ">>> Compiling and packaging Spring Boot JAR with Maven..."
        sh "mvn clean package -DskipTests=${skipTests}"
        sh 'ls -lh target/*.jar'
        echo ">>> [BuildApp] Application packaging completed successfully!"
    }
}
