from sqlalchemy import create_engine, text

# PostgreSQL connection details
DB_NAME = "finsight_db"
DB_USER = "postgres"
DB_HOST = "localhost"
DB_PORT = "5432"

# Enter the PostgreSQL password you created during installation

DB_PASSWORD = "1234" # Replace with your actual password

DATABASE_URL = (
    f"postgresql+psycopg://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

engine = create_engine(DATABASE_URL)

# Test the connection
with engine.connect() as connection:
    result = connection.execute(text("SELECT version();"))
    print("PostgreSQL connection successful!")
    print(result.fetchone()[0])

