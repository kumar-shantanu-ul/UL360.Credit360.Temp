CREATE OR REPLACE PACKAGE BODY csr.test_baseline_pkg AS

-- Fixture scope
v_site_name					VARCHAR(200);

------------------------------------
-- SETUP and TEARDOWN
------------------------------------
PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
END;

-- Called after each PASSED test
PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
	DELETE FROM CSR.BASELINE_CONFIG_PERIOD WHERE APP_SID = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM CSR.BASELINE_CONFIG WHERE APP_SID = SYS_CONTEXT('SECURITY', 'APP');
END;

-- Called once before all tests
PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.LogonAdmin(v_site_name);
	DELETE FROM CSR.BASELINE_CONFIG_PERIOD  WHERE APP_SID = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM CSR.BASELINE_CONFIG WHERE APP_SID = SYS_CONTEXT('SECURITY', 'APP');
END;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
	DELETE FROM CSR.BASELINE_CONFIG WHERE APP_SID = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM CSR.BASELINE_CONFIG_PERIOD WHERE APP_SID = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;


PROCEDURE TestCreateBaselineConfig
AS
	v_baseline_name			VARCHAR2(200);
	v_baseline_lookup_key	VARCHAR2(200);
	v_count					NUMBER;
	v_baseline_config_id	NUMBER;
BEGIN
	Trace('TestCreateBaselineConfig');

	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
	
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=>	v_baseline_name,
		in_baseline_lookup_key	=>	v_baseline_lookup_key,
		out_baseline_config_id	=>	v_baseline_config_id
		);

	SELECT COUNT(*)
	  INTO v_count
	  FROM CSR.BASELINE_CONFIG
	 WHERE baseline_name 	= v_baseline_name
	   AND baseline_lookup_key = v_baseline_lookup_key
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');			

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Created Baseline config not found.');
END;

PROCEDURE TestUpdateBaselineConfig
AS
	v_baseline_name			VARCHAR2(200);
	v_baseline_lookup_key	VARCHAR2(200);
	v_count					NUMBER;
	v_baseline_config_id	NUMBER;
BEGIN
	Trace('TestUpdateBaselineConfig');
	
	-- Create Baseline Config 
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
	
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=> v_baseline_name,
		in_baseline_lookup_key	=> v_baseline_lookup_key,
		out_baseline_config_id	=> v_baseline_config_id
		);

	-- Update Baseline Config
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
	
	baseline_pkg.UpdateBaselineConfig(
		in_baseline_config_id	=>  v_baseline_config_id,
		in_baseline_name 		=>	v_baseline_name,
		in_baseline_lookup_key	=>	v_baseline_lookup_key
		);

	SELECT COUNT(*)
	  INTO v_count
	  FROM CSR.BASELINE_CONFIG
	 WHERE baseline_name 	= v_baseline_name
	   AND baseline_lookup_key = v_baseline_lookup_key
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');			

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Updated Baseline config not found.');
END;

PROCEDURE TestCreateBaselineConfigPeriod
AS
	v_baseline_name						VARCHAR2(200);
	v_baseline_lookup_key				VARCHAR2(200);
	v_baseline_config_id				NUMBER;
	v_baseline_period_dtm				DATE;
	v_baseline_cover_period_start_dtm	DATE;
	v_baseline_cover_period_end_dtm		DATE;
	v_count								NUMBER;
	v_out_period_id						NUMBER;
BEGIN
	Trace('TestCreateBaselineConfigPeriod');

	-- Create Baseline Config 
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
		
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=> v_baseline_name,
		in_baseline_lookup_key	=> v_baseline_lookup_key,
		out_baseline_config_id	=> v_baseline_config_id
		);


	-- Create Baseline Config Period
	v_baseline_period_dtm 				:= SYSDATE;
	v_baseline_cover_period_start_dtm	:= SYSDATE + 1;
	v_baseline_cover_period_end_dtm		:= SYSDATE + 5;

	baseline_pkg.CreateBaselineConfigPeriod(
		in_baseline_config_id				=>	v_baseline_config_id,
		in_baseline_period_dtm				=>	v_baseline_period_dtm,
		in_baseline_cover_period_start_dtm	=>	v_baseline_cover_period_start_dtm,
		in_baseline_cover_period_end_dtm	=>	v_baseline_cover_period_end_dtm,
		out_baseline_config_period_id		=>	v_out_period_id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM CSR.BASELINE_CONFIG_PERIOD
	 WHERE baseline_config_id = v_baseline_config_id
	   AND baseline_period_dtm  = TRUNC(v_baseline_period_dtm)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Baseline config period not found.');
END;

PROCEDURE TestUpdateBaselineConfigPeriod
AS
	v_baseline_name						VARCHAR2(200);
	v_baseline_lookup_key				VARCHAR2(200);
	v_baseline_config_id				NUMBER;
	v_baseline_period_dtm				DATE;
	v_baseline_cover_period_start_dtm	DATE;
	v_baseline_cover_period_end_dtm		DATE;
	v_baseline_config_period_id			NUMBER;
	v_count								NUMBER;
BEGIN
	Trace('TestUpdateBaselineConfigPeriod');

	-- Create Baseline Config 
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
		
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=> v_baseline_name,
		in_baseline_lookup_key	=> v_baseline_lookup_key,
		out_baseline_config_id	=> v_baseline_config_id
		);

	-- Create Baseline Config Period
	v_baseline_period_dtm 				:= SYSDATE;
	v_baseline_cover_period_start_dtm	:= SYSDATE + 1;
	v_baseline_cover_period_end_dtm		:= SYSDATE + 5;


	baseline_pkg.CreateBaselineConfigPeriod(
		in_baseline_config_id				=>	v_baseline_config_id,
		in_baseline_period_dtm				=>	v_baseline_period_dtm,
		in_baseline_cover_period_start_dtm	=>	v_baseline_cover_period_start_dtm,
		in_baseline_cover_period_end_dtm	=>	v_baseline_cover_period_end_dtm,
		out_baseline_config_period_id		=>	v_baseline_config_period_id
	);

	-- Update Baseline Config Period

	v_baseline_period_dtm 				:= SYSDATE + 1;
	v_baseline_cover_period_start_dtm	:= SYSDATE + 2;
	v_baseline_cover_period_end_dtm		:= SYSDATE + 6;
	

	baseline_pkg.UpdateBaselineConfigPeriod(
		in_baseline_config_period_id		=>	v_baseline_config_period_id,
		in_baseline_period_dtm				=>	v_baseline_period_dtm,
		in_baseline_cover_period_start_dtm	=>	v_baseline_cover_period_start_dtm,
		in_baseline_cover_period_end_dtm	=>	v_baseline_cover_period_end_dtm
	);
		
	SELECT COUNT(*)
	  INTO v_count
	  FROM CSR.BASELINE_CONFIG_PERIOD
	 WHERE baseline_config_id = v_baseline_config_id
	   AND baseline_period_dtm  = TRUNC(v_baseline_period_dtm)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Updated Baseline config period not found.');
END;


PROCEDURE INT_CreateConfigAndPeriod
AS
	v_baseline_name						VARCHAR2(200);
	v_baseline_lookup_key				VARCHAR2(200);
	v_baseline_config_id				NUMBER;
	v_baseline_period_dtm				DATE;
	v_baseline_cover_period_start_dtm	DATE;
	v_baseline_cover_period_end_dtm		DATE;
	v_baseline_config_period_id			NUMBER;
BEGIN
	-- Create Baseline Config 
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
	
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=> v_baseline_name,
		in_baseline_lookup_key	=> v_baseline_lookup_key,
		out_baseline_config_id	=> v_baseline_config_id
	);

	-- Create Baseline Config Period
	v_baseline_period_dtm 				:= SYSDATE;
	v_baseline_cover_period_start_dtm	:= SYSDATE + 1;
	v_baseline_cover_period_end_dtm		:= SYSDATE + 5;


	baseline_pkg.CreateBaselineConfigPeriod(
		in_baseline_config_id				=>	v_baseline_config_id,
		in_baseline_period_dtm				=>	v_baseline_period_dtm,
		in_baseline_cover_period_start_dtm	=>	v_baseline_cover_period_start_dtm,
		in_baseline_cover_period_end_dtm	=>	v_baseline_cover_period_end_dtm,
		out_baseline_config_period_id		=>	v_baseline_config_period_id
	);
END;

PROCEDURE TestGetBaselineConfigs AS
	v_baseline_config_id				NUMBER;
	v_baseline_name						VARCHAR2(200);
	v_baseline_lookup_key				VARCHAR2(200);

	v_baseline_config_period_id			NUMBER;
	v_baseline_period_dtm				DATE;
	v_baseline_cover_period_start_dtm	DATE;
	v_baseline_cover_period_end_dtm		DATE;

	v_count								NUMBER;
	v_out_cur_bc						SYS_REFCURSOR;
	v_out_cur_bcp						SYS_REFCURSOR;
BEGIN
	Trace('TestGetBaselineConfigs');

	baseline_pkg.GetBaselineConfigs(
		out_baseline_config_cur				=>	v_out_cur_bc,
		out_baseline_config_period_cur		=>	v_out_cur_bcp
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur_bc INTO v_baseline_config_id, v_baseline_name, v_baseline_lookup_key;
		EXIT WHEN v_out_cur_bc%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Baseline config found.');

	v_count := 0;
	LOOP
		FETCH v_out_cur_bcp INTO v_baseline_config_period_id, v_baseline_config_id, v_baseline_period_dtm, v_baseline_cover_period_start_dtm, v_baseline_cover_period_end_dtm;
		EXIT WHEN v_out_cur_bcp%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Baseline config period found.');


	-- Create Baseline Configs
	INT_CreateConfigAndPeriod();
	INT_CreateConfigAndPeriod();

	baseline_pkg.GetBaselineConfigs(
		out_baseline_config_cur				=>	v_out_cur_bc,
		out_baseline_config_period_cur		=>	v_out_cur_bcp
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur_bc INTO v_baseline_config_id, v_baseline_name, v_baseline_lookup_key;
		EXIT WHEN v_out_cur_bc%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Baseline config not found.');

	v_count := 0;
	LOOP
		FETCH v_out_cur_bcp INTO v_baseline_config_period_id, v_baseline_config_id, v_baseline_period_dtm, v_baseline_cover_period_start_dtm, v_baseline_cover_period_end_dtm;
		EXIT WHEN v_out_cur_bcp%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Baseline config period not found.');

END;

PROCEDURE TestGetBaselineConfig AS
	v_baseline_name						VARCHAR2(200);
	v_baseline_lookup_key				VARCHAR2(200);
	v_baseline_config_id				NUMBER;
	v_count								NUMBER;
	v_out_cur							SYS_REFCURSOR;
	baseline_config_id					NUMBER;
	baseline_name						VARCHAR2(200);
	baseline_lookup_key					VARCHAR2(200);
BEGIN
	Trace('TestGetBaselineConfig');

	-- Create Baseline Config 
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
		
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=> v_baseline_name,
		in_baseline_lookup_key	=> v_baseline_lookup_key,
		out_baseline_config_id	=> v_baseline_config_id
		);

	baseline_pkg.GetBaselineConfig(
		in_baseline_config_id		=>	v_baseline_config_id,
		out_cur						=>	v_out_cur
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO baseline_config_id,baseline_name,baseline_lookup_key;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Baseline config not found.');
END;

PROCEDURE TestGetBaselineConfigList AS
	v_baseline_name						VARCHAR2(200);
	v_baseline_lookup_key				VARCHAR2(200);
	v_baseline_config_id				NUMBER;
	v_count								NUMBER;
	v_out_cur							SYS_REFCURSOR;
	baseline_config_id					NUMBER;
	baseline_name						VARCHAR2(200);
	baseline_lookup_key					VARCHAR2(200);
BEGIN
	Trace('TestGetBaselineConfigList');

	-- Create Baseline Config 
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
		
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=> v_baseline_name,
		in_baseline_lookup_key	=> v_baseline_lookup_key,
		out_baseline_config_id	=> v_baseline_config_id
		);

	baseline_pkg.GetBaselineConfigList(
		out_cur		=>	v_out_cur
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO baseline_config_id,baseline_name,baseline_lookup_key;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Baseline config list not found.');
END;

PROCEDURE TestGetBaselineConfigPeriod AS
	v_baseline_name						VARCHAR2(200);
	v_baseline_lookup_key				VARCHAR2(200);
	v_baseline_config_id				NUMBER;
	v_baseline_period_dtm				DATE;
	v_baseline_cover_period_start_dtm	DATE;
	v_baseline_cover_period_end_dtm		DATE;
	v_baseline_config_period_id			NUMBER;
	v_count								NUMBER;
	v_out_cur							SYS_REFCURSOR;
	baseline_config_period_id			NUMBER;
	baseline_config_id					NUMBER;
	baseline_period_dtm					DATE;
	baseline_cover_period_start_dtm		DATE;
	baseline_cover_period_end_dtm		DATE;
BEGIN
	Trace('TestGetBaselineConfigPeriod');

	-- Create Baseline Config 
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
		
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=> v_baseline_name,
		in_baseline_lookup_key	=> v_baseline_lookup_key,
		out_baseline_config_id	=> v_baseline_config_id
		);

	-- Create Baseline Config Period
	v_baseline_period_dtm 				:= SYSDATE;
	v_baseline_cover_period_start_dtm	:= SYSDATE + 1;
	v_baseline_cover_period_end_dtm		:= SYSDATE + 5;


	baseline_pkg.CreateBaselineConfigPeriod(
		in_baseline_config_id				=>	v_baseline_config_id,
		in_baseline_period_dtm				=>	v_baseline_period_dtm,
		in_baseline_cover_period_start_dtm	=>	v_baseline_cover_period_start_dtm,
		in_baseline_cover_period_end_dtm	=>	v_baseline_cover_period_end_dtm,
		out_baseline_config_period_id		=>	v_baseline_config_period_id
	);

	baseline_pkg.GetBaselineConfigPeriod(
		in_baseline_config_id				=>	v_baseline_config_id,
		out_cur								=>	v_out_cur
	);
	
	v_count := 0;
	LOOP
		FETCH v_out_cur INTO baseline_config_period_id,baseline_config_id,baseline_period_dtm,baseline_cover_period_start_dtm,baseline_cover_period_end_dtm;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Updated Baseline config period not found.');
END;

PROCEDURE TestDeleteBaselineConfig AS
	v_baseline_name						VARCHAR2(200);
	v_baseline_lookup_key				VARCHAR2(200);
	v_baseline_config_id				NUMBER;
	v_count								NUMBER;
BEGIN
	Trace('TestDeleteBaselineConfig');

	-- Create Baseline Config 
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
		
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=> v_baseline_name,
		in_baseline_lookup_key	=> v_baseline_lookup_key,
		out_baseline_config_id	=> v_baseline_config_id
		);

	baseline_pkg.DeleteBaselineConfig(
		in_baseline_config_id		=>	v_baseline_config_id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM CSR.BASELINE_CONFIG
	 WHERE baseline_name 	= v_baseline_name
	   AND baseline_lookup_key = v_baseline_lookup_key
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Baseline config could not deleted.');
END;


PROCEDURE TestDeleteBaselineConfigPeriod AS
	v_baseline_name						VARCHAR2(200);
	v_baseline_lookup_key				VARCHAR2(200);
	v_baseline_config_id				NUMBER;
	v_baseline_period_dtm				DATE;
	v_baseline_cover_period_start_dtm	DATE;
	v_baseline_cover_period_end_dtm		DATE;
	v_baseline_config_period_id			NUMBER;
	v_count								NUMBER;
BEGIN
	Trace('TestDeleteBaselineConfigPeriod');

	-- Create Baseline Config 
	SELECT dbms_random.string('p',10), dbms_random.string('p',10)
	  INTO v_baseline_name, v_baseline_lookup_key
	  FROM dual;
		
	baseline_pkg.CreateBaselineConfig(
		in_baseline_name 		=> v_baseline_name,
		in_baseline_lookup_key	=> v_baseline_lookup_key,
		out_baseline_config_id	=> v_baseline_config_id
		);

	-- Create Baseline Config Period
	v_baseline_period_dtm 				:= SYSDATE;
	v_baseline_cover_period_start_dtm	:= SYSDATE + 1;
	v_baseline_cover_period_end_dtm		:= SYSDATE + 5;

	baseline_pkg.CreateBaselineConfigPeriod(
		in_baseline_config_id				=>	v_baseline_config_id,
		in_baseline_period_dtm				=>	v_baseline_period_dtm,
		in_baseline_cover_period_start_dtm	=>	v_baseline_cover_period_start_dtm,
		in_baseline_cover_period_end_dtm	=>	v_baseline_cover_period_end_dtm,
		out_baseline_config_period_id		=>	v_baseline_config_period_id
	);

	baseline_pkg.DeleteBaselineConfigPeriod(
		in_baseline_config_period_id		=>	v_baseline_config_period_id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM CSR.BASELINE_CONFIG_PERIOD
	 WHERE baseline_config_id = v_baseline_config_id
	   AND baseline_period_dtm  = v_baseline_period_dtm
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Baseline config period could not deleted.');

END;



END test_baseline_pkg;
/