from pathlib import Path
from sqlalchemy import text
from db_connection import engine

RAW_DATA_DIR = Path("data/raw")


def clear_tables():
    print("\nClearing existing FinSight data...")

    with engine.begin() as connection:
        connection.execute(
            text("""
                TRUNCATE TABLE
                    product_events,
                    transactions,
                    support_tickets,
                    products,
                    users
                RESTART IDENTITY CASCADE;
            """)
        )

    print("Existing data cleared successfully.")


def copy_csv_to_postgres(file_name, table_name):
    file_path = RAW_DATA_DIR / file_name

    print(f"\nLoading {file_name} -> {table_name}")

    raw_connection = engine.raw_connection()

    try:
        cursor = raw_connection.cursor()

        with open(file_path, "rb") as file:
            with cursor.copy(
                f"""
                COPY {table_name}
                FROM STDIN
                WITH (
                    FORMAT CSV,
                    HEADER TRUE,
                    NULL ''
                )
                """
            ) as copy:

                while data := file.read(1024 * 1024):
                    copy.write(data)

        raw_connection.commit()

        print(f"Successfully loaded {table_name}")

    except Exception:
        raw_connection.rollback()
        raise

    finally:
        cursor.close()
        raw_connection.close()


# --------------------------------
# Clear old database
# --------------------------------

clear_tables()


# --------------------------------
# Parent tables first
# --------------------------------

copy_csv_to_postgres(
    "users.csv",
    "users"
)

copy_csv_to_postgres(
    "products.csv",
    "products"
)


# --------------------------------
# Dependent tables
# --------------------------------

copy_csv_to_postgres(
    "transactions.csv",
    "transactions"
)

copy_csv_to_postgres(
    "product_events_clean.csv",
    "product_events"
)

copy_csv_to_postgres(
    "support_tickets.csv",
    "support_tickets"
)

print("\nFinSight bulk loading completed!")


