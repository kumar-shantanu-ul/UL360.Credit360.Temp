WHENEVER oserror EXIT FAILURE
WHENEVER sqlerror EXIT FAILURE

--COLUMN 1 NEW_VALUE 1
--SELECT '' "1" FROM DUAL WHERE ROWNUM = 0;
-- Just to use more meaningful variable, i will give it a name
DEF SCRIPT_NAME='&1'

COLUMN 2 NEW_VALUE 2
SELECT '' "2" FROM DUAL WHERE ROWNUM = 1;
DEF SITE_NAME='&2'

VARIABLE bv_site_name VARCHAR2(100);
BEGIN
    :bv_site_name := '&&SITE_NAME';

	IF :bv_site_name IS NULL OR LENGTH(:bv_site_name) = 0 THEN
	  :bv_site_name := 'rag.credit360.com';
	END IF;

    dbms_output.put_line('site set to '||:bv_site_name);
END;
/

-- Run script
@&&SCRIPT_NAME

