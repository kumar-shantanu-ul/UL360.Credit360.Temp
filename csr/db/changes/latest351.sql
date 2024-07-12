-- Please update version.sql too -- this keeps clean builds in sync
define version=351
@update_header

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count FROM all_constraints WHERE constraint_name = 'REFAPPROVAL_STEP461' AND owner = 'CSR' AND table_name = 'APPROVAL_STEP';

	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.approval_step DROP CONSTRAINT refapproval_step461';
	END IF;
END;
/

@update_tail
