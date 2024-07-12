-- Please update version.sql too -- this keeps clean builds in sync
define version=2341
@update_header

  UPDATE CSR.STD_MEASURE_CONVERSION 
     SET STD_MEASURE_ID = 28,
         DESCRIPTION = 'l/kWh',
         A = 3600000000,
         B = 1,
         C = 0,
         DIVISIBLE = 1
   WHERE STD_MEASURE_CONVERSION_ID = 28120;

  UPDATE CSR.STD_MEASURE_CONVERSION
     SET STD_MEASURE_ID = 17,
         DESCRIPTION = 'kWh/kg',
         A = 0.0000002777777778,
         B = 1,
         C = 0,
         DIVISIBLE = 1
   WHERE STD_MEASURE_CONVERSION_ID = 28121;

@update_tail
