# Design Document

By Zachary Schwab

Video overview: https://www.youtube.com/watch?v=8JXv9zHGrbE

## Scope

This database, designed for an automotive dealership, allows dealerships to track their vehicles in inventory, as well as their financials. To achieve this, included in the database's scope is:

* Inventory, containing essential properties of each vehicle, useful for customers and staff
* Customers, including basic identifying information, the number of vehicles they've purchased, and instances of repossesion at the dealership
* Customer loans, including the customer and vehicle id associated with the loan, along with the amounts of missed payments, and the start/end date of the loan.
* Payments, including the vehicle and customer id, amount paid, amount due, as well as stating whether the payment was made on time.

For simplicity sake, certain financial elements such as interest charged, partial payments, and repossesions are out of scope for this database. There are also various vehicle options left out of this such as heated seats, interior material, and other non-core attributes.

## Functional Requirements

This database will support:

* Inventory search operations for prospective customers and salesmen
* Operations for the dealership to sell and purchase vehicles
* Tracking financial information of customers including payments, loans, and repossesions.
* Reporting sales and profits of a given time period

Note that this database is not capable of reporting profits based on partial payments, repossesions, interest charged, and taxes.

## Representation

Entities are captured in SQLite tables with the following schema.

### Entities

The database includes the following entities:

### Inventory

The `inventory` table includes:

* `id`, which specifies the unique ID of each vehicle as an `INTEGER`. This column has the `PRIMARY KEY` constraint applied. Note that if the same vehicle is repossesed or traded in, it will be assigned a new ID.
* `vin`, which represents the unique VIN number associated with the vehicle as `TEXT`, since VIN numbers contain letters.
* `customer_id`, which represents the customer associated with the vehicle as `INTEGER`. This value will be `NULL` if it is unsold and has the `FOREIGN KEY` constraint applied, referencing `customers`.`id`.
* `year`, which represents the model year of the vehicle as a `YEAR`.
* `make`, which represents the make of the vehicle as `TEXT`.
* `model`, which represents the model of the vehicle as `TEXT`.
* `mileage`, which represents the mileage of the vehicle as an `INTEGER`
* `color`, which represents the exterior color of the vehicle as `TEXT`.
* `interior_color`, which represents the interior color of the vehicle as `TEXT`.
* `engine`, which represents the engine specifications as `TEXT`.
* `transmission`, which represents the type of transmission as `TEXT`.
* `drivetrain`, which represents the drivetrain as `TEXT`.
* `city_fuel_economy`, which represents the city fuel economy as `INTEGER`.
* `highway_fuel_economy`, which represents the highway fuel economy as `INTEGER`.
* `date_acquired`, which represents the date the vehicle was acquired as `DATETIME`. This value is assigned as the current timestamp by default.
* `date_sold`, which represents the date the vehicle is sold, which is `NULL` until the vehicle is sold. Once sold this field is represented as `DATETIME`.
* `acquisition_cost` represents the amount paid by the dealership to purchase the vehicle as an `NUMERIC`, allowing for precise financial calculations.
* `repairs_cost`, which represents the amount spent on repairs as an   `NUMERIC` and is useful for calcualating future profits.
* `selling_price`, which represents the amount the selling price of the vehicle as an `NUMERIC` and is used to calculate future profits.
* `sold`, which represents if the vehicle has been sold, even if it hasn't been paid in full yet as an `INTEGER`, where 1 represents it as being sold. This is useful to determine which vehicles are currently in inventory.
* `paid_in_full`, which represents if the vehicle has been paid in full as an `INTEGER` where 1 represents the vehicle has been paid in full.

The columns `year`, `make`, `model`, `mileage`, `color`, `date_acquired`, `acquisition_cost`, `repairs_cost`, `sold`, and `paid_in_full` are essential and hence they are `NOT NULL`. The other attributes are less important and can be updated later if desired.

### Customers

The `customers` table includes:

* `id`, which specifies the unique ID of the customer as an `INTEGER`. This column thus has the `PRIMARY KEY` constraint applied.
* `first_name`, which represents the customer's first name as `TEXT`.
* `last_name`, which represents the customer's last name as `TEXT`.
* `missed_payments`, which represents the amount of payments the customer missed at this dealership as `INTEGER`, which is useful to salesmen.
* `repossesions`, which represents the amount of automotive repossesions of the customer as `INTEGER`, which is useful to salesmen.
* `vehicles_bought`, which represents the amount of vehicles the customer has bought at this dealership as an `INTEGER`, which is useful to salesmen.

Each column in this table is essential and thus they are all `NOT NULL`. The `missed_payments`, `repossesions`, and `vehicles_bought` columns all default to 0 since these are typically all zero when the customer is created.

### Customer loans

The `customer_loans` table includes:

* `id`, which specifies unique the ID of the loan as an `INTEGER`. This column thus has the `PRIMARY KEY` constraint applied.
* `customer_id`, which represents the ID of the customer associated with the loan as an `INTEGER`. Thus the `FOREIGN KEY` constraint is applied, referencing `customers`.`id`.
* `vehicle_id`, which represents the ID of the vehicle associated with the loan as an `INTEGER`. Thus the `FOREIGN KEY` constraint is applied, referencing `inventory`.`id`.
* `current_balance`, which represents the outstanding balance of the loan as `NUMERIC`, allowing for precise financial calculations.
* `payments_missed`, which represents the amount of payments missed on the loan as `INTEGER`, and is useful to determine if a vehicle should be repossesed and calculate interest.
* `start_date`, which represents the start date of the loan as `DATETIME`, and defaults to the current timestamp.
* `end_date`, which represents the end_date of the loan as `DATETIME`.
* `paid_off`, which represents if the loan has been paid off as an `INTEGER`, which 1 represents the loan is paid in full.

Each column in this table, excluding the `end_date`, have the constraint `NOT_NULL` since they are essential. However, `end_date` will remain null until the loan is paid in full.

### Payments

The `payments` table includes:
* `id`, which represents the unique ID of the payment as an `INTEGER`.This column thus has the `PRIMARY KEY` constraint applied.
* `loan_id`, which represents the unique ID of the loan as an `INTEGER`. This column thus has the `FOREIGN KEY` constraint applied, referencing `customer_loans`.`id`.
* `amount_paid`, which represents the amount paid towards the loan as `NUMERIC`, allowing for precise financial calculations.
* `payment_late`, which indicates if the payment was late as an `INTEGER`, where 1 represents the payment is late. This can be useful to charge late fees in the future and defaults to 0.

Each column in this table is essential and thus the `NOT NULL` constraint is applied to each column.

### Relationships

The below entity relationship diagram describes the relationships among the entities in the database.

![ER Diagram](diagram.png)

As detailed by the diagram:

* One customer is capable of buying 0 to many cars. One customer is capable of taking 0 to many customer_loans. This allows customers to buy multiple cars, but we can still store them as a customer if they haven't bought one but are planning to buy a car.
* One car from inventory is capable of having 0 to 1 customer_loans associated with it. This is because if the same car is purchased by the dealership, it will be assigned a new ID, since each car in inventory is only associated with one customer
* One customer_loan receives 0 to many payments. This is because a customer could take out a loan but hasn't paid yet. However, it is essential for a loan to be capable of receiving many payments

## Optimizations

Per the typical queries in `queries.sql`, it is common for users to access certain vehicles based on common attributes such as year, make, model, mileage, and price. Furthermore, the dealership has to keep track of which vehicles have been sold. Therefore, indexes of `year`, `make`, `model`, `mileage`, `price`, and `sold` have in the `inventory` table have been created to optimize inventory searches.

Furthermore, to optimize financial calculations and allow staff to view a customer's history efficiently, indexes for the `customers`.`first_name`, `customers`.`last_name`, `customer_loans`.`customer_id`, `customer_loans`.`paid_off`, `payments`.`loan_id`, and `payments`.`payment_late` have been created.

## Limitations

Currently, the database is not able to accurately convey financial information, since it is unable to perform essential calculations involving partial payments, interest, and repossesions. Furthermore, the use of SQLITE results in large amounts of wasted storage, due to the absence of datatypes such as `TINYINT` and `VARCHAR`. In the future, transitioning this database to use a more sophisticated DBMS such as PostgreSQL would allow us to optimize storage capacity and even create users with certain permissions such as customers, salesmen, accountants, and admins.
