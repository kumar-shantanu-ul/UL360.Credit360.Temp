-- removes hard-coded URL with hosts from Help text
DECLARE
BEGIN
  FOR r IN (
      SELECT REGEXP_REPLACE(body, 'https?://([a-zA-Z0-9\.\-]+\.?){3,4}/?', '/') RESULT, ROWID rid
        FROM help_topic_text 
       WHERE length(REGEXP_SUBSTR(body, 'https?://([a-zA-Z0-9\.\-]+\.?){3,4}/?')) > 0
  )
  LOOP
    UPDATE help_topic_text SET BODY = r.RESULT WHERE ROWID = r.rid;
  END LOOP;
END;
/