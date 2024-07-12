set verify off
prompt ================== VERSION &&rap4_version ========================
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
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&&rap4_version||' CANNOT BE APPLIED TO THE '||v_user||' SCHEMA =======');
	END IF;
	SELECT db_version INTO v_version FROM version WHERE PART='rap4';
	IF v_version >= &&rap4_version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&&rap4_version||' HAS ALREADY BEEN APPLIED TO PART "rap4"=======');
	END IF;
	IF v_version + 1 <> &&rap4_version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&&rap4_version||' CANNOT BE APPLIED TO A PART "rap4" DATABASE OF VERSION '||v_version||' =======');
	END IF;
	IF &&rap4_version > 15 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= THE RAP4 BRANCH IS NOW CLOSED =======');
	END IF;
END;
/
