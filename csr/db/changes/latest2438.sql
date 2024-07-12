-- Please update version.sql too -- this keeps clean builds in sync
define version=2438
@update_header


ALTER TABLE CSR.METER_READING ADD (
	IS_ESTIMATE				NUMBER(1)	DEFAULT 0	NOT NULL,
	CHECK (IS_DELETE IN(0,1))
);

-- The current state of all approved meter readings
CREATE OR REPLACE VIEW csr.v$meter_reading AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.is_estimate,
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
		mr.approved_dtm, mr.approved_by_sid, mr.req_approval, mr.is_delete, mr.replaces_reading_id, mr.is_estimate,
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
		mr.approved_dtm, mr.approved_by_sid, mr.req_approval, mr.is_delete, mr.replaces_reading_id, mr.is_estimate,
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

@../meter_pkg
@../meter_body
@../property_body

--Changes for HeinekenEHS release
@../batch_job_pkg	
@../batch_job_body
@update_tail
