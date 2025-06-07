import os
from kafka import KafkaProducer
import pandas as pd
import json
import time
from dotenv import load_dotenv
import heapq

load_dotenv(dotenv_path=os.path.expanduser("~/.bashrc"), override=True)




broker_list = os.environ.get("KAFKA_BROKERS", "localhost:9092").split(",")
print(broker_list)
producer = KafkaProducer(bootstrap_servers=broker_list,value_serializer=lambda v: json.dumps(v).encode('utf-8'))

master_url = os.environ.get("SPARK_MASTER_URL", "spark://localhost:7077")

#spark = SparkSession.builder \
#    .appName("TaxiTripStream") \
#    .master(master_url).getOrCreate()

df = pd.read_parquet('~/taxi_files/yellow_tripdata_2025-02.parquet')
df = df.head(10000)

# df["trip_id"] = [str(uuid.uuid4()) for _ in range(len(df))]
df["trip_id"] = [id for id in range(len(df))]

start_df = df[["trip_id", "tpep_pickup_datetime", "PULocationID", "DOLocationID", "passenger_count"]].copy()
start_df["event"] = "start"
start_df.rename(columns={"tpep_pickup_datetime": "timestamp"}, inplace=True)

end_df = df[["trip_id", "tpep_dropoff_datetime", "PULocationID", "DOLocationID", "total_amount"]].copy()
end_df["event"] = "end"
end_df.rename(columns={"tpep_dropoff_datetime": "timestamp"}, inplace=True)

start_df = start_df.sort_values("timestamp")
end_df = end_df.sort_values("timestamp")
merged_stream = heapq.merge(
    start_df.to_dict(orient="records"),
    end_df.to_dict(orient="records"),
    key=lambda x: x["timestamp"]
)

SPEEDUP = 60.0*3
start_time = stream_df.iloc[0]["timestamp"]
real_start = time.time()

for row in merged_stream:
    logical_elapsed = (row["timestamp"] - start_time).total_seconds()
    target_time = real_start + logical_elapsed / SPEEDUP
    sleep_duration = target_time - time.time()

    if sleep_duration > 0:
        time.sleep(sleep_duration)

    print(row)
    topic = "trips-start" if row["event"] == "start" else "trips-end"
    # msg = row.drop("timestamp").to_dict()
    msg = row.copy()
    msg["timestamp"] = row["timestamp"].isoformat()
    producer.send(topic, key=str(row["trip_id"]).encode("utf-8") , value=msg)
    # print(f"[{row['event'].upper()}] {msg['trip_id']} @ {row['timestamp']}")

producer.flush()
