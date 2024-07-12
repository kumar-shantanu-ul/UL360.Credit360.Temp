-- Please update version.sql too -- this keeps clean builds in sync
define version=2312
@update_header

    UPDATE CSR.STD_MEASURE_CONVERSION SET A = 0.000000000277777778 WHERE std_measure_conversion_id = 28131;
    UPDATE CSR.STD_MEASURE_CONVERSION SET A = 0.000000277777778 WHERE std_measure_conversion_id = 28132;

@update_tail