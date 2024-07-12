CREATE OR REPLACE PACKAGE CSR.meter_aggr_pkg IS

-- Bucketer aggregate functions

PROCEDURE Sum(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_val				OUT	meter_live_data.consumption%TYPE,
	out_raw_data_id		OUT	meter_raw_data.meter_raw_data_id%TYPE
);

PROCEDURE Average(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_val				OUT	meter_live_data.consumption%TYPE,
	out_raw_data_id		OUT	meter_raw_data.meter_raw_data_id%TYPE
);

-- Aggr ind functions
PROCEDURE GetDataCoverageDaysAggr(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END meter_aggr_pkg;
/
