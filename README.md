# CPTED Spark on Kubernetes
안전한 사회를 위한 모델 구현 : CPTED
![image](https://github.com/user-attachments/assets/f762d48d-b0b4-4837-8ec7-0e9fcb2180ab)
환경설계를 통한 범죄예방으로, 메인 컨셉인 감시와 접근통제 서브컨셉인 공동체강화의 요소들이 환경설계에 반영이 되어 더 안전한 사회를 만들고자하는 이론이다. 감시는 이상접근자를 지속적으로 볼 수 있는 CCTV나 경비원을 말하고, 접근통제는 아예 접근을 하지 못하게끔 하는 잠금장치, 차량 출입조치를 통해 접근자에 대해 통제를 하는 것이다. 이 범죄이론을 이용하여 PySpark 모델을 만들고, 배포까지 하는 파이프라인을 구성해보고자 한다.

## 프로젝트 개요
- 안전한 사회를 위한 모델 구현

- 대용량 데이터를 필요로 하는 머신러닝 모델 구현

- 파이프라인 구현을 통한 수업내용 체화

- 대용량 데이터를 관리하고, 향상시키는 방법

### 1. 프로젝트 모델
![image](https://github.com/user-attachments/assets/2e4225fe-1dce-49eb-bf37-41092b4262c2)
1. PySpark 모델을 개발하고, 훈련시키는 개발자는 깃허브에 업로드
2. ngrok을 통해 깃허브에서 Jenkins로 웹훅 자동연동
3. 젠킨스를 통해 도커 허브 이미지 업로드
4. 도커 허브에 업로드된 이미지 쿠버네티스에 배포
5. 손해보험회사의 상담직원이 모델을 사용하면서 고객의 주거지 위험성 예측 및 분석
6. 고객의 위험성 예측 및 분석 정보를 기반으로 주택종합보험 상품 제안

### 2. 대용량 데이터를 필요로 하는 머신러닝 모델 구현 : Spark 모델
- 1. 훈련데이터 세트 준비
  ![image](https://github.com/user-attachments/assets/3c5b3cf8-1c36-483d-86ec-c6f838c3bf2d)
  Accessibility와 Surveillance는 1점에서 5점으로 나뉘어 점수가 높을수록 좋은 접근성과 감시성을 지님
  Crime Count는 한국 경찰청에서 제공하는 월별 각 지역별 절도범죄 건 수
  Risk Score는 각 아파트 또는 주택에 해당하는 위험점수(점수가 높을수록, 범죄에 노출)

- 2. PySpark 코드
```bash
from pyspark.sql import SparkSession
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.evaluation import MulticlassClassificationEvaluator
from pyspark.ml import Pipeline
from pyspark.sql.functions import when, col

# Spark 세션 생성
spark = SparkSession.builder.appName("Apartment Crime Safety Prediction").getOrCreate()

# 1. 학습용 데이터 로드
train_data_path = "/home/username/APT_Crime_Data.csv"  # 학습용 CSV 파일 경로
train_data = spark.read.csv(train_data_path, header=True, inferSchema=True)

# 2. 필요한 열을 선택
train_data = train_data.select("Accessibility", "Surveillance", "Crime Count", "Risk Score")

# 3. `Risk Score` 값이 100인 경우 99로 조정하고, 정수로 변환
train_data = train_data.withColumn("Risk Score", when(col("Risk Score") >= 100, 99).otherwise(col("Risk Score").cast("integer")))

# 중복된 feature 컬럼이 있는지 확인하고 삭제
if "features" in train_data.columns:
    train_data = train_data.drop("features")

# 4. Feature Vector 생성
assembler = VectorAssembler(inputCols=["Accessibility", "Surveillance", "Crime Count"], outputCol="features")

# 5. 분류 모델 생성 (Random Forest Classifier)
rf = RandomForestClassifier(labelCol="Risk Score", featuresCol="features", numTrees=10)

# 6. 파이프라인 설정
pipeline = Pipeline(stages=[assembler, rf])

# 7. 모델 학습
model = pipeline.fit(train_data)

# 8. 예측용 데이터 로드 (별도의 CSV 파일)
test_data_path = "/home/username/APT_Prediction.csv"  # 예측용 CSV 파일 경로
test_data = spark.read.csv(test_data_path, header=True, inferSchema=True)

# 9. 예측용 데이터 준비 (Risk Score는 예측을 위해 제외)
test_data = test_data.select("Apartment Name", "Accessibility", "Surveillance", "Crime Count")

# 중복된 feature 컬럼이 있는지 확인하고 삭제 (테스트 데이터에 대해서도)
if "features" in test_data.columns:
    test_data = test_data.drop("features")

# 10. 예측 수행
predictions = model.transform(test_data)

# 11. 예측된 Risk Score를 기존 데이터에 추가
predictions_with_risk_score = predictions.select("Apartment Name", "Accessibility", "Surveillance", "Crime Count", col("prediction").alias("Predicted Risk Score"))

# 12. 모델 평가 (성능 평가)
# 테스트 데이터에 실제 "Risk Score"가 없으므로 이 부분은 생략합니다.
print("Unable to evaluate model accuracy: 'Risk Score' column not found in predictions.")

# 13. 예측 결과를 CSV 파일로 저장
output_path = "/home/username/APT_Prediction_with_Risk_Score.csv"
predictions_with_risk_score.write.mode("overwrite").csv(output_path, header=True)

print(f"Predicted results saved to {output_path}")

# Spark 세션 종료
spark.stop()
```

- 3. PySpark 결과
  ![image](https://github.com/user-attachments/assets/a4b61810-d97c-4c33-8979-48d21f850f2e)
  ![image](https://github.com/user-attachments/assets/231438f7-6c44-4137-b9e7-bd210a65353a)
  
  안양에 있는 아파트의 접근성과 감시성 그리고 해당 지역의 절도범죄 건수를 기반으로 예측을 한 결과이며, 모델에 대한 디렉터리도 생성되었음을 알 수 있음

### 3. 파이프라인 구현을 통한 수업내용 체화 : CI / CD 구현

- 지속적인 통합과 배포의 중요성
    1. 일관된 배포
    2. 신속한 테스트와 피드백
    3. 안정적 운영

- 확장성 및 자동화 필요
    1. 대용량 데이터를 다루는 시스템은 확장성 필요
    2. 시스템 부하를 조절하는 자동화
 
- 1. 깃허브와 젠킨스 연동설정
     ![image](https://github.com/user-attachments/assets/72306dd5-37de-4f3b-8cee-fb9819585640)
     ![image](https://github.com/user-attachments/assets/c68840e9-dac5-48f1-ba52-c15df5f9e09c)
     깃허브로부터 파일을 업로드하고, 수정 시 자동으로 감지하고 빌드할 수 있도록 ngrok을 통해 웹훅 연결

- 2. Jenkins 설치 및 실행
     ![image](https://github.com/user-attachments/assets/a40d4361-bc40-42a5-ba1b-894baf72d12b)
     ![image](https://github.com/user-attachments/assets/cd2adf62-245c-49a1-9f39-fc324171a0ea)

- 3. 깃허브 내 Dockerfile, Jenkinsfile, Pyspark 파일 업로드를 통한 CI/CD 구현
     ![image](https://github.com/user-attachments/assets/ce37cd92-0f7d-4052-b970-ad47b9787096)

     1) 젠킨스와 도커 인증설정
        ![image](https://github.com/user-attachments/assets/5887c31a-df3a-42dd-aa20-5027461e1101)
        도커허브 사이트에 로그인 하는 아이디와 비밀번호 설정

     2) Pyspark 파일 설정
        ![image](https://github.com/user-attachments/assets/70438f26-e344-41b8-a34f-30eedd3421e5)
        도커파일이 파이썬 버전을 읽고, 다운받을 수 있도록 설정
        
        ![image](https://github.com/user-attachments/assets/132e4828-d0ee-4017-921c-8f45226d7245)
        형성했던 PySpark 모델 디렉터리 형성 및 업로드
                
```bash
from pyspark.sql import SparkSession
from pyspark.ml import PipelineModel

# 스파크 세션 생성
spark = SparkSession.builder.appName("Apartment Crime Safety Prediction").getOrCreate()

# 저장된 모델 로드
model = PipelineModel.load("/app/prediction_model")

# 예측용 데이터 로드
test_data_path = "/app/APT_Prediction.csv"
test_data = spark.read.csv(test_data_path, header=True, inferSchema=True)

# 예측 수행
predictions = model.transform(test_data)
predictions.show()

# 결과 저장
output_path = "/app/APT_Prediction_with_Risk_Score.csv"
predictions.write.mode("overwrite").csv(output_path, header=True)

# 스파크 세션 종료
spark.stop()
```
      3) Jenkinsfile
      
```bash
pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials-id')
    }
    stages {
        stage('Checkout') {
            steps {
                // 깃허브에서 코드 가져오기
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // 도커 이미지 빌드
                    sh "docker build -t ${imageName} ."
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // Docker Hub에 로그인 및 이미지 푸시
                    sh "echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin"
                    sh "docker push ${imageName}"
                }
            }
        }
    }
    post {
        always {
            // 작업 완료 후 로그아웃
            sh 'docker logout'
        }
    }
}
```

      4) Dockerfile
   ```bash
# Python 3.8 기반의 이미지 사용
FROM python:3.8-slim

# 작업 디렉터리 설정
WORKDIR /app

# 시스템 패키지 업데이트 및 OpenJDK 11 설치 (스파크에 필요)
RUN apt-get update && apt-get install -y openjdk-17-jdk curl

# Spark 설치 (버전은 Spark 3.1.2)
RUN curl -s https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz | tar -xz -C /opt/
ENV SPARK_HOME=/opt/spark-3.1.2-bin-hadoop3.2
ENV PATH=$SPARK_HOME/bin:$PATH

# Python 패키지 설치 (requirements.txt에서 복사)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# crime_prediction.py 및 기타 소스 파일을 복사
COPY Crime_Predict.py .

# 기본 명령어 설정 (컨테이너 실행 시 Crime_Predict.py 실행)
CMD ["python", "Crime_Predict.py"]
```

 - 4. 젠킨스를 통한 도커허브에 이미지 업로드
  ![image](https://github.com/user-attachments/assets/2f7e40d8-369c-43ef-a451-bb53d8972510)
  ![image](https://github.com/user-attachments/assets/5c36062d-985a-4b24-b664-752433ae28fc)

 - 5. 쿠버네티스 구축을 위한 깃허브에 쿠버네티스 관련 파일 업로드 
  ![image](https://github.com/user-attachments/assets/35afed89-fdbb-45a0-aa92-9b2c87d3cff7)

    1) Jenkins k8s 인증설정
       ![image](https://github.com/user-attachments/assets/5bc73e3f-309c-4dd5-8d22-f4bffae0e84d)
       kubeconfig.yaml 파일을 젠킨스에 등록해서 인증설정

    2) Jenkinsfile
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
                // 깃허브에서 코드 가져오기
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // 도커 이미지 빌드
                    sh "docker build -t ${imageName} ."
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    def imageName = "castlehoo/crime_prediction_image:${env.BUILD_NUMBER}"
                    // Docker Hub에 로그인 및 이미지 푸시
                    sh "echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin"
                    sh "docker push ${imageName}"
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // 쿠버네티스에 배포
                    withCredentials([file(credentialsId: 'kubeconfig-credentials-id', variable: 'KUBECONFIG')]) {
                        sh 'kubectl --kubeconfig=$KUBECONFIG apply -f deployment.yaml --validate=false'
                    }
                }
            }
        }
    }
    post {
        always {
            // 작업 완료 후 로그아웃
            sh 'docker logout'
        }
    }
}
```

      3) Deploymentfile
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
        - containerPort: 8081  # 컨테이너 내부에서 8081 포트를 사용
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
    - port: 8081  # 외부에서 접근할 서비스 포트를 8081로 변경
      targetPort: 8081  # 컨테이너의 8081 포트로 연결
      nodePort: 30007  # NodePort를 그대로 유지 (클러스터 외부에서 접근할 포트)
```

    - 6. k8s 배포 완료
  ![image](https://github.com/user-attachments/assets/d443424a-0f69-4696-a742-2183da0c74df)
  ![image](https://github.com/user-attachments/assets/5f28a1c2-0526-4bfd-af9c-bd278b6fd0b8)

  ### 4. 대용량 데이터를 관리하고, 향상시키는 방법 : CI / CD 구현
  파이프라인 최적화에 따른 장점
  1. 배포시간 단축
  2. 리소스 효율성
  3. 확장성과 안정성 향상
  4. 비용절감

       1) 멀티스테이지 Docker 빌드
          ![image](https://github.com/user-attachments/assets/d882bf96-fbb7-44a4-b920-fe65e272bdfe)
          - 빌드 환경과 실행 환경을 분리하여 불필요한 파일과 라이브러리를 최종 Docker 이미지에서 제외
          - 빌드에 필요한 도구와 실행에 필요한 도구를 분리하여, 최종 이미지에 불필요한 파일을 포함하지 않도록 해서 작은 이미지를 생성으로 빠른 다운로드 및 빠른 컨테이너 실행을 가능하게 하는 방법

        2) Docker Cache 활용
           ![image](https://github.com/user-attachments/assets/f79777c7-5338-4f7e-a9e4-a951c423d252)
           - Docker는 레이어 단위로 캐시를 관리하므로, 변동이 없는 레이어는 캐시에서 재사용
           - Docker는 각 명령어를 레이어로 처리하고, 각 명령어의 결과는 캐시로 저장되며, 이후 빌드에서 동일한 명령어를 만나면 Docker는 캐시된 결과를 재사용하여 빌드 시간을 크게 단축
          
        3) Docker 병렬빌드
           ![image](https://github.com/user-attachments/assets/e34cc7bb-e1fd-4fa6-9130-ebb5450aa319)
           - 병렬 빌드 및 테스트는 빌드 프로세스와 테스트 단계를 동시에 실행함으로써 전체 파이프라인 시간을 단축하는 방법
           - 개별적으로 순차적으로 실행될 때 10분씩 걸리던 빌드와 테스트가 병렬로 실행되면, 그 합계 시간 대신 가장 오래 걸리는 작업만큼의 시간만 소요
          
        - Jenkinsfile 수정 : Dokcer cache 재활용
          ![image](https://github.com/user-attachments/assets/30e38568-da77-4f43-8275-45202022454a)
          1. --cache-from 명령어를 사용해서 캐시를 재활용하여 빌드하도록 설정

        - Dockerfile 수정 : 멀티스테이지 빌드 및 cache 재활용
          ![image](https://github.com/user-attachments/assets/e6dc6dfb-1145-4d99-9653-e1bb68f2dd47)
          ![image](https://github.com/user-attachments/assets/2c9020d0-4a72-4352-86cf-9b53bf4954d5)
          1. 빌드단계에서는 파이썬 말고 JDK까지 여러 가지를 설치했지만, 최종단계에서는 불필요한 부분들을 없애고 python 3.8만 남겨서 이미지 경량화
          2. -no-cache-dir -r에서 캐시파일 제거 및 멀티빌드 활용

  ### 5. 실제 배포시간 최적화
      - 최적화 이전
  ![image](https://github.com/user-attachments/assets/d4a176ab-ec40-477e-a0aa-e4af487844b1)
  ![image](https://github.com/user-attachments/assets/4f6917a7-22cb-4ec1-93fb-91c5e030ac6d)
  : 빌드 및 배포까지 2분 4초 소요

      - 최적화 이후
  ![image](https://github.com/user-attachments/assets/e0926fe8-61b1-456b-89fd-ae5aa43fdb65)
  ![image](https://github.com/user-attachments/assets/2dad33d0-7c25-4a02-bd1a-1afe4432a26b)
  : 빌드 및 배포까지 1분 38초 소요, 약 30초가량 배포시간 최소화




      

          





    



        
        

     


     


  




 
