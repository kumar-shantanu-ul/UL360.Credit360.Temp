-- Please update version.sql too -- this keeps clean builds in sync
define version=2128
@update_header

DECLARE
	v_cnt NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_objects
	 WHERE owner = 'CSR'
	   AND object_name = 'ENABLE_UTILS_PKG';
	
	IF v_cnt > 0 THEN		
		EXECUTE IMMEDIATE 'DROP PACKAGE CSR.enable_utils_pkg';
	END IF;
END;
/

@..\enable_pkg
@..\enable_body

@update_tail
