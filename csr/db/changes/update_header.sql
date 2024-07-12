set verify off

column minor_version new_value minor_version noprint
select '' "minor_version" from dual where rownum=0;
select 0 "minor_version" from dual where '&minor_version' is null;

column 2 new_value 2 noprint
select '' "2" from dual where rownum=0;
define ignore_failures='&&2'

column 3 new_value 3 noprint
select '' "3" from dual where rownum=0;
define ignore_version='&&3'

column is_combined new_value is_combined noprint
select '' "is_combined" from dual where rownum=0;
select 0 "is_combined" from dual where '&is_combined' is null;


prompt ================== VERSION &version..&minor_version ========================
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

alter session set ddl_lock_timeout=120;

DECLARE
	v_version		csr.version.db_version%TYPE;
	v_minor_version	number;
	v_user			varchar2(30);
	v_has_minor		number;
BEGIN
	IF NVL('&&ignore_version','0') != 1 THEN
		SELECT COUNT(*)
		  INTO v_has_minor
		  FROM all_tab_columns
		 WHERE table_name = 'VERSION'
		   AND owner = 'CSR'
		   AND column_name = 'MINOR_VERSION';
		
		IF v_has_minor > 0 THEN
			EXECUTE IMMEDIATE 'SELECT db_version, minor_version FROM csr.version' INTO v_version, v_minor_version;
		ELSE
			SELECT db_version, 0
			  INTO v_version, v_minor_version
			  FROM csr.version;
		END IF;
		
		IF v_version > &version THEN
			RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||'.'||&minor_version||' HAS ALREADY BEEN APPLIED =======');
		END IF;
		IF v_version + 1 <> &version THEN
			IF v_version <> &version THEN
				RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||'.'||&minor_version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||'.'||v_minor_version||' =======');
			END IF;
			IF v_minor_version + 1 <> &minor_version THEN
				RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||'.'||&minor_version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||'.'||v_minor_version||' =======');
			END IF;
		END IF;
		IF v_version + 1 = &version AND &minor_version <> 0 THEN
			RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||'.'||&minor_version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||'.'||v_minor_version||' =======');
		END IF;
		SELECT user
		  INTO v_user
		  FROM dual;
		IF v_version < 763 THEN
			IF v_user <> 'CSR' THEN
				RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||'.'||&minor_version||' CANNOT BE APPLIED TO THE '||v_user||' SCHEMA =======');
			END IF;
		ELSE
			IF v_user IN ('ACTIONS', 'CHAIN', 'CMS', 'CSR', 'CSRIMP', 'DONATIONS', 'SUPPLIER', 'ASPEN2', 'POSTCODE') THEN
				RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||'.'||&minor_version||' SHOULD BE RUN BY A SEPARATE DBA NOT '||v_user||' =======');
			END IF;
		END IF;
	END IF;
END;
/

whenever oserror continue
whenever sqlerror continue

column fail_script_path new_value fail_script_path noprint;
select '' "fail_script_path" from dual where rownum=0;
select decode('&ignore_failures', '1', decode('&is_combined', '1', 'null_script.sql', 'fail_on_error.sql'), 'fail_on_error.sql') "fail_script_path" from dual;
PROMPT Running &fail_script_path
@&fail_script_path

column 1 new_value 1 noprint
select '' "1" from dual where rownum=0;
define batch_apply='&&1'
