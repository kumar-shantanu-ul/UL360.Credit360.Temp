-- Please update version.sql too -- this keeps clean builds in sync
define version=159
@update_header


CREATE OR REPLACE FORCE VIEW PENDING_VAL_CONVERTED (
	pending_val_id, pending_ind_id, pending_region_id, pending_period_id, approval_step_id, 	
	 val_number, val_string, from_val_number, from_measure_conversion_id, action, 
	 factor, start_dtm, end_dtm, actual_val_number
) AS
  SELECT pending_val_id, pending_ind_id, pending_region_id, pv.pending_period_id, approval_step_id, 
		pv.from_val_number * nvl(nvl(mc.conversion_factor, mcp.conversion_factor), 1) val_number, 
		val_string, 
		from_val_number, 
		from_measure_conversion_id, 
		action, 
	    NVL(mc.conversion_factor, mcp.conversion_factor) factor, 
	    pp.start_dtm, 
	    pp.end_dtm, 
	    pv.val_number actual_val_number
    FROM pending_val pv, pending_period pp, measure_conversion mc, measure_conversion_period mcp
   WHERE pp.pending_period_id = pv.pending_period_id
     AND pv.from_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (pp.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (pp.start_dtm < mcp.end_dtm or mcp.end_dtm is null);

@..\measure_body
     
@update_tail
