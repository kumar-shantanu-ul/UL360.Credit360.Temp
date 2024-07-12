-- Please update version.sql too -- this keeps clean builds in sync
define version=3205
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description,  plugin_name, in_order, notify_address, max_retries,   priority, timeout_mins)
		 VALUES (86, 'OSHA Zipped Export', 'batch-exporter', 0, 'support@credit360.com', 3, 1, 120);

	INSERT INTO csr.batched_export_type (label, assembly, batch_job_type_id)
		 VALUES ('OSHA Zipped Export', 'Credit360.ExportImport.Export.Batched.Exporters.OshaZippedBatchExporter', 86);
	
	INSERT INTO csr.osha_map_field (osha_map_field_id, label, pos)
		 VALUES (34, 'Standard Industrial Classification (SIC)', 34);

	INSERT INTO csr.osha_map_field_type (osha_map_field_id, osha_map_type_id)
		 VALUES (34, 1);
	INSERT INTO csr.osha_map_field_type (osha_map_field_id, osha_map_type_id)
		 VALUES (34, 2);
	INSERT INTO csr.osha_map_field_type (osha_map_field_id, osha_map_type_id)
		 VALUES (34, 3);

	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		 VALUES (28, 'sic_code', 'Standard Industrial Classification (SIC), if known (e.g., SIC 3715)', 'Integer', 4, 1, 0, 34);

	UPDATE security.menu
	   SET description =  'OSHA Export'
	 WHERE description = 'OSHA 300A Export';
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../osha_pkg

@../osha_body
@../enable_body
@update_tail
