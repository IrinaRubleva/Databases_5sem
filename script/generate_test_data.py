import random
import datetime
import getpass
from decimal import Decimal
import psycopg2
from psycopg2.extras import execute_values
from faker import Faker

DB_NAME = "samokatka"
DB_USER = "postgres"
DB_HOST = "localhost"
DB_PORT = "5432"

SCALE = {
    "darkstores": 3,
    "vendors": 10,
    "products": 50,
    "employees": 15,
    "customers": 200,
    "orders_per_customer": 10,
    "batches_per_product": 3,
    "promotions": 8
}

fake = Faker("ru_RU")

CATEGORIES = [
    'sweets and desserts', 'cooked food', 'vegetables and greens',
    'berries', 'fruits', 'bread and pastries', 'meat and poultry',
    'dairy products and eggs', 'seafood', 'sausage and delicacies',
    'drinks', 'ice cream', 'frozen food', 'cheeses',
    'nuts, chips and snacks', 'spices and oils', 'household goods',
    'vegetarian and lenten', 'pet supplies', 'cosmetics and hygiene products'
]

WEIGHTED_CATEGORIES = {
    'vegetables and greens', 'berries', 'fruits',
    'meat and poultry', 'seafood'
}


def get_connection():
    password = getpass.getpass(f"Введите пароль для пользователя '{DB_USER}' базы '{DB_NAME}': ")
    return psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=password,
        host=DB_HOST,
        port=DB_PORT
    )


def generate_darkstores(cur, count: int):
    data = []
    for i in range(count):
        address = fake.address().replace('\n', ', ')[:200]
        zone = f"Зона {i + 1}"
        status = random.choice(['Active', 'Passive']) if i > 0 else 'Active'
        data.append((address, zone, status))

    query = """
        INSERT INTO DarkStore (address, service_zone, status)
        VALUES %s RETURNING ID_Darkstore, address
    """
    execute_values(cur, query, data, page_size=100)
    rows = cur.fetchall()
    print(f"DarkStores: {len(rows)}")
    return [(r[0], r[1]) for r in rows]


def generate_vendors(cur, count: int):
    data = []
    used_inns = set()
    used_emails = set()

    for _ in range(count):
        inn = str(random.randint(1000000000, 9999999999))
        while inn in used_inns:
            inn = str(random.randint(1000000000, 9999999999))
        used_inns.add(inn)

        name = fake.company()[:100]
        email = fake.unique.email()[:100]
        while email in used_emails:
            email = fake.unique.email()[:100]
        used_emails.add(email)

        coop_status = random.choices(['Cooperate', 'Rejected'], weights=[85, 15])[0]
        data.append((inn, name, email, coop_status))

    query = """
        INSERT INTO Vendor (inn, name_, email, cooperation_status)
        VALUES %s RETURNING ID_Vendor
    """
    execute_values(cur, query, data, page_size=100)
    vendor_ids = [r[0] for r in cur.fetchall()]
    print(f"Vendors: {len(vendor_ids)}")
    return vendor_ids


def generate_products(cur, count: int):
    data = []
    for _ in range(count):
        name = fake.word().capitalize() + " " + fake.word()
        name = name[:100]
        cat = random.choice(CATEGORIES)
        unit = random.choice(['kg', 'l', 'ml', 'pcs'])
        is_weighted = cat in WEIGHTED_CATEGORIES
        status = random.choices(['Active', 'Removed'], weights=[90, 10])[0]
        data.append((name, cat, unit, is_weighted, status))

    query = """
        INSERT INTO Product (name_, category, unit, is_weighted, status)
        VALUES %s RETURNING ID_Product
    """
    execute_values(cur, query, data, page_size=100)
    product_ids = [r[0] for r in cur.fetchall()]
    print(f"Products: {len(product_ids)}")
    return product_ids


def generate_employees(cur, count: int):
    data = []
    used_phones = set()
    used_passports = set()
    used_emails = set()
    positions = ['Сборщик', 'Курьер', 'Менеджер даркстора', 'Старший сборщик']

    for _ in range(count):
        full_name = fake.name()[:200]
        pos = random.choice(positions)

        phone = str(random.randint(79000000000, 79999999999))
        while phone in used_phones:
            phone = str(random.randint(79000000000, 79999999999))
        used_phones.add(phone)

        series = str(random.randint(1000, 9999))
        number = str(random.randint(100000, 999999))
        passport = f"{series} {number}"
        while passport in used_passports:
            series = str(random.randint(1000, 9999))
            number = str(random.randint(100000, 999999))
            passport = f"{series} {number}"
        used_passports.add(passport)

        email = fake.unique.email()[:100]
        while email in used_emails:
            email = fake.unique.email()[:100]
        used_emails.add(email)

        max_weight = round(random.uniform(10, 30), 3) if pos == 'Курьер' else None
        status = random.choices(['Active', 'On Leave', 'Dismissed'], weights=[80, 10, 10])[0]
        data.append((full_name, pos, phone, passport, email, max_weight, status))

    query = """
        INSERT INTO Employee (full_name, position_, phone_number, passport, 
                              email, max_carrying_weight, status)
        VALUES %s RETURNING ID_Employee, position_
    """
    execute_values(cur, query, data, page_size=100)
    rows = cur.fetchall()

    pickers = [r[0] for r in rows if r[1] in ('Сборщик', 'Старший сборщик')]
    couriers = [r[0] for r in rows if r[1] == 'Курьер']
    managers = [r[0] for r in rows if r[1] == 'Менеджер даркстора']

    print(f"Employees: {len(rows)} (pickers: {len(pickers)}, couriers: {len(couriers)})")
    return pickers, couriers, managers


def generate_customers(cur, count: int):
    data = []
    used_phones = set()
    used_emails = set()

    for _ in range(count):
        phone = str(random.randint(79000000000, 79999999999))
        while phone in used_phones:
            phone = str(random.randint(79000000000, 79999999999))
        used_phones.add(phone)

        email = fake.unique.email()[:100]
        while email in used_emails:
            email = fake.unique.email()[:100]
        used_emails.add(email)

        pwd_hash = f"$2b$12${fake.password(length=24)}"
        full_name = fake.name()
        reg_date = fake.date_time_between(start_date='-2y', end_date='now')
        data.append((phone, email, pwd_hash, full_name, reg_date))

    query = """
        INSERT INTO Customer (phone_number, email, password_hash, full_name, registered_at)
        VALUES %s RETURNING ID_Customer
    """
    execute_values(cur, query, data, page_size=100)
    customer_ids = [r[0] for r in cur.fetchall()]
    print(f"Customers: {len(customer_ids)}")
    return customer_ids


def generate_batches(cur, darkstores: list, product_ids: list, vendor_ids: list):
    data = []
    now = datetime.datetime.now(datetime.timezone.utc)

    for ds_id, _ in darkstores:
        for prod_id in product_ids:
            n_batches = random.randint(1, SCALE["batches_per_product"])
            vend_id = random.choice(vendor_ids)

            for b in range(n_batches):
                prod_days_ago = random.randint(5, 60)
                production = now - datetime.timedelta(days=prod_days_ago)
                acceptance = production + datetime.timedelta(hours=random.randint(1, 24))

                shelf_life = random.randint(7, 90)
                expiration = acceptance + datetime.timedelta(days=shelf_life)

                init_qty = round(random.uniform(10, 500), 3)

                if expiration < now:
                    status = 'Expired'
                    balance = round(random.uniform(0, init_qty * 0.3), 3)
                elif (expiration - now).days <= 7:
                    status = 'Available'
                    balance = round(random.uniform(init_qty * 0.1, init_qty * 0.5), 3)
                else:
                    status = 'Available'
                    balance = round(random.uniform(init_qty * 0.5, init_qty), 3)

                priority = random.randint(0, 100)
                data.append((ds_id, prod_id, vend_id, production, acceptance,
                             expiration, init_qty, balance, priority, status))

    query = """
        INSERT INTO Batch (ID_Darkstore, ID_Product, ID_Vendor, production_date,
                           acceptance_date, expiration_date, init_quantity,
                           current_balance, priority, status)
        VALUES %s RETURNING ID_Batch
    """
    execute_values(cur, query, data, page_size=200)
    batch_ids = [r[0] for r in cur.fetchall()]
    print(f"Batches: {len(batch_ids)}")
    return batch_ids


def generate_prices(cur, darkstores: list, product_ids: list):
    data = []
    now = datetime.datetime.now(datetime.timezone.utc)

    for ds_id, _ in darkstores:
        for prod_id in product_ids:
            price = round(random.uniform(30, 2000), 2)
            valid_from = now - datetime.timedelta(days=random.randint(0, 30))
            data.append((prod_id, ds_id, price, 'RUB', valid_from, None))

    query = """
        INSERT INTO Price (ID_Product, ID_Darkstore, price_value, currency, valid_from, valid_to)
        VALUES %s
    """
    execute_values(cur, query, data, page_size=200)
    print(f"Prices: {len(data)}")


def generate_promotions(cur, count: int):
    data = []
    promo_names = [
        'Скидка новичкам', 'Летняя распродажа', 'Черная пятница',
        'Скидка на молочку', 'Фруктовый марафон', 'Бесплатная доставка',
        'Комбо-набор', 'Сезонное предложение'
    ]

    for i in range(min(count, len(promo_names))):
        name = promo_names[i]
        code = f"PROMO{i+1:03d}" if i < 5 else None
        disc_val = round(random.uniform(5, 50), 2)
        disc_type = random.choice(['percent', 'fixed'])
        combinable = random.choice([True, False])
        status = random.choices(['Active', 'Expired', 'Draft'], weights=[60, 30, 10])[0]
        data.append((name, code, disc_val, disc_type, combinable, status))

    query = """
        INSERT INTO Promotion (name_, promo_code, discount_value, discount_type, 
                               is_combinable, status)
        VALUES %s RETURNING ID_Promotion
    """
    execute_values(cur, query, data, page_size=100)
    promo_ids = [r[0] for r in cur.fetchall()]
    print(f"Promotions: {len(promo_ids)}")
    return promo_ids


def generate_orders_and_flow(cur, customer_ids, darkstores, product_ids,
                             pickers, couriers, managers, promo_ids):
    now = datetime.datetime.now(datetime.timezone.utc)
    total_orders = len(customer_ids) * SCALE["orders_per_customer"]
    order_count = 0

    for cust_id in customer_ids:
        ds_id, _ = random.choice(darkstores)
        n_orders = random.randint(1, SCALE["orders_per_customer"])

        for _ in range(n_orders):
            created = now - datetime.timedelta(
                days=random.randint(0, 60),
                hours=random.randint(0, 23),
                minutes=random.randint(0, 59)
            )

            n_positions = random.randint(2, 6)
            chosen_products = random.sample(product_ids, min(n_positions, len(product_ids)))

            planned_amount = Decimal('0')
            total_weight = Decimal('0')
            positions_data = []

            for prod_id in chosen_products:
                qty = round(random.uniform(0.5, 5.0), 3)
                unit_price = round(random.uniform(50, 1500), 2)
                line_total = Decimal(str(qty)) * Decimal(str(unit_price))
                planned_amount += line_total

                is_weighted_prod = random.random() < 0.4
                weight_add = Decimal(str(qty)) if is_weighted_prod else Decimal(str(qty)) * Decimal('0.5')
                total_weight += weight_add

                status = random.choices(
                    ['Planned', 'Substituted', 'Cancelled', 'Assembled'],
                    weights=[40, 20, 10, 30]
                )[0]
                positions_data.append((prod_id, qty, unit_price, status))

            planned_amount = float(planned_amount.quantize(Decimal('0.01')))
            total_weight = float(total_weight.quantize(Decimal('0.001')))

            has_cancelled = any(p[3] == 'Cancelled' for p in positions_data)
            if has_cancelled and random.random() < 0.3:
                final_status = 'Cancelled'
            else:
                final_status = random.choices(
                    ['Confirmed', 'Assembling', 'Ready', 'Delivering', 'Delivered'],
                    weights=[10, 10, 15, 15, 50]
                )[0]

            cur.execute("""
                INSERT INTO Orders (ID_Customer, ID_Darkstore, created_at,
                                    planned_amount, total_weight, status)
                VALUES (%s, %s, %s, %s, %s, %s) RETURNING ID_Order
            """, (cust_id, ds_id, created, planned_amount, total_weight, final_status))
            order_id = cur.fetchone()[0]

            pos_ids = []
            for prod_id, qty, unit_amt, st in positions_data:
                cur.execute("""
                    INSERT INTO OrderPosition (ID_Order, ID_Product, quantity, 
                                               unit_amount, status)
                    VALUES (%s, %s, %s, %s, %s) RETURNING ID_OrderPosition
                """, (order_id, prod_id, qty, unit_amt, st))
                pos_ids.append(cur.fetchone()[0])

            active_pos = [(pid, prod_id, qty, ps) for pid, (prod_id, qty, _, ps) in zip(pos_ids, positions_data)
                          if ps != 'Cancelled']

            reserve_data = []
            expires = created + datetime.timedelta(minutes=30)
            batch_map = {}

            for pos_id, prod_id, qty, _ in active_pos:
                cur.execute("""
                    SELECT ID_Batch FROM Batch 
                    WHERE ID_Darkstore = %s 
                      AND ID_Product = %s 
                      AND current_balance >= %s 
                      AND status = 'Available'
                      AND expiration_date > NOW()
                    ORDER BY expiration_date ASC
                    LIMIT 1
                """, (ds_id, prod_id, qty))

                batch_row = cur.fetchone()
                if batch_row:
                    batch_id = batch_row[0]
                    reserved_qty = round(random.uniform(0.5, min(3.0, qty)), 3)
                    reserve_data.append((batch_id, pos_id, reserved_qty, created, expires, 'Active'))
                    batch_map[pos_id] = batch_id

                    cur.execute("""
                        UPDATE Batch SET current_balance = current_balance - %s 
                        WHERE ID_Batch = %s
                    """, (reserved_qty, batch_id))

            if reserve_data:
                placeholders = ", ".join(["(%s, %s, %s, %s, %s, %s)"] * len(reserve_data))
                flat = [item for row in reserve_data for item in row]
                cur.execute(f"""
                    INSERT INTO Reserve (ID_Batch, ID_OrderPosition, reserved_quantity, 
                                         created_at, expires_at, status) VALUES {placeholders}
                """, flat)
                

            picking_id = None
            if final_status not in ('Cancelled', 'New'):
                picker_id = random.choice(pickers) if pickers else 1
                started = created + datetime.timedelta(minutes=random.randint(5, 30))
                completed = started + datetime.timedelta(minutes=random.randint(10, 45)) \
                    if final_status in ('Ready', 'Delivering', 'Delivered') else None

                pick_status = 'Completed' if completed else 'In Progress'
                cur.execute("""
                    INSERT INTO OrderPicking (ID_Order, ID_Employee, started_at, 
                                              completed_at, status)
                    VALUES (%s, %s, %s, %s, %s) RETURNING ID_OrderPicking
                """, (order_id, picker_id, started, completed, pick_status))
                picking_id = cur.fetchone()[0]

                fulfill_data = []
                actual_total = Decimal('0')
                for pos_id, (prod_id, qty, unit_amt, _) in zip(pos_ids, positions_data):
                    if _ == 'Cancelled':
                        continue

                    batch_id = batch_map.get(pos_id)
                    if not batch_id:
                        continue

                    actual_qty = qty
                    if random.random() < 0.3:
                        deviation = round(random.uniform(-0.2, 0.5), 3)
                        actual_qty = max(0.1, qty + deviation)

                    actual_price = round(float(Decimal(str(actual_qty)) * Decimal(str(unit_amt))), 2)
                    is_repl = random.random() < 0.1
                    actual_total += Decimal(str(actual_price))
                    fulfill_data.append((picking_id, batch_id, pos_id, actual_qty, actual_price, is_repl))

                if fulfill_data:
                    placeholders = ", ".join(["(%s, %s, %s, %s, %s, %s)"] * len(fulfill_data))
                    flat = [item for row in fulfill_data for item in row]
                    cur.execute(f"""
                        INSERT INTO ActualFulfillment
                            (ID_OrderPicking, ID_Batch, ID_OrderPosition,
                             actual_quantity, actual_price, is_replacement)
                        VALUES {placeholders}
                    """, flat)

                final_amt = float(actual_total.quantize(Decimal('0.01')))
                cur.execute("UPDATE Orders SET final_amount = %s WHERE ID_Order = %s",
                            (final_amt, order_id))

            if final_status != 'Cancelled':
                auth_amt = planned_amount
                cur.execute("""
                    INSERT INTO Transactions (ID_Order, operation_type, amount, currency, status)
                    VALUES (%s, 'Authorization', %s, 'RUB', 'Success')
                """, (order_id, auth_amt))

                cap_amt = final_amt if final_amt else auth_amt
                cur.execute("""
                    INSERT INTO Transactions (ID_Order, operation_type, amount, currency, status)
                    VALUES (%s, 'Capture', %s, 'RUB', 'Success')
                """, (order_id, cap_amt))

                if final_amt and abs(final_amt - auth_amt) > 0.01:
                    corr = round(final_amt - auth_amt, 2)
                    cur.execute("""
                        INSERT INTO Transactions (ID_Order, operation_type, amount, currency, status)
                        VALUES (%s, 'Correction', %s, 'RUB', 'Success')
                    """, (order_id, corr))

            if promo_ids and random.random() < 0.3:
                promo_id = random.choice(promo_ids)
                disc = round(random.uniform(5, 50), 2)
                cur.execute("""
                    INSERT INTO AppliedPromotion (ID_Promotion, ID_Order, 
                                                  applied_discount, applied_at)
                    VALUES (%s, %s, %s, %s)
                """, (promo_id, order_id, disc, created))

            if final_status in ('Delivering', 'Delivered') and couriers:
                courier_id = random.choice(couriers)
                max_w = round(random.uniform(15, 30), 3)

                cur.execute("""
                    INSERT INTO CourierRoute (ID_Employee, ID_Darkstore, route_date,
                                              max_weight, current_weight, status)
                    VALUES (%s, %s, %s, %s, %s, 'Active')
                    RETURNING ID_CourierRoute
                """, (courier_id, ds_id, created, max_w, round(total_weight * 0.8, 3)))
                route_id = cur.fetchone()[0]

                handed = created + datetime.timedelta(minutes=random.randint(40, 90))
                arrived = handed + datetime.timedelta(minutes=random.randint(10, 30)) \
                    if final_status == 'Delivered' else None
                delivered = arrived + datetime.timedelta(minutes=random.randint(5, 15)) \
                    if final_status == 'Delivered' else None

                del_status = 'Delivered' if final_status == 'Delivered' else 'On Way'
                cancel_reason = None if del_status != 'Cancelled' else fake.sentence()[:100]

                cur.execute("""
                    INSERT INTO OrderDelivery (ID_Order, ID_CourierRoute,
                                               handed_to_courier_at, arrived_at, delivered_at,
                                               cancellation_reason, status, route_position)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, 1)
                """, (order_id, route_id, handed, arrived, delivered, cancel_reason, del_status))

            order_count += 1
            if order_count % 50 == 0:
                print(f"Orders processed: {order_count}/{total_orders}")

    print(f"Orders & Flow: {order_count}")


def generate_writeoffs(cur, darkstores, product_ids, vendor_ids, managers):
    now = datetime.datetime.now(datetime.timezone.utc)

    for ds_id, _ in darkstores:
        for prod_id in random.sample(product_ids, min(5, len(product_ids))):
            vend_id = random.choice(vendor_ids)
            mgr_id = random.choice(managers) if managers else 1

            prod_days_ago = random.randint(60, 120)
            production = now - datetime.timedelta(days=prod_days_ago)
            acceptance = production + datetime.timedelta(hours=12)
            expiration = acceptance + datetime.timedelta(days=random.randint(7, 30))

            if expiration >= now:
                expiration = now - datetime.timedelta(days=random.randint(1, 10))

            init_qty = round(random.uniform(5, 50), 3)

            cur.execute("""
                INSERT INTO Batch (ID_Darkstore, ID_Product, ID_Vendor, production_date,
                                   acceptance_date, expiration_date, init_quantity,
                                   current_balance, priority, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 0, 'Expired')
                RETURNING ID_Batch
            """, (ds_id, prod_id, vend_id, production, acceptance, expiration,
                  init_qty, init_qty))
            batch_id = cur.fetchone()[0]

            wo_qty = round(random.uniform(1, init_qty), 3)
            reason = random.choice([
                'Истек срок годности', 'Повреждение упаковки',
                'Несоответствие качества', 'Пересорт'
            ])
            conf_status = random.choices(['Confirmed', 'Pending'], weights=[80, 20])[0]

            cur.execute("""
                INSERT INTO WriteOff (ID_Batch, ID_Employee, quantity, reason, confirmation_status)
                VALUES (%s, %s, %s, %s, %s)
            """, (batch_id, mgr_id, wo_qty, reason, conf_status))

            cur.execute("""
                UPDATE Batch SET current_balance = current_balance - %s,
                                 status = CASE WHEN current_balance - %s <= 0
                                               THEN 'Written Off' ELSE status END
                WHERE ID_Batch = %s
            """, (wo_qty, wo_qty, batch_id))

    print("Write-offs generated")


def main():
    print("Starting test data generation...")
    conn = get_connection()
    cur = conn.cursor()

    try:
        darkstores = generate_darkstores(cur, SCALE["darkstores"])
        vendors = generate_vendors(cur, SCALE["vendors"])
        products = generate_products(cur, SCALE["products"])
        pickers, couriers, managers = generate_employees(cur, SCALE["employees"])
        customers = generate_customers(cur, SCALE["customers"])
        promos = generate_promotions(cur, SCALE["promotions"])

        generate_prices(cur, darkstores, products)
        batches = generate_batches(cur, darkstores, products, vendors)
        generate_orders_and_flow(cur, customers, darkstores, products,
                                 pickers, couriers, managers, promos)
        generate_writeoffs(cur, darkstores, products, vendors, managers)

        conn.commit()
        print("Data generation completed successfully.")

    except Exception as e:
        conn.rollback()
        print(f"Error during generation: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()