-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=4
@update_header

-- FB69680

BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (49, 'Delegation Reports', 'EnableDelegationReports', 'Enables delegation reporting. Adds a menu item to the admin menu.', 0);
EXCEPTION WHEN dup_val_on_index THEN 
	NULL;
END;
/

@../enable_pkg
@../enable_body

@update_tail
