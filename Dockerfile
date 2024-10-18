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
COPY crime_prediction.py .

# 기본 명령어 설정 (컨테이너 실행 시 crime_prediction.py 실행)
CMD ["python", "crime_prediction.py"]
