-- Please update version.sql too -- this keeps clean builds in sync
define version=2195
@update_header

ALTER TABLE CSR.METER_SOURCE_TYPE ADD (
	REQ_APPROVAL			NUMBER(1)	DEFAULT 0	NOT NULL,
	FLOW_SID				NUMBER(10),
	DESCENDING				NUMBER(1)	DEFAULT 0	NOT NULL,
	ALLOW_RESET				NUMBER(1)	DEFAULT 0	NOT NULL,
	CHECK (REQ_APPROVAL IN(0,1)),
	CHECK (DESCENDING IN(0,1)),
	CHECK (ALLOW_RESET IN(0,1))
);

ALTER TABLE CSR.METER_READING ADD (
	REQ_APPROVAL			NUMBER(1)	DEFAULT 0	NOT NULL,
	ACTIVE					NUMBER(1)	DEFAULT 1	NOT NULL,
	IS_DELETE				NUMBER(1)	DEFAULT 0	NOT NULL,
	REPLACES_READING_ID		NUMBER(10),
	APPROVED_DTM			DATE,
	APPROVED_BY_SID			NUMBER(10),
	FLOW_ITEM_ID			NUMBER(10),
	BASELINE_VAL			NUMBER(24, 10),
	CHECK (REQ_APPROVAL IN(0,1)),
	CHECK (ACTIVE IN(0,1)),
	CHECK (IS_DELETE IN(0,1))
);

ALTER TABLE CSR.METER_SOURCE_TYPE ADD CONSTRAINT FK_FLOW_MET_SRC_TYPE 
    FOREIGN KEY (APP_SID, FLOW_SID)
    REFERENCES CSR.FLOW(APP_SID, FLOW_SID)
;

ALTER TABLE CSR.METER_READING ADD CONSTRAINT FK_APPRUSR_METREADING 
    FOREIGN KEY (APP_SID, APPROVED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.METER_READING ADD CONSTRAINT FK_METREADING_REPLACES 
    FOREIGN KEY (APP_SID, REPLACES_READING_ID)
    REFERENCES CSR.METER_READING(APP_SID, METER_READING_ID)
;

ALTER TABLE CSR.METER_READING ADD CONSTRAINT FK_FLOW_ITEM_METER_READING 
    FOREIGN KEY (APP_SID, FLOW_ITEM_ID)
    REFERENCES CSR.FLOW_ITEM(APP_SID, FLOW_ITEM_ID)
;

CREATE INDEX CSR.IX_FLOW_MET_SRC_TYPE ON CSR.METER_SOURCE_TYPE(APP_SID, FLOW_SID);
CREATE INDEX CSR.IX_APPRUSR_METREADING ON CSR.METER_READING(APP_SID, APPROVED_BY_SID);
CREATE INDEX CSR.IX_METREADING_REPLACES ON CSR.METER_READING(APP_SID, REPLACES_READING_ID);
CREATE INDEX CSR.IX_FLOW_ITEM_METER_READING ON CSR.METER_READING(APP_SID, FLOW_ITEM_ID);


-- The current state of all approved meter readings
CREATE OR REPLACE VIEW csr.v$meter_reading AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid,
		mr.flow_item_id
	  FROM csr.all_meter am, csr.meter_reading mr
	 WHERE am.app_sid = mr.app_sid
	   AND am.region_sid = mr.region_sid
	   AND am.meter_source_type_id = mr.meter_source_type_id
	   AND mr.active = 1
	   AND req_approval = 0
;

-- A view of all meter readings, approved or otherwise.
-- Because a pending reading can replace an existing reading this view may contain overlaps
CREATE OR REPLACE VIEW csr.v$meter_reading_all AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.req_approval, mr.is_delete, mr.replaces_reading_id,
		mr.flow_item_id
	  FROM csr.all_meter am, csr.meter_reading mr
	 WHERE am.app_sid = mr.app_sid
	   AND am.region_sid = mr.region_sid
	   AND am.meter_source_type_id = mr.meter_source_type_id
	   AND mr.active = 1
;

-- A view onto the latest version of meter readings (if all had been approved)
CREATE OR REPLACE VIEW csr.v$meter_reading_head AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.req_approval, mr.is_delete, mr.replaces_reading_id,
		mr.flow_item_id
	  FROM meter_reading mr, (
	 	SELECT meter_reading_id
	 	  FROM csr.v$meter_reading_all
	 	MINUS
	 	SELECT replaces_reading_id meter_reading_id
	 	  FROM csr.v$meter_reading_all
	 	 WHERE req_approval = 1
	 ) x
	 WHERE mr.meter_reading_id = x.meter_reading_id
	   AND mr.active = 1
;

BEGIN
	INSERT INTO csr.flow_alert_class (flow_alert_class, label)
	VALUES ('meterreading', 'Meter reading');
END;
/

@../meter_pkg
@../meter_body
@../property_body
@../energy_star_body
	
@update_tail
