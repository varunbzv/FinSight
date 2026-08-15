import pandas as pd

input_file = "data/raw/product_events.csv"
output_file = "data/raw/product_events_clean.csv"

print("Cleaning product_events.csv...")

first_chunk = True

for chunk in pd.read_csv(input_file, chunksize=100_000):

    # Convert product_id from values like 1.0 to integer 1.
    # Missing product IDs remain blank.
    chunk["product_id"] = chunk["product_id"].astype("Int64")

    chunk.to_csv(
        output_file,
        mode="w" if first_chunk else "a",
        header=first_chunk,
        index=False
    )

    first_chunk = False

    print(f"Processed {len(chunk):,} rows")

print("Clean product events file created successfully.")
