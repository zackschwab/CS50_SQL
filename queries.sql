-- Adds some cars to our inventory
INSERT INTO "inventory" ("year", "make", "model", "color", "mileage", "acquisition_cost", "repairs_cost", "selling_price", "vin")
VALUES
    (2013, 'Ford', 'Mustang GT', 'Blue', 123000, 13000, 450, 17500, 1),
    (2011, 'Chevrolet', 'Avalanche', 'Red', 144000, 11000, 2400, 17995, 2),
    (2012, 'Chevrolet', 'Cruze', 'Blue', 126000, 4000, 400, 7995, 3),
    (2014, 'Dodge', 'Journey', 'White', 99000, 5000, 200, 10995, 4),
    (2015, 'Ford', 'Fusion', 'Gray', 75000, 6000, 850, 12495, 5),
    (2015, 'Ford', 'Explorer', 'Black', 125000, 11000, 4000, 13995, 6),
    (2013, 'Honda', 'Accord', 'Blue', 95000, 6000, 1500, 12995, 7);

-- Add some customers to our database
INSERT INTO "customers"("first_name", "last_name")
VALUES
    ('Ryan', 'Smith'),
    ('Alex', 'Jones'),
    ('Ben', 'Schwab');

-- Take out some customer loans/purchases
INSERT INTO "customer_loans"("customer_id", "vehicle_id", "current_balance")
VALUES
    -- Ryan wants to buy a Mustang and Explorer
    (
        (SELECT "id" FROM "customers" WHERE "first_name" = 'Ryan' AND "last_name" = 'Smith'),
        (SELECT "id" FROM "inventory" WHERE "make" = 'Ford' AND "model" = 'Mustang GT' AND "year" = 2013),
        (SELECT "selling_price" FROM "inventory" WHERE "make" = 'Ford' AND "model" = 'Mustang GT' AND "year" = 2013)
    ),
    (
        (SELECT "id" FROM "customers" WHERE "first_name" = 'Ryan' AND "last_name" = 'Smith'),
        (SELECT "id" FROM "inventory" WHERE "make" = 'Ford' AND "model" = 'Explorer' AND "year" = 2015),
        (SELECT "selling_price" FROM "inventory" WHERE "make" = 'Ford' AND "model" = 'Explorer' AND "year" = 2015)
    ),
    -- Alex wants to buy the Honda Accord
    (
        (SELECT "id" FROM "customers" WHERE "first_name" = 'Alex' AND "last_name" = 'Jones'),
        (SELECT "id" FROM "inventory" WHERE "make" = 'Honda' AND "model" = 'Accord' AND "year" = 2013),
        (SELECT "selling_price" FROM "inventory" WHERE "make" = 'Honda' AND "model" = 'Accord' AND "year" = 2013)
    ),
    -- Ben wants to buy the Ford Fusion
    (
        (SELECT "id" FROM "customers" WHERE "first_name" = 'Ben' AND "last_name" = 'Schwab'),
        (SELECT "id" FROM "inventory" WHERE "make" = 'Ford' AND "model" = 'Fusion' AND "year" = 2015),
        (SELECT "selling_price" FROM "inventory" WHERE "make" = 'Ford' AND "model" = 'Fusion' AND "year" = 2015)
    );

-- Make some payments
INSERT INTO "payments"("loan_id", "amount_paid", "payment_late")
VALUES
    -- Ryan pays off his Mustang in full
    ((SELECT "id" FROM "customer_loans" WHERE "customer_id" = 1 AND "vehicle_id" = 1), 17500, 0),
    -- Ryan pays 10k towards his explorer
    ((SELECT "id" FROM "customer_loans" WHERE "customer_id" = 1 AND "vehicle_id" = 6), 10000, 0),
    -- Alex makes three late payments
    ((SELECT "id" FROM "customer_loans" WHERE "customer_id" = 2 AND "vehicle_id" = 7), 400, 1),
    ((SELECT "id" FROM "customer_loans" WHERE "customer_id" = 2 AND "vehicle_id" = 7), 400, 1),
    ((SELECT "id" FROM "customer_loans" WHERE "customer_id" = 2 AND "vehicle_id" = 7), 400, 1),
    -- Ben pays his Fusion in full
    ((SELECT "id" FROM "customer_loans" WHERE "customer_id" = 3 AND "vehicle_id" = 5), 12495, 0);



-- Shows the profits of each year
SELECT
    strftime('%Y', "date_sold") AS 'sale_year',
    SUM("selling_price" - ("acquisition_cost" + "repairs_cost")) AS 'total_profit',
    COUNT("id") AS 'vehicles_sold'
FROM "inventory"
WHERE "paid_in_full" = 1
GROUP BY 'sale_year';

-- Shows the vehicles paid in full
SELECT
    "id",
    "make",
    "model",
    "date_sold",
    "selling_price" - ("acquisition_cost" + "repairs_cost") AS 'profit'
FROM "inventory"
WHERE "paid_in_full" = 1
ORDER BY "date_sold";

-- Shows the current vehicles in inventory
SELECT
    "id",
    "year",
    "make",
    "model",
    "mileage",
    "color",
    "selling_price",
    "date_acquired"
FROM "inventory"
WHERE "sold" = 0
ORDER BY "selling_price";

-- Finds every Chevy vehicle on the lot and orders them by price
SELECT
    "id",
    "year",
    "make",
    "model",
    "mileage",
    "color",
    "selling_price"
FROM "inventory"
WHERE "make" = 'Chevrolet'
    AND "sold" = 0
ORDER BY "selling_price";

-- Finds every Mustang GT we have ever owned and orders by selling price
SELECT
    "id",
    "year",
    "make",
    "model",
    "mileage",
    "color"
FROM "inventory"
WHERE "model" = 'Mustang GT'
ORDER BY "selling_price";

-- Finds every vehicle a loyal customer, Ryan Smith, has bought from our dealership.
SELECT
    "inventory"."id",
    "year",
    "make",
    "model",
    "mileage",
    "color"
FROM "inventory"
JOIN "customer_loans" ON "inventory"."id" = "customer_loans"."vehicle_id"
WHERE "customer_loans"."customer_id" = (
    SELECT "id"
    FROM "customers"
    WHERE "first_name" = 'Ryan'
    AND "last_name" = 'Smith'
);

-- Finds loans with over 3 missed payments to determine which cars may need to be repossesed
SELECT
    "inventory"."id" AS 'vehicle_id',
    "inventory"."make" AS 'make',
    "inventory"."model" AS 'model',
    "inventory"."year" AS 'year',
    "inventory"."customer_id" as 'customer_id',
    "customer_loans"."id" as 'loan_id',
    "customer_loans"."current_balance" AS 'current_balance',
    "customer_loans"."payments_missed" AS 'payments_missed'
FROM "customer_loans"
JOIN "inventory" ON "inventory"."id" = "customer_loans"."vehicle_id"
JOIN "customers" ON "customers"."id" = "customer_loans"."customer_id"
WHERE "customer_loans"."payments_missed" >= 3
ORDER BY "customer_loans"."payments_missed" DESC;
