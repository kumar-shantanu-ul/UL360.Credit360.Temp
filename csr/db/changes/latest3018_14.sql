-- Please update version.sql too -- this keeps clean builds in sync
define version=3018
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
--alter table csr.meter_raw_data_source drop constraint FK_METRAWDTSRC_METSRCTYP;
--alter table csr.meter_raw_data_source drop column meter_source_type_id;

CREATE TABLE CSR.METER_MATCH_BATCH_JOB (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID					NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10),
	CONSTRAINT PK_METER_MATCH_BATCH_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);

CREATE TABLE CSR.METER_RAW_DATA_IMPORT_JOB (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID					NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10),
	CONSTRAINT PK_METER_RAW_DATA_IMPORT_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);

CREATE TABLE CSR.DUFF_METER_ERROR_TYPE (
	ERROR_TYPE_ID					NUMBER(10)		NOT NULL,
	LABEL							VARCHAR2(256)	NOT NULL,
	CONSTRAINT PK_DUFF_METER_ERROR_TYPE PRIMARY KEY (ERROR_TYPE_ID)
);

CREATE TABLE CSR.DUFF_METER_REGION (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	URJANET_METER_ID				VARCHAR2(256)	NOT NULL,
	METER_NAME						VARCHAR2(1024)	NOT NULL,
	METER_NUMBER					VARCHAR2(256),
	REGION_REF						VARCHAR2(256),
	SERVICE_TYPE					VARCHAR2(256)	NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ERROR_ID			NUMBER(10),
	REGION_SID						NUMBER(10),
	ISSUE_ID						NUMBER(10),
	MESSAGE							VARCHAR2(4000),
	ERROR_TYPE_ID					NUMBER(10) 		NOT NULL,
	CREATED_DTM						DATE			DEFAULT SYSDATE NOT NULL,
	UPDATED_DTM						DATE			DEFAULT SYSDATE NOT NULL, 
	CONSTRAINT PK_DUFF_METER_REGION PRIMARY KEY (APP_SID, URJANET_METER_ID)
);

CREATE TABLE CSRIMP.DUFF_METER_REGION (
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	URJANET_METER_ID				VARCHAR2(256)	NOT NULL,
	METER_NAME						VARCHAR2(1024)	NOT NULL,
	METER_NUMBER					VARCHAR2(256),
	REGION_REF						VARCHAR2(256),
	SERVICE_TYPE					VARCHAR2(256)	NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ERROR_ID			NUMBER(10),
	REGION_SID						NUMBER(10),
	ISSUE_ID						NUMBER(10),
	MESSAGE							VARCHAR2(4000),
	ERROR_TYPE_ID					NUMBER(10) 		NOT NULL,
	CREATED_DTM						DATE			NOT NULL,
	UPDATED_DTM						DATE			NOT NULL, 
	CONSTRAINT PK_DUFF_METER_REGION PRIMARY KEY (CSRIMP_SESSION_ID, URJANET_METER_ID),
	CONSTRAINT FK_DUFF_METER_REGION_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_DUFF_METER_REGION (
	URJANET_METER_ID				VARCHAR2(256)	NOT NULL,
	METER_NAME						VARCHAR2(1024)	NOT NULL,
	METER_NUMBER					VARCHAR2(256),
	REGION_REF						VARCHAR2(256),
	SERVICE_TYPE					VARCHAR2(256)	NOT NULL,
	METER_RAW_DATA_ID				NUMBER(10)		NOT NULL,
	METER_RAW_DATA_ERROR_ID			NUMBER(10),
	REGION_SID						NUMBER(10),
	ISSUE_ID						NUMBER(10),
	MESSAGE							VARCHAR2(4000),
	ERROR_TYPE_ID					NUMBER(10) 		NOT NULL,
	CONSTRAINT PK_TEMP_DUFF_METER_REGION PRIMARY KEY (URJANET_METER_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_FIXED_DUFF_METER_REGION (
	URJANET_METER_ID				VARCHAR2(256)	NOT NULL,
	CONSTRAINT PK_TEMP_FIXED_DUFF_MTR_REGN PRIMARY KEY (URJANET_METER_ID)
) ON COMMIT DELETE ROWS;

CREATE TABLE csr.meter_data_source_hi_res_input (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	raw_data_source_id			NUMBER(10) NOT NULL,
	meter_input_id				NUMBER(10) NOT NULL,
	CONSTRAINT pk_meter_data_src_hi_res_input PRIMARY KEY (app_sid, raw_data_source_id, meter_input_id),
	CONSTRAINT fk_meter_src_hi_res_meter_src FOREIGN KEY (app_sid, raw_data_source_id)
		REFERENCES csr.meter_raw_data_source (app_sid, raw_data_source_id),
	CONSTRAINT fk_meter_src_hi_res_mtr_input FOREIGN KEY (app_sid, meter_input_id)
		REFERENCES csr.meter_input (app_sid, meter_input_id)
);

CREATE TABLE csrimp.meter_data_source_hi_res_input (
	csrimp_session_id			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	raw_data_source_id			NUMBER(10) NOT NULL,
	meter_input_id				NUMBER(10) NOT NULL,
	CONSTRAINT pk_meter_data_src_hi_res_input PRIMARY KEY (csrimp_session_id, raw_data_source_id, meter_input_id),
	CONSTRAINT fk_meter_data_src_hi_res_in_is FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CSR.METER_ORPHAN_DATA ADD (
	REGION_SID						NUMBER(10),
	HAS_OVERLAP						NUMBER(1)	DEFAULT 0 NOT NULL,
	ERROR_TYPE_ID					NUMBER(10),
	CHECK (HAS_OVERLAP IN (0,1))
);

ALTER TABLE CSRIMP.METER_ORPHAN_DATA ADD (
	REGION_SID						NUMBER(10),
	HAS_OVERLAP						NUMBER(1)		NOT NULL,
	ERROR_TYPE_ID					NUMBER(10),
	CHECK (HAS_OVERLAP IN (0,1))
);

ALTER TABLE CSR.AUTO_IMP_IMPORTER_SETTINGS ADD (
	EXCEL_ROW_INDEX					NUMBER(10),
	DATA_TYPE						VARCHAR2(256)
);

ALTER TABLE CSR.METER_RAW_DATA_SOURCE ADD (
	PROCESS_BODY					NUMBER(1)
);
	
ALTER TABLE CSRIMP.METER_RAW_DATA_SOURCE ADD (
	PROCESS_BODY					NUMBER(1)
);

UPDATE CSR.METER_RAW_DATA_SOURCE
   SET PROCESS_BODY = 0
 WHERE PROCESS_BODY IS NULL;
   
ALTER TABLE CSR.METER_RAW_DATA_SOURCE MODIFY PROCESS_BODY NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE CSR.METER_MATCH_BATCH_JOB ADD CONSTRAINT FK_BATCHJOB_METMATBATJOB
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
;

ALTER TABLE CSR.METER_RAW_DATA_IMPORT_JOB ADD CONSTRAINT FK_BATCHJOB_METRAWDATAJOB
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
;

ALTER TABLE CSR.DUFF_METER_REGION ADD CONSTRAINT FK_DUFMETERG_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

ALTER TABLE CSR.DUFF_METER_REGION ADD CONSTRAINT FK_DUFMETERG_ISSUE
	FOREIGN KEY (APP_SID, ISSUE_ID)
	REFERENCES CSR.ISSUE(APP_SID, ISSUE_ID)
;

ALTER TABLE CSR.DUFF_METER_REGION ADD CONSTRAINT FK_DUFMETERG_ORPMETDAT
	FOREIGN KEY (ERROR_TYPE_ID)
	REFERENCES CSR.DUFF_METER_ERROR_TYPE(ERROR_TYPE_ID)
;

ALTER TABLE CSR.METER_ORPHAN_DATA ADD CONSTRAINT FK_METERORPHANDATADATA_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

ALTER TABLE CSR.METER_ORPHAN_DATA ADD CONSTRAINT FK_DUFMETERRTYP_ORPMETDAT
	FOREIGN KEY (ERROR_TYPE_ID)
	REFERENCES CSR.DUFF_METER_ERROR_TYPE(ERROR_TYPE_ID)
;

CREATE INDEX CSR.IX_DUFMETERG_REGION ON CSR.DUFF_METER_REGION (APP_SID, REGION_SID);
CREATE INDEX CSR.IX_DUFMETERG_ISSUE ON CSR.DUFF_METER_REGION (APP_SID, ISSUE_ID);
CREATE INDEX CSR.IX_DUFMETERG_ORPMETDAT ON CSR.DUFF_METER_REGION(ERROR_TYPE_ID);
CREATE INDEX CSR.IX_METERORPHANDATADATA_REGION ON CSR.METER_ORPHAN_DATA(APP_SID, REGION_SID);
CREATE INDEX CSR.IX_DUFMETERRTYP_ORPMETDAT ON CSR.METER_ORPHAN_DATA(ERROR_TYPE_ID);


DROP INDEX CSR.UK_METER_ORPHAN_DATA;
CREATE UNIQUE INDEX CSR.UK_METER_ORPHAN_DATA ON CSR.METER_ORPHAN_DATA(APP_SID, SERIAL_ID, METER_INPUT_ID, PRIORITY, START_DTM, END_DTM, UOM);

ALTER TABLE csr.auto_imp_mail_attach_filter ADD (
	attachment_validator_plugin		VARCHAR2(1024)
);

ALTER TABLE csr.temp_meter_reading_rows ADD (
	priority						NUMBER(10)
);
ALTER TABLE csr.meter_insert_data ADD (
	priority						NUMBER(10)
);

ALTER TABLE csr.metering_options ADD (
	period_set_id				NUMBER(10),
	period_interval_id			NUMBER(10),
	show_invoice_reminder		NUMBER(1) DEFAULT 0 NOT NULL,
	invoice_reminder			VARCHAR2(1024),
	supplier_data_mandatory		NUMBER(1) DEFAULT 0 NOT NULL,
	region_date_clipping		NUMBER(1) DEFAULT 0 NOT NULL,
	fwd_estimate_meters			NUMBER(1) DEFAULT 0 NOT NULL,
	reference_mandatory			NUMBER(1) DEFAULT 0 NOT NULL,
	realtime_metering_enabled	NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_show_invoice_reminder_1_0 CHECK (show_invoice_reminder IN (1,0)),
	CONSTRAINT chk_supplier_data_mand_1_0 CHECK (supplier_data_mandatory IN (1,0)),
	CONSTRAINT chk_region_date_clipping_1_0 CHECK (region_date_clipping IN (1,0)),
	CONSTRAINT chk_fwd_estimate_meters_1_0 CHECK (fwd_estimate_meters IN (1,0)),
	CONSTRAINT chk_reference_mandatory_1_0 CHECK (reference_mandatory IN (1,0)),
	CONSTRAINT chk_realtime_meter_enbld_1_0 CHECK (realtime_metering_enabled IN (1,0)),
	CONSTRAINT fk_metering_options_period_set FOREIGN KEY (app_sid, period_set_id, period_interval_id)
		REFERENCES csr.period_interval (app_sid, period_set_id, period_interval_id)
);

DELETE FROM csrimp.metering_options;
ALTER TABLE csrimp.metering_options ADD (
	CONSTRAINT FK_METERING_OPTIONS_IS FOREIGN KEY (CSRIMP_SESSION_ID) 
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

ALTER TABLE csrimp.metering_options ADD (
	period_set_id				NUMBER(10) NOT NULL,
	period_interval_id			NUMBER(10) NOT NULL,
	show_invoice_reminder		NUMBER(1) NOT NULL,
	invoice_reminder			VARCHAR2(1024),
	supplier_data_mandatory		NUMBER(1) NOT NULL,
	region_date_clipping		NUMBER(1) NOT NULL,
	fwd_estimate_meters			NUMBER(1) NOT NULL,
	reference_mandatory			NUMBER(1) NOT NULL,
	realtime_metering_enabled	NUMBER(1) NOT NULL,
	CONSTRAINT chk_show_invoice_reminder_1_0 CHECK (show_invoice_reminder IN (1,0)),
	CONSTRAINT chk_supplier_data_mand_1_0 CHECK (supplier_data_mandatory IN (1,0)),
	CONSTRAINT chk_region_date_clipping_1_0 CHECK (region_date_clipping IN (1,0)),
	CONSTRAINT chk_fwd_estimate_meters_1_0 CHECK (fwd_estimate_meters IN (1,0)),
	CONSTRAINT chk_reference_mandatory_1_0 CHECK (reference_mandatory IN (1,0)),
	CONSTRAINT chk_realtime_meter_enbld_1_0 CHECK (realtime_metering_enabled IN (1,0))
);

ALTER TABLE csr.all_meter ADD (
	manual_data_entry			NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT chk_manual_data_entry_1_0 CHECK (manual_data_entry IN (1,0))
);

ALTER TABLE csrimp.all_meter ADD (
	manual_data_entry			NUMBER(1) NOT NULL,
	CONSTRAINT chk_manual_data_entry_1_0 CHECK (manual_data_entry IN (1,0))
);

ALTER TABLE csr.meter_type ADD (
	req_approval				NUMBER(1) DEFAULT 0 NOT NULL,
	flow_sid					NUMBER(10),
	CONSTRAINT chk_req_approval_1_0 CHECK (req_approval IN (1,0)),
	CONSTRAINT fk_meter_type_flow FOREIGN KEY (app_sid, flow_sid)
		REFERENCES csr.flow (app_sid, flow_sid)
);

ALTER TABLE csrimp.meter_type ADD (
	req_approval				NUMBER(1) NOT NULL,
	flow_sid					NUMBER(10),
	CONSTRAINT chk_req_approval_1_0 CHECK (req_approval IN (1,0))
);

ALTER TABLE csrimp.meter_source_type DROP COLUMN period_set_id;
ALTER TABLE csrimp.meter_source_type DROP COLUMN period_interval_id;
ALTER TABLE csrimp.meter_source_type DROP COLUMN show_invoice_reminder;
ALTER TABLE csrimp.meter_source_type DROP COLUMN invoice_reminder;
ALTER TABLE csrimp.meter_source_type DROP COLUMN supplier_data_mandatory;
ALTER TABLE csrimp.meter_source_type DROP COLUMN region_date_clipping;
ALTER TABLE csrimp.meter_source_type DROP COLUMN reference_mandatory;
ALTER TABLE csrimp.meter_source_type DROP COLUMN realtime_metering;
ALTER TABLE csrimp.meter_source_type DROP COLUMN manual_data_entry;
ALTER TABLE csrimp.meter_source_type DROP COLUMN req_approval;
ALTER TABLE csrimp.meter_source_type DROP COLUMN flow_sid;
ALTER TABLE csrimp.meter_source_type DROP COLUMN auto_patch;
ALTER TABLE csrimp.customer DROP COLUMN fwd_estimate_meters;

BEGIN
	security.user_pkg.LogonAdmin;
	
	INSERT INTO csr.meter_data_source_hi_res_input (app_sid, raw_data_source_id, meter_input_id)
		SELECT mrds.app_sid, mrds.raw_data_source_id, mi.meter_input_id
		  FROM csr.meter_raw_data_source mrds
		  JOIN csr.meter_input mi on mrds.app_sid = mi.app_sid
		 WHERE EXISTS (
			SELECT *
			  FROM csr.meter_raw_data mrd
			 WHERE mrd.app_sid = mrds.app_sid
			   AND mrd.raw_data_source_id = mrds.raw_data_source_id
			   AND EXISTS (
				SELECT *
				  FROM csr.meter_live_data mld
				  JOIN csr.meter_bucket mb ON mld.app_sid = mb.app_sid AND mld.meter_bucket_id = mb.meter_bucket_id
				 WHERE mld.app_sid = mrd.app_sid
				   AND mld.meter_raw_data_id = mrd.meter_raw_data_id
				   AND mb.high_resolution_only = 1
			 )
		 );
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT mst.app_sid, MIN(period_set_id) period_set_id, MIN(period_interval_id) period_interval_id,
		       MAX(show_invoice_reminder) show_invoice_reminder, MAX(invoice_reminder) invoice_reminder,
			   MAX(supplier_data_mandatory) supplier_data_mandatory, MAX(region_date_clipping) region_date_clipping,
			   MAX(reference_mandatory) reference_mandatory, MAX(realtime_metering) realtime_metering_enabled,
			   MAX(fwd_estimate_meters) fwd_estimate_meters, MAX(flow_sid) flow_sid, MAX(req_approval) req_approval
		  FROM csr.meter_source_type mst
		  JOIN csr.customer c ON mst.app_sid = c.app_sid
		 GROUP BY mst.app_sid
	) LOOP
		BEGIN
			INSERT INTO csr.metering_options (app_sid, period_set_id, period_interval_id, show_invoice_reminder,
							invoice_reminder, supplier_data_mandatory, region_date_clipping, fwd_estimate_meters,
							reference_mandatory, realtime_metering_enabled)
			     VALUES (r.app_sid, r.period_set_id, r.period_interval_id, r.show_invoice_reminder, r.invoice_reminder,
				 		 r.supplier_data_mandatory, r.region_date_clipping, r.fwd_estimate_meters,
						 r.reference_mandatory, r.realtime_metering_enabled);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.metering_options
				   SET period_set_id = r.period_set_id,
				       period_interval_id = r.period_interval_id,
					   show_invoice_reminder = r.show_invoice_reminder,
					   invoice_reminder = r.invoice_reminder,
					   supplier_data_mandatory = r.supplier_data_mandatory,
					   region_date_clipping = r.region_date_clipping,
					   fwd_estimate_meters = r.fwd_estimate_meters,
					   reference_mandatory = r.reference_mandatory,
					   realtime_metering_enabled = r.realtime_metering_enabled
				 WHERE app_sid = r.app_sid;
		END;
		
		-- flow sid is null for all live meter source types, so this is just here for dev envs
		-- (which is why its lazily doing max(flow_sid))
		UPDATE csr.meter_type
		   SET req_approval = r.req_approval,
		       flow_sid = r.flow_sid
		 WHERE app_sid = r.app_sid;
	END LOOP;
	
	UPDATE csr.metering_options
	   SET period_set_id = 1,
	       period_interval_id =1
	 WHERE period_set_id IS NULL
	    OR period_interval_id IS NULL;
		
	UPDATE csr.all_meter am
	   SET manual_data_entry = (
			SELECT manual_data_entry
			  FROM csr.meter_source_type mst
			 WHERE mst.app_sid = am.app_sid
			   AND mst.meter_source_type_id = am.meter_source_type_id
		);
		
	-- remove old amr meter source type where it is no longer used
	DELETE FROM csr.meter_source_type mst
	 WHERE name = 'amr'
	  AND NOT EXISTS (
		SELECT 1
		  FROM csr.all_meter am
		 WHERE am.app_sid = mst.app_sid
		   AND am.meter_source_type_id = mst.meter_source_type_id
	  );

	-- remove live/urjanet meter source types
	FOR r IN (
		SELECT mst.app_sid, mst.meter_source_type_id old_id, MIN(nmst.meter_source_type_id) new_id
		  FROM csr.meter_source_type mst
		  JOIN csr.meter_source_type nmst ON mst.app_sid = nmst.app_sid
		 WHERE mst.name IN ('live', 'urjanet')
		   AND nmst.name IN ('period', 'consumption')
		 GROUP BY mst.app_sid, mst.meter_source_type_id
	) LOOP
		UPDATE csr.all_meter
		   SET meter_source_type_id = r.new_id
		 WHERE app_sid = r.app_sid
		   AND meter_source_type_id = r.old_id;

		DELETE FROM csr.meter_source_type
		 WHERE app_sid = r.app_sid
		   AND meter_source_type_id = r.old_id;
	END LOOP;
END;
/
 
ALTER TABLE csr.metering_options MODIFY period_set_id NOT NULL;
ALTER TABLE csr.metering_options MODIFY period_interval_id NOT NULL;

ALTER TABLE csr.meter_source_type RENAME COLUMN period_set_id TO xxx_period_set_id;
ALTER TABLE csr.meter_source_type RENAME COLUMN period_interval_id TO xxx_period_interval_id;
ALTER TABLE csr.meter_source_type RENAME COLUMN show_invoice_reminder TO xxx_show_invoice_reminder;
ALTER TABLE csr.meter_source_type RENAME COLUMN invoice_reminder TO	xxx_invoice_reminder;
ALTER TABLE csr.meter_source_type RENAME COLUMN supplier_data_mandatory TO xxx_supplier_data_mandatory;
ALTER TABLE csr.meter_source_type RENAME COLUMN region_date_clipping TO xxx_region_date_clipping;
ALTER TABLE csr.meter_source_type RENAME COLUMN reference_mandatory TO xxx_reference_mandatory;
ALTER TABLE csr.meter_source_type RENAME COLUMN realtime_metering TO xxx_realtime_metering;
ALTER TABLE csr.meter_source_type RENAME COLUMN manual_data_entry TO xxx_manual_data_entry;
ALTER TABLE csr.meter_source_type RENAME COLUMN req_approval TO xxx_req_approval;
ALTER TABLE csr.meter_source_type RENAME COLUMN flow_sid TO xxx_flow_sid;
ALTER TABLE csr.meter_source_type RENAME COLUMN auto_patch TO xxx_auto_patch;

ALTER TABLE csr.meter_source_type MODIFY xxx_period_set_id NULL;
ALTER TABLE csr.meter_source_type MODIFY xxx_period_interval_id NULL;


ALTER TABLE csr.meter_source_type DROP CONSTRAINT FK_FLOW_MET_SRC_TYPE;
ALTER TABLE csr.meter_source_type DROP CONSTRAINT FK_PERIOD_SET_MTR_SRC_TYPE;

DROP INDEX csr.ix_flow_met_src_type;
DROP INDEX csr.ix_period_set_mtr_src_type;

create index csr.ix_metering_opti_period_set_id on csr.metering_options (app_sid, period_set_id, period_interval_id);
create index csr.ix_meter_data_so_meter_input_i on csr.meter_data_source_hi_res_input (app_sid, meter_input_id);
create index csr.ix_meter_type_flow_sid on csr.meter_type (app_sid, flow_sid);

ALTER TABLE csr.customer RENAME COLUMN fwd_estimate_meters TO xxx_fwd_estimate_meters;

-- clear up old columns from previous refactor
BEGIN
	FOR r IN (
		SELECT column_name
		  FROM all_tab_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'ALL_METER'
		   AND column_name LIKE 'XXX_%'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.all_meter DROP COLUMN '||r.column_name;
	END LOOP;

	FOR r IN (
		SELECT column_name
		  FROM all_tab_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'METER_TYPE'
		   AND column_name LIKE 'XXX_%'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.meter_type DROP COLUMN '||r.column_name;
	END LOOP;
END;
/

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON csr.duff_meter_region TO csrimp;
grant select,insert,update on csr.meter_data_source_hi_res_input to csrimp;
grant select, insert, update, delete on csrimp.meter_data_source_hi_res_input to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW CSR.V$METER_ORPHAN_DATA_SUMMARY AS
	SELECT od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.source_email, ds.source_folder,
		MIN(rd.received_dtm) created_dtm, MAX(rd.received_dtm) updated_dtm, 
		MIN(od.start_dtm) start_dtm, NVL(MAX(od.end_dtm), MAX(od.start_dtm)) end_dtm, 
		SUM(od.consumption) consumption,
		MAX(od.has_overlap) has_overlap,
		MAX(od.region_sid) region_sid,
		MAX(od.error_type_id) KEEP (DENSE_RANK LAST ORDER BY rd.received_dtm) error_type_id
	  FROM meter_orphan_data od
	  JOIN meter_raw_data rd ON rd.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND rd.meter_raw_data_id = od.meter_raw_data_id
	  JOIN meter_raw_data_source ds ON ds.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ds.raw_data_source_id = rd.raw_data_source_id
	 WHERE od.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 GROUP BY od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.source_email, ds.source_folder
;

CREATE OR REPLACE VIEW CSR.V$LEGACY_METER AS
	SELECT
		am.app_sid,
		am.region_sid,
		am.note,
		iip.ind_sid primary_ind_sid,
		iai.measure_conversion_id primary_measure_conversion_id,
		am.active,
		am.meter_source_type_id,
		am.reference,
		am.crc_meter,
		ciip.ind_sid cost_ind_sid,
		ciai.measure_conversion_id cost_measure_conversion_id,
		am.export_live_data_after_dtm,
		mi.days_ind_sid,
		am.days_measure_conversion_id,
		mi.costdays_ind_sid,
		am.costdays_measure_conversion_id,
		am.approved_by_sid,
		am.approved_dtm,
		am.is_core,
		am.meter_type_id,
		am.lower_threshold_percentage,
		am.upper_threshold_percentage,
		am.metering_version,
		am.urjanet_meter_id,
		am.manual_data_entry
	 FROM all_meter am
	 JOIN meter_type mi ON mi.app_sid = am.app_sid AND mi.meter_type_id = am.meter_type_id
	 -- Consumption mandatory
	 JOIN csr.meter_input ip ON ip.app_sid = am.app_sid AND ip.lookup_key = 'CONSUMPTION'
	 JOIN csr.v$legacy_aggregator iag ON iag.app_sid = ip.app_sid AND iag.meter_input_id = ip.meter_input_id
	 JOIN csr.meter_type_input iip ON iip.app_sid = am.app_sid AND iip.meter_type_id = am.meter_type_id AND iip.meter_input_id = iag.meter_input_id
	 JOIN meter_input_aggr_ind iai ON iai.app_sid = am.app_sid AND iai.region_sid = am.region_sid AND iai.meter_input_id = ip.meter_input_id
	 -- Cost optional
	 LEFT JOIN csr.meter_input cip ON cip.app_sid = am.app_sid AND cip.lookup_key = 'COST'
	 LEFT JOIN csr.v$legacy_aggregator ciag ON ciag.app_sid = cip.app_sid AND ciag.meter_input_id = cip.meter_input_id
	 LEFT JOIN csr.meter_type_input ciip ON ciip.app_sid = am.app_sid AND ciip.meter_type_id = am.meter_type_id AND ciip.meter_input_id = cip.meter_input_id
	 LEFT JOIN meter_input_aggr_ind ciai ON ciai.app_sid = am.app_sid AND ciai.region_sid = am.region_sid AND ciai.meter_input_id = cip.meter_input_id
;

CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description,
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		a.manual_data_entry, ms.arbitrary_period, ms.add_invoice_data,
		ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_type_id, r.active, r.region_type,
		r.acquisition_dtm, r.disposal_dtm
	  FROM csr.v$legacy_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_type mi ON a.meter_type_id = mi.meter_type_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;

CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description,
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		a.manual_data_entry, ms.arbitrary_period, ms.add_invoice_data,
		ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_type_id, r.active, r.region_type,
		r.acquisition_dtm, r.disposal_dtm
	  FROM csr.v$legacy_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_type mi ON a.meter_type_id = mi.meter_type_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;
		
CREATE OR REPLACE VIEW csr.v$temp_meter_reading_rows AS
       SELECT t.source_row, t.region_sid, t.start_dtm, t.end_dtm, t.reference, t.note, t.reset_val, t.error_msg,
              t.priority, v.consumption consumption, c.consumption cost
	    FROM ( SELECT DISTINCT source_row,
			    region_sid,
			    start_dtm,
			    end_dtm,
			    REFERENCE,
			    priority,
			    note,
			    reset_val,
			    error_msg
    			FROM csr.temp_meter_reading_rows
			  ) t
	LEFT JOIN csr.temp_meter_reading_rows v
		   ON v.source_row       = t.source_row
		  AND t.region_sid      =v.region_sid
		  AND v.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'CONSUMPTION'
								  )
	LEFT JOIN csr.temp_meter_reading_rows c
		   ON c.source_row       = t.source_row
		  AND t.region_sid      =c.region_sid
		  AND c.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'COST'
								  );

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	security.user_pkg.LogonAdmin;
	
	-- some dev sites seemed to have missed these
	BEGIN
		INSERT INTO csr.meter_raw_data_source_type (raw_data_source_type_id, feed_type, description) VALUES(1, 'email', 'Email');		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.meter_raw_data_source_type (raw_data_source_type_id, feed_type, description) VALUES(2, 'ftp', 'FTP');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	UPDATE csr.auto_imp_importer_plugin
	   SET label='Meter raw data importer', importer_assembly= 'Credit360.ExportImport.Automated.Import.Importers.MeterRawDataImporter.MeterRawDataImporter'
	 WHERE plugin_id = 2;

	UPDATE csr.meter_raw_data_source
	   SET raw_data_source_type_id = 2
	 WHERE raw_data_source_type_id = 3;

	DELETE FROM csr.meter_raw_data_source_type WHERE raw_data_source_type_id = 3;
END;
/

BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (55, 'Meter and meter data matching', null, 'meter-match', 0, null);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (56, 'Meter raw data import', null, 'meter-raw-data-import', 0, null);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (57, 'Meter recompute buckets', 'csr.meter_monitor_pkg.ProcessRecomputeBucketsJob', null, 0, null);
END;
/

BEGIN
	INSERT INTO CSR.AUTOMATED_IMPORT_FILE_TYPE (AUTOMATED_IMPORT_FILE_TYPE_ID, LABEL)
		VALUES (3, 'ediel');
	INSERT INTO CSR.AUTOMATED_IMPORT_FILE_TYPE (AUTOMATED_IMPORT_FILE_TYPE_ID, LABEL)
		VALUES (4, 'wi5');
END;
/

BEGIN
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (1 /*DUFF_METER_GENERIC*/, 'Orphan meter data');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (2 /*DUFF_METER_MATCH_SERIAL*/, 'Failed to match meter number');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (3 /*DUFF_METER_MATCH_UOM*/, 'Failed to match UOM');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (4 /*DUFF_METER_OVERLAP*/, 'Data has overlaps');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (5 /*DUFF_METER_EXISTING_MISMATCH*/, 'Meter number mismatch');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (6 /*DUFF_METER_PARENT_NOT_FOUND*/, 'Parent region not found');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (7 /*DUFF_METER_HOLDING_NOT_FOUND*/, 'Holding region not found');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (8 /*DUFF_METER_SVC_TYPE_NOT_FOUND*/, 'Service type not found');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (9 /*DUFF_METER_SVC_TYPE_MISMATCH*/, 'Service type mismatch');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (10 /*DUFF_METER_NOT_SET_UP*/, 'System not configured');

	UPDATE csr.meter_orphan_data
	   SET error_type_id = 1 /*DUFF_METER_GENERIC*/
	;
END;
/

ALTER TABLE CSR.METER_ORPHAN_DATA MODIFY (
	ERROR_TYPE_ID					NUMBER(10) 		NOT NULL
);

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
	job_name		=> 'csr.MeterRawDataJob',
	job_type		=> 'PLSQL_BLOCK',
	job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.meter_monitor_pkg.CreateRawDataJobsForApps; commit; END;',
	job_class		=> 'low_priority_job',
	start_date		=> to_timestamp_tz('2016/10/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval	=> 'FREQ=DAILY',
	enabled			=> TRUE,
	auto_drop		=> FALSE,
	comments		=> 'Schedule creating meter raw data jobs');
END;
/

BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name		=> 'csr.MeterMatchJob',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.meter_monitor_pkg.CreateMatchJobsForApps; commit; END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2016/10/01 03:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=DAILY',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Schedule creating meter match jobs'
	);
END;
/

--Migrate existing urjanet/yum clients to the new framework
DECLARE
	v_mapping_xml		VARCHAR2(3000);
BEGIN
	FOR x IN (
		SELECT aics.app_sid, aics.automated_import_class_sid, aics.step_number, mrds.raw_data_source_id,
			   mrds.source_folder, mec.worksheet_index, mec.row_index
		  FROM csr.automated_import_class_step aics
		  JOIN csr.meter_raw_data_source mrds ON aics.automated_import_class_sid = mrds.automated_import_class_sid AND aics.app_sid = mrds.app_sid
		  JOIN csr.meter_excel_option mec ON mec.raw_data_source_id = mrds.raw_data_source_id AND mec.app_sid = mrds.app_sid
		 WHERE plugin='Credit360.ExportImport.Automated.Import.Plugins.UrjanetImporterStepPlugin')
	LOOP
		UPDATE csr.automated_import_class_step
		   SET plugin = 'Credit360.ExportImport.Automated.Import.Plugins.MeterRawDataImportStepPlugin',
			   on_completion_sp = 'csr.meter_monitor_pkg.QueueRawDataImportJob'
		 WHERE automated_import_class_sid = x.automated_import_class_sid
		   AND step_number = x.step_number
		   AND app_sid = x.app_sid;

		UPDATE csr.meter_raw_data_source
		   SET create_meters = 1
		 WHERE app_sid = x.app_sid
		   AND raw_data_source_id = x.raw_data_source_id;


		IF x.source_folder LIKE '%yum%' THEN
			v_mapping_xml := '<columnMappings>
				<column name="METERID" column-type="urjanet-meter-id" />
				<column name="STOREID" column-type="region-ref"/>
				<column name="FROM_DATE" format="yyyy-MM-dd" column-type="start-date"/>
				<column name="TO_DATE" format="yyyy-MM-dd" column-type="end-date"/>
				<column name="USAGE" column-type="meter-input" format="CONSUMPTION" />
				<column name="UNIT_OF_MEASURE" column-type="meter-input-unit" format="CONSUMPTION" />
				<column name="MERCHANDISE_AMT" column-type="meter-input" format="COST" />
				<column name="TYPE" column-type="service-type"/>
				<column name="Name" format="{type} - {meterid}" column-type="name"/>
				</columnMappings>	';

		ELSE
			v_mapping_xml := '<columnMappings>
				<column name="LogicalMeterId" column-type="urjanet-meter-id" mandatory="yes"/>
				<column name="StartDate" format="MM/dd/yyyy" column-type="start-date"/>
				<column name="EndDate" format="MM/dd/yyyy" column-type="end-date"/>
				<column name="ConsumptionUnit" column-type="meter-input-unit" format="CONSUMPTION" filter-type="exclude" filter="kW"/>
				<column name="Consumption" column-type="meter-input" format="CONSUMPTION" />
				<column name="Cost" column-type="meter-input" format="COST" />
				<column name="Currency" column-type="meter-input-unit" format="COST" />
				<column name="ConsumptionReadType" column-type="is-estimate" />
				<column name="ServiceAddress"/>
				<column name="SiteCode" column-type="region-ref" mandatory="yes"/>
				<column name="ServiceType" column-type="service-type" filter-type="exclude" filter="sanitation" mandatory="yes" />
				<column name="MeterNumber" column-type="meter-number" mandatory="yes"/>
				<column name="Name" format="{MeterNumber} {ServiceAddress} {ServiceType}" column-type="name" />
				<column name="Url"/>
			 </columnMappings>	';

		END IF;

		UPDATE csr.auto_imp_importer_settings
		   SET mapping_xml = XMLTYPE(v_mapping_xml),
			   excel_worksheet_index = x.worksheet_index,
			   excel_row_index = x.row_index
		 WHERE app_sid = x.app_sid
		   AND automated_import_class_sid = x.automated_import_class_sid;

		DELETE FROM csr.meter_excel_mapping WHERE raw_data_source_id = x.raw_data_source_id AND app_sid = x.app_sid;
		DELETE FROM csr.meter_excel_option WHERE raw_data_source_id = x.raw_data_source_id AND app_sid = x.app_sid;

	END LOOP;
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	
	-- move auto patch down a level and put new estimate level in between
	FOR r IN (
		SELECT app_sid
		  FROM csr.meter_data_priority
		 WHERE priority = 1
		   AND lookup_key = 'AUTO'
	) LOOP
		BEGIN
			INSERT INTO csr.meter_data_priority (app_sid, priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
			VALUES (r.app_sid, 0, 'Auto patch', 'AUTO', 0, 0, 1, 1);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		
		-- commented out for live run as it takes 30 seconds and doesn't update any rows
		-- the only systems with auto patch setup with be Dickie's laptop
		-- DICKIE - RUN THIS!
		--UPDATE csr.meter_reading_data
		--   SET priority = 0
		-- WHERE app_sid = r.app_sid
		--   AND priority = 1;
--
		--UPDATE csr.meter_source_data
		--   SET priority = 0
		-- WHERE app_sid = r.app_sid
		--   AND priority = 1;
		   
		UPDATE csr.meter_data_priority
		   SET label = 'Estimate',
		       lookup_key = 'ESTIMATE',
			   is_input = 1,
			   is_output = 0,
			   is_patch = 0,
			   is_auto_patch = 0
		 WHERE app_sid = r.app_sid
		   AND priority = 1;		   
	END LOOP;
	 
	-- move urjanet low res readings into the estimate level
	FOR r IN (
		SELECT app_sid
		  FROM csr.automated_import_class
		 WHERE lookup_key = 'URJANET_IMPORTER'
	) LOOP
		UPDATE csr.meter_source_data
		   SET priority = 1
		 WHERE app_sid = r.app_sid
		   AND priority = 2;
	END LOOP;
END;
/

BEGIN
	security.user_pkg.LogonAdmin;

	UPDATE security.menu
	   SET action = '/csr/site/meter/monitor/OrphanMeterRegions.acds'
	 WHERE LOWER(action) = '/csr/site/meter/monitor/orphandatalist.acds';
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.meter_duff_region_pkg
IS
END;
/
	
GRANT EXECUTE ON csr.meter_duff_region_pkg to web_user;


-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg
@../meter_pkg
@../meter_monitor_pkg
@../meter_duff_region_pkg
@../meter_patch_pkg
@../batch_job_pkg
@../schema_pkg
@../csr_data_pkg
@../space_pkg

@../automated_import_body
@../meter_body
@../meter_monitor_body
@../meter_duff_region_body
@../schema_body
@../enable_body
@../csrimp/imp_body
@../csr_app_body
@../energy_star_body
@../meter_patch_body
@../property_body
@../space_body
@../util_script_body

@update_tail
