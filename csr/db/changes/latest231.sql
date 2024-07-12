-- Please update version.sql too -- this keeps clean builds in sync
define version=231
@update_header

alter table val drop column status;

CREATE OR REPLACE FORCE VIEW VAL_CONVERTED (VAL_ID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM, VAL_NUMBER, AGGR_EST_NUMBER, ALERT, FLAGS, SOURCE_ID, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, LAST_VAL_CHANGE_ID, NOTE, SOURCE_TYPE_ID, FACTOR) AS 
SELECT v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
      v.entry_val_number * NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) val_number, -- we derive val_number from entry_val_number in case of pct_ownership
      v.aggr_est_number,
      v.alert, v.flags, v.source_id,
      v.entry_measure_conversion_id, v.entry_val_number, v.last_val_change_id,
      v.note, v.source_type_id,
      NVL(mc.conversion_factor, mcp.conversion_factor) factor
 FROM VAL V, MEASURE_CONVERSION MC, MEASURE_CONVERSION_PERIOD MCP
WHERE MC.MEASURE_CONVERSION_ID = MCP.MEASURE_CONVERSION_ID(+)
  AND V.entry_measure_conversion_id = mc.measure_conversion_id(+)
  AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
  AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);

@..\indicator_pkg
@..\region_body
@..\sheet_body
@..\meter_body
@..\imp_body
@..\indicator_body
@..\approval_step_range_body
@..\measure_body
@..\val_body
@..\schema_pkg
@..\schema_body
@..\form_body
@..\range_body
@..\val_datasource_pkg
@..\val_datasource_body

alter session set current_schema="ACTIONS";
@..\actions\initiative_body
@..\actions\task_body

alter session set current_schema="CSR";
@..\..\..\aspen2\tools\recompile_packages

@update_tail
