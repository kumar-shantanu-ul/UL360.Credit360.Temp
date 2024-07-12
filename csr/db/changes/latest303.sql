-- Please update version.sql too -- this keeps clean builds in sync
define version=303
@update_header

ALTER TABLE IMP_VAL ADD (NOTE CLOB);

CREATE OR REPLACE VIEW V$IMP_MERGE AS
    SELECT iv.imp_val_id, iv.imp_session_Sid, iv.file_sid, ii.maps_to_ind_sid, iv.start_dtm, iv.end_dtm, 
           ii.description ind_description,
           i.description maps_to_ind_description,
           ir.description region_description,
           i.aggregate,
           iv.val,			               				
           NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) factor,
           m.description measure_description,
           im.maps_to_measure_conversion_id,
           mc.description from_measure_description,
           NVL(i.format_mask, m.format_mask) format_mask,
           ir.maps_to_region_sid, 
           iv.rowid rid,
           ii.app_Sid, iv.note
      FROM imp_val iv,
           imp_ind ii,
           imp_region ir,
           imp_measure im,
           imp_conflict_val icv,
           measure_conversion mc,
           measure_conversion_period mcp,
           ind i,
           measure m
     WHERE --iv.file_sid = in_file_sid
       --iv.imp_session_sid = 9878663
        iv.imp_ind_id = ii.imp_ind_id
       AND iv.imp_region_id = ir.imp_region_id
       AND maps_to_region_sid IS NOT NULL
       AND maps_to_ind_sid IS NOT NULL
       AND im.imp_ind_id(+) = iv.imp_ind_id
       AND im.imp_measure_id(+) = iv.imp_measure_id
       AND im.maps_to_measure_conversion_id = mc.measure_conversion_id(+)
       AND maps_to_ind_sid = i.ind_sid
       AND i.measure_sid = m.measure_sid 
       AND MC.MEASURE_CONVERSION_ID = MCP.MEASURE_CONVERSION_ID(+)
       AND (iv.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
       AND (iv.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
       AND iv.imp_val_id = icv.imp_val_id(+)
       AND icv.imp_conflict_id is null
       AND iv.app_sid = ii.app_sid
       AND iv.app_sid = ir.app_sid
       AND ii.app_sid = i.app_sid
       AND i.app_sid = m.app_sid;

@..\imp_body

@update_tail
