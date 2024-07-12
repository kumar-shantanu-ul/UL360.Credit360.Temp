--Please update version.sql too -- this keeps clean builds in sync
define version=2630
@update_header

-- Fix meter reading baseline_val column not being nullable in create_schema.
DECLARE
	v_is_nullable		NUMBER(1);
BEGIN
	SELECT COUNT(*)
	  INTO v_is_nullable
	  FROM all_tab_cols
	 WHERE owner = 'CSR'
	   AND table_name = 'METER_READING'
	   AND column_name = 'BASELINE_VAL'
	   AND NULLABLE = 'N';
	
	IF v_is_nullable = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.meter_reading MODIFY baseline_val NULL';
	END IF;
END;
/

-- Grants
GRANT SELECT, INSERT, UPDATE ON CSR.ALL_PROPERTY TO CSRIMP;
GRANT SELECT, INSERT, UPDATE ON CSR.ALL_SPACE TO CSRIMP;
REVOKE INSERT, UPDATE ON CSR.PROPERTY FROM CSRIMP;
REVOKE INSERT, UPDATE ON CSR.SPACE FROM CSRIMP;

@../csrimp/imp_body
	
@update_tail
