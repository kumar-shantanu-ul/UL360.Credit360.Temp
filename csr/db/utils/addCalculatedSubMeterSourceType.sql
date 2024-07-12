DECLARE
BEGIN
	user_pkg.logonadmin('&&host');
	
	FOR r IN (
		SELECT metering_enabled
		  FROM csr.customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		IF r.metering_enabled = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Metering must be enabled before adding calculated sub-meters');
		END IF;
	END LOOP;
	
	FOR r IN (
		SELECT is_calculated_sub_meter
		  FROM csr.meter_source_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND is_calculated_sub_meter = 1
	) LOOP
		RAISE_APPLICATION_ERROR(-20001, 'meter_source_type table already contains calculated sub-meter types');
	END LOOP;
	
	INSERT INTO csr.meter_source_type (meter_source_type_id, name, description, manual_data_entry, supplier_data_mandatory, arbitrary_period, reference_mandatory,
		add_invoice_data, realtime_metering, show_in_meter_list, region_date_clipping, is_calculated_sub_meter, req_approval, flow_sid, descending, allow_reset)
		SELECT MAX(meter_source_type_id) + 1, 'calcsub', 'Calculated sub-meter', 0, 0, 1, 0,
			0, 0, 0, 0, 1, 0, NULL, 0, 0
		  FROM csr.meter_source_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	;
	
	COMMIT;
END;
/

EXIT