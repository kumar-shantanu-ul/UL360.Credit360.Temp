-- Please update version.sql too -- this keeps clean builds in sync
define version=1550
@update_header

-- insert base data missing from latest scripts.
BEGIN
	BEGIN
		INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (8, 'Selected region and its children');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (9, 'Selected region, its parents and its children');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

@update_tail
