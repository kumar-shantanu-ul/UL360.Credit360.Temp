-- Please update version.sql too -- this keeps clean builds in sync
define version=1867
@update_header
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (8, 'Percentage change from same period previous year');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (9, 'Percentage in year to date from same period previous year');
@update_tail


