define version=67
@update_header

DECLARE
	v_rap5 		version.db_version%TYPE;
BEGIN
	SELECT MAX(db_version)
	  INTO v_rap5
	  FROM chain.version
	 WHERE part = 'rap5';
	
	IF v_rap5 IS NULL THEN
		update chain.version set db_version = &version where part = 'trunk';
	ELSIF v_rap5 < 14 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= RAP5 VERSION IS SITTING MID VERSION - PLEASE FINISH RUNNING IT AND THEN RE-RUN THIS SCRIPT =======');
	ELSE
		-- allow it to skip the rap5->trunk merge script
		update chain.version set db_version = &version + 1 where part = 'trunk';
	END IF;
END;
/

-- update tail not included because we're manually fiddling the version above
commit;
PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
