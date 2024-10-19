# 빌드 단계
FROM python:3.8-slim AS build

# 작업 디렉터리 설정
WORKDIR /app

# 시스템 패키지 업데이트 및 OpenJDK 17 설치 (스파크에 필요)
RUN apt-get update && apt-get install -y openjdk-17-jdk curl

# Spark 설치 (버전은 Spark 3.1.2)
RUN curl -s https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz | tar -xz -C /opt/
ENV SPARK_HOME=/opt/spark-3.1.2-bin-hadoop3.2
ENV PATH=$SPARK_HOME/bin:$PATH

# Python 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 최종 단계 (최소한의 실행 환경만 유지)
FROM python:3.8-slim

# Spark 및 Python 패키지 복사
COPY --from=build /opt/spark-3.1.2-bin-hadoop3.2 /opt/spark-3.1.2-bin-hadoop3.2
COPY --from=build /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages

# 작업 디렉터리 설정
WORKDIR /app

# 소스 파일 복사
COPY Crime_Predict.py .

# 실행 환경 변수 설정
ENV SPARK_HOME=/opt/spark-3.1.2-bin-hadoop3.2
ENV PATH=$SPARK_HOME/bin:$PATH

# 기본 명령어 설정 (컨테이너 실행 시 Crime_Predict.py 실행)
CMD ["python", "Crime_Predict.py"]
