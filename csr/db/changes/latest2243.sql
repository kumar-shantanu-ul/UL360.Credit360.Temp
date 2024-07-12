-- Please update version.sql too -- this keeps clean builds in sync
define version=2243
@update_header

DECLARE
	v_col_exists		NUMBER(1);
BEGIN
	SELECT COUNT(column_name)
	  INTO v_col_exists
	  FROM all_tab_cols
	 WHERE owner = 'CSR'
	   AND table_name = 'CUSTOMER'
	   AND column_name = 'RESTRICT_ISSUE_VISIBILITY';
	
	IF v_col_exists = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.customer ADD restrict_issue_visibility NUMBER(1) DEFAULT 1 NOT NULL';
		EXECUTE IMMEDIATE 'ALTER TABLE csr.customer ADD CONSTRAINT ck_customer_issue_visibility CHECK (check_divisibility IN (0, 1))';
	END IF;
END;
/

@../issue_body
    	
@update_tail
