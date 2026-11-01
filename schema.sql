DROP TABLE IF EXISTS WriteOff CASCADE;
DROP TABLE IF EXISTS OrderDelivery CASCADE;
DROP TABLE IF EXISTS CourierRoute CASCADE;
DROP TABLE IF EXISTS Transactions CASCADE;
DROP TABLE IF EXISTS ActualFulfillment CASCADE;
DROP TABLE IF EXISTS OrderPicking CASCADE;
DROP TABLE IF EXISTS SubstitutionDecision CASCADE;
DROP TABLE IF EXISTS SubstitutionOffer CASCADE;
DROP TABLE IF EXISTS Reserve CASCADE;
DROP TABLE IF EXISTS AppliedPromotion CASCADE;
DROP TABLE IF EXISTS OrderPosition CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS Batch CASCADE;
DROP TABLE IF EXISTS Price CASCADE;
DROP TABLE IF EXISTS Promotion CASCADE;
DROP TABLE IF EXISTS Employee CASCADE;
DROP TABLE IF EXISTS Customer CASCADE;
DROP TABLE IF EXISTS Vendor CASCADE;
DROP TABLE IF EXISTS Product CASCADE;
DROP TABLE IF EXISTS DarkStore CASCADE;

DROP TYPE IF EXISTS category_product CASCADE;

CREATE TYPE category_product AS ENUM (
    'sweets and desserts', 'cooked food', 'vegetables and greens',
    'berries', 'fruits', 'bread and pastries', 'meat and poultry', 
    'dairy products and eggs', 'seafood', 'sausage and delicacies',
    'drinks', 'ice cream', 'frozen food', 'cheeses', 'nuts, chips and snacks',
    'spices and oils', 'household goods', 'vegetarian and lenten', 
    'pet supplies', 'cosmetics and hygiene products'
);

CREATE TABLE DarkStore (
    ID_Darkstore int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address VARCHAR(200) NOT NULL UNIQUE,
    service_zone text NOT NULL,
    status varchar(10) DEFAULT 'Active',
    CONSTRAINT darkstore_status_check CHECK (status IN ('Active', 'Passive'))
);

CREATE TABLE Product (
    ID_Product int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name_ VARCHAR(100) NOT NULL, 
    category category_product NOT NULL, 
    unit text NOT NULL,
    is_weighted boolean NOT NULL DEFAULT false,
    status varchar(10) DEFAULT 'Active',
    CONSTRAINT product_unit_check CHECK (unit IN ('kg', 'l', 'ml', 'pcs')),
    CONSTRAINT product_status_check CHECK (status IN ('Active', 'Removed'))
);

CREATE TABLE Vendor (
    ID_Vendor int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inn varchar(12) NOT NULL UNIQUE,
    name_ varchar(100) NOT NULL,
    email varchar(100) NOT NULL UNIQUE,
    cooperation_status varchar(10) DEFAULT 'Cooperate',
    CONSTRAINT vendor_inn_check CHECK (inn ~ '^[0-9]{10}$|^[0-9]{12}$'),
    CONSTRAINT vendor_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT vendor_coop_status_check CHECK (cooperation_status IN ('Cooperate', 'Rejected'))
);

CREATE TABLE Customer (
    ID_Customer int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    phone_number varchar(12) NOT NULL UNIQUE,
    email varchar(100) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    full_name text,
    registered_at timestamptz DEFAULT NOW(),
    CONSTRAINT customer_phone_check CHECK (phone_number ~ '^\+?[0-9]{10,11}$'),
    CONSTRAINT customer_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE TABLE Employee (
    ID_Employee int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    position_ text NOT NULL,
    phone_number varchar(12),
    passport varchar(11) NOT NULL UNIQUE,
    email varchar(100) NOT NULL UNIQUE,
    max_carrying_weight numeric(10, 3), 
    status varchar(20) DEFAULT 'Active',
    CONSTRAINT employee_status_check CHECK (status IN ('Active', 'On Leave', 'Dismissed')),
    CONSTRAINT employee_phone_check CHECK (phone_number IS NULL OR phone_number ~ '^\+?[0-9]{10,11}$'),
    CONSTRAINT employee_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT employee_passport_check CHECK (passport ~ '^\d{4} \d{6}$')
);

CREATE TABLE Promotion (
    ID_Promotion int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name_ text NOT NULL,
    promo_code varchar(20),
    discount_value numeric(12, 2) NOT NULL,
    discount_type text NOT NULL,
    is_combinable boolean DEFAULT true,
    status text DEFAULT 'Active',
    CONSTRAINT promotion_discount_type_check CHECK (discount_type IN ('percent', 'fixed')),
    CONSTRAINT promotion_status_check CHECK (status IN ('Active', 'Expired', 'Draft')),
    CONSTRAINT promotion_value_check CHECK (discount_value > 0)
);

CREATE TABLE Price (
    ID_Price int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Product int NOT NULL,
    ID_Darkstore int NOT NULL,
    price_value numeric(12, 2) NOT NULL,
    currency text DEFAULT 'RUB',
    valid_from timestamptz NOT NULL DEFAULT NOW(),
    valid_to timestamptz,
    FOREIGN KEY (ID_Product) REFERENCES Product(ID_Product) ON DELETE CASCADE,
    FOREIGN KEY (ID_Darkstore) REFERENCES DarkStore(ID_Darkstore) ON DELETE CASCADE,
    CONSTRAINT price_value_check CHECK (price_value >= 0)
);

CREATE TABLE Batch (
    ID_Batch int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Darkstore int NOT NULL,
    ID_Product int NOT NULL,
    ID_Vendor int NOT NULL,
    production_date timestamptz NOT NULL, 
    acceptance_date timestamptz NOT NULL DEFAULT NOW(),
    expiration_date timestamptz NOT NULL,
    init_quantity numeric(12, 3) NOT NULL, 
    current_balance numeric(12, 3) NOT NULL DEFAULT 0, 
    priority int DEFAULT 0,
    status text DEFAULT 'Available',
    FOREIGN KEY (ID_Darkstore) REFERENCES DarkStore(ID_Darkstore) ON DELETE CASCADE,
    FOREIGN KEY (ID_Product) REFERENCES Product(ID_Product) ON DELETE CASCADE,
    FOREIGN KEY (ID_Vendor) REFERENCES Vendor(ID_Vendor) ON DELETE CASCADE,
    CONSTRAINT batch_qty_check CHECK (init_quantity >= 0 AND current_balance >= 0),
    CONSTRAINT batch_dates_check CHECK (acceptance_date >= production_date AND expiration_date > acceptance_date),
    CONSTRAINT batch_status_check CHECK (status IN ('Available', 'Reserved', 'Expired', 'Written Off'))
);

CREATE TABLE Orders (
    ID_Order int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Customer int NOT NULL,
    ID_Darkstore int NOT NULL,
    created_at timestamptz DEFAULT NOW(),
    planned_amount numeric(12, 2), 
    final_amount numeric(12, 2),   
    total_weight numeric(10, 3),   
    status text DEFAULT 'New',
    FOREIGN KEY (ID_Customer) REFERENCES Customer(ID_Customer),
    FOREIGN KEY (ID_Darkstore) REFERENCES DarkStore(ID_Darkstore),
    CONSTRAINT order_status_check CHECK (status IN ('New', 'Confirmed', 'Assembling', 'Ready', 'Delivering', 'Delivered', 'Cancelled')),
    CONSTRAINT order_amount_check CHECK (planned_amount >= 0 AND (final_amount IS NULL OR final_amount >= 0))
);

CREATE TABLE OrderPosition (
    ID_OrderPosition int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Order int NOT NULL,
    ID_Product int NOT NULL,
    quantity numeric(10, 3) NOT NULL,
    unit_amount numeric(12, 2), 
    status text DEFAULT 'Planned',
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order) ON DELETE CASCADE,
    FOREIGN KEY (ID_Product) REFERENCES Product(ID_Product),
    CONSTRAINT orderpos_qty_check CHECK (quantity > 0),
    CONSTRAINT orderpos_status_check CHECK (status IN ('Planned', 'Substituted', 'Cancelled', 'Assembled'))
);

CREATE TABLE AppliedPromotion (
    ID_Promotion int NOT NULL,
    ID_Order int NOT NULL,
    applied_discount numeric(12, 2) NOT NULL DEFAULT 0, 
    applied_at timestamptz DEFAULT NOW(),
    PRIMARY KEY (ID_Promotion, ID_Order),
    FOREIGN KEY (ID_Promotion) REFERENCES Promotion(ID_Promotion),
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order) ON DELETE CASCADE,
    CONSTRAINT applied_promo_discount_check CHECK (applied_discount >= 0)
);

CREATE TABLE Reserve (
    ID_Reserve int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Batch int NOT NULL,
    ID_OrderPosition int NOT NULL,
    reserved_quantity numeric(10, 3) NOT NULL,
    created_at timestamptz DEFAULT NOW(),
    expires_at timestamptz NOT NULL,
    status text DEFAULT 'Active',
    FOREIGN KEY (ID_Batch) REFERENCES Batch(ID_Batch) ON DELETE CASCADE,
    FOREIGN KEY (ID_OrderPosition) REFERENCES OrderPosition(ID_OrderPosition) ON DELETE CASCADE,
    CONSTRAINT reserve_qty_check CHECK (reserved_quantity > 0),
    CONSTRAINT reserve_status_check CHECK (status IN ('Active', 'Released', 'Used')),
    CONSTRAINT reserve_time_check CHECK (expires_at > created_at)
);

CREATE TABLE SubstitutionOffer (
    ID_SubstitutionOffer int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_OrderPosition int NOT NULL,
    ID_Product int NOT NULL,
    offered_quantity numeric(10, 3),
    price_difference numeric(12, 2),
    status text DEFAULT 'Pending',
    FOREIGN KEY (ID_OrderPosition) REFERENCES OrderPosition(ID_OrderPosition) ON DELETE CASCADE,
    FOREIGN KEY (ID_Product) REFERENCES Product(ID_Product),
    CONSTRAINT sub_offer_status_check CHECK (status IN ('Pending', 'Accepted', 'Rejected'))
);

CREATE TABLE SubstitutionDecision (
    ID_SubstitutionDecision int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_SubstitutionOffer int NOT NULL,
    ID_Employee int NOT NULL,
    decision_type text NOT NULL,
    decided_at timestamptz DEFAULT NOW(),
    FOREIGN KEY (ID_SubstitutionOffer) REFERENCES SubstitutionOffer(ID_SubstitutionOffer) ON DELETE CASCADE,
    FOREIGN KEY (ID_Employee) REFERENCES Employee(ID_Employee),
    CONSTRAINT decision_type_check CHECK (decision_type IN ('Accept', 'Reject'))
);

CREATE TABLE OrderPicking (
    ID_OrderPicking int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Order int NOT NULL,
    ID_Employee int NOT NULL,
    started_at timestamptz DEFAULT NOW(),
    completed_at timestamptz,
    status text DEFAULT 'In Progress',
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order) ON DELETE CASCADE,
    FOREIGN KEY (ID_Employee) REFERENCES Employee(ID_Employee),
    CONSTRAINT picking_status_check CHECK (status IN ('In Progress', 'Completed', 'Cancelled')),
    CONSTRAINT picking_time_check CHECK (completed_at IS NULL OR completed_at >= started_at)
);

CREATE TABLE ActualFulfillment (
    ID_ActualFulfillment int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_OrderPicking int NOT NULL,
    ID_Batch int NOT NULL,
    ID_OrderPosition int NOT NULL,
    actual_quantity numeric(10, 3) NOT NULL,
    actual_price numeric(12, 2), 
    is_replacement boolean DEFAULT false,
    FOREIGN KEY (ID_OrderPicking) REFERENCES OrderPicking(ID_OrderPicking) ON DELETE CASCADE,
    FOREIGN KEY (ID_Batch) REFERENCES Batch(ID_Batch),
    FOREIGN KEY (ID_OrderPosition) REFERENCES OrderPosition(ID_OrderPosition),
    CONSTRAINT fulfillment_qty_check CHECK (actual_quantity > 0)
);

CREATE TABLE Transactions (
    ID_Transaction int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Order int NOT NULL,
    operation_type varchar(20) NOT NULL,
    amount numeric(12, 2) NOT NULL,
    currency text DEFAULT 'RUB',
    created_at timestamptz DEFAULT NOW(),
    status varchar(20) DEFAULT 'Pending',
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order),
    CONSTRAINT transaction_op_type_check CHECK (operation_type IN ('Authorization', 'Capture', 'Refund', 'Correction')),
    CONSTRAINT transaction_status_check CHECK (status IN ('Pending', 'Success', 'Failed')),
    CONSTRAINT transaction_amount_check CHECK (amount != 0),
    CONSTRAINT transaction_currency_check CHECK (currency IN ('RUB', 'USD', 'EUR', 'CNY'))
);

CREATE TABLE CourierRoute (
    ID_CourierRoute int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Employee int NOT NULL,
    ID_Darkstore int NOT NULL,
    route_date timestamptz DEFAULT NOW(),
    max_weight numeric(10, 3),
    current_weight numeric(10, 3) DEFAULT 0,
    status text DEFAULT 'Planning',
    FOREIGN KEY (ID_Employee) REFERENCES Employee(ID_Employee),
    FOREIGN KEY (ID_Darkstore) REFERENCES DarkStore(ID_Darkstore),
    CONSTRAINT route_weight_check CHECK ((max_weight IS NULL OR current_weight <= max_weight) AND current_weight >= 0),
    CONSTRAINT route_status_check CHECK (status IN ('Planning', 'Active', 'Completed', 'Cancelled'))
);

CREATE TABLE OrderDelivery (
    ID_OrderDelivery int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Order int NOT NULL,
    ID_CourierRoute int NOT NULL,
    handed_to_courier_at timestamptz,
    arrived_at timestamptz,
    delivered_at timestamptz,
    cancellation_reason text,
    status varchar(12) DEFAULT 'Assigned',
    route_position int,
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order),
    FOREIGN KEY (ID_CourierRoute) REFERENCES CourierRoute(ID_CourierRoute),
    CONSTRAINT delivery_status_check CHECK (status IN ('Assigned', 'On Way', 'Arrived', 'Delivered', 'Cancelled', 'Returned')),
    CONSTRAINT delivery_time_logic CHECK (
        (arrived_at IS NULL OR arrived_at >= handed_to_courier_at) AND
        (delivered_at IS NULL OR delivered_at >= arrived_at)
    )
);

CREATE TABLE WriteOff (
    ID_WriteOff int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Batch int NOT NULL,
    ID_Employee int NOT NULL,
    quantity numeric(10, 3) NOT NULL,
    reason text,
    created_at timestamptz DEFAULT NOW(),
    confirmation_status varchar(12) DEFAULT 'Pending',
    FOREIGN KEY (ID_Batch) REFERENCES Batch(ID_Batch),
    FOREIGN KEY (ID_Employee) REFERENCES Employee(ID_Employee),
    CONSTRAINT writeoff_qty_check CHECK (quantity > 0),
    CONSTRAINT writeoff_conf_status_check CHECK (confirmation_status IN ('Pending', 'Confirmed', 'Rejected'))
);