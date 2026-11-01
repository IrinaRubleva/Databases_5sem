INSERT INTO DarkStore (address, service_zone, status) VALUES
('ул. Ленина, д. 10', 'Центральный район', 'Active'),
('пр. Мира, д. 45', 'Северный район', 'Active');

INSERT INTO Employee (full_name, position_, phone_number, passport, email, max_carrying_weight, status) VALUES
('Иванов Иван Иванович', 'Сборщик', '+79001112233', '4509 123456', 'ivanov@samoskatka.ru', 15.000, 'Active'),
('Петрова Анна Сергеевна', 'Курьер', '+79004445566', '4601 987654', 'petrova@samoskatka.ru', 20.000, 'Active'),
('Сидоров Петр Алексеевич', 'Менеджер даркстора', '+79007778899', '4510 112233', 'sidorov@samoskatka.ru', NULL, 'Active');


INSERT INTO Vendor (inn, name_, email, cooperation_status) VALUES
('7701234567', 'ООО "Молочная река"', 'supply@milkriver.ru', 'Cooperate'),
('5001987654', 'ИП Смирнов В.А.', 'smirnov@fruits.com', 'Cooperate');

INSERT INTO Product (name_, category, unit, is_weighted, status) VALUES
('Молоко Домик в деревне 3.2%', 'dairy products and eggs', 'l', false, 'Active'),
('Бананы Эквадор', 'fruits', 'kg', true, 'Active'),
('Хлеб Бородинский нарезной', 'bread and pastries', 'pcs', false, 'Active'),
('Яблоки Гала', 'fruits', 'kg', true, 'Active');

INSERT INTO Price (ID_Product, ID_Darkstore, price_value, currency, valid_from) VALUES
(1, 1, 89.90, 'RUB', NOW()),   
(2, 1, 120.00, 'RUB', NOW()),  
(3, 1, 65.00, 'RUB', NOW()),   
(4, 1, 150.00, 'RUB', NOW());  


INSERT INTO Batch (ID_Darkstore, ID_Product, ID_Vendor, production_date, acceptance_date, expiration_date, init_quantity, current_balance, priority, status) VALUES
(1, 1, 1, '2026-10-01', '2026-10-02', '2026-10-25', 100.000, 100.000, 10, 'Available'),
(1, 2, 2, '2026-10-15', '2026-10-16', '2026-10-22', 50.000, 50.000, 20, 'Available'), 
(1, 3, 1, '2026-10-18', '2026-10-19', '2026-10-28', 200.000, 200.000, 5, 'Available'),
(1, 4, 2, '2026-10-10', '2026-10-11', '2026-11-10', 80.000, 80.000, 15, 'Available');


INSERT INTO Customer (phone_number, email, password_hash, full_name) VALUES
('+79990001122', 'client@test.ru', '$2b$12$LJ3m4ys3Gl5k...', 'Алексей Тестов');

INSERT INTO Orders (ID_Customer, ID_Darkstore, planned_amount, total_weight, status) VALUES
(1, 1, 329.90, 2.500, 'Confirmed');


INSERT INTO OrderPosition (ID_Order, ID_Product, quantity, unit_amount, status) VALUES
(1, 1, 2.000, 89.90, 'Planned'),     
(1, 2, 1.500, 120.00, 'Planned'),    
(1, 3, 1.000, 65.00, 'Planned');     


INSERT INTO Reserve (ID_Batch, ID_OrderPosition, reserved_quantity, expires_at, status) VALUES
(1, 1, 2.000, NOW() + INTERVAL '30 minutes', 'Active'),  
(2, 2, 1.500, NOW() + INTERVAL '30 minutes', 'Active'),  
(3, 3, 1.000, NOW() + INTERVAL '30 minutes', 'Active');  


UPDATE Batch SET current_balance = current_balance - 2.000 WHERE ID_Batch = 1;
UPDATE Batch SET current_balance = current_balance - 1.500 WHERE ID_Batch = 2;
UPDATE Batch SET current_balance = current_balance - 1.000 WHERE ID_Batch = 3;


INSERT INTO OrderPicking (ID_Order, ID_Employee, started_at, completed_at, status) VALUES
(1, 1, NOW() - INTERVAL '15 minutes', NOW(), 'Completed');


INSERT INTO ActualFulfillment (ID_OrderPicking, ID_Batch, ID_OrderPosition, actual_quantity, actual_price, is_replacement) VALUES
(1, 1, 1, 2.000, 179.80, false),
(1, 2, 2, 1.650, 198.00, false),  
(1, 3, 3, 1.000, 65.00, false);


UPDATE Orders SET final_amount = 447.80, status = 'Ready' WHERE ID_Order = 1;


INSERT INTO Transactions (ID_Order, operation_type, amount, currency, status) VALUES
(1, 'Authorization', 329.90, 'RUB', 'Success'),
(1, 'Capture', 329.90, 'RUB', 'Success'),
(1, 'Correction', 18.00, 'RUB', 'Success');


INSERT INTO Promotion (name_, promo_code, discount_value, discount_type, is_combinable, status) VALUES
('Скидка новичкам', 'NEW10', 10.00, 'percent', true, 'Active');

INSERT INTO AppliedPromotion (ID_Promotion, ID_Order, applied_discount, applied_at) VALUES
(1, 1, 44.78, NOW());

INSERT INTO CourierRoute (ID_Employee, ID_Darkstore, max_weight, current_weight, status) VALUES
(2, 1, 25.000, 3.000, 'Active');

INSERT INTO OrderDelivery (ID_Order, ID_CourierRoute, handed_to_courier_at, arrived_at, delivered_at, status, route_position) VALUES
(1, 1, NOW() - INTERVAL '10 minutes', NOW() - INTERVAL '5 minutes', NOW(), 'Delivered', 1);


INSERT INTO Batch (ID_Darkstore, ID_Product, ID_Vendor, production_date, acceptance_date, expiration_date, init_quantity, current_balance, status) VALUES
(1, 4, 2, '2026-09-01', '2026-09-02', '2026-10-20', 10.000, 10.000, 'Expired');

INSERT INTO WriteOff (ID_Batch, ID_Employee, quantity, reason, confirmation_status) VALUES
(5, 3, 10.000, 'Истек срок годности', 'Confirmed');


UPDATE Batch SET current_balance = 0, status = 'Written Off' WHERE ID_Batch = 5;