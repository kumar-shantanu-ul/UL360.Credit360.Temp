-- Please update version.sql too -- this keeps clean builds in sync
define version=2563
@update_header

DECLARE
	v_nullable	VARCHAR2(1);
BEGIN
	SELECT nullable INTO v_nullable
	  FROM all_tab_columns
	 WHERE UPPER(owner) = 'CSR'
	   AND UPPER(table_name) = 'EST_ATTR_MEASURE'
	   AND UPPER(column_name) = 'MEASURE_SID';
	
	IF v_nullable <> 'Y' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.EST_ATTR_MEASURE MODIFY (MEASURE_SID	NUMBER(10, 0) NULL)';
	END IF;
END;
/

@../measure_body

@update_tail
