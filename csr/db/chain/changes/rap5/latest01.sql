define rap5_version=1

whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

DECLARE
	v_version	version.db_version%TYPE;
	v_user		varchar2(30);
BEGIN
	SELECT user
	  INTO v_user
	  FROM dual;
	  
	IF v_user <> 'CHAIN' THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE CANNOT BE APPLIED TO THE '||v_user||' SCHEMA =======');
	END IF;
	
	BEGIN
		SELECT db_version 
		  INTO v_version
		  FROM chain.version
		 WHERE part='rap5';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_version := NULL;
	END;
	
	IF v_version IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, '========= "rap5" PART ALREADY EXISTS AT VERSION '||v_version||'=======');
	END IF;
	
	INSERT INTO version
	(db_version, part)
	VALUES
	(1, 'rap5'); 
END;
/

commit;

exit

