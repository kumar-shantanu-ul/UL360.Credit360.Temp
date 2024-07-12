DECLARE
	v_ds_type_id	meter_raw_data_source_type.raw_data_source_type_id%TYPE;
	v_ds_id			meter_raw_data_source.raw_data_source_id%TYPE;
BEGIN
	
	security.user_pkg.logonadmin('&&1');
	
	SELECT raw_data_source_type_id
	  INTO v_ds_type_id
	  FROM meter_raw_data_source_type
	 WHERE feed_type = 'ftp';
	
	csr.meter_monitor_pkg.SaveDataSource(
		in_data_source_id		=> NULL,
		in_source_email			=> NULL,
		in_source_folder		=> 'ftp',
		in_file_match_rx		=> '.+[^_sum]\.txt',
		in_parser_type			=> 'Wi5',
		in_export_system_values	=> 1,
		in_export_after_dtm		=> NULL,
		in_default_user_sid		=> NULL,
		in_type_id				=> v_ds_type_id,
		out_data_source_id		=> v_ds_id
	);

	COMMIT;
END;
/

