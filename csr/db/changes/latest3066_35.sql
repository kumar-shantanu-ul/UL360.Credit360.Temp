-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=35
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.METER_READING_DATA ADD (
	NOTE		VARCHAR2(4000)
);

ALTER TABLE CSR.METER_SOURCE_DATA ADD (
	NOTE		VARCHAR2(4000)
);

ALTER TABLE CSR.METER_ORPHAN_DATA ADD (
	NOTE		VARCHAR2(4000)
);

ALTER TABLE CSR.METER_INSERT_DATA ADD (
	NOTE		VARCHAR2(4000)
);


ALTER TABLE CSRIMP.METER_READING_DATA ADD (
	NOTE		VARCHAR2(4000)
);

ALTER TABLE CSRIMP.METER_SOURCE_DATA ADD (
	NOTE		VARCHAR2(4000)
);

ALTER TABLE CSRIMP.METER_ORPHAN_DATA ADD (
	NOTE		VARCHAR2(4000)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- /svn/csr/db/create_views
CREATE OR REPLACE VIEW csr.v$meter_reading_multi_src AS
	WITH m AS (
		SELECT m.app_sid, m.region_sid legacy_region_sid, NULL urjanet_arb_region_sid, 0 auto_source
		  FROM csr.all_meter m
		 WHERE urjanet_meter_id IS NULL
		UNION
		SELECT app_sid, NULL legacy_region_sid, region_sid urjanet_arb_region_sid, 1 auto_source
		  FROM csr.all_meter m
		 WHERE urjanet_meter_id IS NOT NULL
		   AND EXISTS (
			SELECT 1
			  FROM csr.meter_source_data sd
			 WHERE sd.app_sid = m.app_sid
			   AND sd.region_sid = m.region_sid
		)
	)
	--
	-- Legacy meter readings part
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.cost,
		mr.baseline_val, mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference,
		mr.meter_document_id, mr.created_invoice_id, mr.approved_dtm, mr.approved_by_sid,
		mr.is_estimate, mr.flow_item_id, mr.pm_reading_id, mr.format_mask,
		m.auto_source
	  FROM m
	  JOIN csr.v$meter_reading mr on mr.app_sid = m.app_sid AND mr.region_sid = m.legacy_region_sid
	--
	-- Source data part
	UNION
	SELECT MAX(x.app_sid) app_sid, ROW_NUMBER() OVER (ORDER BY x.start_dtm) meter_reading_id,
		MAX(x.region_sid) region_sid, x.start_dtm, x.end_dtm, MAX(x.val_number) val_number, MAX(x.cost) cost,
		NULL baseline_val, 3 entered_by_user_sid, NULL entered_dtm, 
		REPLACE(STRAGG(x.note), ',', '; ') note,
		NULL reference, NULL meter_document_id, NULL created_invoice_id, NULL approved_dtm, NULL approved_by_sid,
		0 is_estimate, NULL flow_item_id, NULL pm_reading_id, NULL format_mask, x.auto_source
	FROM (
		-- Consumption (value part)
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, sd.consumption val_number, NULL cost, m.auto_source, NULL note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost (value part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, sd.consumption cost, m.auto_source, NULL note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Consumption (distinct note part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, m.auto_source, sd.note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost (distinct note part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, m.auto_source, sd.note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	) x
	GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, x.auto_source
;

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE csr.auto_imp_importer_settings
	   SET mapping_xml = INSERTCHILDXML(
	   		mapping_xml, 
			'/columnMappings/column[@name="Url"]', 
			'@column-type', 
			'note')
	 WHERE EXISTSNODE(mapping_xml, '/columnMappings/column[@name="Url"]') = 1			-- Where the column name is "Url"
	   AND EXISTSNODE(mapping_xml, '/columnMappings/column[@column-type="note"]') = 0	-- and no nodes are already set to the "Note" column type
	   AND automated_import_class_sid IN (
		SELECT automated_import_class_sid
		  FROM csr.meter_raw_data_source
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_monitor_pkg

@../meter_body
@../meter_monitor_body
@../enable_body

@../csrimp/imp_body

@update_tail
