CREATE DATABASE IF NOT EXISTS tici_sample;
USE tici_sample;

CREATE TABLE IF NOT EXISTS t9(id BIGINT AUTO_INCREMENT,body TEXT,PRIMARY KEY (id));
DROP INDEX IF EXISTS ft_index ON t9;
ALTER TABLE t9 ADD FULLTEXT INDEX ft_index (body) WITH PARSER standard;
TRUNCATE TABLE t9;
INSERT INTO t9 (body) VALUES
    ('This is the first test pdata, used to demonstrate the insert operation'),
    ('The second record contains some sample text for testing'),
    ('Third entry: verifying the TEXT field''s ability to store longer content'),
    ('Fourth data row, which can be used for subsequent query or analysis tests'),
    ('Fifth sample entry to complete the basic insertion example');

CREATE TABLE IF NOT EXISTS t8(id BIGINT AUTO_INCREMENT,body TEXT,PRIMARY KEY (id));
DROP INDEX IF EXISTS ft_index ON t8;
ALTER TABLE t8 ADD FULLTEXT INDEX ft_index (body) WITH PARSER standard;
TRUNCATE TABLE t8;
INSERT INTO t8 (body) VALUES
    ('This is the first test data, used to demonstrate the insert operation'),
    ('The second record contains some sample text for testing'),
    ('Third entry: verifying the TEXT field''s ability to store longer content'),
    ('Fourth data row, which can be used for subsequent query or analysis tests'),
    ('Fifth sample entry to complete the basic insertion example');

CREATE TABLE IF NOT EXISTS t7(id BIGINT AUTO_INCREMENT,content TEXT,PRIMARY KEY (id));
DROP INDEX IF EXISTS ft_index ON t7;
ALTER TABLE t7 ADD FULLTEXT INDEX ft_index (content) WITH PARSER standard;
TRUNCATE TABLE t7;
INSERT INTO t7 (content) VALUES
    ('This is the first test data, used to demonstrate the insert operation'),
    ('The second record contains some sample text for testing'),
    ('Third entry: verifying the TEXT field''s ability to store longer content'),
    ('Fourth data row, which can be used for subsequent query or analysis tests'),
    ('Fifth sample entry to complete the basic insertion example');
