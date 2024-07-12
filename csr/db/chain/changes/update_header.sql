set verify off
prompt ================== VERSION &version ========================
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
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE &version CANNOT BE APPLIED TO THE '||v_user||' SCHEMA =======');
	END IF;
	IF &version < 52 THEN
		SELECT db_version INTO v_version FROM version;
	ELSE
		EXECUTE IMMEDIATE 'BEGIN SELECT db_version INTO :1 FROM version WHERE PART=''trunk''; END;'
		USING OUT v_version;
	END IF;
	IF v_version >= &version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE &version HAS ALREADY BEEN APPLIED TO PART "trunk"=======');
	END IF;
	IF v_version + 1 <> &version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE &version CANNOT BE APPLIED TO A PART "trunk" DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/
