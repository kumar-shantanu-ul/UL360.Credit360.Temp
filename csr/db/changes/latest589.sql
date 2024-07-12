-- Please update version.sql too -- this keeps clean builds in sync
define version=589
@update_header


CREATE OR REPLACE VIEW V$IMP_VAL_MAPPED AS
    SELECT iv.imp_val_id, iv.imp_session_Sid, iv.file_sid, ii.maps_to_ind_sid, iv.start_dtm, iv.end_dtm, 
           ii.description ind_description,
           i.description maps_to_ind_description,
           ir.description region_description,
           i.aggregate,
           iv.val,			               				
           NVL(NVL(mc.a, mcp.a),1) factor_a,
           NVL(NVL(mc.b, mcp.b),1) factor_b,
           NVL(NVL(mc.c, mcp.c),0) factor_c,
           m.description measure_description,
           im.maps_to_measure_conversion_id,
           mc.description from_measure_description,
           NVL(i.format_mask, m.format_mask) format_mask,
           ir.maps_to_region_sid, 
           iv.rowid rid,
           ii.app_Sid, iv.note,
           CASE WHEN m.custom_field LIKE '|%' THEN 1 ELSE 0 END is_text_ind,
           icv.imp_conflict_id,
           iv.imp_ind_id, iv.imp_region_id
      FROM imp_val iv
           JOIN imp_ind ii ON iv.imp_ind_id = ii.imp_ind_id AND iv.app_sid = ii.app_sid
           JOIN imp_region ir ON iv.imp_region_id = ir.imp_region_id AND iv.app_sid = ir.app_sid
           LEFT JOIN imp_measure im 
                ON  iv.imp_ind_id = im.imp_ind_id 
                AND iv.imp_measure_id = im.imp_measure_id 
                AND iv.app_sid = im.app_sid
           LEFT JOIN measure_conversion mc
                ON im.maps_to_measure_conversion_id = mc.measure_conversion_id
                AND im.app_sid = mc.app_sid
           LEFT JOIN measure_conversion_period mcp                
                ON mc.measure_conversion_id = mcp.measure_conversion_id
                AND (iv.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
                AND (iv.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
           LEFT JOIN imp_conflict_val icv
                ON iv.imp_val_id = icv.imp_val_id
                AND iv.app_sid = icv.app_sid
           JOIN ind i 
                ON ii.maps_to_ind_sid = i.ind_sid
                AND ii.app_sid = i.app_sid
           JOIN measure m 
                ON i.measure_sid = m.measure_sid 
                AND i.app_sid = m.app_sid
     WHERE ir.maps_to_region_sid IS NOT NULL
       AND ii.maps_to_ind_sid IS NOT NULL;

CREATE OR REPLACE VIEW V$IMP_MERGE AS
	SELECT * FROM v$imp_val_mapped 
	  WHERE imp_conflict_id is null;

@..\imp_body

DROP VIEW IMP_VAL_MAPPED;

@update_tail
