CREATE TABLE IF NOT EXISTS customer_contacts ( 
    mobile CHAR(10) UNIQUE,
    email VARCHAR(50) NOT NULL PRIMARY KEY
);

INSERT INTO customer_contacts (mobile, email) VALUES
('0481816206', 'something@gmail.com'),
('0481816207', 'Idontknow@yahoo.com'),
('0481816208', 'neverknew@tafe.wa.edu.au');

CREATE TABLE IF NOT EXISTS accounts (
    account_number INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    balance DECIMAL(7, 2) UNSIGNED,
    interest_rate DECIMAL(5, 4) UNSIGNED
);

INSERT INTO accounts (balance, interest_rate) VALUES
(19000.00, 0.0386),
(72000.50, 0.0386),
(14500.00, 0.0386);

ALTER TABLE accounts ADD COLUMN contact_email VARCHAR(50) NOT NULL;
ALTER TABLE accounts ADD FOREIGN KEY (contact_email) REFERENCES customer_contacts(email);

UPDATE accounts SET contact_email = 'something@gmail.com' WHERE account_number = 1;
UPDATE accounts SET contact_email = 'Idontknow@yahoo.com' WHERE account_number = 2;
UPDATE accounts SET contact_email = 'neverknew@tafe.wa.edu.au' WHERE account_number = 3;

DELIMITER //
CREATE PROCEDURE add_monthly_interest()
BEGIN
    UPDATE accounts
    SET balance = balance + (balance * interest_rate / 12);
END //
DELIMITER ;

CREATE TABLE IF NOT EXISTS change_log (
    account_number INT UNSIGNED,
    old_balance DECIMAL(7, 2),
    new_balance DECIMAL(7, 2),
    old_interest_rate DECIMAL(5, 4),
    new_interest_rate DECIMAL(5, 4),
    modified TIMESTAMP
);

DELIMITER //
CREATE TRIGGER update_change_log
AFTER UPDATE ON accounts
FOR EACH ROW
BEGIN
    IF NEW.balance != OLD.balance THEN
        INSERT INTO change_log(account_number, old_balance, new_balance, old_interest_rate, new_interest_rate, modified)
        VALUES (NEW.account_number, OLD.balance, NEW.balance, OLD.interest_rate, NEW.interest_rate, CURRENT_TIMESTAMP);
    END IF;
    
    IF NEW.interest_rate != OLD.interest_rate THEN
        INSERT INTO change_log(account_number, old_balance, new_balance, old_interest_rate, new_interest_rate, modified)
        VALUES (NEW.account_number, OLD.balance, NEW.balance, OLD.interest_rate, NEW.interest_rate, CURRENT_TIMESTAMP);
    END IF;
END //
DELIMITER ;

UPDATE accounts SET balance = 1 WHERE account_number = 1;
UPDATE accounts SET interest_rate = 1 WHERE account_number = 2;

SELECT * FROM change_log;

account_number	old_balance	new_balance	old_interest_rate	new_interest_rate	modified
1		19000.00	1.00		0.0386			0.0386			2023-03-25 09:19:59
2		72000.50	72000.50	0.0386			1.0000			2023-03-25 09:23:40

DELIMITER //
CREATE TRIGGER empty_account 
AFTER DELETE ON customer_contacts 
FOR EACH ROW
BEGIN
    UPDATE accounts SET balance = 0.00 WHERE contact_email = OLD.email;
    DELETE FROM accounts WHERE balance = 0.00;
END //
DELIMITER ;

DELETE FROM customer_contacts WHERE email = 'something@gmail.com';

SELECT * FROM accounts;

account_number		balance		interest_rate		contact_email
2			72000.50	1.0000			Idontknow@yahoo.com
3			14500.00	0.0386	     		neverknew@tafe.wa.edu.au

SELECT * FROM change_log;

account_number		old_balance	new_balance	old_interest_rate	new_interest_rate	modified
1			19000.00	1.00		0.0386			0.0386			2023-03-25 09:19:59
2			72000.50	72000.50	0.0386			1.0000			2023-03-25 09:23:40
1			19000.00	0.00		0.0386			0.0386			2023-04-13 14:07:57