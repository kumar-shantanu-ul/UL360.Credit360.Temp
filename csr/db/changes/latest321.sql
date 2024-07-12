-- Please update version.sql too -- this keeps clean builds in sync
define version=321
@update_header

CREATE OR REPLACE FORCE VIEW sheet_value_converted 
	(app_sid, sheet_value_id, sheet_id, ind_sid, region_sid, val_number, set_by_user_sid, 
	 set_dtm, note, entry_measure_conversion_id, entry_val_number, is_inherited, 
	 status, last_sheet_value_change_id, alert, flag, factor, 
	 start_dtm, end_dtm, actual_val_number) AS
  SELECT sv.app_sid, sv.sheet_value_id, sv.sheet_id, sv.ind_sid, sv.region_sid,
         sv.entry_val_number * NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) val_number,
         sv.set_by_user_sid, sv.set_dtm, sv.note,
         sv.entry_measure_conversion_id, sv.entry_val_number,
         sv.is_inherited, sv.status, sv.last_sheet_value_change_id,
         sv.alert, sv.flag,
         NVL(mc.conversion_factor, mcp.conversion_factor) factor,
         s.start_dtm, s.end_dtm, sv.val_number actual_val_number
    FROM sheet_value sv, sheet s, measure_conversion mc, measure_conversion_period mcp
   WHERE sv.app_sid = s.app_sid 
     AND sv.sheet_id = s.sheet_id
     AND sv.app_sid = mc.app_sid(+)
     AND sv.entry_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.app_sid = mcp.app_sid(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (s.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (s.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
;

@update_tail