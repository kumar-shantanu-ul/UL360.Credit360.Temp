-- Please update version.sql too -- this keeps clean builds in sync
define version=249
@update_header

CREATE OR REPLACE VIEW val_converted (
	app_sid, val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, 
	aggr_est_number, alert, flags, source_id, entry_measure_conversion_id, entry_val_number, 
	last_val_change_id, note, source_type_id, factor
) AS
	SELECT v.app_sid, v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
		   v.entry_val_number * NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) val_number, -- we derive val_number from entry_val_number in case of pct_ownership
		   v.aggr_est_number,
		   v.alert, v.flags, v.source_id,
		   v.entry_measure_conversion_id, v.entry_val_number, v.last_val_change_id,
		   v.note, v.source_type_id,
		   NVL(mc.conversion_factor, mcp.conversion_factor) factor
	  FROM val v, measure_conversion mc, measure_conversion_period mcp
	 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
	   AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
	   AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
	   AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null)
	   AND v.app_sid = mc.app_sid
	   AND v.app_sid = mcp.app_sid
	   AND mc.app_sid = mcp.app_sid;

@update_tail
