USE tici_sample;

SELECT * FROM __TABLE_NAME__ WHERE fts_match_word('first', body);
