-- Please update version.sql too -- this keeps clean builds in sync
define version=335
@update_header

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count FROM all_tab_columns WHERE table_name = 'PENDING_DATASET' AND owner = 'CSR' AND column_name = 'NEW_SID';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.pending_dataset ADD (new_sid NUMBER(10))';
	END IF;
END;
/

@..\pending_body.sql

@update_tail
