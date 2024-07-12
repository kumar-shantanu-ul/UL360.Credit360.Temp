CREATE OR REPLACE PACKAGE BODY csr.test_energy_star_pkg AS

-- Fixture scope
v_site_name					VARCHAR(50) := 'dbtest-energystar.credit360.com';
v_app_sid					security.security_pkg.T_SID_ID;
v_act_id					security.security_pkg.T_ACT_ID;
v_administrator_sid			security.security_pkg.T_SID_ID;
v_workflow_sid				security.security_pkg.T_SID_ID;
v_test_group_sid			security.security_pkg.T_SID_ID;
v_unauthed_user_sid			security.security_pkg.T_SID_ID;

PROCEDURE CreateSite
AS
BEGIN
	security.user_pkg.LogonAdmin;

	BEGIN
		v_app_sid := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), 0, '//Aspen/Applications/' || v_site_name);
		security.user_pkg.LogonAdmin(v_site_name);
		csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	csr.csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);
	v_test_group_sid := unit_test_pkg.GetOrCreateGroup('TEST_GROUP');
	v_unauthed_user_sid := unit_test_pkg.GetOrCreateUser('unauthed.user');

	COMMIT; -- need to commit before logging as this user
END;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	NULL;
END;

PROCEDURE DeleteDataCreatedDuringTests
AS
BEGIN
	-- delete data that could have been created during tests, in case of previously aborted/failed runs.
	NULL;
END;

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
END;

-- Called once before all tests
PROCEDURE SetUpFixture
AS
	v_user_sid					security.security_pkg.T_SID_ID;
BEGIN
	CreateSite;
	security.user_pkg.LogonAdmin(v_site_name);
	SELECT csr_user_sid INTO v_administrator_sid FROM csr.csr_user WHERE user_name = 'builtinadministrator';
	v_act_id := SYS_CONTEXT('SECURITY','ACT');

	v_user_sid := unit_test_pkg.GetOrCreateUser('admin');

	unit_test_pkg.CreateCommonMenu;
	unit_test_pkg.CreateCommonWebResources;
	unit_test_pkg.EnableChain;

	enable_pkg.EnableMeteringBase();
	enable_pkg.EnableWorkflow;
	enable_pkg.EnableProperties(
		in_company_name => 'ENERGYSTAR_COMPANY',
		in_property_type => 'ENERGYSTAR_PROPTYPE'
	);
	enable_pkg.EnableEnergyStar;

	DeleteDataCreatedDuringTests;
END;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);

	DeleteDataCreatedDuringTests;

	security.user_pkg.LogonAdmin(v_site_name);
	csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
END;


--- tests ---

PROCEDURE TestPrepConsumptionDataWithDataAfterLockShouldSucceed
AS
	v_pm_ids					security_pkg.T_SID_IDS;
	v_start_dates				energy_star_pkg.T_DATE_ARRAY;
	v_end_dates					energy_star_pkg.T_DATE_ARRAY;
	v_consumptions				energy_star_pkg.T_VAL_ARRAY;
	v_costs						energy_star_pkg.T_VAL_ARRAY;
	v_estimates					security_pkg.T_SID_IDS;
	v_region_sid				security_pkg.T_SID_ID;
	v_lock_end_dtm				DATE;
	v_success 					BOOLEAN := false;
BEGIN
	TRACE('TestPrepConsumptionDataWithDataAfterLockShouldSucceed');
	-- set system data lock
	v_lock_end_dtm:= DATE '2016-01-01';
	UPDATE customer
		SET lock_end_dtm =  v_lock_end_dtm
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		v_pm_ids(1) := 1;
		v_start_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-AUG-2018');
		v_end_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-AUG-2018');
		v_consumptions := energy_star_pkg.T_VAL_ARRAY(1=> 10);
		v_costs := energy_star_pkg.T_VAL_ARRAY(1=> 100);
		v_estimates(1) := 1;
		v_estimates(2) := 2;
		v_region_sid := 1;
		
		energy_star_pkg.Test_PrepConsumptionData(
			in_pm_ids					=> v_pm_ids,
			in_start_dates				=> v_start_dates,
			in_end_dates				=> v_end_dates,
			in_consumptions				=> v_consumptions,
			in_costs					=> v_costs,
			in_estimates				=> v_estimates,
			in_region_sid				=> v_region_sid,
			in_ignore_lock				=> FALSE
		);
		
		v_success := true; 
	END;

	IF v_success = false THEN
		unit_test_pkg.TestFail('PrepConsumptionData should not throw ERR_METER_WITHIN_LOCK_PERIOD exception!');
	END IF;

	-- set back to default data lock
	UPDATE customer
		SET lock_end_dtm =  DATE '1980-01-01'
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE TestPrepConsumptionDataWithDataBeforeLockShouldThrowLockPeriodException
AS
	v_pm_ids					security_pkg.T_SID_IDS;
	v_start_dates				energy_star_pkg.T_DATE_ARRAY;
	v_end_dates					energy_star_pkg.T_DATE_ARRAY;
	v_consumptions				energy_star_pkg.T_VAL_ARRAY;
	v_costs						energy_star_pkg.T_VAL_ARRAY;
	v_estimates					security_pkg.T_SID_IDS;
	v_region_sid				security_pkg.T_SID_ID;
	v_lock_end_dtm				DATE;
	v_success 					BOOLEAN := false;
BEGIN
	TRACE('TestPrepConsumptionDataWithDataBeforeLockShouldThrowLockPeriodException');
	-- set system data lock
	v_lock_end_dtm:= DATE '2023-01-01';
	UPDATE customer
		SET lock_end_dtm =  v_lock_end_dtm
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		v_pm_ids(1) := 1;
		v_start_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-AUG-2018');
		v_end_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-AUG-2018');
		v_consumptions := energy_star_pkg.T_VAL_ARRAY(1=> 10);
		v_costs := energy_star_pkg.T_VAL_ARRAY(1=> 100);
		v_estimates(1) := 1;
		v_estimates(2) := 2;
		v_region_sid := 1;

		
		energy_star_pkg.Test_PrepConsumptionData(
			in_pm_ids					=> v_pm_ids,
			in_start_dates				=> v_start_dates,
			in_end_dates				=> v_end_dates,
			in_consumptions				=> v_consumptions,
			in_costs					=> v_costs,
			in_estimates				=> v_estimates,
			in_region_sid				=> v_region_sid,
			in_ignore_lock				=> FALSE
		);
		
		v_success := true; 
	EXCEPTION
		WHEN OTHERS THEN
		BEGIN
			Trace(SQLERRM);
			unit_test_pkg.AssertAreEqual(csr_data_pkg.ERR_METER_WITHIN_LOCK_PERIOD, SQLCODE, 'Exception should have been ERR_METER_WITHIN_LOCK_PERIOD!');
		END;
	END;

	IF v_success = true THEN
		unit_test_pkg.TestFail('PrepConsumptionData should throw ERR_METER_WITHIN_LOCK_PERIOD exception!');
	END IF;

	-- set back to default data lock
	UPDATE customer
		SET lock_end_dtm =  DATE '1980-01-01'
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


PROCEDURE TestPrepConsumptionDataWithDataPartiallyPastLockShouldThrowLockPeriodException
AS
	v_pm_ids					security_pkg.T_SID_IDS;
	v_start_dates				energy_star_pkg.T_DATE_ARRAY;
	v_end_dates					energy_star_pkg.T_DATE_ARRAY;
	v_consumptions				energy_star_pkg.T_VAL_ARRAY;
	v_costs						energy_star_pkg.T_VAL_ARRAY;
	v_estimates					security_pkg.T_SID_IDS;
	v_region_sid				security_pkg.T_SID_ID;
	v_lock_end_dtm				DATE;
	v_success 					BOOLEAN := false;
BEGIN
	TRACE('TestPrepConsumptionDataWithDataPartiallyPastLockShouldThrowLockPeriodException');
	-- set system data lock
	v_lock_end_dtm:= DATE '2023-01-01';
	UPDATE customer
		SET lock_end_dtm =  v_lock_end_dtm
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		v_pm_ids(1) := 1;
		v_start_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-DEC-2022');
		v_end_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-FEB-2023');
		v_consumptions := energy_star_pkg.T_VAL_ARRAY(1=> 10);
		v_costs := energy_star_pkg.T_VAL_ARRAY(1=> 100);
		v_estimates(1) := 1;
		v_estimates(2) := 2;
		v_region_sid := 1;

		
		energy_star_pkg.Test_PrepConsumptionData(
			in_pm_ids					=> v_pm_ids,
			in_start_dates				=> v_start_dates,
			in_end_dates				=> v_end_dates,
			in_consumptions				=> v_consumptions,
			in_costs					=> v_costs,
			in_estimates				=> v_estimates,
			in_region_sid				=> v_region_sid,
			in_ignore_lock				=> FALSE
		);
		
		v_success := true; 
	EXCEPTION
		WHEN OTHERS THEN
		BEGIN
			Trace(SQLERRM);
			unit_test_pkg.AssertAreEqual(csr_data_pkg.ERR_METER_WITHIN_LOCK_PERIOD, SQLCODE, 'Exception should have been ERR_METER_WITHIN_LOCK_PERIOD!');
		END;
	END;

	IF v_success = true THEN
		unit_test_pkg.TestFail('PrepConsumptionData should throw ERR_METER_WITHIN_LOCK_PERIOD exception!');
	END IF;

	-- set back to default data lock
	UPDATE customer
		SET lock_end_dtm =  DATE '1980-01-01'
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;




PROCEDURE TestPrepConsumptionDataWhenLockIgnoredWithDataAfterLockShouldSucceed
AS
	v_pm_ids					security_pkg.T_SID_IDS;
	v_start_dates				energy_star_pkg.T_DATE_ARRAY;
	v_end_dates					energy_star_pkg.T_DATE_ARRAY;
	v_consumptions				energy_star_pkg.T_VAL_ARRAY;
	v_costs						energy_star_pkg.T_VAL_ARRAY;
	v_estimates					security_pkg.T_SID_IDS;
	v_region_sid				security_pkg.T_SID_ID;
	v_lock_end_dtm				DATE;
	v_success 					BOOLEAN := false;
BEGIN
	TRACE('TestPrepConsumptionDataWhenLockIgnoredWithDataAfterLockShouldSucceed');
	-- set system data lock
	v_lock_end_dtm:= DATE '2016-01-01';
	UPDATE customer
		SET lock_end_dtm =  v_lock_end_dtm
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		v_pm_ids(1) := 1;
		v_start_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-AUG-2018');
		v_end_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-AUG-2018');
		v_consumptions := energy_star_pkg.T_VAL_ARRAY(1=> 10);
		v_costs := energy_star_pkg.T_VAL_ARRAY(1=> 100);
		v_estimates(1) := 1;
		v_estimates(2) := 2;
		v_region_sid := 1;
		
		energy_star_pkg.Test_PrepConsumptionData(
			in_pm_ids					=> v_pm_ids,
			in_start_dates				=> v_start_dates,
			in_end_dates				=> v_end_dates,
			in_consumptions				=> v_consumptions,
			in_costs					=> v_costs,
			in_estimates				=> v_estimates,
			in_region_sid				=> v_region_sid,
			in_ignore_lock				=> TRUE
		);
		
		v_success := true; 
	END;

	IF v_success = false THEN
		unit_test_pkg.TestFail('PrepConsumptionData should not throw ERR_METER_WITHIN_LOCK_PERIOD exception!');
	END IF;

	-- set back to default data lock
	UPDATE customer
		SET lock_end_dtm =  DATE '1980-01-01'
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE TestPrepConsumptionDataWhenLockIgnoredWithDataBeforeLockShouldSucceed
AS
	v_pm_ids					security_pkg.T_SID_IDS;
	v_start_dates				energy_star_pkg.T_DATE_ARRAY;
	v_end_dates					energy_star_pkg.T_DATE_ARRAY;
	v_consumptions				energy_star_pkg.T_VAL_ARRAY;
	v_costs						energy_star_pkg.T_VAL_ARRAY;
	v_estimates					security_pkg.T_SID_IDS;
	v_region_sid				security_pkg.T_SID_ID;
	v_lock_end_dtm				DATE;
	v_success 					BOOLEAN := false;
BEGIN
	TRACE('TestPrepConsumptionDataWhenLockIgnoredWithDataBeforeLockShouldSucceed');
	-- set system data lock
	v_lock_end_dtm:= DATE '2023-01-01';
	UPDATE customer
		SET lock_end_dtm =  v_lock_end_dtm
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		v_pm_ids(1) := 1;
		v_start_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-AUG-2018');
		v_end_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-AUG-2018');
		v_consumptions := energy_star_pkg.T_VAL_ARRAY(1=> 10);
		v_costs := energy_star_pkg.T_VAL_ARRAY(1=> 100);
		v_estimates(1) := 1;
		v_estimates(2) := 2;
		v_region_sid := 1;

		
		energy_star_pkg.Test_PrepConsumptionData(
			in_pm_ids					=> v_pm_ids,
			in_start_dates				=> v_start_dates,
			in_end_dates				=> v_end_dates,
			in_consumptions				=> v_consumptions,
			in_costs					=> v_costs,
			in_estimates				=> v_estimates,
			in_region_sid				=> v_region_sid,
			in_ignore_lock				=> TRUE
		);
		
		v_success := true; 
	END;

	IF v_success = false THEN
		unit_test_pkg.TestFail('PrepConsumptionData should not throw ERR_METER_WITHIN_LOCK_PERIOD exception!');
	END IF;

	-- set back to default data lock
	UPDATE customer
		SET lock_end_dtm =  DATE '1980-01-01'
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


PROCEDURE TestPrepConsumptionDataWhenLockIgnoredWithDataPartiallyPastLockShouldSucceed
AS
	v_pm_ids					security_pkg.T_SID_IDS;
	v_start_dates				energy_star_pkg.T_DATE_ARRAY;
	v_end_dates					energy_star_pkg.T_DATE_ARRAY;
	v_consumptions				energy_star_pkg.T_VAL_ARRAY;
	v_costs						energy_star_pkg.T_VAL_ARRAY;
	v_estimates					security_pkg.T_SID_IDS;
	v_region_sid				security_pkg.T_SID_ID;
	v_lock_end_dtm				DATE;
	v_success 					BOOLEAN := false;
BEGIN
	TRACE('TestPrepConsumptionDataWhenLockIgnoredWithDataPartiallyPastLockShouldSucceed');
	-- set system data lock
	v_lock_end_dtm:= DATE '2023-01-01';
	UPDATE customer
		SET lock_end_dtm =  v_lock_end_dtm
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	BEGIN
		v_pm_ids(1) := 1;
		v_start_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-DEC-2022');
		v_end_dates := energy_star_pkg.T_DATE_ARRAY(1=> '01-FEB-2023');
		v_consumptions := energy_star_pkg.T_VAL_ARRAY(1=> 10);
		v_costs := energy_star_pkg.T_VAL_ARRAY(1=> 100);
		v_estimates(1) := 1;
		v_estimates(2) := 2;
		v_region_sid := 1;

		
		energy_star_pkg.Test_PrepConsumptionData(
			in_pm_ids					=> v_pm_ids,
			in_start_dates				=> v_start_dates,
			in_end_dates				=> v_end_dates,
			in_consumptions				=> v_consumptions,
			in_costs					=> v_costs,
			in_estimates				=> v_estimates,
			in_region_sid				=> v_region_sid,
			in_ignore_lock				=> TRUE
		);
		
		v_success := true; 
	END;

	IF v_success = false THEN
		unit_test_pkg.TestFail('PrepConsumptionData should not throw ERR_METER_WITHIN_LOCK_PERIOD exception!');
	END IF;

	-- set back to default data lock
	UPDATE customer
		SET lock_end_dtm =  DATE '1980-01-01'
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;





PROCEDURE TestOnRegionChange
AS
	v_test_name				VARCHAR2(200) := 'TestOnRegionChange';

	v_region_sid			security_pkg.T_SID_ID;

	v_region_root_sid		security_pkg.T_SID_ID;
	v_company_sid			security_pkg.T_SID_ID;
	v_nullStringArray 		chain.chain_pkg.T_STRINGS; --cannot pass NULL so need an empty varchar2 array instead
	v_company_type_id		NUMBER;
	
	v_property_type_id		NUMBER;
	v_property_region_sid	security_pkg.T_SID_ID;
	v_customer_sid			security_pkg.T_SID_ID;
	v_account_sid			security_pkg.T_SID_ID;

	v_lock_count			NUMBER;
	v_log_count				NUMBER;
BEGIN
	TRACE('TestOnRegionChange');
	v_region_sid := 1;
	BEGIN
		energy_star_job_pkg.OnRegionChange(
			in_region_sid => v_region_sid
		);
	EXCEPTION
		WHEN OTHERS THEN unit_test_pkg.TestFail('Should not throw exception.');
	END;


	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;

	v_company_type_id := 1;
	INSERT INTO chain.company_type (company_type_id, lookup_key, singular, plural) values 
		(v_company_type_id, 'COMPANY_TYPE_TESTONREGIONCHANGE_LK', 'ct s', 'ct p');

	BEGIN
		chain.company_pkg.CreateUniqueCompany(
			in_name => v_test_name, 
			in_country_code => 'gb',
			in_company_type_id => v_company_type_id, 
			in_sector_id => NULL,
			in_lookup_keys => v_nullStringArray,
			in_values =>  v_nullStringArray,
			out_company_sid => v_company_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_company_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetApp, 'Chain/Companies/'||v_test_name||' ('||'gb'||')');
	END;

	property_pkg.SavePropertyType(
		in_property_type_id		=>	NULL,
		in_property_type_name	=>	v_test_name||'_TestPropertyType',
		in_space_type_ids		=>	'',
		in_gresb_prop_type		=>	'',
		out_property_type_id	=>	v_property_type_id
	);
	
	property_pkg.CreateProperty(
		in_company_sid		=>	v_company_sid,
		in_parent_sid		=>	v_region_root_sid,
		in_description		=>	v_test_name||'_TestProperty',
		in_country_code		=>	'gb',
		in_property_type_id	=>	v_property_type_id,
		out_region_sid		=>	v_property_region_sid
	);

	BEGIN
		energy_star_job_pkg.OnRegionChange(
			in_region_sid => v_property_region_sid
		);
	EXCEPTION
		WHEN OTHERS THEN unit_test_pkg.TestFail('Should not throw exception.');
	END;
	-- App should not be locked (csr_data_pkg.LOCK_TYPE_ENERGY_STAR)
	SELECT COUNT(*)
	  INTO v_lock_count
	  FROM app_lock
	 WHERE lock_type = csr_data_pkg.LOCK_TYPE_ENERGY_STAR
	   AND app_sid = security_pkg.GetApp
	   AND dummy = 1;
	unit_test_pkg.AssertAreEqual(0, v_lock_count, 'App should not be locked (csr_data_pkg.LOCK_TYPE_ENERGY_STAR)');


	TRACE('Update prop to es sync');
	UPDATE property
	   SET energy_star_sync = 1, energy_star_push = 1
	 WHERE region_sid = v_property_region_sid;

	BEGIN
		energy_star_job_pkg.OnRegionChange(
			in_region_sid => v_property_region_sid
		);
	EXCEPTION
		WHEN OTHERS THEN unit_test_pkg.TestFail('Should not throw exception.');
	END;
	-- App should be locked (csr_data_pkg.LOCK_TYPE_ENERGY_STAR)
	SELECT COUNT(*)
	  INTO v_lock_count
	  FROM app_lock
	 WHERE lock_type = csr_data_pkg.LOCK_TYPE_ENERGY_STAR
	   AND app_sid = security_pkg.GetApp
	   AND dummy = 1;
	unit_test_pkg.AssertAreEqual(1, v_lock_count, 'App should be locked (csr_data_pkg.LOCK_TYPE_ENERGY_STAR)');

	-- map
	INSERT INTO est_property_type_map (property_type_id, est_property_type)
	VALUES (v_property_type_id, 'Adult Education');

	UPDATE est_account 
	   SET est_account_sid = (SELECT default_account_sid FROM est_options)
	 WHERE app_sid = security_pkg.GetApp;

	BEGIN
		energy_star_job_pkg.OnRegionChange(
			in_region_sid => v_property_region_sid
		);
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE <> -20534 THEN
				unit_test_pkg.TestFail('Expecting 20534.');
			END IF;
			IF SQLCODE = -20534 THEN
				unit_test_pkg.AssertAreEqual('ORA-20534: There is no default customer or account Id set in the energy star options.', SQLERRM, 'Unexpected exception');
			END IF;
	END;

	TRACE('Update options to have an account but no mapped customer');
	UPDATE est_options
	   SET default_customer_id = 999
	 WHERE app_sid = security_pkg.GetApp;

	SELECT est_account_sid
	  INTO v_account_sid
	  FROM est_account
	 WHERE app_sid = security_pkg.GetApp;

	BEGIN
		energy_star_job_pkg.OnRegionChange(
			in_region_sid => v_property_region_sid
		);
		unit_test_pkg.TestFail('Should throw exception.');
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE = -20534 THEN
				unit_test_pkg.TestFail('Should not throw this exception.');
			END IF;
	END;

	TRACE('Map a customer');
	INSERT INTO est_customer (est_account_sid, pm_customer_id, est_customer_sid, org_name)
	VALUES (v_account_sid, 999, 1999, 'test');
	energy_star_pkg.MapCustomer(
		in_account_sid		=> v_account_sid,
		in_pm_customer_id	=> 999,
		out_customer_sid	=> v_customer_sid
	);

	SELECT COUNT(*)
	  INTO v_log_count
	  FROM est_region_change_log
	 WHERE app_sid = security_pkg.GetApp;
	unit_test_pkg.AssertAreEqual(0, v_log_count, 'Expected no log records');
	BEGIN
		energy_star_job_pkg.OnRegionChange(
			in_region_sid => v_property_region_sid
		);
	EXCEPTION
		WHEN OTHERS THEN unit_test_pkg.TestFail('Should not throw exception.');
	END;
	SELECT COUNT(*)
	  INTO v_log_count
	  FROM est_region_change_log
	 WHERE app_sid = security_pkg.GetApp;
	unit_test_pkg.AssertAreEqual(1, v_log_count, 'Expected one log record');

END;

END test_energy_star_pkg;
/
