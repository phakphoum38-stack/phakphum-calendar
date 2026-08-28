CREATE DATABASE IF NOT EXISTS phakphum CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE phakphum;

CREATE TABLE IF NOT EXISTS swap_requests (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  origin_name VARCHAR(255),
  swap_name VARCHAR(255),
  receiver_name VARCHAR(255),
  payload_json JSON,
  status VARCHAR(32) DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
