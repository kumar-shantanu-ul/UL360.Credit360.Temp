CREATE OR REPLACE PACKAGE BODY csr.test_core_api_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;

PROCEDURE SetUpFixtureScenarios AS
	v_merged_scenario_sid				security.security_pkg.T_SID_ID;
	v_unmerged_scenario_sid				security.security_pkg.T_SID_ID;
	v_merged_scenario_run_sid			security.security_pkg.T_SID_ID;
	v_unmerged_scenario_run_sid			security.security_pkg.T_SID_ID;
BEGIN 
	Trace('SetUpFixtureScenarios');
	
	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
			security.class_pkg.GetClassId('CSRScenario'), 'CA Merged scenario', v_merged_scenario_sid);
	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
			security.class_pkg.GetClassId('CSRScenario'), 'CA Unmerged scenario', v_unmerged_scenario_sid);
	
	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
			security.class_pkg.GetClassId('CSRScenarioRun'), 'CA Merged scenario run', v_merged_scenario_run_sid);
	security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
			security.class_pkg.GetClassId('CSRScenarioRun'), 'CA Unmerged scenario run', v_unmerged_scenario_run_sid);
	
	INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, include_all_inds)
		SELECT v_merged_scenario_sid, 'CA Merged scenario', calc_start_dtm, calc_end_dtm, 1, 1, 0
		  FROM csr.customer;

	INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, include_all_inds)
		SELECT v_unmerged_scenario_sid, 'CA Unmerged scenario', calc_start_dtm, calc_end_dtm, 1, 1, 0
		  FROM csr.customer;

	INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description)
	VALUES (v_merged_scenario_run_sid, v_merged_scenario_sid, 'CA Merged scenario run');

	INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, description)
	VALUES (v_unmerged_scenario_run_sid, v_unmerged_scenario_sid, 'CA Unmerged scenario run');

	UPDATE csr.customer
	   SET merged_scenario_run_sid = v_merged_scenario_run_sid,
		   unmerged_scenario_run_sid = v_unmerged_scenario_run_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE SetUpFixtureIndicators AS
	v_ind_root_sid				security.security_pkg.T_SID_ID;
	v_new_ind_sid_a				security.security_pkg.T_SID_ID;
BEGIN 
	Trace('SetUpFixtureIndicators');
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM csr.customer;
	
	csr.indicator_pkg.CreateIndicator(in_parent_sid_id => v_ind_root_sid,
		in_name => 'CATestInd1_Lookup_N',
		in_description => 'CATestInd1_Lookup_D',
		in_lookup_key => 'CATestInd1_Lookup_L',
		out_sid_id => v_new_ind_sid_a
	);

	csr.indicator_pkg.CreateIndicator(in_parent_sid_id => v_ind_root_sid,
		in_name => 'CATestInd1a_Lookup_N',
		in_description => 'CATestInd1a_Lookup_D',
		in_lookup_key => 'CATestInd1_Lookup_L',
		out_sid_id => v_new_ind_sid_a
	);

	csr.indicator_pkg.CreateIndicator(in_parent_sid_id => v_ind_root_sid,
		in_name => 'CATestInd1b_Lookup_N',
		in_description => 'CATestInd1b_Lookup_D',
		in_lookup_key => 'CATestInd1_Lookup_L',
		out_sid_id => v_new_ind_sid_a
	);
	csr.indicator_pkg.TrashObject(security.security_pkg.GetAct, v_new_ind_sid_a);

	csr.indicator_pkg.CreateIndicator(in_parent_sid_id => v_ind_root_sid,
		in_name => 'CATestInd2_Lookup_N',
		in_description => 'CATestInd2_Lookup_D',
		in_lookup_key => 'CATestInd2_Lookup_L',
		out_sid_id => v_new_ind_sid_a
	);

	csr.indicator_pkg.CreateIndicator(in_parent_sid_id => v_ind_root_sid,
		in_name => 'CATestInd3_Lookup_N',
		in_description => 'CATestInd3_Lookup_D',
		in_lookup_key => 'CATestInd3_Lookup_L',
		out_sid_id => v_new_ind_sid_a
	);

	csr.indicator_pkg.CreateIndicator(in_parent_sid_id => v_ind_root_sid,
		in_name => 'CATestInd1_NoLookup_N',
		in_description => 'CATestInd1_NoLookup_D',
		out_sid_id => v_new_ind_sid_a
	);
	
	csr.indicator_pkg.CreateIndicator(in_parent_sid_id => v_ind_root_sid,
		in_name => 'CATestInd2_NoLookup_N',
		in_description => 'CATestInd2_NoLookup_D',
		out_sid_id => v_new_ind_sid_a
	);
END;

PROCEDURE SetUpFixtureRegions AS
	v_region_root_sid				security.security_pkg.T_SID_ID;
	v_new_region_sid_a				security.security_pkg.T_SID_ID;
	v_new_region_sid_b				security.security_pkg.T_SID_ID;
	v_new_region_sid_c				security.security_pkg.T_SID_ID;
BEGIN 
	Trace('SetUpFixtureRegions');
	SELECT region_root_sid
	  INTO v_region_root_sid
	  FROM csr.customer;
	
	csr.region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => 'CATestReg1_LevelA1',
		in_description => 'CATestReg1_LevelA1',
		out_region_sid => v_new_region_sid_a
	);
	
	Trace(to_char('1st region: ' || v_new_region_sid_a));
	
	csr.region_pkg.SetLookupKey(in_region_sid => v_new_region_sid_a,
	in_lookup_key => 'CATestReg1_Lookup_A1'
	);
		csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
			in_name => 'CATestReg1_LevelB1',
			in_description => 'CATestReg1_LevelB1',
			out_region_sid => v_new_region_sid_b
		);
		Trace(to_char('2nd region: ' || v_new_region_sid_b));
		csr.region_pkg.SetLookupKey(in_region_sid => v_new_region_sid_b,
		in_lookup_key => 'CATestReg1_Lookup_B1'
		);
		csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
			in_name => 'CATestReg1_LevelB2',
			in_description => 'CATestReg1_LvlB2_NoLookup',
			out_region_sid => v_new_region_sid_b
		);
			csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_b,
				in_name => 'CATestReg1_LevelC1',
				in_description => 'CATestReg1_LevelC1',
				out_region_sid => v_new_region_sid_c
			);
			csr.region_pkg.SetLookupKey(in_region_sid => v_new_region_sid_c,
			in_lookup_key => 'CATestReg1_Lookup_C1'
			);
	
	csr.region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => 'CATestReg2_LevelA1',
		in_description => 'CATestReg2_LevelA1_NoLookUp',
		out_region_sid => v_new_region_sid_a
	);
		csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
			in_name => 'CATestReg2_LevelB1',
			in_description => 'CATestReg2_LevelB1',
			out_region_sid => v_new_region_sid_b
		);
		csr.region_pkg.SetLookupKey(in_region_sid => v_new_region_sid_b,
		in_lookup_key => 'CATestReg2_LevelB1_Lookup'
		);
			csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_b,
				in_name => 'CATestReg2_LevelC1',
				in_description => 'CATestReg2_LevelC1_NoLookUp',
				out_region_sid => v_new_region_sid_c
			);
		csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
			in_name => 'CATestReg2_LevelB2',
			in_description => 'CATestReg2_LevelB2',
			out_region_sid => v_new_region_sid_b
		);
		csr.region_pkg.SetLookupKey(in_region_sid => v_new_region_sid_b,
			in_lookup_key => 'CATestReg2_LevelB2_Lookup'
			);
END;

PROCEDURE SetUpFixtureMeasures AS
	v_measure_sid						security.security_pkg.T_SID_ID;
	v_measure_conv_sid					security.security_pkg.T_SID_ID;
BEGIN 
	Trace('SetUpFixtureMeasures');
	
	measure_pkg.CreateMeasure(in_name => 'CATestMeasure1_N', in_description => 'CATestMeasure1_D', 
		out_measure_sid => v_measure_sid);
	measure_pkg.SetConversion(in_act_id => security_pkg.GetAct,
								in_conversion_id => NULL,
								in_measure_sid => v_measure_sid,
								in_description => 'CATestMeasureConv1_D',
								in_a => 0, in_b => 0, in_c => 0,
								out_conversion_id => v_measure_conv_sid);
	
	measure_pkg.CreateMeasure(in_name => 'CATestMeasure2_N', in_description => 'CATestMeasure2_D', 
		out_measure_sid => v_measure_sid);
	measure_pkg.SetConversion(in_act_id => security_pkg.GetAct,
								in_conversion_id => NULL,
								in_measure_sid => v_measure_sid,
								in_description => 'CATestMeasureConv2_D',
								in_a => 0, in_b => 0, in_c => 0,
								out_conversion_id => v_measure_conv_sid);
	
	measure_pkg.CreateMeasure(in_name => 'CATestMeasure3_N', in_description => 'CATestMeasure3_D', in_lookup_key => 'CATestMeasure3_LK',
		out_measure_sid => v_measure_sid);
	measure_pkg.SetConversion(in_act_id => security_pkg.GetAct,
								in_conversion_id => NULL,
								in_measure_sid => v_measure_sid,
								in_description => 'CATestMeasureConv3_D',
								in_a => 0, in_b => 0, in_c => 0,
								out_conversion_id => v_measure_conv_sid);
	
	measure_pkg.CreateMeasure(in_name => 'CATestMeasure4_N', in_description => 'CATestMeasure4_D', in_lookup_key => 'CATestMeasure4_LK',
		out_measure_sid => v_measure_sid);
	measure_pkg.SetConversion(in_act_id => security_pkg.GetAct,
								in_conversion_id => NULL,
								in_measure_sid => v_measure_sid,
								in_description => 'CATestMeasureConv4_D',
								in_a => 0, in_b => 0, in_c => 0,
								out_conversion_id => v_measure_conv_sid);
	
END;

PROCEDURE TearDownFixtureScenarios AS
	v_merged_scenario_run_sid			security.security_pkg.T_SID_ID;
	v_merged_scenario_sid				security.security_pkg.T_SID_ID;
	v_unmerged_scenario_run_sid			security.security_pkg.T_SID_ID;
	v_unmerged_scenario_sid				security.security_pkg.T_SID_ID;
BEGIN 
	Trace('TearDownFixtureScenarios');

	UPDATE csr.customer
	   SET merged_scenario_run_sid = NULL,
		   unmerged_scenario_run_sid = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT scenario_run_sid, scenario_sid
	  INTO v_merged_scenario_run_sid, v_merged_scenario_sid
	  FROM csr.scenario_run
	 WHERE description = 'CA Merged scenario run'
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT scenario_run_sid, scenario_sid
	  INTO v_unmerged_scenario_run_sid, v_unmerged_scenario_sid
	  FROM csr.scenario_run
	 WHERE description = 'CA Unmerged scenario run'
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_merged_scenario_run_sid);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_merged_scenario_sid);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_unmerged_scenario_run_sid);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_unmerged_scenario_sid);
END;

PROCEDURE TearDownFixtureIndicators AS
BEGIN 
	Trace('TearDownFixtureIndicators');
	FOR r IN (SELECT ind_sid FROM csr.ind WHERE name like 'CATestInd%')
	LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, r.ind_sid);
	END LOOP;
END;

PROCEDURE TearDownFixtureRegions AS
BEGIN 
	Trace('TearDownFixtureRegions');
	FOR r IN (SELECT region_sid FROM csr.region WHERE name like 'CATestReg%')
	LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, r.region_sid);
	END LOOP;
END;

PROCEDURE TearDownFixtureMeasures AS
BEGIN 
	Trace('TearDownFixtureMeasures');
	FOR r IN (SELECT measure_sid FROM csr.measure WHERE name like 'CATestMeasure%')
	LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, r.measure_sid);
	END LOOP;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_primary_root_sid				security.security_pkg.T_SID_ID;
	v_cust_comp_sid					security.security_pkg.T_SID_ID;
	v_xml							CLOB;
	v_str 							VARCHAR2(2000);
BEGIN
	Trace('SetUpFixture');
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	--TearDownFixtureRegions;
	--SetUpFixtureScenarios;
	--SetUpFixtureIndicators;
	--SetUpFixtureRegions;
	--SetUpFixtureMeasures;
END;

PROCEDURE SetUp AS
	v_company_sid					security.security_pkg.T_SID_ID;
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
	
	/* Comment out for testing tests. */
	--TearDownFixtureScenarios;
	--TearDownFixtureIndicators;
	--TearDownFixtureRegions;
	--TearDownFixtureMeasures;
	/* Comment out for testing tests. */
END;

/*
PROCEDURE TestScenarios AS
	out_scn_cur			SYS_REFCURSOR;
	v_count				NUMBER;
	v_scenario_run_sid	NUMBER;
	v_scenario_sid		NUMBER;
	v_description		scenario_run.description%TYPE;
	v_file_based		NUMBER;
BEGIN
	Trace('TestScenarios');

	scenario_pkg.GetScenarios(out_scn_cur);
	-- Expecting two scenarios.
	v_count := 0;
	LOOP
		FETCH out_scn_cur INTO v_scenario_run_sid, v_scenario_sid, v_description, v_file_based;
		EXIT WHEN out_scn_cur%NOTFOUND;
		-- Ignore non-test scenarios.
		IF v_description like 'CA % scenario' THEN
			v_count := v_count + 1;
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(2 = v_count, 'Expected count was '||v_count||', expected 2');
	
	scenario_pkg.GetMergedScenario(out_scn_cur);
	-- Expecting one scenario.
	v_count := 0;
	LOOP
		FETCH out_scn_cur INTO v_scenario_run_sid, v_scenario_sid, v_description, v_file_based;
		EXIT WHEN out_scn_cur%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_description = 'CA Merged scenario', 'Merged scenario');
	END LOOP;
	unit_test_pkg.AssertIsTrue(1 = v_count, 'Expected count');
	
	scenario_pkg.GetUnmergedScenario(out_scn_cur);
	-- Expecting one scenario.
	v_count := 0;
	LOOP
		FETCH out_scn_cur INTO v_scenario_run_sid, v_scenario_sid, v_description, v_file_based;
		EXIT WHEN out_scn_cur%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_description = 'CA Unmerged scenario', 'Unmerged scenario');
	END LOOP;
	unit_test_pkg.AssertIsTrue(1 = v_count, 'Expected count');
END;*/

PROCEDURE INTERNAL_TestIndicatorsResult(
	in_expected_count		IN	NUMBER,
	in_has_lookups			IN	NUMBER,
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_ind_cur				IN	SYS_REFCURSOR,
	in_description_cur		IN	SYS_REFCURSOR
)
AS
	v_count					NUMBER;
	v_ind_sid				NUMBER;
	v_lookup_key			ind.lookup_key%TYPE;
	v_desc_ind_sid			NUMBER;
	v_lang					ind_description.lang%TYPE;
	v_description			ind_description.description%TYPE;
	v_lookup_keys			security.T_VARCHAR2_TABLE;
	v_lookup_keys_count		NUMBER;
	v_lookup_match			NUMBER;
BEGIN
	v_count := 0;
	v_lookup_keys := security_pkg.Varchar2ArrayToTable(in_lookup_keys);
	SELECT COUNT(*)
	  INTO v_lookup_keys_count
	  FROM TABLE(v_lookup_keys);
	
	LOOP
		FETCH in_ind_cur INTO v_ind_sid, v_lookup_key;
		FETCH in_description_cur INTO v_desc_ind_sid, v_lang, v_description;
		EXIT WHEN in_ind_cur%NOTFOUND;
		
		unit_test_pkg.AssertIsTrue(v_ind_sid = v_desc_ind_sid, 'ind sid does not match desc ind sid');
		unit_test_pkg.AssertIsTrue(v_lang = 'en', 'Unexpected lang');
		unit_test_pkg.AssertIsTrue(LENGTH(v_description) > 0, 'Missing description');
		
		-- Ignore non-test indicators.
		IF v_description like 'CATestInd%' THEN
			v_count := v_count + 1;
			v_lookup_match := 0;
			IF in_has_lookups = 1 THEN
				IF v_lookup_keys_count = 0 THEN
					unit_test_pkg.AssertIsTrue(v_lookup_key IS NULL, 'Lookup Keys not matched (null), was '||v_lookup_key);
				ELSE
					FOR r IN (SELECT value FROM TABLE(v_lookup_keys))
					LOOP
						IF r.value IS NULL OR LENGTH(r.value) = 0 AND v_lookup_key IS NULL THEN
							v_lookup_match := 1;
						ELSIF r.value = v_lookup_key THEN
							v_lookup_match := 1;
						END IF;
					END LOOP;
					unit_test_pkg.AssertIsTrue(v_lookup_match = 1, 'Lookup Keys not matched (explicit)');
				END IF;
			END IF;
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(in_expected_count = v_count, 'Actual count was '||v_count||', expected '||in_expected_count);
END;

/*PROCEDURE TestIndicators AS
	v_ind_cur				SYS_REFCURSOR;
	v_description_cur		SYS_REFCURSOR;
	v_lookup_keys			security.security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	Trace('TestIndicators');
	
	indicator_pkg.GetCoreIndicators(out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(6, 0, v_lookup_keys, v_ind_cur, v_description_cur);
	
	v_lookup_keys(1) := NULL;
	indicator_pkg.GetCoreIndicators(in_lookup_keys => v_lookup_keys, out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(2, 1, v_lookup_keys, v_ind_cur, v_description_cur);
	
	v_lookup_keys(1) := '';
	indicator_pkg.GetCoreIndicators(in_lookup_keys => v_lookup_keys, out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(2, 1, v_lookup_keys, v_ind_cur, v_description_cur);
	
	v_lookup_keys(1) := 'CATestInd1_Lookup_L';
	indicator_pkg.GetCoreIndicators(in_lookup_keys => v_lookup_keys, out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(2, 1, v_lookup_keys, v_ind_cur, v_description_cur);
	
	v_lookup_keys(1) := 'CATestInd2_Lookup_L';
	indicator_pkg.GetCoreIndicators(in_lookup_keys => v_lookup_keys, out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(1, 1, v_lookup_keys, v_ind_cur, v_description_cur);
	
	v_lookup_keys(1) := 'CATestInd2_Lookup_L';
	v_lookup_keys(2) := 'CATestInd3_Lookup_L';
	indicator_pkg.GetCoreIndicators(in_lookup_keys => v_lookup_keys, out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(2, 1, v_lookup_keys, v_ind_cur, v_description_cur);
	
	v_lookup_keys(1) := NULL;
	v_lookup_keys(2) := 'CATestInd3_Lookup_L';
	indicator_pkg.GetCoreIndicators(in_lookup_keys => v_lookup_keys, out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(3, 1, v_lookup_keys, v_ind_cur, v_description_cur);
	
	v_lookup_keys(1) := '';
	v_lookup_keys(2) := 'CATestInd3_Lookup_L';
	indicator_pkg.GetCoreIndicators(in_lookup_keys => v_lookup_keys, out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(3, 1, v_lookup_keys, v_ind_cur, v_description_cur);
	
	v_lookup_keys(1) := 'CATestInd3_Lookup_L';
	v_lookup_keys(2) := NULL;
	indicator_pkg.GetCoreIndicators(in_lookup_keys => v_lookup_keys, out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(3, 1, v_lookup_keys, v_ind_cur, v_description_cur);
	
	v_lookup_keys(1) := 'CATestInd3_Lookup_L';
	v_lookup_keys(2) := '';
	indicator_pkg.GetCoreIndicators(in_lookup_keys => v_lookup_keys, out_ind_cur => v_ind_cur, out_description_cur => v_description_cur);
	INTERNAL_TestIndicatorsResult(3, 1, v_lookup_keys, v_ind_cur, v_description_cur);
END;*/

PROCEDURE INTERNAL_TestRegionsResult(
	in_expected_count		IN	NUMBER,
	in_has_lookups			IN	NUMBER,
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_region_cur			IN	SYS_REFCURSOR,
	in_description_cur		IN	SYS_REFCURSOR
)
AS
	v_count					NUMBER;
	v_region_sid			NUMBER;
	v_lookup_key			region.lookup_key%TYPE;
	v_desc_region_sid		NUMBER;
	v_lang					region_description.lang%TYPE;
	v_description			region_description.description%TYPE;
	v_lookup_keys			security.T_VARCHAR2_TABLE;
	v_lookup_keys_count		NUMBER;
	v_lookup_match			NUMBER;
	v_path					VARCHAR2(2000);
	v_geo_country			VARCHAR2(200);
	v_geo_region			VARCHAR2(200);
	v_geo_city_id			NUMBER;
	
BEGIN
	v_count := 0;
	v_lookup_keys := security_pkg.Varchar2ArrayToTable(in_lookup_keys);
	SELECT COUNT(*)
	  INTO v_lookup_keys_count
	  FROM TABLE(v_lookup_keys);
	
	LOOP
		FETCH in_region_cur INTO v_region_sid, v_lookup_key, v_path, v_geo_country, v_geo_region, v_geo_city_id;
		FETCH in_description_cur INTO v_desc_region_sid, v_lang, v_description;
		
		unit_test_pkg.AssertIsTrue(v_region_sid = v_desc_region_sid, 'region sid does not match desc region sid');
		unit_test_pkg.AssertIsTrue(v_lang = 'en', 'Unexpected lang');
		unit_test_pkg.AssertIsTrue(LENGTH(v_description) > 0, 'Missing description');
		
		EXIT WHEN in_region_cur%NOTFOUND;
		-- Ignore non-test regions.
		IF v_description like 'CATestReg%' THEN
			v_count := v_count + 1;
			v_lookup_match := 0;
			IF in_has_lookups = 1 THEN
				IF v_lookup_keys_count = 0 THEN
					unit_test_pkg.AssertIsTrue(v_lookup_key IS NULL, 'Lookup Keys not matched (null), was '||v_lookup_key);
				ELSE
					FOR r IN (SELECT value FROM TABLE(v_lookup_keys))
					LOOP
						IF r.value IS NULL OR LENGTH(r.value) = 0 AND v_lookup_key IS NULL THEN
							v_lookup_match := 1;
						ELSIF r.value = v_lookup_key THEN
							v_lookup_match := 1;
						END IF;
					END LOOP;
					unit_test_pkg.AssertIsTrue(v_lookup_match = 1, 'Lookup Keys not matched (explicit)');
				END IF;
			END IF;
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(in_expected_count = v_count, 'Actual count was '||v_count||', expected '||in_expected_count);
END;
/*
PROCEDURE TestRegions AS
	v_region_cur			SYS_REFCURSOR;
	v_description_cur		SYS_REFCURSOR;
	v_total_rows_cur		SYS_REFCURSOR;
	v_count					NUMBER;
	v_reg_sid				NUMBER;
	v_lookup_key			region.lookup_key%TYPE;
	v_desc_reg_sid			NUMBER;
	v_lang					region_description.lang%TYPE;
	v_description			region_description.description%TYPE;
	v_lookup_keys			security.security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	Trace('TestRegions');
		
	region_pkg.GetCoreRegions(
		in_skip 			=> 0, 
		in_take 			=> 20, 
		out_region_cur 		=> v_region_cur, 
		out_description_cur => v_description_cur, 
		out_total_rows_cur 	=> v_total_rows_cur);
	--INTERNAL_TestRegionsResult(8, 0, v_lookup_keys, v_region_cur, v_description_cur);

	v_lookup_keys(1) := NULL;
	region_pkg.GetCoreRegionsByLookupKey(
		in_lookup_keys 		=> v_lookup_keys, 
		in_skip 			=> 0, 
		in_take 			=> 20, 
		out_region_cur 		=> v_region_cur, 
		out_description_cur => v_description_cur,
		out_total_rows_cur	=> v_total_rows_cur);
	INTERNAL_TestRegionsResult(3, 1, v_lookup_keys, v_region_cur, v_description_cur);
	
	v_lookup_keys(1) := '';
	region_pkg.GetCoreRegionsByLookupKey(
		in_lookup_keys 		=> v_lookup_keys, 
		in_skip 			=> 0, 
		in_take 			=> 20, 
		out_region_cur 		=> v_region_cur, 
		out_description_cur => v_description_cur,
		out_total_rows_cur	=> v_total_rows_cur);
	INTERNAL_TestRegionsResult(3, 1, v_lookup_keys, v_region_cur, v_description_cur);

	v_lookup_keys(1) := 'CATestReg1_Lookup_A1';
	region_pkg.GetCoreRegionsByLookupKey(
		in_lookup_keys 		=> v_lookup_keys, 
		in_skip 			=> 0, 
		in_take 			=> 20, 
		out_region_cur 		=> v_region_cur, 
		out_description_cur => v_description_cur,
		out_total_rows_cur	=> v_total_rows_cur);
	INTERNAL_TestRegionsResult(1, 1, v_lookup_keys, v_region_cur, v_description_cur);
	
	v_lookup_keys(1) := 'CATestReg1_Lookup_A1';
	v_lookup_keys(2) := 'CATestReg1_Lookup_B1';
	v_lookup_keys(3) := 'CATestReg1_Lookup_C1';
	v_lookup_keys(4) := 'CATestReg2_LevelB1_Lookup';
	v_lookup_keys(5) := 'CATestReg2_LevelB2_Lookup';
	region_pkg.GetCoreRegionsByLookupKey(
		in_lookup_keys 		=> v_lookup_keys, 
		in_skip 			=> 0, 
		in_take 			=> 20, 
		out_region_cur 		=> v_region_cur, 
		out_description_cur => v_description_cur,
		out_total_rows_cur	=> v_total_rows_cur);
	INTERNAL_TestRegionsResult(5, 1, v_lookup_keys, v_region_cur, v_description_cur);
	
	v_lookup_keys(1) := NULL;
	v_lookup_keys(2) := 'CATestReg2_LevelB1_Lookup';
	v_lookup_keys(3) := NULL;
	v_lookup_keys(4) := NULL;--must set these to null otherwise they'll still have the values from the preceeding test.
	v_lookup_keys(5) := NULL;
	region_pkg.GetCoreRegionsByLookupKey(
		in_lookup_keys 		=> v_lookup_keys, 
		in_skip 			=> 0, 
		in_take 			=> 20, 
		out_region_cur 		=> v_region_cur, 
		out_description_cur => v_description_cur,
		out_total_rows_cur	=> v_total_rows_cur);
	INTERNAL_TestRegionsResult(4, 1, v_lookup_keys, v_region_cur, v_description_cur);
	
	v_lookup_keys(1) := '';
	v_lookup_keys(2) := 'CATestReg2_LevelB1_Lookup';
	region_pkg.GetCoreRegionsByLookupKey(
		in_lookup_keys 		=> v_lookup_keys, 
		in_skip 			=> 0, 
		in_take 			=> 20, 
		out_region_cur 		=> v_region_cur, 
		out_description_cur => v_description_cur,
		out_total_rows_cur	=> v_total_rows_cur);
	INTERNAL_TestRegionsResult(4, 1, v_lookup_keys, v_region_cur, v_description_cur);
	
	v_lookup_keys(1) := NULL;
	v_lookup_keys(2) := 'CATestReg2_LevelB1_Lookup';
	v_lookup_keys(3) := '';
	v_lookup_keys(4) := NULL;
	v_lookup_keys(5) := '';
	region_pkg.GetCoreRegionsByLookupKey(
		in_lookup_keys 		=> v_lookup_keys, 
		in_skip 			=> 0, 
		in_take 			=> 20, 
		out_region_cur 		=> v_region_cur, 
		out_description_cur => v_description_cur,
		out_total_rows_cur	=> v_total_rows_cur);
	INTERNAL_TestRegionsResult(4, 1, v_lookup_keys, v_region_cur, v_description_cur);
END;*/
/*
PROCEDURE TestMeasures AS
	v_measure_cur				SYS_REFCURSOR;
	v_measure_conv_cur			SYS_REFCURSOR;
	v_measure_conv_date_cur		SYS_REFCURSOR;
	v_count						NUMBER;
	
	v_measure					measure%ROWTYPE;
	v_label						measure.description%TYPE;
	v_std_measure_description	std_measure_conversion.description%TYPE;
	v_measure_conversion		measure_conversion%ROWTYPE;
	v_measure_conversion_period	measure_conversion_period%ROWTYPE;
BEGIN
	--Trace('TestMeasures');
	NULL;
	
	csr.measure_pkg.GetAllMeasures(
		out_measure_cur => v_measure_cur,
		out_measure_conv_cur => v_measure_conv_cur,
		out_measure_conv_date_cur => v_measure_conv_date_cur);
	
	v_count := 0;
	LOOP
		FETCH v_measure_cur 
		 INTO v_measure.measure_sid, v_measure.format_mask,
				v_measure.scale, v_measure.name, v_measure.description, v_measure.custom_field,
				v_measure.pct_ownership_applies, v_measure.std_measure_conversion_id, v_measure.divisibility,
				v_measure.factor, v_measure.m, v_measure.kg, 
				v_measure.s, v_measure.a, v_measure.k, v_measure.mol,
				v_measure.cd,
				v_label,
				v_measure.option_set_id, v_std_measure_description,
				v_measure.lookup_key;
		EXIT WHEN v_measure_cur%NOTFOUND;
		
		FETCH v_measure_conv_cur 
		 INTO v_measure_conversion.measure_conversion_id, v_measure_conversion.measure_sid, v_measure_conversion.std_measure_conversion_id,
				v_measure_conversion.description, v_measure_conversion.a, v_measure_conversion.b, v_measure_conversion.c, v_measure_conversion.lookup_key;

		FETCH v_measure_conv_date_cur 
		 INTO v_measure_conversion_period.measure_conversion_id, v_measure_conversion_period.start_dtm, v_measure_conversion_period.end_dtm,
				v_measure_conversion_period.a, v_measure_conversion_period.b, v_measure_conversion_period.c;

		IF v_measure.name LIKE 'CATestMeasure%' THEN
			unit_test_pkg.AssertIsTrue(v_measure.measure_sid > 0, 'Missing measure sid');
			unit_test_pkg.AssertIsTrue(v_measure_conversion.measure_conversion_id != v_measure.measure_sid, 'Mismatched measure conversionv sid');
			unit_test_pkg.AssertIsTrue(v_measure_conversion_period.measure_conversion_id != v_measure_conversion.measure_conversion_id, 'Mismatched measure conversion period sid');
			v_count := v_count + 1;
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(4 = v_count, 'Expected count was '||v_count||', expected 4');
	
	v_count := 0;
	FOR r IN (
		SELECT measure_sid
		  FROM measure
		 WHERE name LIKE 'CATestMeasure%'
		   AND app_sid = security.security_pkg.GetApp
	)
	LOOP
		csr.measure_pkg.GetConversions(in_act_id => security.security_pkg.getACT, in_measure_sid => r.measure_sid, out_cur => v_measure_conv_cur);
		LOOP
			FETCH v_measure_conv_cur 
			 INTO v_measure_conversion.measure_conversion_id,
					v_measure_conversion.description,
					v_measure_conversion.a, v_measure_conversion.b, v_measure_conversion.c,
					v_measure_conversion.std_measure_conversion_id;
			EXIT WHEN v_measure_conv_cur%NOTFOUND;
			
			IF v_measure_conversion.description LIKE 'CATestMeasure%' THEN
				unit_test_pkg.AssertIsTrue(v_measure_conversion.measure_conversion_id > 0, 'Missing measure conversion sid');
				v_count := v_count + 1;
			END IF;
		END LOOP;
	END LOOP;
	unit_test_pkg.AssertIsTrue(4 = v_count, 'Actual count was '||v_count||', expected 4');
END;*/

END test_core_api_pkg;
/
