-- Please update version.sql too -- this keeps clean builds in sync
define version=1230
@update_header

-- correction to some conversion factors - wrong way round
	UPDATE ct.distance_unit 
	   SET conversion_to_km = 1/0.621371192
	 WHERE distance_unit_id = 2;
	 
	UPDATE ct.volume_unit 
	   SET conversion_to_litres = 1/0.264172053
	 WHERE volume_unit_id = 2;
	 
	UPDATE ct.volume_unit 
	   SET conversion_to_litres = 1/0.219969157
	 WHERE volume_unit_id = 3;
	   
	UPDATE ct.mass_unit
	   SET conversion_to_kg = 1/0.45359237
	 WHERE mass_unit_id = 2;

@update_tail
