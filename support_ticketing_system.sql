CREATE DATABASE IF NOT EXISTS SupportTicketSystem;
USE SupportTicketSystem;

CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20)
);

CREATE TABLE Support_Agents (
    agent_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(100)
);

CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE Status (
    status_id INT AUTO_INCREMENT PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL
);

CREATE TABLE Tickets (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    agent_id INT,
    category_id INT NOT NULL,
    status_id INT NOT NULL,
    priority ENUM('Low', 'Medium', 'High') DEFAULT 'Medium',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    closed_at DATETIME,
    subject VARCHAR(255) NOT NULL,
    description TEXT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (agent_id) REFERENCES Support_Agents(agent_id),
    FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    FOREIGN KEY (status_id) REFERENCES Status(status_id)
);

CREATE TABLE Ticket_Updates (
    update_id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_comment TEXT,
    FOREIGN KEY (ticket_id) REFERENCES Tickets(ticket_id)
);

USE SupportTicketSystem;

-- Insert sample Customers
INSERT INTO Customers (name, email, phone) VALUES
('Alice Johnson', 'alice.johnson@example.com', '555-1234'),
('Bob Smith', 'bob.smith@example.com', '555-5678'),
('Carol Davis', 'carol.davis@example.com', '555-8765');

-- Insert sample Support Agents
INSERT INTO Support_Agents (name, email, department) VALUES
('David Lee', 'david.lee@example.com', 'IT Support'),
('Eva Green', 'eva.green@example.com', 'Technical Support');

-- Insert sample Categories
INSERT INTO Categories (category_name) VALUES
('Software Issue'),
('Hardware Issue'),
('Network Problem'),
('Account Management');

-- Insert sample Statuses
INSERT INTO Status (status_name) VALUES
('Open'),
('In Progress'),
('Resolved'),
('Closed');

-- Insert sample Tickets
INSERT INTO Tickets (customer_id, agent_id, category_id, status_id, priority, created_at, subject, description) VALUES
(1, 1, 1, 1, 'High', NOW(), 'Cannot install software', 'Installation fails with error code 123'),
(2, 2, 3, 2, 'Medium', NOW(), 'Wi-Fi is not connecting', 'Device loses Wi-Fi connection frequently'),
(3, NULL, 4, 1, 'Low', NOW(), 'Need password reset', 'Forgot password, need assistance resetting');

-- Insert sample Ticket Updates
INSERT INTO Ticket_Updates (ticket_id, updated_at, update_comment) VALUES
(1, NOW(), 'Team acknowledged the issue and started investigation'),
(2, NOW(), 'Technician assigned; testing network hardware'),
(1, NOW(), 'Provided workaround to user; waiting for feedback');

-- List all open tickets with customer and agent details:
SELECT t.ticket_id, t.subject, c.name AS customer_name, a.name AS agent_name, t.priority, t.created_at
FROM Tickets t
JOIN Customers c ON t.customer_id = c.customer_id
LEFT JOIN Support_Agents a ON t.agent_id = a.agent_id
JOIN Status s ON t.status_id = s.status_id
WHERE s.status_name = 'Open'
ORDER BY t.created_at DESC;

--  Count tickets by category and status:
SELECT cat.category_name, s.status_name, COUNT(*) AS ticket_count
FROM Tickets t
JOIN Categories cat ON t.category_id = cat.category_id
JOIN Status s ON t.status_id = s.status_id
GROUP BY cat.category_name, s.status_name
ORDER BY cat.category_name, s.status_name;

-- Show ticket updates timeline for a specific ticket (e.g., ticket_id = 1):
SELECT updated_at, update_comment
FROM Ticket_Updates
WHERE ticket_id = 1
ORDER BY updated_at ASC;

-- List agents with their current open ticket workload:
SELECT a.name AS agent_name, COUNT(t.ticket_id) AS open_tickets
FROM Support_Agents a
LEFT JOIN Tickets t ON a.agent_id = t.agent_id
JOIN Status s ON t.status_id = s.status_id AND s.status_name = 'Open'
GROUP BY a.agent_id, a.name
ORDER BY open_tickets DESC;

-- Average time to close tickets by category:
SELECT cat.category_name,
       AVG(TIMESTAMPDIFF(HOUR, t.created_at, t.closed_at)) AS avg_hours_to_close
FROM Tickets t
JOIN Categories cat ON t.category_id = cat.category_id
WHERE t.closed_at IS NOT NULL
GROUP BY cat.category_name
ORDER BY avg_hours_to_close ASC;

-- Tickets reopened within 15 days of closure:
SELECT t.ticket_id, c.name AS customer_name, t.subject, t.closed_at, tu.updated_at AS reopened_at
FROM Tickets t
JOIN Customers c ON t.customer_id = c.customer_id
JOIN Ticket_Updates tu ON t.ticket_id = tu.ticket_id
WHERE tu.updated_at > t.closed_at
AND tu.updated_at <= DATE_ADD(t.closed_at, INTERVAL 15 DAY)
AND t.closed_at IS NOT NULL
ORDER BY tu.updated_at DESC;

-- Monthly ticket creation trends:
SELECT DATE_FORMAT(created_at, '%Y-%m') AS month, COUNT(*) AS tickets_created
FROM Tickets
GROUP BY month
ORDER BY month DESC;

-- Top 5 customers by number of tickets submitted:
SELECT c.name, COUNT(t.ticket_id) AS total_tickets
FROM Customers c
JOIN Tickets t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_tickets DESC
LIMIT 5;

-- Tickets by priority with aging (days since created):
SELECT ticket_id, subject, priority, DATEDIFF(CURRENT_DATE, created_at) AS days_open
FROM Tickets
WHERE status_id != (SELECT status_id FROM Status WHERE status_name = 'Closed')
ORDER BY priority DESC, days_open DESC;

-- Agent performance: number of tickets resolved per agent:
SELECT a.name AS agent_name, COUNT(t.ticket_id) AS tickets_resolved
FROM Support_Agents a
JOIN Tickets t ON a.agent_id = t.agent_id
JOIN Status s ON t.status_id = s.status_id
WHERE s.status_name = 'Closed'
GROUP BY a.agent_id, a.name
ORDER BY tickets_resolved DESC;


