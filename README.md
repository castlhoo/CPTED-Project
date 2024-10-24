
# 🚨 CPTED Spark on Kubernetes: For Safer Society 🏙️

### Project Overview
![image](https://github.com/user-attachments/assets/f762d48d-b0b4-4837-8ec7-0e9fcb2180ab)
This project aims to implement a machine learning model using CPTED (Crime Prevention Through Environmental Design) to create a safer society. The focus is on key concepts like surveillance and access control, which are reflected in environmental design to reduce crime risks. We will develop a PySpark model, implement it in a CI/CD pipeline, and deploy it on Kubernetes. The model will help insurance agents assess the crime risk of residential areas and recommend appropriate home insurance products.

### Goals 🎯
- Develop a model that requires large-scale data for machine learning.
- Learn how to manage and optimize large-scale data using a CI/CD pipeline.
- Implement the concepts from CPTED (surveillance, access control) to predict crime risks.

---

## Project Model 🧠
![image](https://github.com/user-attachments/assets/2e4225fe-1dce-49eb-bf37-41092b4262c2)
1. A developer uploads the PySpark model to GitHub.
2. **Webhook** integration using **ngrok** to trigger Jenkins builds automatically.
3. Jenkins builds and uploads the Docker image to Docker Hub.
4. The Docker image is deployed to Kubernetes.
5. **Insurance agents** use the model to predict crime risk for customers' residences and offer relevant home insurance.
6. Insurance suggestions are made based on the predicted crime risk.

---

## Large-scale Machine Learning Model: Spark ⚙️

### 1. Training Dataset Preparation 📊
![image](https://github.com/user-attachments/assets/3c5b3cf8-1c36-483d-86ec-c6f838c3bf2d)
- **Features:**
    - **Accessibility** and **Surveillance** scores range from 1 (low) to 5 (high).
    - **Crime Count** represents the number of burglary crimes from public police data.
    - **Risk Score** is the target variable predicting the crime risk for each apartment or house (higher score = higher risk).

### 2. PySpark Code Implementation 💻
```bash
from pyspark.sql import SparkSession
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml import Pipeline
from pyspark.sql.functions import col, when

# Create Spark session
spark = SparkSession.builder.appName("Apartment Crime Safety Prediction").getOrCreate()

# Load training data
train_data = spark.read.csv("/home/username/APT_Crime_Data.csv", header=True, inferSchema=True)

# Select necessary columns
train_data = train_data.select("Accessibility", "Surveillance", "Crime Count", "Risk Score")

# Adjust risk score where necessary
train_data = train_data.withColumn("Risk Score", when(col("Risk Score") >= 100, 99).otherwise(col("Risk Score").cast("integer")))

# Feature vector creation
assembler = VectorAssembler(inputCols=["Accessibility", "Surveillance", "Crime Count"], outputCol="features")

# Random Forest model
rf = RandomForestClassifier(labelCol="Risk Score", featuresCol="features", numTrees=10)

# Create pipeline
pipeline = Pipeline(stages=[assembler, rf])

# Train model
model = pipeline.fit(train_data)

# Load test data
test_data = spark.read.csv("/home/username/APT_Prediction.csv", header=True, inferSchema=True)

# Predictions
predictions = model.transform(test_data)

# Save predictions
predictions.write.mode("overwrite").csv("/home/username/APT_Prediction_with_Risk_Score.csv", header=True)

# Stop Spark session
spark.stop()
```

**Pyspark Results**
![image](https://github.com/user-attachments/assets/a4b61810-d97c-4c33-8979-48d21f850f2e)
![image](https://github.com/user-attachments/assets/231438f7-6c44-4137-b9e7-bd210a65353a)
>> This is results which predict in Anyang-City Apartment. Additionally, We can recongnize that directory about model also created.


### 3. 🏗️ GitHub & Jenkins CI/CD Pipeline for CPTED Crime Prediction Model
### Step 1: GitHub and Jenkins Integration 🔗
![image](https://github.com/user-attachments/assets/72306dd5-37de-4f3b-8cee-fb9819585640)
![image](https://github.com/user-attachments/assets/c68840e9-dac5-48f1-ba52-c15df5f9e09c)
- The integration is set up via **ngrok** for **webhook** notifications. Changes pushed to GitHub are automatically detected and trigger builds in Jenkins.
- Jenkins monitors GitHub for updates, fetching files when uploaded or modified and running the corresponding jobs.

### Step 2: Installing and Running Jenkins ⚙️
![image](https://github.com/user-attachments/assets/a40d4361-bc40-42a5-ba1b-894baf72d12b)
![image](https://github.com/user-attachments/assets/cd2adf62-245c-49a1-9f39-fc324171a0ea)
- **Jenkins Installation**: Jenkins is set up and configured for continuous integration and deployment.
- **Running Jenkins**: After installation, Jenkins is initiated to handle incoming webhooks and perform automated tasks.
  
### Step 3: CI/CD Pipeline Implementation with Docker & PySpark ⚙️
![image](https://github.com/user-attachments/assets/ce37cd92-0f7d-4052-b970-ad47b9787096)

#### 1) Docker Hub Authentication 🛠️
![image](https://github.com/user-attachments/assets/5887c31a-df3a-42dd-aa20-5027461e1101)
- **Credentials Setup**: Docker Hub credentials (username and password) are configured in Jenkins to allow seamless login and image pushing to Docker Hub.
  
#### 2) PySpark Configuration and Setup 🧑‍💻
![image](https://github.com/user-attachments/assets/70438f26-e344-41b8-a34f-30eedd3421e5)
![image](https://github.com/user-attachments/assets/132e4828-d0ee-4017-921c-8f45226d7245)
- The Dockerfile is configured to download and set up **Python** and **PySpark**.
- **Directory Setup**: Directories for storing the PySpark model are created and uploaded as part of the build.

```bash
from pyspark.sql import SparkSession
from pyspark.ml import PipelineModel

# Create Spark session
spark = SparkSession.builder.appName("Apartment Crime Safety Prediction").getOrCreate()

# Load saved model
model = PipelineModel.load("/app/prediction_model")

# Load data for prediction
test_data_path = "/app/APT_Prediction.csv"
test_data = spark.read.csv(test_data_path, header=True, inferSchema=True)

# Perform predictions
predictions = model.transform(test_data)
predictions.show()

# Save results
output_path = "/app/APT_Prediction_with_Risk_Score.csv"
predictions.write.mode("overwrite").csv(output_path, header=True)

# Stop Spark session
spark.stop()
```

#### 3) Jenkins Pipeline Configuration for CI/CD 🔄
- The Jenkinsfile automates the process of building the Docker image, pushing it to Docker Hub, and deploying it to Kubernetes.
```bash
pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials-id')
    }
    stages {
        stage('Checkout') {
            steps {
                // Fetch code from GitHub
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // Build the Docker image
                    sh "docker build -t ${imageName} ."
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // Login to Docker Hub and push the image
                    sh "echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin"
                    sh "docker push ${imageName}"
                }
            }
        }
    }
    post {
        always {
            // Logout from Docker Hub after job completion
            sh 'docker logout'
        }
    }
}
```

#### 4) Dockerfile Configuration for PySpark Model 🎯
- The Dockerfile specifies the environment setup, including Python and Spark installation, required to run the PySpark model:
```bash
# Base image with Python 3.8
FROM python:3.8-slim

# Set working directory
WORKDIR /app

# Update system and install OpenJDK 11 for Spark
RUN apt-get update && apt-get install -y openjdk-17-jdk curl

# Download and install Spark 3.1.2
RUN curl -s https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz | tar -xz -C /opt/
ENV SPARK_HOME=/opt/spark-3.1.2-bin-hadoop3.2
ENV PATH=$SPARK_HOME/bin:$PATH

# Install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy model and prediction files
COPY Crime_Predict.py .

# Default command to run prediction script
CMD ["python", "Crime_Predict.py"]
```

### Step 4: Pushing Docker Image to Docker Hub via Jenkins 🐋
  ![image](https://github.com/user-attachments/assets/2f7e40d8-369c-43ef-a451-bb53d8972510)
  ![image](https://github.com/user-attachments/assets/5c36062d-985a-4b24-b664-752433ae28fc)
- The Docker image is built and pushed to Docker Hub, making it available for deployment.
  
### Step 5: Deploying to Kubernetes 🐳
![image](https://github.com/user-attachments/assets/35afed89-fdbb-45a0-aa92-9b2c87d3cff7)

#### 1) Jenkins Kubernetes Authentication 🌐
![image](https://github.com/user-attachments/assets/5bc73e3f-309c-4dd5-8d22-f4bffae0e84d)
- The **kubeconfig.yaml** file is uploaded to Jenkins for authenticating and deploying to the Kubernetes cluster.

#### 2) Jenkinsfile for Kubernetes Deployment 🔧
- The updated Jenkinsfile includes Kubernetes deployment steps.
```bash
pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials-id')
        KUBECONFIG = credentials('kubeconfig-credentials-id') // Securely accessing kubeconfig
    }
    stages {
        stage('Checkout') {
            steps {
                // Pull code from GitHub
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // Build Docker image
                    sh "docker build -t ${imageName} ."
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // Push Docker image to Docker Hub
                    sh "echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin"
                    sh "docker push ${imageName}"
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Deploy to Kubernetes
                    withCredentials([file(credentialsId: 'kubeconfig-credentials-id', variable: 'KUBECONFIG')]) {
                        sh 'kubectl --kubeconfig=$KUBECONFIG apply -f deployment.yaml --validate=false'
                    }
                }
            }
        }
    }
    post {
        always {
            // Logout from Docker after job completion
            sh 'docker logout'
        }
    }
}
```

#### 3) Kubernetes Deployment Configuration 🚀
  ![image](https://github.com/user-attachments/assets/d443424a-0f69-4696-a742-2183da0c74df)
  ![image](https://github.com/user-attachments/assets/5f28a1c2-0526-4bfd-af9c-bd278b6fd0b8)

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crime-prediction-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: crime-prediction
  template:
    metadata:
      labels:
        app: crime-prediction
    spec:
      containers:
      - name: crime-prediction
        image: castlehoo/crime_prediction_image:latest
        ports:
        - containerPort: 8081  # Inside container
---
apiVersion: v1
kind: Service
metadata:
  name: crime-prediction-service
spec:
  type: NodePort
  selector:
    app: crime-prediction
  ports:
    - port: 8081  # External service port
      targetPort: 8081  # Container port
      nodePort: 30007  # Cluster external access port
```

---

## Optimizing CI/CD for Large-scale Data 📈

### Benefits of Optimized Pipelines
1. **Reduced Deployment Time** 🕒
2. **Efficient Resource Usage** 🖥️
3. **Improved Scalability and Stability** 📊
4. **Cost-effective Operation** 💰

#### 1) Multi-stage Docker Build 🛠️
![image](https://github.com/user-attachments/assets/d882bf96-fbb7-44a4-b920-fe65e272bdfe)
- The build environment is separated from the runtime environment, removing unnecessary files and reducing the final image size.

![image](https://github.com/user-attachments/assets/e6dc6dfb-1145-4d99-9653-e1bb68f2dd47)
![image](https://github.com/user-attachments/assets/2c9020d0-4a72-4352-86cf-9b53bf4954d5)

#### 2) Leveraging Docker Cache 🧑‍💻
 ![image](https://github.com/user-attachments/assets/f79777c7-5338-4f7e-a9e4-a951c423d252)
- Docker caches layers, speeding up build times by reusing unchanged layers from previous builds.

![image](https://github.com/user-attachments/assets/30e38568-da77-4f43-8275-45202022454a)

#### 3) Parallel Build & Test 🏎️
![image](https://github.com/user-attachments/assets/e34cc7bb-e1fd-4fa6-9130-ebb5450aa319)
- By running builds and tests in parallel, the overall pipeline time is significantly reduced.

---

### Final Results 🏁

#### Before Optimization
![image](https://github.com/user-attachments/assets/d4a176ab-ec40-477e-a0aa-e4af487844b1)
![image](https://github.com/user-attachments/assets/4f6917a7-22cb-4ec1-93fb-91c5e030ac6d)
- **Deployment Time**: **2 minutes 4 seconds** ⏳

#### After Optimization
![image](https://github.com/user-attachments/assets/e0926fe8-61b1-456b-89fd-ae5aa43fdb65)
![image](https://github.com/user-attachments/assets/2dad33d0-7c25-4a02-bd1a-1afe4432a26b)
- **Deployment Time**: **1 minute 38 seconds** (approximately 30 seconds faster) ⚡

---

## Summary 📋
- Implemented a robust CI/CD pipeline using Jenkins, Docker, and Kubernetes.
- Optimized the build and deployment process for large-scale data handling.
- The crime prediction model was automated from build to deployment, enabling insurance agents to recommend home insurance based on crime risk predictions.
