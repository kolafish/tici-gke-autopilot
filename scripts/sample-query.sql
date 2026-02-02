USE tici_sample;

SELECT * FROM t9 WHERE fts_match_word('first', body);
SELECT * FROM t8 WHERE fts_match_word('first', body);
SELECT * FROM t7 WHERE fts_match_word('first', content);
