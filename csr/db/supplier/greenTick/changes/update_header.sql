set verify off
prompt ================== VERSION &version ========================
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

DECLARE
	v_version	version.db_version%TYPE;
	v_user		varchar2(30);
	v_part		version.part%TYPE DEFAULT 'greentick';
BEGIN
	
	SELECT user
	  INTO v_user
	  FROM dual;
	IF v_user <> 'SUPPLIER' THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO THE '||v_user||' SCHEMA =======');
	END IF;
	
	BEGIN
		SELECT db_version INTO v_version FROM version WHERE part=v_part;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF &version = 1 THEN
				INSERT INTO version (db_version, part) VALUES (0, v_part);
				v_version := 0;
			END IF;
			
			IF &version > 1 THEN
				RAISE_APPLICATION_ERROR(-20001, '========= '||UPPER(v_part)||' UPDATE '||&version||' CANNOT BE APPLIED TO AN EMPTY DATABASE OF VERSION =======');
			END IF;
	END;
	
	
	IF v_version >= &version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= '||UPPER(v_part)||' UPDATE '||&version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	
	IF v_version + 1 <> &version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= '||UPPER(v_part)||' UPDATE '||&version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/
