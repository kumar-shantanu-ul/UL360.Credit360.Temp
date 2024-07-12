-- Please update version.sql too -- this keeps clean builds in sync
define version=1257
@update_header

--common script
BEGIN
	UPDATE ct.volume_unit SET symbol = 'litre' WHERE volume_unit_id = 1;
	UPDATE ct.mass_unit SET symbol= 'ton' WHERE mass_unit_id = 3;
	UPDATE ct.power_unit SET description = 'Watt hour', symbol = 'Wh' WHERE power_unit_id = 1;
	UPDATE ct.power_unit SET description = 'Kilowatt hour', symbol = 'kWh' WHERE power_unit_id = 2;
	UPDATE ct.power_unit SET description = 'Megawatt hour', symbol = 'MWh' WHERE power_unit_id = 3;
END;
/

@update_tail