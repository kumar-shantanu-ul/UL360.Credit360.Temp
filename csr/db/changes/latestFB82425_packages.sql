CREATE OR REPLACE PACKAGE csr.temp_factors_pkg
IS

PROCEDURE StdFactorAmendValue(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	in_value				IN std_factor.value%TYPE,
	in_std_meas_conv_id		IN std_factor.std_measure_conversion_id%TYPE,
	in_note					IN std_factor.note%TYPE
);

END temp_factors_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_factors_pkg
IS

PROCEDURE StdFactorAmendValue(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	in_value				IN std_factor.value%TYPE,
	in_std_meas_conv_id		IN std_factor.std_measure_conversion_id%TYPE,
	in_note					IN std_factor.note%TYPE
)
AS
BEGIN
	
	UPDATE factor SET start_dtm = in_start_dtm,
						  end_dtm = in_end_dtm,
						  gas_type_id = in_gas_type_id,
						  value = in_value,
						  std_measure_conversion_id = in_std_meas_conv_id,
						  note = in_note
					WHERE std_factor_id = in_std_factor_id;
					
	UPDATE std_factor SET start_dtm = in_start_dtm,
						  end_dtm = in_end_dtm,
						  gas_type_id = in_gas_type_id,
						  value = in_value,
						  std_measure_conversion_id = in_std_meas_conv_id,
						  note = in_note
					WHERE std_factor_id = in_std_factor_id;

END;

END temp_factors_pkg;
/