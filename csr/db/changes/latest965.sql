-- Please update version.sql too -- this keeps clean builds in sync
define version=965
@update_header

DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns 
	 WHERE owner = 'CSR'
	   AND table_name = 'EST_CUSTOMER' 
	   AND column_name = 'ORG_NAME' 
	   AND nullable = 'N';
	 
	IF v_count = 1 THEN
		EXECUTE IMMEDIATE('
			ALTER TABLE CSR.EST_CUSTOMER MODIFY ORG_NAME VARCHAR(256) NULL
		');
	END IF;
END;
/

@update_tail
