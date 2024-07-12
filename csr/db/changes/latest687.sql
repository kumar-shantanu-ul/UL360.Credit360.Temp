-- Please update version.sql too -- this keeps clean builds in sync
define version=687
@update_header

INSERT INTO csr.calculation_type (calculation_type_id, description)
	VALUES (3, 'Same period previous year');
INSERT INTO csr.calculation_type (calculation_type_id, description)
	VALUES (4, 'Same period in the year before last year');

@update_tail
