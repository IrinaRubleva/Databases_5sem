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



CREATE TABLE DarkStore (
    ID_Darkstore int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address text NOT NULL,
    service_zone text NOT NULL,
    status text
);

CREATE TABLE Product (
    ID_Product int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name_ text NOT NULL, 
    category text NOT NULL, 
    unit text NOT NULL,
    is_weighted boolean,
    status text,
    CONSTRAINT unit_check CHECK (unit IN ('kg', 'l', 'ml', 'pcs'))
);

CREATE TABLE Vendor (
    ID_Vendor int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inn bigint NOT NULL,
    name_ text NOT NULL,
    email text,
    cooperation_status text
);

CREATE TABLE Customer (
    ID_Customer int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    phone_number text NOT NULL,
    email text UNIQUE,
    password_hash text NOT NULL,
    full_name text,
    registered_at timestamptz DEFAULT NOW()
);

CREATE TABLE Employee (
    ID_Employee int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    position_ text NOT NULL,
    phone_number text,
    max_carrying_weight numeric(10, 3), 
    status text
);

CREATE TABLE Promotion (
    ID_Promotion int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name_ text NOT NULL,
    promo_code text,
    discount_value numeric(12, 2) NOT NULL,
    discount_type text NOT NULL,
    is_combinable boolean DEFAULT true,
    status text,
    CONSTRAINT discount_type_check CHECK (discount_type IN ('percent', 'fixed'))
);


CREATE TABLE Price (
    ID_Price int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Product int,
    ID_Darkstore int,
    price_value numeric(12, 2) NOT NULL,
    currency text DEFAULT 'RUB',
    valid_from timestamptz NOT NULL,
    valid_to timestamptz,
    FOREIGN KEY (ID_Product) REFERENCES Product(ID_Product) ON DELETE CASCADE,
    FOREIGN KEY (ID_Darkstore) REFERENCES DarkStore(ID_Darkstore) ON DELETE CASCADE
);

CREATE TABLE Batch (
    ID_Batch int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Darkstore int,
    ID_Product int,
    ID_Vendor int,
    batch_number text,
    production_date timestamptz NOT NULL, 
    acceptance_date timestamptz NOT NULL,
    expiration_date timestamptz NOT NULL,
    init_quantity numeric(12, 3) NOT NULL, 
    current_balance numeric(12, 3) NOT NULL, 
    priority int DEFAULT 0,
    FOREIGN KEY (ID_Darkstore) REFERENCES DarkStore(ID_Darkstore) ON DELETE CASCADE,
    FOREIGN KEY (ID_Product) REFERENCES Product(ID_Product) ON DELETE CASCADE,
    FOREIGN KEY (ID_Vendor) REFERENCES Vendor(ID_Vendor) ON DELETE CASCADE
);

CREATE TABLE Orders (
    ID_Order int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Customer int,
    ID_Darkstore int,
    created_at timestamptz DEFAULT NOW(),
    planned_amount numeric(12, 2), 
    final_amount numeric(12, 2),   
    total_weight numeric(10, 3),   
    status text,
    FOREIGN KEY (ID_Customer) REFERENCES Customer(ID_Customer),
    FOREIGN KEY (ID_Darkstore) REFERENCES DarkStore(ID_Darkstore)
);

CREATE TABLE OrderPosition (
    ID_OrderPosition int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Order int,
    ID_Product int,
    quantity numeric(10, 3) NOT NULL,
    unit_amount numeric(12, 2), 
    status text,
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order) ON DELETE CASCADE,
    FOREIGN KEY (ID_Product) REFERENCES Product(ID_Product)
);

CREATE TABLE AppliedPromotion (
    ID_Promotion int,
    ID_Order int,
    applied_discount numeric(12, 2), 
    applied_at timestamptz DEFAULT NOW(),
    PRIMARY KEY (ID_Promotion, ID_Order),
    FOREIGN KEY (ID_Promotion) REFERENCES Promotion(ID_Promotion),
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order) ON DELETE CASCADE
);

CREATE TABLE Reserve (
    ID_Reserve int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Batch int,
    ID_OrderPosition int,
    reserved_quantity numeric(10, 3) NOT NULL,
    created_at timestamptz DEFAULT NOW(),
    expires_at timestamptz NOT NULL,
    status text,
    FOREIGN KEY (ID_Batch) REFERENCES Batch(ID_Batch) ON DELETE CASCADE,
    FOREIGN KEY (ID_OrderPosition) REFERENCES OrderPosition(ID_OrderPosition) ON DELETE CASCADE
);

CREATE TABLE SubstitutionOffer (
    ID_SubstitutionOffer int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_OrderPosition int,
    ID_Product int,
    offered_quantity numeric(10, 3),
    price_difference numeric(12, 2),
    status text,
    FOREIGN KEY (ID_OrderPosition) REFERENCES OrderPosition(ID_OrderPosition) ON DELETE CASCADE,
    FOREIGN KEY (ID_Product) REFERENCES Product(ID_Product)
);

CREATE TABLE SubstitutionDecision (
    ID_SubstitutionDecision int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_SubstitutionOffer int,
    ID_Employee int,
    decision_type text NOT NULL,
    decided_at timestamptz DEFAULT NOW(),
    CONSTRAINT decision_check CHECK (decision_type IN ('Accept', 'Reject')),
    FOREIGN KEY (ID_SubstitutionOffer) REFERENCES SubstitutionOffer(ID_SubstitutionOffer) ON DELETE CASCADE,
    FOREIGN KEY (ID_Employee) REFERENCES Employee(ID_Employee)
);

CREATE TABLE OrderPicking (
    ID_OrderPicking int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Order int,
    ID_Employee int,
    started_at timestamptz,
    completed_at timestamptz,
    status text,
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order) ON DELETE CASCADE,
    FOREIGN KEY (ID_Employee) REFERENCES Employee(ID_Employee)
);

CREATE TABLE ActualFulfillment (
    ID_ActualFulfillment int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_OrderPicking int,
    ID_Batch int,
    ID_OrderPosition int,
    actual_quantity numeric(10, 3) NOT NULL,
    actual_price numeric(12, 2), 
    is_replacement boolean DEFAULT false,
    FOREIGN KEY (ID_OrderPicking) REFERENCES OrderPicking(ID_OrderPicking) ON DELETE CASCADE,
    FOREIGN KEY (ID_Batch) REFERENCES Batch(ID_Batch),
    FOREIGN KEY (ID_OrderPosition) REFERENCES OrderPosition(ID_OrderPosition)
);

CREATE TABLE Transactions (
    ID_Transaction int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Order int,
    operation_type text NOT NULL,
    amount numeric(12, 2) NOT NULL,
    currency text DEFAULT 'RUB',
    created_at timestamptz DEFAULT NOW(),
    status text,
    CONSTRAINT op_type_check CHECK (operation_type IN ('Authorization', 'Capture', 'Refund', 'Correction')),
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order)
);

CREATE TABLE CourierRoute (
    ID_CourierRoute int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Employee int,
    ID_Darkstore int,
    route_date timestamptz DEFAULT NOW(),
    max_weight numeric(10, 3),
    current_weight numeric(10, 3),
    status text,
    FOREIGN KEY (ID_Employee) REFERENCES Employee(ID_Employee),
    FOREIGN KEY (ID_Darkstore) REFERENCES DarkStore(ID_Darkstore)
);

CREATE TABLE OrderDelivery (
    ID_OrderDelivery int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Order int,
    ID_CourierRoute int,
    handed_to_courier_at timestamptz,
    arrived_at timestamptz,
    delivered_at timestamptz,
    cancellation_reason text,
    status text,
    route_position int,
    FOREIGN KEY (ID_Order) REFERENCES Orders(ID_Order),
    FOREIGN KEY (ID_CourierRoute) REFERENCES CourierRoute(ID_CourierRoute)
);

CREATE TABLE WriteOff (
    ID_WriteOff int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_Batch int,
    ID_Employee int,
    quantity numeric(10, 3) NOT NULL,
    reason text,
    created_at timestamptz DEFAULT NOW(),
    confirmation_status text,
    FOREIGN KEY (ID_Batch) REFERENCES Batch(ID_Batch),
    FOREIGN KEY (ID_Employee) REFERENCES Employee(ID_Employee)
);