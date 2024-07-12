-- Please update version.sql too -- this keeps clean builds in sync
define version=1684
@update_header


CREATE SEQUENCE CSR.REGION_METRIC_VAL_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

 
ALTER TABLE CSR.REGION_METRIC_VAL ADD (
    REGION_METRIC_VAL_ID    NUMBER(10, 0)
);

ALTER TABLE CSR.REGION_METRIC_VAL DROP PRIMARY KEY DROP INDEX;

UPDATE csr.region_metric_val SET region_metric_val_id = csr.region_metric_val_id_seq.nextval;

ALTER TABLE CSR.REGION_METRIC_VAL MODIFY REGION_METRIC_VAL_ID NOT NULL;

ALTER TABLE CSR.REGION_METRIC_VAL ADD PRIMARY KEY (APP_SID, REGION_METRIC_VAL_ID);

ALTER TABLE CSR.REGION_METRIC_VAL ADD CONSTRAINT UK_REGION_METRIC_VAL UNIQUE (APP_SID, IND_SID, REGION_SID, EFFECTIVE_DTM);

ALTER TABLE CSR.IMP_VAL ADD (
  SET_REGION_METRIC_VAL_ID    NUMBER(10, 0)
);

ALTER TABLE CSR.IMP_VAL ADD CONSTRAINT FK_REG_MET_VAL_IMP_VAL 
    FOREIGN KEY (APP_SID, SET_REGION_METRIC_VAL_ID)
    REFERENCES CSR.REGION_METRIC_VAL(APP_SID, REGION_METRIC_VAL_ID)  ON DELETE SET NULL;


CREATE OR REPLACE VIEW csr.V$IMP_VAL_MAPPED AS
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
           m.measure_sid,
           iv.imp_ind_id, iv.imp_region_id,
           CASE WHEN rm.ind_Sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric,
           CASE WHEN rmr.region_Sid IS NOT NULL THEN 1 ELSE 0 END region_metric_region_exists,
           rmr.measure_conversion_id region_metric_conversion_id
      FROM imp_val iv
           JOIN imp_ind ii ON iv.imp_ind_id = ii.imp_ind_id AND iv.app_sid = ii.app_sid AND ii.maps_to_ind_sid IS NOT NULL
           JOIN imp_region ir ON iv.imp_region_id = ir.imp_region_id AND iv.app_sid = ir.app_sid AND ir.maps_to_region_sid IS NOT NULL
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
           JOIN v$ind i 
                ON ii.maps_to_ind_sid = i.ind_sid
                AND ii.app_sid = i.app_sid
                AND i.ind_type = 0 
           LEFT JOIN region_metric rm
                ON i.ind_sid = rm.ind_sid AND i.app_sid = rm.app_sid
           LEFT JOIN region_metric_region rmr
                ON rm.ind_sid = rmr.ind_sid AND rm.app_sid = rmr.app_sid
                AND ir.maps_to_region_sid = rmr.region_sid AND ir.app_sid = rmr.app_sid
           JOIN measure m 
                ON i.measure_sid = m.measure_sid 
                AND i.app_sid = m.app_sid;

CREATE OR REPLACE VIEW csr.V$IMP_MERGE AS
    SELECT * FROM v$imp_val_mapped 
      WHERE imp_conflict_id is null;



@..\imp_pkg
@..\region_metric_pkg
@..\property_pkg

@..\imp_body
@..\region_metric_body
@..\property_body


@update_tail
