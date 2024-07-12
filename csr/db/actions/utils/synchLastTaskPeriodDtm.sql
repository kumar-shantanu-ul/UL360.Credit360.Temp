
BEGIN
	FOR r IN (
		SELECT task_sid, MAX(start_dtm) start_dtm FROM task_period GROUP BY task_sid
  		)
	LOOP
		UPDATE TASK SET last_task_period_dtm = r.start_dtm WHERE task_sid = r.task_sid; 
	END LOOP;
END; 
