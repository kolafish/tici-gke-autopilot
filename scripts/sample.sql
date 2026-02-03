CREATE DATABASE IF NOT EXISTS tici_sample;
USE tici_sample;

CREATE TABLE IF NOT EXISTS t1 (
  id CHAR(36) NOT NULL,
  body TEXT,
  PRIMARY KEY (id)
);
ALTER TABLE t1 ADD FULLTEXT INDEX ft_index (body) WITH PARSER standard;
INSERT INTO t1 (id, body) VALUES
  ('00000000-0000-0000-0000-000000000001', 'This is the first test data, used to demonstrate the insert operation'),
  ('00000000-0000-0000-0000-000000000002', 'The second record contains some sample text for testing'),
  ('00000000-0000-0000-0000-000000000003', 'Third entry: verifying the TEXT field''s ability to store longer content'),
  ('00000000-0000-0000-0000-000000000004', 'Fourth data row, which can be used for subsequent query or analysis tests'),
  ('00000000-0000-0000-0000-000000000005', 'Fifth sample entry to complete the basic insertion example');
