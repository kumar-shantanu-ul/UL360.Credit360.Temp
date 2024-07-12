-- Please update version.sql too -- this keeps clean builds in sync
define version=1906
@update_header

BEGIN
	BEGIN
		INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL)
		VALUES (15, 'Immediate children of the currently selected region');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

@update_tail
