# Lab 1: Building and Packaging Java Application with Maven

This project demonstrates how to compile, test, package, and execute a Java application using **Apache Maven**.

---

## 📋 Objectives

1. Install Java and Maven.
2. Clone and explore the source code.
3. Execute unit tests using Maven Surefire.
4. Build the application and generate an executable JAR file at `target/calculator.jar`.
5. Run the application and verify its interactive functionality.

---

## 🗂️ Project Structure

```
Lab-1-Maven/
├── pom.xml
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
- **Apache Maven 3.8+**: Ensure Maven is installed and added to PATH.
  ```bash
  mvn -version
  ```

---

## 🚀 Step-by-Step Execution Guide

### 1. Clone Source Code

```bash
git clone https://github.com/Ibrahim-Adel15/CalculatorMavenApp.git
cd CalculatorMavenApp
```
*(Or navigate to this directory: `cd Lab-1-Maven`)*

---

### 2. Run Unit Tests

Execute the JUnit 5 test suite using Maven:

```bash
mvn test
```

**Expected Output:**
```
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.calculator.CalculatorTest
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.082 s
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] BUILD SUCCESS
```

---

### 3. Build Application (Generate Artifact in `target/calculator.jar`)

Package the compiled classes into an executable JAR file:

```bash
mvn clean package
```

The build configuration in `pom.xml` uses `<finalName>calculator</finalName>` and configures `maven-jar-plugin` with the main class `com.example.calculator.Main`. The resulting artifact is saved to:
```
target/calculator.jar
```

---

### 4. Run Application

Execute the packaged JAR using the Java runtime:

```bash
java -jar target/calculator.jar
```

---

### 5. Verify Application Functionality

When prompted, input two numbers:

```
Enter first number: 10
Enter second number: 5
a = 10.0, b = 5.0
Sum: 15.0
Subtract: 5.0
Multiply: 50.0
Divide: 2.0
```

---

## 🔍 Key Configuration (`pom.xml`)

- **Compiler Properties**: Target Java 17.
- **JUnit 5 Jupiter**: Provides unit testing framework (`junit-jupiter:5.10.2`).
- **Maven Jar Plugin**: Bundles the main manifest attribute `Main-Class: com.example.calculator.Main`.
