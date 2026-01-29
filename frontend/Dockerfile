# ===========================
# STAGE 1 — Build Application
# ===========================
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

# Copy pom.xml first and download dependencies
COPY pom.xml .
RUN mvn -q dependency:go-offline

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests


# ===========================
# STAGE 2 — Run Application
# ===========================
FROM eclipse-temurin:21-jdk
WORKDIR /app

# Copy the built jar file
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
