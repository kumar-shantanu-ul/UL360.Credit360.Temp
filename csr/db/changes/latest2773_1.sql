-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=1
define is_combined=0
@update_header

-- Remove column added in create_schema but had no change script that was
-- also removed from live without a change script...

DECLARE
	v_exists	NUMBER;
BEGIN
	-- Just check for the constraint.
	-- If this exists the column must do too.
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_constraints
	 WHERE constraint_name = 'REFCSR_USER2983'
	   AND owner = 'CSR';
	
	IF v_exists = 1 THEN
		EXECUTE IMMEDIATE('ALTER TABLE csr.deleg_data_change_alert DROP CONSTRAINT REFCSR_USER2983');
		EXECUTE IMMEDIATE('ALTER TABLE csr.deleg_data_change_alert DROP COLUMN csr_user_sid');
	END IF;
END;
/

@update_tail
