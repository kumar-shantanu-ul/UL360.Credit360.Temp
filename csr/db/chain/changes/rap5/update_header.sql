set verify off
prompt ================== VERSION &rap5_version ========================
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
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE &rap5_version CANNOT BE APPLIED TO THE '||v_user||' SCHEMA =======');
	END IF;
	
	SELECT db_version 
	  INTO v_version 
	  FROM version 
	 WHERE PART='rap5';
		
	IF v_version >= &rap5_version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE &rap5_version HAS ALREADY BEEN APPLIED TO PART "rap5"=======');
	END IF;
	IF v_version + 1 <> &rap5_version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE &rap5_version CANNOT BE APPLIED TO A PART "rap5" DATABASE OF VERSION '||v_version||' =======');
	END IF;
	IF &&rap5_version > 14 THEN
			RAISE_APPLICATION_ERROR(-20001, '========= THE RAP5 BRANCH IS NOW CLOSED =======');
	END IF;
END;
/
