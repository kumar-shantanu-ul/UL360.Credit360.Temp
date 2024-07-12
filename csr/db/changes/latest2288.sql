-- Please update version.sql too -- this keeps clean builds in sync
define version=2288
@update_header

DELETE FROM CSR.STD_MEASURE_CONVERSION
WHERE STD_MEASURE_CONVERSION_ID = 28131
AND STD_MEASURE_ID = 3
AND DESCRIPTION = 'm^3/m^2'
AND A=1
AND B=1
AND C=0
AND DIVISIBLE=0;

@update_tail