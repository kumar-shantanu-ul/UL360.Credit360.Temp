--Please update version.sql too -- this keeps clean builds in sync
define version=2657
@update_header

BEGIN
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (12, 'Comparative year to date');
EXCEPTION WHEN dup_val_on_index THEN
	NULL;
END;
/

@update_tail
