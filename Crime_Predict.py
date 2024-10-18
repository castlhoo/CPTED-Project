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
