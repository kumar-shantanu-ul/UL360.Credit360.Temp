-- Please update version too -- this keeps clean builds in sync
define version=1719
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

begin
	UPDATE CSR.STD_MEASURE_CONVERSION SET a = 0.000000000001 WHERE std_measure_conversion_id = 26173;
end;
/

@update_tail