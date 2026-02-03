USE tici_sample;

SELECT * FROM t1 WHERE fts_match_word('first', body);
