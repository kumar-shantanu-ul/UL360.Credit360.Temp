-- Please update version.sql too -- this keeps clean builds in sync
define version=2343
@update_header

DECLARE
  PROCEDURE fix_standard_factor(
    in_std_factor_id  number,
    in_factor_type_id number,
    in_value	      number,
    in_description    varchar2
  )

  AS
    v_std_measure_conversion_id   NUMBER(10);

  BEGIN
    update csr.std_factor
    set std_measure_conversion_id=16
    where std_factor_id=in_std_factor_id;
  END;

BEGIN
  fix_standard_factor(184318610, 8066, 3.715712,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318615, 8130, 2.476656,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318619, 8179, 1.88496,		'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318728, 8066, 0.0003016,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318733, 8130, 0.0002268,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318737, 8179, 0.000168,	'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318846, 8066, 0.000006032,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318851, 8130, 0.000004536,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318855, 8179, 0.00000336,	'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318964, 8066, 3.723916,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318969, 8130, 2.482825,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184318973, 8179, 1.88953,		'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319082, 8066, 3.715712,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319087, 8130, 2.476656,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319091, 8179, 1.88496,		'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319200, 8066, 0.0003016,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319205, 8130, 0.0002268,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319209, 8179, 0.000168,	'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319318, 8066, 0.000006032,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319323, 8130, 0.000004536,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319327, 8179, 0.00000336,	'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319436, 8066, 3.723916,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319441, 8130, 2.482825,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319445, 8179, 1.88953,		'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319554, 8066, 3.715712,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319559, 8130, 2.476656,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319563, 8179, 1.88496,		'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319672, 8066, 0.0003016,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319677, 8130, 0.0002268,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319681, 8179, 0.000168,	'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319790, 8066, 0.000006032,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319795, 8130, 0.000004536,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319799, 8179, 0.00000336,	'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319908, 8066, 3.723916,	'Stationary Fuel - Ethane (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319913, 8130, 2.482825,	'Stationary Fuel - Landfill Gas (Compressed) (Volume) (Direct)');
  fix_standard_factor(184319917, 8179, 1.88953,		'Stationary Fuel - Natural Gas (Compressed) (Volume) (Direct)');
END;
/

@update_tail
