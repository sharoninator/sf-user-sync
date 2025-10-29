-- Run this SQL in Railway's MySQL database after deployment
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    external_user_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(50),
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_external_user_id ON users(external_user_id);
CREATE INDEX idx_updated_at ON users(updated_at);

-- Insert sample data
INSERT INTO users (external_user_id, email, first_name, last_name, phone) VALUES
('USER001', 'john.doe@example.com', 'John', 'Doe', '+1234567890'),
('USER002', 'jane.smith@example.com', 'Jane', 'Smith', '+1987654321'),
('USER003', 'bob.wilson@example.com', 'Bob', 'Wilson', '+1555123456');