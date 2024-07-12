-- Please update version.sql too -- this keeps clean builds in sync
define version=2310
@update_header

    INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28132, 17, 'mWh/t', 0.000000277778, 1, 0, 0);
    UPDATE CSR.STD_MEASURE_CONVERSION SET A = 0.000000000277778 WHERE std_measure_conversion_id = 28131;

@update_tail