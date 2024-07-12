-- Please update version.sql too -- this keeps clean builds in sync
define version=479
@update_header

DELETE FROM gas_type;

BEGIN
	INSERT INTO gas_type (gas_type_id, name) VALUES (1, 'CO2E');
	INSERT INTO gas_type (gas_type_id, name) VALUES (2, 'CO2');
	INSERT INTO gas_type (gas_type_id, name) VALUES (3, 'CH4');
	INSERT INTO gas_type (gas_type_id, name) VALUES (4, 'N2O');
END;
/

@update_tail
