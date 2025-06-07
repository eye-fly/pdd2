import os
from kafka import KafkaProducer
import pandas as pd
import json
import time
from dotenv import load_dotenv
import heapq

from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, window, lit
from pyspark.sql.types import StructType, StringType, TimestampType, IntegerType


# load_dotenv(dotenv_path=os.path.expanduser("~/.bashrc"), override=True)
# os.environ["SHELL"] = "/usr/bin/bash"
# os.environ["JAVA_HOME"] = "/usr/lib/jvm/java-11-openjdk-amd64"
# os.environ["JAVA_HOME"] = "/usr/lib/jvm/java-17-openjdk-amd64"
# os.environ["SPARK_HOME"] = "/opt/spark"


master_url = os.environ.get("SPARK_MASTER_URL", "spark://localhost:7077")


trip_schema = StructType() \
    .add("trip_id", StringType()) \
    .add("timestamp", TimestampType()) \
    .add("event", StringType()) \
    .add("PULocationID", IntegerType()) \
    .add("DOLocationID", IntegerType()) \
    .add("passenger_count", IntegerType())

print("done")



print(master_url)
# try:
#     spark.stop()
# except:
#     pass
spark = SparkSession.builder \
    .appName("TaxiTripStream") \
    .master(master_url) \
     .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1") \
    .getOrCreate()


# print(spark.sparkContext._jsc.sc().listJars())

df_raw = spark.readStream.format("kafka") \
    .option("kafka.bootstrap.servers", "34.118.14.52:9092") \
    .option("subscribe", "trips-start") \
    .option("startingOffsets", "earliest") \
    .load()



df_parsed = df_raw.selectExpr("CAST(value AS STRING)") \
    .select(from_json(col("value"), trip_schema).alias("data")) \
    .select(a"data.*")

query = df_parsed.writeStream \
    .format("console") \
    .outputMode("append") \
    .option("truncate", False) \
    .start()

query.awaitTermination(3)
query.stop()
