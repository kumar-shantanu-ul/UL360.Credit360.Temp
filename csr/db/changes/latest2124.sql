-- Please update version.sql too -- this keeps clean builds in sync
define version=2124
@update_header

INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (10,'Absolute change');

@update_tail
