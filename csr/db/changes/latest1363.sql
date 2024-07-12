-- Please update version.sql too -- this keeps clean builds in sync
define version=1363
@update_header

ALTER TABLE CSR.METER_READING ADD (
    METER_SOURCE_TYPE_ID		NUMBER(10, 0)
);

ALTER TABLE CSR.METER_READING ADD CONSTRAINT REF_SRC_TYPE 
    FOREIGN KEY (APP_SID, METER_SOURCE_TYPE_ID)
    REFERENCES CSR.METER_SOURCE_TYPE(APP_SID, METER_SOURCE_TYPE_ID)
;

BEGIN
	FOR r IN (
		SELECT app_sid, region_sid, meter_source_type_id
		  FROM csr.all_meter
	) LOOP
		UPDATE csr.meter_reading
		   SET meter_source_type_id = r.meter_source_type_id
		 WHERE app_sid = r.app_sid
		   AND region_sid = r.region_sid;
	END LOOP;
END;
/

ALTER TABLE CSR.METER_READING MODIFY (
    METER_SOURCE_TYPE_ID		NUMBER(10, 0)	NOT NULL
);

ALTER TABLE CSRIMP.METER_READING ADD (
    METER_SOURCE_TYPE_ID   NUMBER(10, 0)	NOT NULL
);

-- View of meter readings corresponding to the meter's current source type
CREATE OR REPLACE VIEW csr.v$meter_reading AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.reading_dtm, mr.val_number, mr.entered_by_user_sid, 
		mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id
	  FROM csr.all_meter am, csr.meter_reading mr
	 WHERE am.app_sid = mr.app_sid
	   AND am.region_sid = mr.region_sid
	   AND am.meter_source_type_id = mr.meter_source_type_id
;
	  
@../meter_body
@../energy_star_body
@../utility_body
@../utility_report_body
@../schema_body
@../csrimp/imp_body

@update_tail
