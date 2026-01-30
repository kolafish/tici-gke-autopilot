CREATE TABLE IF NOT EXISTS t9(id BIGINT AUTO_INCREMENT,body TEXT,PRIMARY KEY (id));
ALTER TABLE t9 ADD FULLTEXT INDEX ft_index (body) WITH PARSER standard;
INSERT INTO t9 (body) VALUES
    ('This is the first test pdata, used to demonstrate the insert operation'),
    ('The second record contains some sample text for testing'),
    ('Third entry: verifying the TEXT field''s ability to store longer content'),
    ('Fourth data row, which can be used for subsequent query or analysis tests'),
    ('Fifth sample entry to complete the basic insertion example');
SELECT * FROM t9 WHERE fts_match_word('first', body);

CREATE TABLE IF NOT EXISTS t8(id BIGINT AUTO_INCREMENT,body TEXT,PRIMARY KEY (id));
ALTER TABLE t8 ADD FULLTEXT INDEX ft_index (body) WITH PARSER standard;
INSERT INTO t8 (body) VALUES
    ('This is the first test data, used to demonstrate the insert operation'),
    ('The second record contains some sample text for testing'),
    ('Third entry: verifying the TEXT field''s ability to store longer content'),
    ('Fourth data row, which can be used for subsequent query or analysis tests'),
    ('Fifth sample entry to complete the basic insertion example');
SELECT * FROM t8 WHERE fts_match_word('first', body);

CREATE TABLE IF NOT EXISTS t7(id BIGINT AUTO_INCREMENT,content TEXT,PRIMARY KEY (id));
ALTER TABLE t7 ADD FULLTEXT INDEX ft_index (content) WITH PARSER standard;
INSERT INTO t7 (content) VALUES
    ('This is the first test data, used to demonstrate the insert operation'),
    ('The second record contains some sample text for testing'),
    ('Third entry: verifying the TEXT field''s ability to store longer content'),
    ('Fourth data row, which can be used for subsequent query or analysis tests'),
    ('Fifth sample entry to complete the basic insertion example');
SELECT * FROM t7 WHERE fts_match_word('first', content);
