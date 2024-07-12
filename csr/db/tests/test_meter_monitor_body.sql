CREATE OR REPLACE PACKAGE BODY csr.test_meter_monitor_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	--NULL;
END;

PROCEDURE DeleteImporterTestData
AS
	v_class_sid		NUMBER := 0;
BEGIN
	DELETE FROM csr.auto_imp_importer_settings;
	DELETE FROM csr.automated_import_class_step;
	DELETE FROM csr.automated_import_class;
	DELETE FROM csr.auto_imp_fileread_ftp;
	DELETE FROM csr.auto_imp_importer_settings;

	BEGIN
		SELECT NVL(sid_id,0)
		  INTO v_class_sid
		  FROM security.securable_object
		 WHERE name = 'Meter data source 101';

		IF v_class_sid > 0 THEN
			csr.automated_import_pkg.DeleteClass(v_class_sid);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;	
END;

PROCEDURE DeleteMeterTestData
AS
BEGIN
	DELETE FROM csr.meter_live_data;
	DELETE FROM csr.all_meter;
	DELETE FROM meter_type_input;
	DELETE FROM meter_type;
	DELETE FROM csr.meter_source_type;
	DELETE FROM csr.meter_alarm_statistic;
	DELETE FROM csr.meter_bucket;
	DELETE FROM meter_input_aggregator;
	DELETE FROM meter_input;
	DELETE FROM meter_data_priority;
	
	FOR r IN (SELECT region_sid FROM csr.region WHERE name like 'TestUpsertMeterLiveData%')
	LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, r.region_sid);
	END LOOP;
END;


PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	Trace('SetUpFixture');
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE SetUp AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);

	DeleteImporterTestData;
	DeleteMeterTestData;
END;



-- HELPER PROCS



-- Tests

PROCEDURE SetupAutoCreateMeters AS
	v_test_name			VARCHAR2(100) := 'SetupAutoCreateMeters';
	v_count				NUMBER;

	v_class_sid			NUMBER;
	v_path				VARCHAR2(100);
	v_fileread_ftp_id	NUMBER;
	v_fileread_ftp_id_2	NUMBER;
BEGIN
	Trace(v_test_name);

	BEGIN
		SELECT sid_id
		INTO v_class_sid
		FROM security.securable_object
		WHERE name = 'Meter data source 101';
		csr.automated_import_pkg.DeleteClass(v_class_sid);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	-- expect to start with empty
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.automated_import_class;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0 aic records'||' - '||v_count||' found.');
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.auto_imp_fileread_ftp;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0 aiftp records'||' - '||v_count||' found.');
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.auto_imp_importer_settings;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0 aiis records'||' - '||v_count||' found.');
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.automated_import_class_step;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0 aics records'||' - '||v_count||' found.');


	csr.meter_monitor_pkg.SetupAutoCreateMeters(
		in_automated_import_class_sid	=> NULL,
		in_data_source_id				=> 101,
		in_mapping_xml					=> '<mappings></mappings>',
		in_delimiter					=> ',',
		in_ftp_path						=> 'testMeterFtp',
		in_file_mask					=> '*',
		in_file_type					=> 'DSV',
		in_source_email					=> NULL,
		in_process_body					=> '',
		out_class_sid					=> v_class_sid
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.automated_import_class;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 aic records'||' - '||v_count||' found.');


	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.auto_imp_fileread_ftp;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 aiftp records'||' - '||v_count||' found.');
	SELECT payload_path
	  INTO v_path
	  FROM csr.auto_imp_fileread_ftp;
	unit_test_pkg.AssertIsTrue(v_path = '/testMeterFtp/', 'Unexpected path in aiftp record.');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.auto_imp_importer_settings;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 aiis records'||' - '||v_count||' found.');


	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.automated_import_class_step;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 aics records'||' - '||v_count||' found.');
	SELECT auto_imp_fileread_ftp_id
	  INTO v_fileread_ftp_id
	  FROM csr.automated_import_class_step;
	unit_test_pkg.AssertIsTrue(v_fileread_ftp_id > 0, 'Expected nonzero value for auto_imp_fileread_ftp_id.');

	-- recreate and recheck
	csr.meter_monitor_pkg.SetupAutoCreateMeters(
		in_automated_import_class_sid	=> NULL,
		in_data_source_id				=> 101,
		in_mapping_xml					=> '<mappings></mappings>',
		in_delimiter					=> ',',
		in_ftp_path						=> 'testMeterFtp',
		in_file_mask					=> '*',
		in_file_type					=> 'DSV',
		in_source_email					=> NULL,
		in_process_body					=> '',
		out_class_sid					=> v_class_sid
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.auto_imp_fileread_ftp;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 aiftp records'||' - '||v_count||' found.');
	SELECT payload_path
	  INTO v_path
	  FROM csr.auto_imp_fileread_ftp;
	unit_test_pkg.AssertIsTrue(v_path = '/testMeterFtp/', 'Unexpected path in aiftp record.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.automated_import_class_step;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 aics records'||' - '||v_count||' found.');

	SELECT auto_imp_fileread_ftp_id
	  INTO v_fileread_ftp_id_2
	  FROM csr.automated_import_class_step;
	unit_test_pkg.AssertIsTrue(v_fileread_ftp_id = v_fileread_ftp_id_2, 'Expected unchanged fileread_ftp_id.');

END;

PROCEDURE TestUpsertMeterLiveData AS
	v_test_name			VARCHAR2(100) := 'UpsertMeterLiveData';
	v_count				NUMBER;

	v_region_sid		NUMBER;
	v_period_val		meter_live_data.consumption%TYPE;
	v_update_period_val		meter_live_data.consumption%TYPE;
	v_raw_data_id		meter_raw_data.meter_raw_data_id%TYPE;

	v_curr_meter_data_id	NUMBER;
	v_max_meter_data_id		NUMBER;
	v_new_meter_data_id		NUMBER;

	v_meter_bucket_id		NUMBER := 1;
	v_meter_type_id			NUMBER := 2;
	v_source_type_id		NUMBER := 1;
	v_manual_data_entry		NUMBER := 0;
	v_crc_meter				NUMBER := 0;
	v_is_core				NUMBER := 1;
	v_meter_input_id_consumption	NUMBER := 101;
BEGIN
	Trace(v_test_name);

	v_region_sid := unit_test_pkg.GetOrCreateRegion('TestUpsertMeterLiveData_1');

	-- have to get next at least once for the session
	SELECT meter_data_id_seq.NEXTVAL
	  INTO v_curr_meter_data_id
	  FROM dual;
	Trace('next '|| v_curr_meter_data_id);

	SELECT meter_data_id_seq.CURRVAL
	  INTO v_curr_meter_data_id
	  FROM dual;
	Trace('curr '|| v_curr_meter_data_id);

	v_meter_bucket_id := 100;

	BEGIN
		INSERT INTO meter_bucket (meter_bucket_id, description, is_export_period, period_set_id, period_interval_id)
		VALUES(v_meter_bucket_id, 'Monthly', 1, 1, 1);

		INSERT INTO meter_source_type (meter_source_type_id, name, description,
			arbitrary_period, add_invoice_data, show_in_meter_list)
		VALUES (1, 'point', 'Point in time', 0, 1, 1);

		INSERT INTO meter_type (meter_type_id, label, group_key, days_ind_sid, costdays_ind_sid)
			VALUES (v_meter_type_id, 'in_label', 'in_group_key', NULL, NULL);

		INSERT INTO all_meter
			(region_sid, meter_type_id, meter_source_type_id, manual_data_entry, crc_meter, 
				is_core, active)
			VALUES (v_region_sid, v_meter_type_id, v_source_type_id, v_manual_data_entry, v_crc_meter, 
				v_is_core, 1);

		INSERT INTO meter_input (meter_input_id, label, lookup_key, is_consumption_based)
		VALUES (v_meter_input_id_consumption, 'Consumption', 'CONSUMPTION', 1);
		INSERT INTO meter_input_aggregator(meter_input_id, aggregator, is_mandatory)
		VALUES(v_meter_input_id_consumption, 'SUM', 1);

		INSERT INTO meter_data_priority (priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
		VALUES (3, 'High resolution', 'HI_RES', 1, 0, 0, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	v_period_val := 1234;
	meter_monitor_pkg.UpsertMeterLiveData(
		in_region_sid => v_region_sid,
		in_meter_bucket_id => v_meter_bucket_id,
		in_meter_input_id => v_meter_input_id_consumption,
		in_aggregator => 'SUM',
		in_priority => 3,
		in_period_start_dtm => DATE '2021-01-01',
		in_period_end_dtm => DATE '2021-01-02',
		in_period_val => v_period_val,
		in_raw_data_id => v_raw_data_id
	);

	SELECT max(meter_data_id)
	  INTO v_max_meter_data_id
	  FROM meter_live_data;
	Trace('max '|| v_max_meter_data_id);
	SELECT meter_data_id_seq.CURRVAL
	  INTO v_curr_meter_data_id
	  FROM dual;
	Trace('new '|| v_curr_meter_data_id);
	unit_test_pkg.AssertIsTrue(v_curr_meter_data_id + 1 = v_new_meter_data_id, 'Expected meter_data_ids to be contiguous.');
	unit_test_pkg.AssertIsTrue(v_curr_meter_data_id = v_max_meter_data_id, 'Expected matched max,curr.');

	SELECT count(*)
	  INTO v_count
	  FROM meter_live_data
	 WHERE region_sid = v_region_sid;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one record, got '||v_count);

	----------------
	Trace('---update---');


	SELECT meter_data_id_seq.CURRVAL
	  INTO v_curr_meter_data_id
	  FROM dual;
	Trace('update curr '|| v_curr_meter_data_id);

	v_update_period_val := 1235;
	meter_monitor_pkg.UpsertMeterLiveData(
		in_region_sid => v_region_sid,
		in_meter_bucket_id => v_meter_bucket_id,
		in_meter_input_id => v_meter_input_id_consumption,
		in_aggregator => 'SUM',
		in_priority => 3,
		in_period_start_dtm => DATE '2021-01-01',
		in_period_end_dtm => DATE '2021-01-02',
		in_period_val => v_update_period_val,
		in_raw_data_id => v_raw_data_id
	);

	SELECT max(meter_data_id)
	  INTO v_max_meter_data_id
	  FROM meter_live_data;
	Trace('max '|| v_max_meter_data_id);
	SELECT meter_data_id_seq.CURRVAL
	  INTO v_curr_meter_data_id
	  FROM dual;
	Trace('new '|| v_curr_meter_data_id);
	unit_test_pkg.AssertIsTrue(v_curr_meter_data_id + 1 = v_new_meter_data_id, 'Expected meter_data_ids to be contiguous.');
	unit_test_pkg.AssertIsTrue(v_curr_meter_data_id = v_max_meter_data_id, 'Expected matched max,curr.');

	SELECT count(*)
	  INTO v_count
	  FROM meter_live_data
	 WHERE region_sid = v_region_sid;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one record, got '||v_count);

END;


--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);

	DeleteImporterTestData;

	DeleteMeterTestData;
END;

END test_meter_monitor_pkg;
/
