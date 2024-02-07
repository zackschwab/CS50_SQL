-- Represents the dealership's inventory
CREATE TABLE "inventory" (
    "id" INTEGER,
    "vin" TEXT UNIQUE NOT NULL,
    "customer_id" INTEGER,
    "year" YEAR NOT NULL,
    "make" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "mileage" INTEGER NOT NULL,
    "color" TEXT NOT NULL,
    "interior_color" TEXT,
    "engine" TEXT,
    "transmission" TEXT,
    "drivetrain" TEXT,
    "city_fuel_economy" INTEGER,
    "highway_fuel_economy" INTEGER,
    "date_acquired" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_sold" DATETIME,
    "acquisition_cost" NUMERIC NOT NULL,
    "repairs_cost" NUMERIC NOT NULL DEFAULT 0,
    "selling_price" NUMERIC,
    "sold" INTEGER NOT NULL DEFAULT 0,
    "paid_in_full" INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY("id"),
    FOREIGN KEY("customer_id") REFERENCES "customers"("id")
);

-- Represents customers
CREATE TABLE "customers" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "missed_payments" INTEGER NOT NULL DEFAULT 0,
    "repossesions" INTEGER NOT NULL DEFAULT 0,
    "vehicles_bought" INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY("id")
);

-- Represents customer loans. For simplicity, if a customer buys a car in full, it will be considered a loan with a current balance of 0
CREATE TABLE "customer_loans" (
    "id" INTEGER,
    "customer_id" INTEGER,
    "vehicle_id" INTEGER,
    "current_balance" NUMERIC NOT NULL,
    "payments_missed" INTEGER NOT NULL DEFAULT 0,
    "start_date" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "end_date" DATETIME,
    "paid_off" INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY("id"),
    FOREIGN KEY("customer_id") REFERENCES "customers"("id"),
    FOREIGN KEY("vehicle_id") REFERENCES "inventory"("id")
);

-- Represents each payment made on a vehicle. Doesn't account for interest that may be charged
CREATE TABLE "payments" (   
    "id" INTEGER,
    "loan_id" INTEGER,
    "amount_paid" NUMERIC NOT NULL,
    "payment_late" INTEGER NOT NULL DEFAULT 0, -- 0 represents the payment was made on time
    PRIMARY KEY("id"),
    FOREIGN KEY("loan_id") REFERENCES "customer_loans"("id")
);

-- This trigger marks a car as sold once a loan is taken out
CREATE TRIGGER "loan_taken"
AFTER INSERT ON "customer_loans"
FOR EACH ROW
BEGIN
    UPDATE "inventory"
    SET "sold" = 1
    WHERE "id" = NEW."vehicle_id";

    UPDATE "inventory"
    SET "customer_id" = NEW."customer_id"
    WHERE "id" = NEW."vehicle_id";
END;

-- This trigger updates the customer loan once a payment is made
CREATE TRIGGER "payment_made"
AFTER INSERT ON "payments"
BEGIN
    UPDATE "customer_loans"
    SET "current_balance" = "current_balance" - NEW."amount_paid"
    WHERE "id" = NEW."loan_id";

    UPDATE "customer_loans"
    SET "payments_missed" = "payments_missed" + 1
    WHERE "id" = NEW."loan_id" AND NEW."payment_late" = 1;

    UPDATE "customers"
    SET "missed_payments" = "missed_payments" + 1
    WHERE "id" = (SELECT "customer_id" FROM "customer_loans" WHERE "id" = NEW."loan_id" AND NEW."payment_late" = 1);
END;


-- This trigger ensures that a vehicle is marked as sold once it is paid in full
CREATE TRIGGER "car_sold"
AFTER UPDATE ON "customer_loans"
WHEN NEW."current_balance" <= 0
BEGIN
    UPDATE "inventory"
    SET "paid_in_full" = 1
    WHERE "id" = NEW."vehicle_id";

    UPDATE "inventory"
    SET "date_sold" = CURRENT_TIMESTAMP
    WHERE "id" = NEW."vehicle_id";

    UPDATE "customer_loans"
    SET "paid_off" = 1
    WHERE "id" = NEW."id";

    UPDATE "customer_loans"
    SET "end_date" = CURRENT_TIMESTAMP
    WHERE "id" = NEW."id";

    UPDATE "customers"
    SET "vehicles_bought" = "vehicles_bought" + 1
    WHERE "id" = NEW."customer_id";
END;

-- This index optimizes searches based on customer name
CREATE INDEX "customer_name_index" ON "customers" ("first_name", "last_name");

-- This index optimizes our search for vehicles that are unsold
CREATE INDEX "vehicle_sold_index" ON "inventory" ("sold");

-- This index optimizes searches based on the year and make of the vehicle
CREATE INDEX "vehicle_make_index" ON "inventory" ("make", "year");

-- This index optimizes searches based on mileage and price
CREATE INDEX "vehicle_mileage_index" ON "inventory" ("mileage", "selling_price");

-- This index optimizes searches based on customer loans and loans that have been paid in full.
CREATE INDEX "customer_loan_index" ON "customer_loans" ("customer_id", "paid_off");

-- This index optimizes searches based on loan_id and missed payments
CREATE INDEX "customer_payment_index" ON "payments" ("loan_id", "payment_late");


