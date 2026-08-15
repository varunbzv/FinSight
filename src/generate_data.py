import pandas as pd
import numpy as np
from pathlib import Path

# Make the generated data reproducible
np.random.seed(42)

# Number of users we want to generate
NUM_USERS = 50_000

# Project directories
PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

# Make sure the raw-data folder exists
RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)

print("FinSight data generation started...")

# -----------------------------
# Generate users
# -----------------------------

user_ids = np.arange(1, NUM_USERS + 1)

signup_dates = pd.to_datetime(
    np.random.choice(
        pd.date_range("2024-01-01", "2025-12-31"),
        size=NUM_USERS
    )
)

age_groups = np.random.choice(
    ["18-24", "25-34", "35-44", "45-54", "55+"],
    size=NUM_USERS,
    p=[0.20, 0.35, 0.25, 0.12, 0.08]
)

cities = np.random.choice(
    ["Delhi", "Mumbai", "Bengaluru", "Hyderabad", "Pune",
     "Chennai", "Kolkata", "Ahmedabad", "Jaipur", "Lucknow"],
    size=NUM_USERS
)

device_types = np.random.choice(
    ["Android", "iOS", "Web"],
    size=NUM_USERS,
    p=[0.55, 0.30, 0.15]
)

acquisition_channels = np.random.choice(
    ["Organic", "Google Ads", "Instagram", "YouTube", "Referral", "Partner"],
    size=NUM_USERS,
    p=[0.25, 0.20, 0.15, 0.10, 0.20, 0.10]
)

kyc_status = np.random.choice(
    ["Completed", "Pending", "Failed"],
    size=NUM_USERS,
    p=[0.78, 0.15, 0.07]
)

kyc_completed_at = pd.Series(pd.NaT, index=range(NUM_USERS))

completed_mask = kyc_status == "Completed"

kyc_completed_at.loc[completed_mask] = (
    signup_dates[completed_mask]
    + pd.to_timedelta(
        np.random.randint(1, 72, size=completed_mask.sum()),
        unit="h"
    )
)

account_status = np.random.choice(
    ["Active", "Inactive"],
    size=NUM_USERS,
    p=[0.72, 0.28]
)

users = pd.DataFrame({
    "user_id": user_ids,
    "signup_date": signup_dates,
    "age_group": age_groups,
    "city": cities,
    "device_type": device_types,
    "acquisition_channel": acquisition_channels,
    "kyc_status": kyc_status,
    "kyc_completed_at": kyc_completed_at,
    "account_status": account_status
})

print(f"Users generated: {len(users):,}")

users.to_csv(
    RAW_DATA_DIR / "users.csv",
    index=False
)


print("users.csv saved successfully.")


# --------------------------------
# Generate Products
# --------------------------------

products = pd.DataFrame({
    "product_id": range(1, 7),

    "product_name": [
        "Payments",
        "Savings",
        "Investments",
        "Credit",
        "Insurance",
        "Bill Payments"
    ],

    "product_category": [
        "Payments",
        "Savings",
        "Investments",
        "Credit",
        "Insurance",
        "Payments"
    ],

    "launch_date": pd.to_datetime([
        "2024-01-01",
        "2024-03-01",
        "2024-06-01",
        "2024-09-01",
        "2025-01-01",
        "2024-02-01"
    ])
})

print(f"Products generated: {len(products)}")

products.to_csv(
    RAW_DATA_DIR / "products.csv",
    index=False
)

print("products.csv saved successfully.")


# --------------------------------
# Generate Transactions
# --------------------------------

print("Generating retention-aware transactions...")

transactions = []

transaction_id = 1

# Retention probability by month after signup
RETENTION_PROBABILITY = {
    0: 0.80,
    1: 0.60,
    2: 0.48,
    3: 0.40,
    4: 0.35,
    5: 0.31,
    6: 0.28,
}

# Generate transactions for each user
for _, user in users.iterrows():

    user_id = user["user_id"]
    signup_date = pd.Timestamp(user["signup_date"])

    # Users can remain active for up to 18 months
    for month_offset in range(18):

        activity_month = (
            signup_date.to_period("M").to_timestamp()
            + pd.DateOffset(months=month_offset)
        )

        # Don't generate activity beyond the dataset period
        if activity_month > pd.Timestamp("2025-12-31"):
            break

        # Retention probability decreases over time
        if month_offset <= 6:
            retention_probability = RETENTION_PROBABILITY[month_offset]
        else:
            retention_probability = max(
                0.08,
                0.28 - (month_offset - 6) * 0.025
            )

        # Decide whether the user is active this month
        if np.random.random() > retention_probability:
            continue

        # Number of transactions for an active user
        num_transactions = np.random.poisson(2) + 1

        for _ in range(num_transactions):


            # Determine valid activity window within the calendar month
            month_start = activity_month
            month_end = activity_month + pd.offsets.MonthEnd(0)

            if month_offset == 0:
                activity_start = max(
                    signup_date,
                    month_start
                )
            else:
                activity_start = month_start

            days_available = (
                month_end.normalize() - activity_start.normalize()
            ).days

            if days_available < 0:
                continue

            transaction_date = (
                activity_start
                + pd.Timedelta(
                    days=np.random.randint(0, days_available + 1),
                    hours=np.random.randint(0, 24),
                    minutes=np.random.randint(0, 60)
                )
            )

            # Don't create transactions after the dataset end date
            if transaction_date > pd.Timestamp("2025-12-31 23:59:59"):
                continue

            product_id = np.random.choice(
                products["product_id"].values,
                p=[0.40, 0.18, 0.12, 0.12, 0.08, 0.10]
            )

            amount = round(
                np.random.lognormal(
                    mean=np.log(1500),
                    sigma=0.45
                ),
                2
            )

            status = np.random.choice(
                ["Successful", "Failed", "Pending"],
                p=[0.92, 0.06, 0.02]
            )

            transaction_type = np.random.choice(
                ["Purchase", "Payment", "Transfer"],
                p=[0.45, 0.35, 0.20]
            )

            merchant_category = np.random.choice(
                [
                    "Retail",
                    "Food",
                    "Travel",
                    "Utilities",
                    "Healthcare",
                    "Entertainment"
                ]
            )

            payment_method = np.random.choice(
                [
                    "UPI",
                    "Card",
                    "Net Banking",
                    "Wallet"
                ],
                p=[0.50, 0.25, 0.15, 0.10]
            )

            transactions.append({
                "transaction_id": transaction_id,
                "user_id": user_id,
                "product_id": product_id,
                "transaction_date": transaction_date,
                "transaction_type": transaction_type,
                "amount": amount,
                "status": status,
                "merchant_category": merchant_category,
                "payment_method": payment_method
            })

            transaction_id += 1


transactions = pd.DataFrame(transactions)

print(
    f"Transactions generated: "
    f"{len(transactions):,}"
)

transactions.to_csv(
    RAW_DATA_DIR / "transactions.csv",
    index=False
)

print("transactions.csv saved successfully.")



# --------------------------------
# Generate Product Events
# --------------------------------

print("Generating retention-aware product events...")

events = []
event_id = 1

for _, user in users.iterrows():

    user_id = user["user_id"]
    signup_date = pd.Timestamp(user["signup_date"])

    for month_offset in range(18):

        activity_month = (
            signup_date.to_period("M").to_timestamp()
            + pd.DateOffset(months=month_offset)
        )

        if activity_month > pd.Timestamp("2025-12-31"):
            break

        # Same retention curve as transactions
        if month_offset == 0:
            retention_probability = 0.80
        elif month_offset == 1:
            retention_probability = 0.60
        elif month_offset == 2:
            retention_probability = 0.48
        elif month_offset == 3:
            retention_probability = 0.40
        elif month_offset == 4:
            retention_probability = 0.35
        elif month_offset == 5:
            retention_probability = 0.31
        elif month_offset == 6:
            retention_probability = 0.28
        else:
            retention_probability = max(
                0.08,
                0.28 - (month_offset - 6) * 0.025
            )

        # User is inactive during this month
        if np.random.random() > retention_probability:
            continue

        # Number of sessions during active month
        sessions = np.random.poisson(3) + 1

        for _ in range(sessions):

            month_start = activity_month
            month_end = activity_month + pd.offsets.MonthEnd(0)
            
            if month_offset == 0:
                activity_start = max(
                    signup_date,
                    month_start
                )
            else:
                activity_start = month_start
            
            days_available = (
                month_end.normalize() - activity_start.normalize()
            ).days
            
            if days_available < 0:
                continue
            
            session_time = (
                activity_start
                + pd.Timedelta(
                    days=np.random.randint(0, days_available + 1),
                    hours=np.random.randint(0, 24),
                    minutes=np.random.randint(0, 60)
                )
            )

            if session_time > pd.Timestamp("2025-12-31 23:00:00"):
                continue

            # --------------------------------
            # App Open
            # --------------------------------

            events.append({
                "event_id": event_id,
                "user_id": user_id,
                "product_id": None,
                "event_timestamp": session_time,
                "event_type": "app_open"
            })

            event_id += 1

            # --------------------------------
            # Product View
            # --------------------------------

            product_id = np.random.choice(
                products["product_id"].values,
                p=[0.40, 0.18, 0.12, 0.12, 0.08, 0.10]
            )

            view_time = session_time + pd.Timedelta(
                minutes=np.random.randint(1, 5)
            )

            events.append({
                "event_id": event_id,
                "user_id": user_id,
                "product_id": product_id,
                "event_timestamp": view_time,
                "event_type": "product_view"
            })

            event_id += 1

            # --------------------------------
            # Product Click
            # --------------------------------

            if np.random.random() < 0.65:

                click_time = view_time + pd.Timedelta(
                    minutes=np.random.randint(1, 3)
                )

                events.append({
                    "event_id": event_id,
                    "user_id": user_id,
                    "product_id": product_id,
                    "event_timestamp": click_time,
                    "event_type": "product_click"
                })

                event_id += 1

                # --------------------------------
                # Transaction Start
                # --------------------------------

                if np.random.random() < 0.55:

                    start_time = click_time + pd.Timedelta(
                        minutes=np.random.randint(1, 5)
                    )

                    events.append({
                        "event_id": event_id,
                        "user_id": user_id,
                        "product_id": product_id,
                        "event_timestamp": start_time,
                        "event_type": "transaction_start"
                    })

                    event_id += 1

                    # --------------------------------
                    # Transaction Result
                    # --------------------------------

                    result = np.random.choice(
                        [
                            "transaction_success",
                            "transaction_failed"
                        ],
                        p=[0.90, 0.10]
                    )

                    result_time = start_time + pd.Timedelta(
                        minutes=np.random.randint(1, 3)
                    )

                    events.append({
                        "event_id": event_id,
                        "user_id": user_id,
                        "product_id": product_id,
                        "event_timestamp": result_time,
                        "event_type": result
                    })

                    event_id += 1

            # --------------------------------
            # Feature Usage
            # --------------------------------

            if np.random.random() < 0.30:

                feature_time = session_time + pd.Timedelta(
                    minutes=np.random.randint(2, 20)
                )

                events.append({
                    "event_id": event_id,
                    "user_id": user_id,
                    "product_id": product_id,
                    "event_timestamp": feature_time,
                    "event_type": "feature_used"
                })

                event_id += 1


product_events = pd.DataFrame(events)

print(
    f"Product events generated: "
    f"{len(product_events):,}"
)

product_events.to_csv(
    RAW_DATA_DIR / "product_events.csv",
    index=False
)

print("product_events.csv saved successfully.")



# --------------------------------
# Generate Support Tickets
# --------------------------------

NUM_TICKETS = 75_000

print("Generating support tickets...")

ticket_user_ids = np.random.choice(
    users["user_id"].values,
    size=NUM_TICKETS
)

ticket_dates = pd.to_datetime(
    np.random.choice(
        pd.date_range("2024-01-01", "2025-12-31"),
        size=NUM_TICKETS
    )
)

issue_types = np.random.choice(
    [
        "Payment Failed",
        "KYC Issue",
        "Transaction Pending",
        "Account Access",
        "Refund Request",
        "Product Issue",
        "Fraud Concern",
        "Other"
    ],
    size=NUM_TICKETS,
    p=[0.22, 0.12, 0.15, 0.10, 0.12, 0.10, 0.07, 0.12]
)

priorities = np.random.choice(
    ["Low", "Medium", "High", "Critical"],
    size=NUM_TICKETS,
    p=[0.25, 0.45, 0.25, 0.05]
)

resolution_times = np.random.lognormal(
    mean=np.log(8),
    sigma=0.8,
    size=NUM_TICKETS
)

resolution_times = np.clip(
    resolution_times,
    0.5,
    168
)

ticket_statuses = np.random.choice(
    ["Resolved", "Open", "Escalated"],
    size=NUM_TICKETS,
    p=[0.82, 0.12, 0.06]
)

support_tickets = pd.DataFrame({
    "ticket_id": range(1, NUM_TICKETS + 1),
    "user_id": ticket_user_ids,
    "created_at": ticket_dates,
    "issue_type": issue_types,
    "priority": priorities,
    "resolution_time_hours": np.round(resolution_times, 2),
    "status": ticket_statuses
})

print(f"Support tickets generated: {len(support_tickets):,}")

support_tickets.to_csv(
    RAW_DATA_DIR / "support_tickets.csv",
    index=False
)

print("support_tickets.csv saved successfully.")




