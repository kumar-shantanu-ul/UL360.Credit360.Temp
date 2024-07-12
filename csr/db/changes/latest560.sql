-- Please update version.sql too -- this keeps clean builds in sync
define version=560
@update_header

update std_measure_conversion
   set description = 'lb/GWh', A = 7936641432000
   where std_measure_conversion_id = 49;

insert into std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	values (59, 9, 'lb/MWh', 7936641432, 1, 0);

@update_tail
