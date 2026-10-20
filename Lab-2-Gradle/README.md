# Lab 2: Building and Packaging Application with Gradle

This project demonstrates how to compile, test, package, and execute an application using **Gradle**.

> **Note on Lab Title**: While the slide title notes *"Building and Packaging Go Application with Gradle"*, the referenced repository (`CalculatorGradleApp`) and instructions target a Java application configured with Gradle, producing `build/libs/calculator.jar`.

---

## 📋 Objectives

1. Install Gradle.
2. Clone and explore the source code.
3. Execute unit tests using Gradle test runner.
4. Build the application and generate an executable JAR file at `build/libs/calculator.jar`.
5. Run the application and verify its interactive functionality.

---

## 🗂️ Project Structure

```
Lab-2-Gradle/
├── build.gradle
├── settings.gradle
├── README.md
└── src/
    ├── main/
    │   └── java/
    │       └── com/
    │           └── example/
    │               └── calculator/
    │                   ├── Calculator.java
    │                   └── Main.java
    └── test/
        └── java/
            └── com/
                └── example/
                    └── calculator/
                        └── CalculatorTest.java
```

---

## ⚙️ Prerequisites

- **Java JDK 17+**: Ensure Java 17 or later is installed.
  ```bash
  java -version
  ```
- **Gradle 7+ / 8+**: Ensure Gradle is installed and added to PATH.
  ```bash
  gradle -version
  ```

---

## 🚀 Step-by-Step Execution Guide

### 1. Clone Source Code

```bash
git clone https://github.com/Ibrahim-Adel15/CalculatorGradleApp.git
cd CalculatorGradleApp
```
*(Or navigate to this directory: `cd Lab-2-Gradle`)*

---

### 2. Run Unit Tests

Execute the JUnit 5 tests via Gradle:

```bash
gradle test
```

To see detailed test output in the terminal:
```bash
gradle test --info
```

**Expected Output:**
```
> Task :compileJava
> Task :processResources NO-SOURCE
> Task :classes
> Task :compileTestJava
> Task :processTestResources NO-SOURCE
> Task :testClasses
> Task :test

BUILD SUCCESSFUL in 2s
```

Test reports are generated in `build/reports/tests/test/index.html`.

---

### 3. Build Application (Generate Artifact in `build/libs/calculator.jar`)

Build the executable JAR:

```bash
gradle build
```
*(Or specifically build the jar: `gradle jar`)*

The `build.gradle` is configured with:
```groovy
jar {
    archiveBaseName = 'calculator'
    archiveVersion = ''
    manifest {
        attributes 'Main-Class': 'com.example.calculator.Main'
    }
}
```

The resulting artifact is generated at:
```
build/libs/calculator.jar
```

---

### 4. Run Application

Execute the packaged JAR using Java:

```bash
java -jar build/libs/calculator.jar
```

Alternatively, you can also run directly through Gradle's application plugin:
```bash
gradle run --console=plain
```

---

### 5. Verify Application Functionality

When prompted, input two numbers:

```
Enter first number: 20
Enter second number: 4
a = 20.0, b = 4.0
Sum: 24.0
Subtract: 16.0
Multiply: 80.0
Divide: 5.0
```

---

## 🔍 Key Configuration (`build.gradle`)

- **Plugins**: `id 'java'` and `id 'application'`.
- **Toolchain**: Enforces Java 17 compatibility (`JavaLanguageVersion.of(17)`).
- **Application block**: Sets `mainClass = 'com.example.calculator.Main'`.
- **Jar task**: Configures archive name without version (`calculator.jar`) and specifies the manifest `Main-Class`.
