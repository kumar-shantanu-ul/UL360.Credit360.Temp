CREATE OR REPLACE PACKAGE BODY csr.test_emission_factors_pkg AS

v_site_name			VARCHAR2(200);

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	--NULL;
END;

PROCEDURE SetUpFixtureRegions AS
	v_region_root_sid				security.security_pkg.T_SID_ID;
	v_new_region_sid_a				security.security_pkg.T_SID_ID;
	v_new_region_sid_b				security.security_pkg.T_SID_ID;
	v_new_region_sid_c				security.security_pkg.T_SID_ID;
BEGIN 
	Trace('SetUpFixtureRegions');
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	csr.region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => 'EFTestReg1_LevelA1',
		in_description => 'EFTestReg1_LevelA1',
		out_region_sid => v_new_region_sid_a
	);
		csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
			in_name => 'EFTestReg1_LevelB1',
			in_description => 'EFTestReg1_LevelB1',
			out_region_sid => v_new_region_sid_b
		);
		csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
			in_name => 'EFTestReg1_LevelB2',
			in_description => 'EFTestReg1_LevelB2',
			out_region_sid => v_new_region_sid_b
		);
			csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_b,
				in_name => 'EFTestReg1_LevelC1',
				in_description => 'EFTestReg1_LevelC1',
				out_region_sid => v_new_region_sid_c
			);
	
	csr.region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => 'EFTestReg2_LevelA1',
		in_description => 'EFTestReg2_LevelA1',
		out_region_sid => v_new_region_sid_a
	);
		csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
			in_name => 'EFTestReg2_LevelB1',
			in_description => 'EFTestReg2_LevelB1',
			out_region_sid => v_new_region_sid_b
		);
			csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_b,
				in_name => 'EFTestReg2_LevelC1',
				in_description => 'EFTestReg2_LevelC1',
				out_region_sid => v_new_region_sid_c
			);
		csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
			in_name => 'EFTestReg2_LevelB2',
			in_description => 'EFTestReg2_LevelB2',
			out_region_sid => v_new_region_sid_b
		);

	-- enable factor types used in tests, in case this is running somewhere unusual.
	UPDATE csr.factor_type
	   SET enabled = 1
	 WHERE factor_type_id IN (228, 10485, 10486);
END;

PROCEDURE TearDownFixtureRegions AS
BEGIN 
	Trace('TearDownFixtureRegions');
	FOR r IN (SELECT region_sid FROM csr.region WHERE name like 'EFTestReg%')
	LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, r.region_sid);
	END LOOP;
	
	FOR r IN (
		SELECT factor_set_group_id
		  FROM factor_set_group
		 WHERE LOWER(name) IN ('testcancreateandgetcustfactorset profile', 'testcancreateandgetstdfactorset profile', 'testgetfactortypemappedpathsreturnsinfonote profile')
	)
	LOOP
		DELETE FROM csr.std_factor_set WHERE factor_set_group_id = r.factor_set_group_id;
		DELETE FROM csr.custom_factor WHERE custom_factor_set_id IN (
			SELECT custom_factor_set_id FROM csr.custom_factor_set WHERE factor_set_group_id = r.factor_set_group_id
		); 
		DELETE FROM csr.custom_factor_set WHERE factor_set_group_id = r.factor_set_group_id;
		factor_set_group_pkg.DeleteFactorSetGroup(r.factor_set_group_id);
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
	
	enable_pkg.EnableCarbonEmissions;
	
	TearDownFixtureRegions;
	SetUpFixtureRegions;
END;

PROCEDURE DeleteFactors AS
BEGIN
	Trace('DeleteFactors');
	DELETE FROM csr.factor WHERE app_sid = security_pkg.GetApp;
	DELETE FROM csr.custom_factor WHERE app_sid = security_pkg.GetApp;
	DELETE FROM custom_factor WHERE app_sid = security_pkg.GetApp;
	DELETE FROM custom_factor_set WHERE app_sid = security_pkg.GetApp;
	DELETE FROM emission_factor_profile_factor WHERE app_sid = security_pkg.GetApp;
	DELETE FROM emission_factor_profile WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE SetUp AS
	v_company_sid					security.security_pkg.T_SID_ID;
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
	enable_pkg.EnableRegionEmFactorCascading(1);
	DeleteFactors;

	UPDATE customer
	   SET start_month = 1,
		   adj_factorset_startmonth = 0
	 WHERE app_sid = security.security_pkg.getapp;
END;

PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
	DeleteFactors; -- Comment out for testing tests.
	enable_pkg.EnableRegionEmFactorCascading(0);

	UPDATE customer
	   SET start_month = 1,
		   adj_factorset_startmonth = 0
	 WHERE app_sid = security.security_pkg.getapp;
	
	security.user_pkg.logonadmin();	
	
	FOR r IN (
		SELECT c.host, efp.profile_id
		  FROM emission_factor_profile efp
		  JOIN customer c ON efp.app_sid = c.app_sid
		 WHERE efp.name IN ('TestUnpublishStdFactorSetFailsWhenInUseBySameApp', 'TestUnpublishStdFactorSetFailsWhenInUseByDifferentApp')
	) LOOP
		security.user_pkg.logonadmin(r.host);
		factor_pkg.DeleteEmissionProfile(r.profile_id);
	END LOOP;
	
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDownFixture AS
	v_other_app security.security_pkg.T_SID_ID;
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
	TearDownFixtureRegions; -- Comment out for testing tests.
	
	security.user_pkg.logonadmin();
	SELECT MAX(app_sid)
	  INTO v_other_app
	  FROM customer
	 WHERE host = 'emissionfactorsdbunittest.credit360.com';
		 
	IF v_other_app IS NOT NULL THEN
		security.user_pkg.logonadmin('emissionfactorsdbunittest.credit360.com');
		csr.csr_app_pkg.DeleteApp(
			in_reduce_contention			=> 1,
			in_debug_log_deletes			=> 0,
			in_logoff_before_delete_so		=> 1
		);
	END IF;
	security.user_pkg.logonadmin(v_site_name);
END;


PROCEDURE TestEFBase AS
BEGIN
	Trace('TestEFBase');
	factor_pkg.UpdateSubRegionFactors;
	unit_test_pkg.AssertIsTrue(0 = 0, 'Ok');
END;

PROCEDURE InsertRegionFactor(in_region IN security.security_pkg.T_SID_ID, in_value IN NUMBER)
AS
BEGIN
	INSERT INTO factor (factor_id, factor_type_id, gas_type_id, start_dtm, end_dtm, 
		geo_country, geo_region, egrid_ref, region_sid, value, note, std_factor_id, std_measure_conversion_id, is_selected)
		VALUES (factor_id_seq.nextval, 
			10485,--factor_type_id
			1,--gas_type_id
			DATE '2016-01-01',--start_dtm
			NULL,--end_dtm
			NULL,--geo_country
			NULL,--geo_region
			NULL,--egrid_ref
			in_region,-- region_sid
			in_value,--value
			'note',--note
			184407202,--std_factor_id
			26170,--std_measure_conversion_id
			1--is_selected
	);
END;

PROCEDURE ValidateFactorCount(in_expected IN NUMBER, in_msg IN VARCHAR2)
AS
	v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.factor
	 WHERE is_virtual <> 0;
	 
	unit_test_pkg.AssertIsTrue(v_count = in_expected, in_msg||' - '||v_count||' found.');
END;

PROCEDURE TestEFFactor1
AS
	v_count NUMBER;
BEGIN
	/*
		Insert one factor at global scope; no virtual factors should be generated.
	*/
	Trace('TestEFFactor1');
	InsertRegionFactor(NULL, 100);
	factor_pkg.UpdateSubRegionFactors;
	ValidateFactorCount(0, 'Virtual factors should not exist');
END;


PROCEDURE ValidateFactors(in_sids IN security.T_SID_TABLE, in_value IN NUMBER)
AS
	v_expected NUMBER;
	v_matched NUMBER := 0;
BEGIN
	SELECT COUNT(*)
	  INTO v_expected
	  FROM csr.factor
	 WHERE is_virtual = 1
	   AND value = in_value;

	FOR f IN (SELECT * FROM csr.factor WHERE is_virtual = 1)
	LOOP
		FOR s IN (SELECT * FROM TABLE(in_sids))
		LOOP
			TRACE('Compare '||f.region_sid||' against sid '||s.column_value);
			IF s.column_value = f.region_sid THEN
				v_matched := v_matched + 1;
				unit_test_pkg.AssertIsTrue(f.factor_type_id = 10485, 'Virtual factors should have expected factor_type_id.');
				unit_test_pkg.AssertIsTrue(f.gas_type_id = 1, 'Virtual factors should have expected gas_type_id.');
				unit_test_pkg.AssertIsTrue(f.value = in_value, 'Virtual factors should have expected value - was '||f.value||', expected '||in_value);
				unit_test_pkg.AssertIsTrue(f.start_dtm = DATE '2016-01-01', 'Virtual factors should have expected start_dtm.');
				unit_test_pkg.AssertIsTrue(f.end_dtm = NULL, 'Virtual factors should have expected end_dtm.');
				EXIT;
			END IF;
		END LOOP;

	END LOOP;
	unit_test_pkg.AssertIsTrue(v_matched = v_expected, 'Expected virtual factors should exist - matched '||v_matched||', expected '||v_expected);
END;

PROCEDURE GetRegionSid(in_name IN VARCHAR2, out_region_sid OUT security.security_pkg.T_SID_ID)
AS
BEGIN
	SELECT region_sid
	  INTO out_region_sid
	  FROM csr.region
	 WHERE name = in_name;
END;

PROCEDURE TestEFFactor2
AS
	v_count NUMBER;
	v_region_sid security.security_pkg.T_SID_ID;
	v_region_B1_sid security.security_pkg.T_SID_ID;
	v_region_B2_sid security.security_pkg.T_SID_ID;
	v_region_C1_sid security.security_pkg.T_SID_ID;
	v_table_sids security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	/*
		Insert one factor at Region1 scope; some virtual factors should be generated.
	*/
	Trace('TestEFFactor2');

	GetRegionSid('EFTestReg1_LevelA1', v_region_sid);
	GetRegionSid('EFTestReg1_LevelB1', v_region_B1_sid);
	GetRegionSid('EFTestReg1_LevelB2', v_region_B2_sid);
	GetRegionSid('EFTestReg1_LevelC1', v_region_C1_sid);
	
	InsertRegionFactor(v_region_sid, 100);

	factor_pkg.UpdateSubRegionFactors;
	
	ValidateFactorCount(3, '3 virtual factors should exist');
	
	v_table_sids.extend(3);
	v_table_sids(1) := v_region_B1_sid;
	v_table_sids(2) := v_region_B2_sid;
	v_table_sids(3) := v_region_C1_sid;
	ValidateFactors(v_table_sids, 100);
	
	/*
		Update the factor value and check again
	*/
	TRACE('Update to 101');
	UPDATE factor
	   SET value = 101
	 WHERE is_virtual = 0 AND value = 100;
	
	factor_pkg.UpdateSubRegionFactors;
	
	ValidateFactorCount(3, '3 virtual factors should still exist');
	ValidateFactors(v_table_sids, 101);
END;


PROCEDURE TestEFFactor3
AS
	v_count NUMBER;
	v_region_sid security.security_pkg.T_SID_ID;
	v_region_B1_sid security.security_pkg.T_SID_ID;
	v_region_B2_sid security.security_pkg.T_SID_ID;
	v_region_C1_sid security.security_pkg.T_SID_ID;
	v_table_sids security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	/*
		Insert one factor at Region1 scope and one at the bottom; some virtual factors should be generated, but shouldn't overwrite the explicit one.
	*/
	Trace('TestEFFactor3');

	GetRegionSid('EFTestReg1_LevelA1', v_region_sid);
	GetRegionSid('EFTestReg1_LevelB1', v_region_B1_sid);
	GetRegionSid('EFTestReg1_LevelB2', v_region_B2_sid);
	GetRegionSid('EFTestReg1_LevelC1', v_region_C1_sid);
	
	InsertRegionFactor(v_region_sid, 100);
	InsertRegionFactor(v_region_C1_sid, 200);

	factor_pkg.UpdateSubRegionFactors;
	
	ValidateFactorCount(2, '2 virtual factors should exist');
	
	v_table_sids.extend(2);
	v_table_sids(1) := v_region_B1_sid;
	v_table_sids(2) := v_region_B2_sid;
	ValidateFactors(v_table_sids, 100);

	/*
		Update the factor value and check again
	*/
	TRACE('Update to 101');
	UPDATE factor
	   SET value = 101
	 WHERE is_virtual = 0 AND value = 100;
	
	factor_pkg.UpdateSubRegionFactors;
	
	ValidateFactorCount(2, '2 virtual factors should still exist');
	ValidateFactors(v_table_sids, 101);
END;


PROCEDURE TestEFFactor4
AS
	v_count NUMBER;
	v_region_sid security.security_pkg.T_SID_ID;
	v_region_B1_sid security.security_pkg.T_SID_ID;
	v_region_B2_sid security.security_pkg.T_SID_ID;
	v_region_C1_sid security.security_pkg.T_SID_ID;
	v_table_sids security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	/*
		Insert one factor at Region1 scope and one in the middle; some virtual factors should be generated, but shouldn't overwrite the explicit one
		and the correct ones should cascade.
	*/
	Trace('TestEFFactor4');

	GetRegionSid('EFTestReg1_LevelA1', v_region_sid);
	GetRegionSid('EFTestReg1_LevelB1', v_region_B1_sid);
	GetRegionSid('EFTestReg1_LevelB2', v_region_B2_sid);
	GetRegionSid('EFTestReg1_LevelC1', v_region_C1_sid);
	
	InsertRegionFactor(v_region_sid, 100);
	InsertRegionFactor(v_region_B2_sid, 200);

	factor_pkg.UpdateSubRegionFactors;
	
	ValidateFactorCount(2, '2 virtual factors should exist');
	
	v_table_sids.extend(1);
	v_table_sids(1) := v_region_B1_sid;
	ValidateFactors(v_table_sids, 100);

	v_table_sids(1) := v_region_C1_sid;
	ValidateFactors(v_table_sids, 200);

	-- Update the factor value and check again
	TRACE('Update to 101');
	UPDATE factor
	   SET value = 101
	 WHERE is_virtual = 0 AND value = 100;
	UPDATE factor
	   SET value = 201
	 WHERE is_virtual = 0 AND value = 200;
	
	factor_pkg.UpdateSubRegionFactors;
	
	ValidateFactorCount(2, '2 virtual factors should still exist');
	v_table_sids(1) := v_region_B1_sid;
	ValidateFactors(v_table_sids, 101);
	v_table_sids(1) := v_region_C1_sid;
	ValidateFactors(v_table_sids, 201);
END;


PROCEDURE TestEFFactor5
AS
	v_count NUMBER;
	v_region1_sid security.security_pkg.T_SID_ID;
	v_region1_B1_sid security.security_pkg.T_SID_ID;
	v_region1_B2_sid security.security_pkg.T_SID_ID;
	v_region1_C1_sid security.security_pkg.T_SID_ID;
	v_region2_sid security.security_pkg.T_SID_ID;
	v_region2_B1_sid security.security_pkg.T_SID_ID;
	v_region2_B2_sid security.security_pkg.T_SID_ID;
	v_region2_C1_sid security.security_pkg.T_SID_ID;
	v_table_sids security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	/*
		Insert factor at Region1 and 2 scope; some virtual factors should be generated.
		Remove one factor, and virtual factors from one region tree should be removed.
	*/
	Trace('TestEFFactor5');

	GetRegionSid('EFTestReg1_LevelA1', v_region1_sid);
	GetRegionSid('EFTestReg1_LevelB1', v_region1_B1_sid);
	GetRegionSid('EFTestReg1_LevelB2', v_region1_B2_sid);
	GetRegionSid('EFTestReg1_LevelC1', v_region1_C1_sid);
	
	GetRegionSid('EFTestReg2_LevelA1', v_region2_sid);
	GetRegionSid('EFTestReg2_LevelB1', v_region2_B1_sid);
	GetRegionSid('EFTestReg2_LevelB2', v_region2_B2_sid);
	GetRegionSid('EFTestReg2_LevelC1', v_region2_C1_sid);
	
	InsertRegionFactor(v_region1_sid, 100);
	InsertRegionFactor(v_region2_sid, 101);

	factor_pkg.UpdateSubRegionFactors;
	
	ValidateFactorCount(6, '6 virtual factors should exist');
	
	v_table_sids.extend(3);
	v_table_sids(1) := v_region1_B1_sid;
	v_table_sids(2) := v_region1_B2_sid;
	v_table_sids(3) := v_region1_C1_sid;
	ValidateFactors(v_table_sids, 100);

	v_table_sids(1) := v_region2_B1_sid;
	v_table_sids(2) := v_region2_B2_sid;
	v_table_sids(3) := v_region2_C1_sid;
	ValidateFactors(v_table_sids, 101);

	-- Delete one of the factors
	TRACE('Delete factor 100');
	DELETE FROM factor
	 WHERE is_virtual = 0 AND value = 100;
	
	factor_pkg.UpdateSubRegionFactors;
	
	ValidateFactorCount(3, '3 virtual factors should still exist');
	-- table_sids are same as above
	ValidateFactors(v_table_sids, 101);
END;


PROCEDURE TestEFFactor6
AS
	v_count NUMBER;
	v_region1_sid security.security_pkg.T_SID_ID;
	v_region1_B1_sid security.security_pkg.T_SID_ID;
	v_region1_B2_sid security.security_pkg.T_SID_ID;
	v_region1_C1_sid security.security_pkg.T_SID_ID;
	v_region2_sid security.security_pkg.T_SID_ID;
	v_region2_B1_sid security.security_pkg.T_SID_ID;
	v_region2_B2_sid security.security_pkg.T_SID_ID;
	v_region2_C1_sid security.security_pkg.T_SID_ID;
	v_table_sids security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	/*
		Disable cascading.
	*/
	Trace('TestEFFactor6');
	enable_pkg.EnableRegionEmFactorCascading(0);

	GetRegionSid('EFTestReg1_LevelA1', v_region1_sid);
	GetRegionSid('EFTestReg1_LevelB1', v_region1_B1_sid);
	GetRegionSid('EFTestReg1_LevelB2', v_region1_B2_sid);
	GetRegionSid('EFTestReg1_LevelC1', v_region1_C1_sid);
	
	InsertRegionFactor(v_region1_sid, 100);

	factor_pkg.UpdateSubRegionFactors;
	
	ValidateFactorCount(0, '0 virtual factors should exist');
END;


PROCEDURE TestEFFactorExportEmptyProfile
AS
	v_count NUMBER;
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;

	v_cur_profile			security_pkg.T_OUTPUT_CUR;
	v_cur_factors			security_pkg.T_OUTPUT_CUR;
	v_cur_mapped			security_pkg.T_OUTPUT_CUR;

BEGIN
	Trace('TestEFFactorExportEmptyProfile');

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles.');
	
	v_name := 'TestEFFactorExportEmptyProfile';
	v_applied := 0;
	v_start_dtm := DATE '2010-01-01';
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_start_dtm, v_profile_id);
	
	v_applied := 1;
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);

	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile.');
	
	v_applied := 0;
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);

	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	
	factor_pkg.DeleteEmissionProfile(v_profile_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles after delete.');
END;

PROCEDURE CheckFactorProfileFactors(
	in_cur_factors	IN	security_pkg.T_OUTPUT_CUR,
	in_start_month	IN	NUMBER,
	out_count		OUT	NUMBER,
	out_count_co	OUT	NUMBER,
	out_count_co2	OUT	NUMBER
)
AS
	v_count NUMBER;
	v_count_co NUMBER;
	v_count_co2 NUMBER;

	v_cf_factor_type_id							NUMBER;
	v_cf_std_factor_set_id						NUMBER;
	v_cf_custom_factor_set_id					NUMBER;
	v_cf_region_sid								NUMBER;
	v_cf_pr_factor_geo_country					VARCHAR2(200);
	v_cf_pr_factor_geo_region					VARCHAR2(200);
	v_cf_pr_factor_egrid_ref					VARCHAR2(200);
	v_cf_local_region							VARCHAR2(200);
	v_cf_region_geo_country						VARCHAR2(200);
	v_cf_region_geo_region						VARCHAR2(200);
	v_cf_region_egrid_ref						VARCHAR2(200);
	v_cf_region_active							NUMBER;
	v_cf_geo_country							VARCHAR2(200);
	v_cf_geo_region								VARCHAR2(200);
	v_cf_egrid_ref								VARCHAR2(200);
	v_cf_factor									VARCHAR2(200);
	v_cf_factor_path							VARCHAR2(200);
	v_cf_fs_std_factor_set_id					NUMBER;
	v_cf_std_factor_set							VARCHAR2(200);
	v_cf_cfs_custom_factor_set_id				NUMBER;
	v_cf_custom_factor_set						VARCHAR2(200);
	v_cf_gas_type_id							NUMBER;
	v_cf_gas									VARCHAR2(200);
	v_cf_factor_id								NUMBER;
	v_cf_value									NUMBER;
	v_cf_start_dtm								DATE;
	v_cf_end_dtm								DATE;
	v_cf_note									VARCHAR2(200);
	v_cf_std_factor_id							NUMBER;
	v_cf_custom_factor_id						NUMBER;
	v_cf_std_measure_conv_id					NUMBER;
	v_cf_unit									VARCHAR2(200);
	v_cf_country								VARCHAR2(200);
	v_cf_region									VARCHAR2(200);
	v_cf_egrid									VARCHAR2(200);
BEGIN
	Trace('Factors:');
	v_count := 0;
	v_count_co:= 0;
	v_count_co2 := 0;
	LOOP
		FETCH in_cur_factors INTO 
			v_cf_factor_type_id,
			v_cf_std_factor_set_id,
			v_cf_custom_factor_set_id,
			v_cf_region_sid,
			v_cf_pr_factor_geo_country,
			v_cf_pr_factor_geo_region,
			v_cf_pr_factor_egrid_ref,
			v_cf_local_region,
			v_cf_region_geo_country,
			v_cf_region_geo_region,
			v_cf_region_egrid_ref,
			v_cf_region_active,
			v_cf_geo_country,
			v_cf_geo_region,
			v_cf_egrid_ref,
			v_cf_factor,
			v_cf_factor_path,
			v_cf_fs_std_factor_set_id,
			v_cf_std_factor_set,
			v_cf_cfs_custom_factor_set_id,
			v_cf_custom_factor_set,
			v_cf_gas_type_id,
			v_cf_gas,
			v_cf_factor_id,
			v_cf_value,
			v_cf_start_dtm,
			v_cf_end_dtm,
			v_cf_note,
			v_cf_std_factor_id,
			v_cf_custom_factor_id,
			v_cf_std_measure_conv_id,
			v_cf_unit,
			v_cf_country,
			v_cf_region,
			v_cf_egrid
		;
		EXIT WHEN in_cur_factors%NOTFOUND;
		v_count := v_count + 1;
		IF v_cf_gas_type_id = 1 THEN 
			v_count_co := v_count_co + 1;
		END IF;
		IF v_cf_gas_type_id = 2 THEN 
			v_count_co2 := v_count_co2 + 1;
		END IF;
		
		unit_test_pkg.AssertIsTrue(EXTRACT(MONTH FROM v_cf_start_dtm) = in_start_month, 'Expected start month match.');
		
		IF v_cf_end_dtm IS NOT NULL THEN
			unit_test_pkg.AssertIsTrue(EXTRACT(MONTH FROM v_cf_end_dtm) = in_start_month, 'Expected end month match.');
		END IF;
		
		Trace('Factor: '||v_cf_factor_type_id||','||v_cf_std_factor_set_id||','||v_cf_start_dtm||','||v_cf_end_dtm||','||v_cf_gas||','||v_cf_value||','||
			v_cf_region_sid||','||v_cf_pr_factor_geo_country||','||v_cf_pr_factor_geo_region||','||v_cf_pr_factor_egrid_ref);
		--Trace('.     : '||v_cf_std_factor_id||','||v_cf_custom_factor_id||','||v_cf_std_measure_conv_id||','||v_cf_unit||','||v_cf_country||','||v_cf_region||','||v_cf_egrid);
	END LOOP;
	
	out_count := v_count;
	out_count_co := v_count_co;
	out_count_co2 := v_count_co2;
END;


PROCEDURE TestEFFactorExportStdFactor
AS
	v_count NUMBER;
	v_count_a NUMBER;
	v_count_b NUMBER;
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;

	v_cur_profile			security_pkg.T_OUTPUT_CUR;
	v_cur_factors			security_pkg.T_OUTPUT_CUR;
	v_cur_mapped			security_pkg.T_OUTPUT_CUR;

	v_cur_profile_id		emission_factor_profile.profile_id%TYPE;
	v_cur_name				emission_factor_profile.name%TYPE;
	v_cur_start_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_end_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_applied			emission_factor_profile.applied%TYPE;

	v_cm_factor_type_id							NUMBER;
	v_cm_factor_type_name						VARCHAR2(200);
	v_cm_path									VARCHAR2(200);
	v_cm_ind_sid								NUMBER;
	v_cm_ind_description						VARCHAR2(200);
	
BEGIN
	Trace('TestEFFactorExportStdFactor');

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles, found '||v_count);
	
	v_name := 'TestEFFactorExportStdFactor';
	v_applied := 0;
	v_start_dtm := NULL;
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_start_dtm, v_profile_id);
	
	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_profile_id = v_profile_id, 'Expected profile id match.');
		unit_test_pkg.AssertIsTrue(v_cur_name = v_name, 'Expected profile name match.');
		unit_test_pkg.AssertIsTrue(v_cur_start_dtm = v_start_dtm, 'Expected profile start dtm match.');
		unit_test_pkg.AssertIsTrue(v_cur_end_dtm IS NULL, 'Expected null end dtm.');
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);

	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_std_factor_set_id		=> 58, -- International Energy Agency (IEA) 2015
		in_custom_factor_set_id		=> NULL,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile factor, found '||v_count);

	v_applied := 1;
	v_start_dtm := DATE '1990-01-01';
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);

	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM factor;
	unit_test_pkg.AssertIsTrue(v_count = 22, 'Expected 22 factors, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);
	
	
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 1, v_count, v_count_a, v_count_b);
	unit_test_pkg.AssertIsTrue(v_count = 22, 'Expected 22 profile factor returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = 11, 'Expected 11 CO2 profile factor returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 11, 'Expected 11 CO2e profile factors returned, found '||v_count_b);
	
	
	v_count := 0;
	LOOP
		FETCH v_cur_mapped INTO v_cm_factor_type_id, v_cm_factor_type_name, v_cm_path, v_cm_ind_sid, v_cm_ind_description;
		EXIT WHEN v_cur_mapped%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile mapped inds returned, found '||v_count);
	
	v_applied := 0;
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);
	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 1, v_count, v_count_a, v_count_b);
	unit_test_pkg.AssertIsTrue(v_count = 22, 'Expected 22 profile factor returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = 11, 'Expected 11 CO2 profile factor returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 11, 'Expected 11 CO2e profile factors returned, found '||v_count_b);
	
	factor_pkg.DeleteEmissionProfile(v_profile_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles after delete, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile factors after delete, found '||v_count);
END;


PROCEDURE TestEFFactorExportCustomFactor
AS
	v_count NUMBER;
	v_factor_count_expected NUMBER;
	v_count_expected NUMBER;
	v_count_a NUMBER;
	v_count_b NUMBER;
	v_region1_sid NUMBER;
	
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;

	v_custom_factor_set_id	custom_factor.custom_factor_set_id%TYPE;
	v_geo_country			VARCHAR2(200);
	v_geo_region			VARCHAR2(200);
	v_region_sid			NUMBER;
	v_end_dtm				DATE;
	v_gas_type_id			NUMBER;
	v_value					NUMBER;
	v_std_meas_conv_id		NUMBER;
	v_note					VARCHAR2(200);
	v_custom_factor_id		NUMBER;
	
	v_cur_profile			security_pkg.T_OUTPUT_CUR;
	v_cur_factors			security_pkg.T_OUTPUT_CUR;
	v_cur_mapped			security_pkg.T_OUTPUT_CUR;

	v_cur_profile_id		emission_factor_profile.profile_id%TYPE;
	v_cur_name				emission_factor_profile.name%TYPE;
	v_cur_start_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_end_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_applied			emission_factor_profile.applied%TYPE;

	v_cm_factor_type_id							NUMBER;
	v_cm_factor_type_name						VARCHAR2(200);
	v_cm_path									VARCHAR2(200);
	v_cm_ind_sid								NUMBER;
	v_cm_ind_description						VARCHAR2(200);
	
BEGIN
	Trace('TestEFFactorExportCustomFactor');

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles, found '||v_count);
	
	GetRegionSid('EFTestReg1_LevelA1', v_region1_sid);

	v_name := 'TestEFFactorExportCustomFactor';
	v_applied := 0;
	v_start_dtm := NULL;
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_start_dtm, v_profile_id);
	
	v_custom_factor_set_id := factor_pkg.CreateCustomFactorSet(v_name, 0);
	
	v_factor_count_expected := 0;
	v_value:= 1.23;
	v_start_dtm:= DATE '2000-01-01';
	v_end_dtm := NULL;
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	factor_pkg.InsertCustomValue(10485, v_custom_factor_set_id, v_geo_country, v_geo_region, v_region_sid,
		v_start_dtm, v_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_custom_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	
	v_value:= 2.34;
	v_start_dtm:= DATE '2001-01-01';
	v_end_dtm := NULL;
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	v_geo_country := NULL;
	v_geo_region := NULL;
	v_region_sid := NULL;
	factor_pkg.InsertCustomValue(10486, v_custom_factor_set_id, v_geo_country, v_geo_region, v_region_sid,
		v_start_dtm, v_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_custom_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	
	v_value:= 2.35;
	v_start_dtm:= DATE '2001-01-01';
	v_end_dtm := NULL;
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	v_geo_country := 'fr';
	v_geo_region := NULL;
	v_region_sid := NULL;
	factor_pkg.InsertCustomValue(10486, v_custom_factor_set_id, v_geo_country, v_geo_region, v_region_sid,
		v_start_dtm, v_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_custom_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	
	v_value:= 2.36;
	v_start_dtm:= DATE '2001-01-01';
	v_end_dtm := NULL;
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	v_geo_country := NULL;
	v_geo_region := 'ASCC';
	v_region_sid := NULL;
	factor_pkg.InsertCustomValue(10486, v_custom_factor_set_id, v_geo_country, v_geo_region, v_region_sid,
		v_start_dtm, v_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_custom_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	
	v_value:= 2.37;
	v_start_dtm:= DATE '2001-01-01';
	v_end_dtm := NULL;
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	v_geo_country := NULL;
	v_geo_region := NULL;
	v_region_sid := v_region1_sid;
	factor_pkg.InsertCustomValue(10486, v_custom_factor_set_id, v_geo_country, v_geo_region, v_region_sid,
		v_start_dtm, v_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_custom_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	
	v_value:= 2.38;
	v_start_dtm:= DATE '2001-01-01';
	v_end_dtm := NULL;
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	v_geo_country := 'fr';
	v_geo_region := NULL;
	v_region_sid := v_region1_sid;
	factor_pkg.InsertCustomValue(10486, v_custom_factor_set_id, v_geo_country, v_geo_region, v_region_sid,
		v_start_dtm, v_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_custom_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM custom_factor;
	unit_test_pkg.AssertIsTrue(v_count = v_factor_count_expected, 'Expected '||v_factor_count_expected||' custom factors, found '||v_count);


	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_profile_id = v_profile_id, 'Expected profile id match.');
		unit_test_pkg.AssertIsTrue(v_cur_name = v_name, 'Expected profile name match.');
		unit_test_pkg.AssertIsTrue(v_cur_start_dtm = v_start_dtm, 'Expected profile start dtm match.');
		unit_test_pkg.AssertIsTrue(v_cur_end_dtm IS NULL, 'Expected null end dtm.');
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);

	v_count_expected := 0;
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> NULL,
		in_geo_country				=> 'en',
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10486, -- Grid Electricity Generated - Average Load (Rolling Average) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10486, -- Grid Electricity Generated - Average Load (Rolling Average) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> v_region1_sid,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10486, -- Grid Electricity Generated - Average Load (Rolling Average) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> NULL,
		in_geo_country				=> 'fr',
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10486, -- Grid Electricity Generated - Average Load (Rolling Average) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> 'ca',
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10486, -- Grid Electricity Generated - Average Load (Rolling Average) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> 'ASCC');
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10486, -- Grid Electricity Generated - Average Load (Rolling Average) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> v_region1_sid,
		in_geo_country				=> 'fr',
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s), found '||v_count);

	v_applied := 1;
	v_start_dtm := DATE '1990-01-01';
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);

	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM factor;
	unit_test_pkg.AssertIsTrue(v_count = 6, 'Expected '||6||' factors, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);
	
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 1, v_count, v_count_a, v_count_b);
	v_count_expected := 6;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 0, 'Expected 0 CO2e profile factors returned, found '||v_count_b);
	
	v_count := 0;
	LOOP
		FETCH v_cur_mapped INTO v_cm_factor_type_id, v_cm_factor_type_name, v_cm_path, v_cm_ind_sid, v_cm_ind_description;
		EXIT WHEN v_cur_mapped%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile mapped inds returned, found '||v_count);
	
	v_applied := 0;
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);
	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 1, v_count, v_count_a, v_count_b);
	v_count_expected := 6;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 0, 'Expected 0 CO2e profile factors returned, found '||v_count_b);

	factor_pkg.DeleteEmissionProfile(v_profile_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles after delete, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile factors after delete, found '||v_count);
END;


PROCEDURE TestEFFactorMultiProfile1
AS
	v_count NUMBER;
	v_factor_count_expected NUMBER;
	v_count_expected NUMBER;
	v_count_a NUMBER;
	v_count_b NUMBER;
	v_region1_sid NUMBER;
	
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_profile_start_dtm		emission_factor_profile.start_dtm%TYPE;
	v_profile1_id			emission_factor_profile.profile_id%TYPE;
	v_profile2_id			emission_factor_profile.profile_id%TYPE;

	v_factor_start_dtm		DATE;
	v_factor_end_dtm		DATE;

	v_custom_factor_set_id	custom_factor.custom_factor_set_id%TYPE;
	v_geo_country			VARCHAR2(200);
	v_geo_region			VARCHAR2(200);
	v_region_sid			NUMBER;
	v_start_dtm				DATE;
	v_end_dtm				DATE;
	v_gas_type_id			NUMBER;
	v_value					NUMBER;
	v_std_meas_conv_id		NUMBER;
	v_note					VARCHAR2(200);
	v_custom_factor_id		NUMBER;
	v_factor_id				NUMBER;
	
	v_cur_profile			security_pkg.T_OUTPUT_CUR;
	v_cur_factors			security_pkg.T_OUTPUT_CUR;
	v_cur_mapped			security_pkg.T_OUTPUT_CUR;

	v_cur_profile_id		emission_factor_profile.profile_id%TYPE;
	v_cur_name				emission_factor_profile.name%TYPE;
	v_cur_start_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_end_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_applied			emission_factor_profile.applied%TYPE;

	v_cm_factor_type_id							NUMBER;
	v_cm_factor_type_name						VARCHAR2(200);
	v_cm_path									VARCHAR2(200);
	v_cm_ind_sid								NUMBER;
	v_cm_ind_description						VARCHAR2(200);
	
BEGIN
	/*
		Test to ensure that a custom factor that spans more than one profile is correctly reflected in the factor table.
		Refer to FB123292.
	*/
	Trace('TestEFFactorMultiProfile1');

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles, found '||v_count);
	
	GetRegionSid('EFTestReg1_LevelA1', v_region1_sid);

	v_name := 'TestEFFactorMultiProfile1-1';
	v_applied := 0;
	v_profile_start_dtm := DATE '1990-01-01';
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_profile_start_dtm, v_profile1_id);

	v_custom_factor_set_id := factor_pkg.CreateCustomFactorSet(v_name, 0);

	v_factor_count_expected := 0;
	v_value:= 1.23;
	v_factor_start_dtm:= DATE '2000-01-01';
	v_factor_end_dtm := NULL;
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	factor_pkg.InsertCustomValue(10485, v_custom_factor_set_id, v_geo_country, v_geo_region, v_region_sid,
		v_factor_start_dtm, v_factor_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_custom_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM custom_factor;
	unit_test_pkg.AssertIsTrue(v_count = v_factor_count_expected, 'Expected '||v_factor_count_expected||' custom factors, found '||v_count);

	-- Create the second profile
	factor_pkg.CreateEmissionProfile('TestEFFactorMultiProfile1-2', 0, DATE '2017-01-01', v_profile2_id);
	
	
	factor_pkg.GetEmissionProfile(v_profile1_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_profile_id = v_profile1_id, 'Expected profile id match.');
		unit_test_pkg.AssertIsTrue(v_cur_name = v_name, 'Expected profile name match.');
		unit_test_pkg.AssertIsTrue(v_cur_start_dtm = v_profile_start_dtm, 'Expected profile start dtm match.');
		unit_test_pkg.AssertIsTrue(v_cur_end_dtm IS NULL, 'Expected null end dtm.');
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);

	v_count_expected := 0;
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile1_id,
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile2_id,
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_std_factor_set_id		=> NULL,
		in_custom_factor_set_id		=> v_custom_factor_set_id,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s), found '||v_count);


	v_applied := 1;
	factor_pkg.UpdateEmissionProfileStatus(v_profile1_id, v_applied, DATE '1990-01-01');

	v_count := 1;
	FOR r IN (SELECT * from factor WHERE factor_type_id = 10485)
	LOOP
		unit_test_pkg.AssertIsTrue(v_count <= 1, 'Unexpected factor, there can be only one.');
		v_factor_id := r.factor_id;
		Trace('Factor (1 applied): profile='||r.profile_id||'; factor_type='||r.factor_type_id||'; start='||r.start_dtm||'; end='||r.end_dtm);
		unit_test_pkg.AssertIsTrue(r.profile_id = v_profile1_id, 'Expected profile match.');
		unit_test_pkg.AssertIsTrue(r.start_dtm = DATE '2000-01-01', 'Expected factor start date match.');
		unit_test_pkg.AssertIsTrue(r.end_dtm IS NULL, 'Expected factor end date match.');
		v_count := v_count + 1;
	END LOOP;

	factor_pkg.UpdateEmissionProfileStatus(v_profile2_id, v_applied, DATE '2017-01-01');

	v_count := 1;
	FOR r IN (SELECT * from factor WHERE factor_type_id = 10485)
	LOOP
		unit_test_pkg.AssertIsTrue(v_count <= 2, 'Unexpected factor, there can be only two.');
		Trace('Factor (2 applied): profile='||r.profile_id||'; factor_type='||r.factor_type_id||'; start='||r.start_dtm||'; end='||r.end_dtm);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.profile_id = v_profile1_id, 'Expected profile match.');
			unit_test_pkg.AssertIsTrue(r.start_dtm = DATE '2000-01-01', 'Expected factor start date match.');
			unit_test_pkg.AssertIsTrue(r.end_dtm = DATE '2017-01-01', 'Expected factor end date match.');
		END IF;
		IF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(r.profile_id = v_profile2_id, 'Expected profile match.');
			unit_test_pkg.AssertIsTrue(r.start_dtm = DATE '2017-01-01', 'Expected factor start date match.');
			unit_test_pkg.AssertIsTrue(r.end_dtm IS NULL, 'Expected factor end date match.');
		END IF;
		v_count := v_count + 1;
	END LOOP;

	factor_pkg.GetEmissionProfile(v_profile1_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM factor;
	unit_test_pkg.AssertIsTrue(v_count = 2, 'Expected '||2||' factors, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);
	
	
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 1, v_count, v_count_a, v_count_b);
	v_count_expected := 1;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 0, 'Expected 0 CO2e profile factors returned, found '||v_count_b);
	
	
	v_count := 0;
	LOOP
		FETCH v_cur_mapped INTO v_cm_factor_type_id, v_cm_factor_type_name, v_cm_path, v_cm_ind_sid, v_cm_ind_description;
		EXIT WHEN v_cur_mapped%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile mapped inds returned, found '||v_count);
	


	v_applied := 0;
	factor_pkg.UpdateEmissionProfileStatus(v_profile1_id, v_applied, v_start_dtm);
	factor_pkg.GetEmissionProfile(v_profile1_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 1, v_count, v_count_a, v_count_b);
	v_count_expected := 1;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 0, 'Expected 0 CO2e profile factors returned, found '||v_count_b);


	v_applied := 0;
	factor_pkg.UpdateEmissionProfileStatus(v_profile2_id, v_applied, v_start_dtm);
	factor_pkg.GetEmissionProfile(v_profile2_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 1, v_count, v_count_a, v_count_b);
	v_count_expected := 1;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 0, 'Expected 0 CO2e profile factors returned, found '||v_count_b);


	factor_pkg.DeleteEmissionProfile(v_profile1_id);
	factor_pkg.DeleteEmissionProfile(v_profile2_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles after delete, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile factors after delete, found '||v_count);

	DELETE FROM custom_factor
	 WHERE custom_factor_set_id = v_custom_factor_set_id;
	DELETE FROM custom_factor_set
	 WHERE custom_factor_set_id = v_custom_factor_set_id;
END;


PROCEDURE InsertStandardValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	in_value				IN std_factor.value%TYPE,
	in_std_meas_conv_id		IN std_factor.std_measure_conversion_id%TYPE,
	in_note					IN std_factor.note%TYPE,
	out_std_factor_id		OUT std_factor.std_factor_id%TYPE
)
AS
	v_std_factor_id			std_factor.std_factor_id%TYPE;
	v_count					NUMBER(10);
	v_app_sid				security_pkg.T_SID_ID;
	v_audit_msg				VARCHAR2(1000);
	v_audit_info			VARCHAR2(1000);
	v_gas					VARCHAR2(1000);
	v_smc					VARCHAR2(1000);
BEGIN
	v_std_factor_id := STD_FACTOR_ID_SEQ.nextval;
	
	--add new entry to std factor table
	SELECT COUNT(country)
	  INTO v_count
	  FROM POSTCODE.region
	 WHERE country = in_geo_country
	   AND in_geo_region IS NULL OR region = in_geo_region;
	   
	IF v_count > 0 THEN
		--Set geo_region
		INSERT INTO std_factor(std_factor_id, factor_type_id, std_factor_set_id, gas_type_id, 
				geo_country, geo_region, start_dtm, end_dtm, value,
				std_measure_conversion_id, note)
		VALUES(v_std_factor_id, in_factor_type_id, in_std_factor_set_id, in_gas_type_id,
			   in_geo_country, in_geo_region, in_start_dtm, in_end_dtm, in_value,
			   in_std_meas_conv_id, in_note);
	ELSE
		--Set egrid_ref
		INSERT INTO std_factor(std_factor_id, factor_type_id, std_factor_set_id, gas_type_id, 
				geo_country, egrid_ref, start_dtm, end_dtm, value,
				std_measure_conversion_id, note)
		VALUES(v_std_factor_id, in_factor_type_id, in_std_factor_set_id, in_gas_type_id,
			   in_geo_country, in_geo_region, in_start_dtm, in_end_dtm, in_value,
			   in_std_meas_conv_id, in_note);
	END IF;

	out_std_factor_id := v_std_factor_id;

END;

PROCEDURE TestEFFactorMultiProfile2
AS
	v_count NUMBER;
	v_new_count NUMBER;
	v_factor_count_expected NUMBER;
	v_count_expected NUMBER;
	v_count_a NUMBER;
	v_count_b NUMBER;
	v_region1_sid NUMBER;
	
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_profile_start_dtm		emission_factor_profile.start_dtm%TYPE;
	v_profile1_id			emission_factor_profile.profile_id%TYPE;
	v_profile2_id			emission_factor_profile.profile_id%TYPE;

	v_factor_start_dtm		DATE;
	v_factor_end_dtm		DATE;

	v_std_factor_set_id		std_factor.std_factor_set_id%TYPE;
	v_geo_country			VARCHAR2(200);
	v_geo_region			VARCHAR2(200);
	v_region_sid			NUMBER;
	v_start_dtm				DATE;
	v_end_dtm				DATE;
	v_gas_type_id			NUMBER;
	v_value					NUMBER;
	v_std_meas_conv_id		NUMBER;
	v_note					VARCHAR2(200);
	v_std_factor_id			NUMBER;
	v_factor_id				NUMBER;
	
	v_cur_profile			security_pkg.T_OUTPUT_CUR;
	v_cur_factors			security_pkg.T_OUTPUT_CUR;
	v_cur_mapped			security_pkg.T_OUTPUT_CUR;

	v_cur_profile_id		emission_factor_profile.profile_id%TYPE;
	v_cur_name				emission_factor_profile.name%TYPE;
	v_cur_start_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_end_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_applied			emission_factor_profile.applied%TYPE;

	v_cm_factor_type_id							NUMBER;
	v_cm_factor_type_name						VARCHAR2(200);
	v_cm_path									VARCHAR2(200);
	v_cm_ind_sid								NUMBER;
	v_cm_ind_description						VARCHAR2(200);
	
	v_start_month			NUMBER := 5;
	
BEGIN
	/*
		Test to ensure that a std factor that starts on the end date of the primary profile is correctly ignored.
		Refer to FB124489.
	*/
	Trace('TestEFFactorMultiProfile2');

	UPDATE customer
	   SET start_month = v_start_month,
		   adj_factorset_startmonth = 1
	 WHERE app_sid = security.security_pkg.getapp;

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles, found '||v_count);
	
	GetRegionSid('EFTestReg1_LevelA1', v_region1_sid);

	v_name := 'TestEFFactorMultiProfile2-1';
	v_applied := 0;
	v_profile_start_dtm := DATE '1990-05-01';
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_profile_start_dtm, v_profile1_id);


	SELECT COUNT(*)
	  INTO v_count
	  FROM std_factor;

	--DELETE FROM std_factor_set WHERE name = v_name;
	v_std_factor_set_id := factor_pkg.CreateStdFactorSet(v_name, 16);
	Trace('CreateStdFactorSet '||'('||v_name||'): '||v_std_factor_set_id);

	v_factor_count_expected := 0;
	v_value:= 1.23;
	v_factor_start_dtm:= DATE '2000-01-01';
	v_factor_end_dtm := DATE '2017-01-01';
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	InsertStandardValue(10485, v_std_factor_set_id, v_geo_country, v_geo_region,
		v_factor_start_dtm, v_factor_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_std_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	
	v_value:= 4.56;
	v_factor_start_dtm:= DATE '2017-01-01';
	v_factor_end_dtm := NULL;
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	InsertStandardValue(10485, v_std_factor_set_id, v_geo_country, v_geo_region,
		v_factor_start_dtm, v_factor_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_std_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	
	
	SELECT COUNT(*)
	  INTO v_new_count
	  FROM std_factor;
	unit_test_pkg.AssertIsTrue(v_new_count - v_count = v_factor_count_expected, 'Expected '||v_factor_count_expected||' std factors, found '|| (v_new_count - v_count) );
	
	-- Create the second profile
	factor_pkg.CreateEmissionProfile('TestEFFactorMultiProfile2-2', 0, DATE '2017-05-01', v_profile2_id);
	
	
	factor_pkg.GetEmissionProfile(v_profile1_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_profile_id = v_profile1_id, 'Expected profile id match.');
		unit_test_pkg.AssertIsTrue(v_cur_name = v_name, 'Expected profile name match.');
		unit_test_pkg.AssertIsTrue(v_cur_start_dtm = v_profile_start_dtm, 'Expected profile start dtm match.');
		unit_test_pkg.AssertIsTrue(v_cur_end_dtm IS NULL, 'Expected null end dtm.');
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);

	v_count_expected := 0;
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile1_id,
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_std_factor_set_id		=> v_std_factor_set_id,
		in_custom_factor_set_id		=> NULL,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile2_id,
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_std_factor_set_id		=> v_std_factor_set_id,
		in_custom_factor_set_id		=> NULL,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s), found '||v_count);


	v_applied := 1;
	factor_pkg.UpdateEmissionProfileStatus(v_profile1_id, v_applied, DATE '1990-05-01');

	v_count := 1;
	FOR r IN (SELECT * from factor WHERE factor_type_id = 10485)
	LOOP
		unit_test_pkg.AssertIsTrue(v_count <= 2, 'Unexpected factor (a), there can be only two.');
		v_factor_id := r.factor_id;
		Trace('Factor (1 applied): profile='||r.profile_id||'; factor_type='||r.factor_type_id||'; start='||r.start_dtm||'; end='||r.end_dtm);
		unit_test_pkg.AssertIsTrue(r.profile_id = v_profile1_id, 'Expected profile match (a).');
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.start_dtm = DATE '2000-05-01', 'Expected factor start date match (a):'||r.start_dtm);
			unit_test_pkg.AssertIsTrue(r.end_dtm = DATE '2017-05-01', 'Expected factor end date match (a):'||r.end_dtm);
		END IF;
		IF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(r.start_dtm = DATE '2017-05-01', 'Expected factor start date match (a).');
			unit_test_pkg.AssertIsTrue(r.end_dtm IS NULL, 'Expected factor end date match (a).');
		END IF;
		v_count := v_count + 1;
	END LOOP;

	factor_pkg.UpdateEmissionProfileStatus(v_profile2_id, v_applied, DATE '2017-05-01');

	v_count := 1;
	FOR r IN (SELECT * from factor WHERE factor_type_id = 10485)
	LOOP
		unit_test_pkg.AssertIsTrue(v_count <= 2, 'Unexpected factor (b), there can be only two.');
		Trace('Factor (2 applied): profile='||r.profile_id||'; factor_type='||r.factor_type_id||'; start='||r.start_dtm||'; end='||r.end_dtm);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.profile_id = v_profile1_id, 'Expected profile match (b).');
			unit_test_pkg.AssertIsTrue(r.start_dtm = DATE '2000-05-01', 'Expected factor start date match (b):'||r.start_dtm);
			unit_test_pkg.AssertIsTrue(r.end_dtm = DATE '2017-05-01', 'Expected factor end date match (b):'||r.end_dtm);
		END IF;
		IF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(r.profile_id = v_profile2_id, 'Expected profile match (c).');
			unit_test_pkg.AssertIsTrue(r.start_dtm = DATE '2017-05-01', 'Expected factor start date match (c):'||r.start_dtm);
			unit_test_pkg.AssertIsTrue(r.end_dtm IS NULL, 'Expected factor end date match (c):'||r.end_dtm);
		END IF;
		v_count := v_count + 1;
	END LOOP;

	factor_pkg.GetEmissionProfile(v_profile1_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM factor;
	unit_test_pkg.AssertIsTrue(v_count = 2, 'Expected '||2||' factors, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);
	
	
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, v_start_month, v_count, v_count_a, v_count_b);
	v_count_expected := 2;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 0, 'Expected 0 CO2e profile factors returned, found '||v_count_b);
	
	
	v_count := 0;
	LOOP
		FETCH v_cur_mapped INTO v_cm_factor_type_id, v_cm_factor_type_name, v_cm_path, v_cm_ind_sid, v_cm_ind_description;
		EXIT WHEN v_cur_mapped%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile mapped inds returned, found '||v_count);
	


	v_applied := 0;
	factor_pkg.UpdateEmissionProfileStatus(v_profile1_id, v_applied, v_start_dtm);
	factor_pkg.GetEmissionProfile(v_profile1_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, v_start_month, v_count, v_count_a, v_count_b);
	v_count_expected := 1;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 0, 'Expected 0 CO2e profile factors returned, found '||v_count_b);


	v_applied := 0;
	factor_pkg.UpdateEmissionProfileStatus(v_profile2_id, v_applied, v_start_dtm);
	factor_pkg.GetEmissionProfile(v_profile2_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, v_start_month, v_count, v_count_a, v_count_b);
	v_count_expected := 1;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 0, 'Expected 0 CO2e profile factors returned, found '||v_count_b);


	factor_pkg.DeleteEmissionProfile(v_profile1_id);
	factor_pkg.DeleteEmissionProfile(v_profile2_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles after delete, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile factors after delete, found '||v_count);

	DELETE FROM std_factor
	 WHERE std_factor_set_id = v_std_factor_set_id;
	DELETE FROM std_factor_set
	 WHERE std_factor_set_id = v_std_factor_set_id;
END;


PROCEDURE TestEFFactorExportEgrid
AS
	v_factor_count_expected NUMBER;
	v_count NUMBER;
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;
	v_count_expected NUMBER;
	v_count_a NUMBER;
	v_count_b NUMBER;

	v_custom_factor_set_id	custom_factor.custom_factor_set_id%TYPE;
	v_geo_country			VARCHAR2(200);
	v_geo_region			VARCHAR2(200);
	v_region_sid			NUMBER;
	v_gas_type_id			NUMBER;
	v_value					NUMBER;
	v_std_meas_conv_id		NUMBER;
	v_note					VARCHAR2(200);
	v_custom_factor_id		NUMBER;

	v_cur_profile			security_pkg.T_OUTPUT_CUR;
	v_cur_factors			security_pkg.T_OUTPUT_CUR;
	v_cur_mapped			security_pkg.T_OUTPUT_CUR;

	v_start_dtm				DATE;
	v_end_dtm				DATE;
	
	v_region_root_sid				security.security_pkg.T_SID_ID;
	v_new_region_sid_a				security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestEFFactorExportEgrid');

	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	csr.region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => 'EFTestReg1_LevelA1_Egrid',
		in_description => 'EFTestReg1_LevelA1_Egrid',
		in_egrid_ref => 'ASCC',
		out_region_sid => v_new_region_sid_a
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles.');
	
	v_name := 'TestEFFactorExportEgrid';
	
	v_custom_factor_set_id := factor_pkg.CreateCustomFactorSet(v_name, 0);
	
	v_factor_count_expected := 0;
	v_value:= 1.23;
	v_start_dtm:= DATE '2000-01-01';
	v_end_dtm := NULL;
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	factor_pkg.InsertCustomValue(228, v_custom_factor_set_id, v_geo_country, v_geo_region, v_region_sid,
		v_start_dtm, v_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_custom_factor_id -- out
	);
	v_factor_count_expected := v_factor_count_expected + 1;
	

	v_applied := 0;
	v_start_dtm := DATE '1990-01-01';
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_start_dtm, v_profile_id);
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 228, -- Grid
		in_std_factor_set_id		=> 2, -- Egrid
		in_custom_factor_set_id		=> NULL,
		in_region_sid				=> NULL,
		in_geo_country				=> 'us',
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	v_count_expected := v_count_expected + 1;
	
	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 228, -- Grid
		in_std_factor_set_id		=> 2, -- Egrid
		in_custom_factor_set_id		=> NULL,
		in_region_sid				=> NULL,
		in_geo_country				=> 'us',
		in_geo_region				=> NULL,
		in_egrid_ref				=> 'MROW');
	v_count_expected := v_count_expected + 1;
	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s), found '||v_count);

	v_applied := 1;
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile.');
	
	v_count_expected := 1;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);

	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);

	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 1, v_count, v_count_a, v_count_b);
	v_count_expected := 16;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	v_count_expected := 4;
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = v_count_expected, 'Expected '||v_count_expected||' CO2e profile factor(s) returned, found '||v_count_b);


	Trace('And unapplied...');
	v_applied := 0;
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);

	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);

	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 1, v_count, v_count_a, v_count_b);
	v_count_expected := 16;
	unit_test_pkg.AssertIsTrue(v_count = v_count_expected, 'Expected '||v_count_expected||' profile factor(s) returned, found '||v_count);
	v_count_expected := 4;
	unit_test_pkg.AssertIsTrue(v_count_a = v_count_expected, 'Expected '||v_count_expected||' CO2 profile factor(s) returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = v_count_expected, 'Expected '||v_count_expected||' CO2e profile factor(s) returned, found '||v_count_b);

	factor_pkg.DeleteEmissionProfile(v_profile_id);
	--Delete Region;
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_new_region_sid_a);

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles after delete.');
END;


PROCEDURE TestExpStdFctrWthStDtmOffst
AS
	v_count NUMBER;
	v_count_a NUMBER;
	v_count_b NUMBER;
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;

	v_cur_profile			security_pkg.T_OUTPUT_CUR;
	v_cur_factors			security_pkg.T_OUTPUT_CUR;
	v_cur_mapped			security_pkg.T_OUTPUT_CUR;

	v_cur_profile_id		emission_factor_profile.profile_id%TYPE;
	v_cur_name				emission_factor_profile.name%TYPE;
	v_cur_start_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_end_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_applied			emission_factor_profile.applied%TYPE;

	v_cm_factor_type_id							NUMBER;
	v_cm_factor_type_name						VARCHAR2(200);
	v_cm_path									VARCHAR2(200);
	v_cm_ind_sid								NUMBER;
	v_cm_ind_description						VARCHAR2(200);
	
BEGIN
	Trace('TestEFFactorExportStdFactorWithStartDateOffset');

	UPDATE customer
	   SET start_month = 4,
		   adj_factorset_startmonth = 1
	 WHERE app_sid = security.security_pkg.getapp;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles, found '||v_count);
	
	v_name := 'TestEFFactorExportStdFactorWithStartDateOffset';
	v_applied := 0;
	v_start_dtm := NULL;
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_start_dtm, v_profile_id);
	
	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_profile_id = v_profile_id, 'Expected profile id match.');
		unit_test_pkg.AssertIsTrue(v_cur_name = v_name, 'Expected profile name match.');
		unit_test_pkg.AssertIsTrue(v_cur_start_dtm = v_start_dtm, 'Expected profile start dtm match.');
		unit_test_pkg.AssertIsTrue(v_cur_end_dtm IS NULL, 'Expected null end dtm.');
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);

	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_std_factor_set_id		=> 58, -- International Energy Agency (IEA) 2015
		in_custom_factor_set_id		=> NULL,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile factor, found '||v_count);

	v_applied := 1;
	v_start_dtm := DATE '1990-01-01';
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);

	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM factor;
	unit_test_pkg.AssertIsTrue(v_count = 22, 'Expected 22 factors, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);
	
	
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 4, v_count, v_count_a, v_count_b);
	unit_test_pkg.AssertIsTrue(v_count = 22, 'Expected 22 profile factor returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = 11, 'Expected 11 CO2 profile factor returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 11, 'Expected 11 CO2e profile factors returned, found '||v_count_b);
	
	
	v_count := 0;
	LOOP
		FETCH v_cur_mapped INTO v_cm_factor_type_id, v_cm_factor_type_name, v_cm_path, v_cm_ind_sid, v_cm_ind_description;
		EXIT WHEN v_cur_mapped%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile mapped inds returned, found '||v_count);
	
	v_applied := 0;
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);
	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, 4, v_count, v_count_a, v_count_b);
	unit_test_pkg.AssertIsTrue(v_count = 22, 'Expected 22 profile factor returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = 11, 'Expected 11 CO2 profile factor returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 11, 'Expected 11 CO2e profile factors returned, found '||v_count_b);
	
	factor_pkg.DeleteEmissionProfile(v_profile_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles after delete, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile factors after delete, found '||v_count);
END;


PROCEDURE INT_TestGetAllFactors(
	in_start_month		IN	NUMBER,
	in_test_name		IN	VARCHAR2
)
AS
	v_count NUMBER;
	v_count_a NUMBER;
	v_count_b NUMBER;
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;

	v_cur_profile			security_pkg.T_OUTPUT_CUR;
	v_cur_factors			security_pkg.T_OUTPUT_CUR;
	v_cur_mapped			security_pkg.T_OUTPUT_CUR;

	v_cur_profile_id		emission_factor_profile.profile_id%TYPE;
	v_cur_name				emission_factor_profile.name%TYPE;
	v_cur_start_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_end_dtm			emission_factor_profile.start_dtm%TYPE;
	v_cur_applied			emission_factor_profile.applied%TYPE;

	v_cm_factor_type_id							NUMBER;
	v_cm_factor_type_name						VARCHAR2(200);
	v_cm_path									VARCHAR2(200);
	v_cm_ind_sid								NUMBER;
	v_cm_ind_description						VARCHAR2(200);
	
	v_period_cur			SYS_REFCURSOR;
	v_gas_cur				SYS_REFCURSOR;
	v_gc_factor_id								NUMBER;
	v_gc_factor_name							VARCHAR2(200);
	v_gc_gas_type_id							NUMBER;
	v_gc_name									VARCHAR2(200);
	v_gc_value									NUMBER;
	v_gc_note									VARCHAR2(200);
	v_gc_start_dtm								DATE;
	v_gc_end_dtm								DATE;
	v_gc_unit									VARCHAR2(200);
	v_gc_unit_id								NUMBER;
BEGIN
	Trace(in_test_name);

	unit_test_pkg.AssertIsTrue(in_start_month >= 1 AND in_start_month <=12, 'Invalid start month');
	UPDATE customer
	   SET start_month = in_start_month,
		   adj_factorset_startmonth = 1
	 WHERE app_sid = security.security_pkg.getapp;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles, found '||v_count);
	
	v_name := in_test_name;
	v_applied := 0;
	v_start_dtm := NULL;
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_start_dtm, v_profile_id);
	
	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_profile_id = v_profile_id, 'Expected profile id match.');
		unit_test_pkg.AssertIsTrue(v_cur_name = v_name, 'Expected profile name match.');
		unit_test_pkg.AssertIsTrue(v_cur_start_dtm = v_start_dtm, 'Expected profile start dtm match.');
		unit_test_pkg.AssertIsTrue(v_cur_end_dtm IS NULL, 'Expected null end dtm.');
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);

	factor_pkg.AprxSaveProfileFactor(in_profile_id	=> v_profile_id,
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_std_factor_set_id		=> 58, -- International Energy Agency (IEA) 2015
		in_custom_factor_set_id		=> NULL,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile factor, found '||v_count);

	v_applied := 1;
	v_start_dtm := DATE '1990-01-01';
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, v_start_dtm);

	factor_pkg.GetEmissionProfile(v_profile_id, v_cur_profile, v_cur_factors, v_cur_mapped);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM factor;
	unit_test_pkg.AssertIsTrue(v_count = 22, 'Expected 22 factors, found '||v_count);

	v_count := 0;
	LOOP
		FETCH v_cur_profile INTO v_cur_profile_id, v_cur_name, v_cur_start_dtm, v_cur_end_dtm, v_cur_applied;
		EXIT WHEN v_cur_profile%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.AssertIsTrue(v_cur_applied = v_applied, 'Expected profile applied match.');
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected one profile returned, found '||v_count);
	
	
	v_count := 0;
	v_count_a := 0;
	v_count_b := 0;
	CheckFactorProfileFactors(v_cur_factors, in_start_month, v_count, v_count_a, v_count_b);
	unit_test_pkg.AssertIsTrue(v_count = 22, 'Expected 22 profile factor returned, found '||v_count);
	unit_test_pkg.AssertIsTrue(v_count_a = 11, 'Expected 11 CO2 profile factor returned, found '||v_count_a);
	unit_test_pkg.AssertIsTrue(v_count_b = 11, 'Expected 11 CO2e profile factors returned, found '||v_count_b);
	
	
	factor_pkg.GetAllFactors(
		in_factor_type_id			=> 10485, -- Grid Electricity Generated - Average Load (Annual) (Direct)
		in_factor_set_id			=> 58, -- International Energy Agency (IEA) 2015
		in_country					=> NULL,
		in_region					=> NULL,
		in_region_sid				=> NULL,
		period_cur					=> v_period_cur,
		gas_cur						=> v_gas_cur);
	
	v_count := 0;
	LOOP
		FETCH v_period_cur INTO v_cur_start_dtm, v_cur_end_dtm;
		EXIT WHEN v_period_cur%NOTFOUND;
		v_count := v_count + 1;
		Trace('period '||v_cur_start_dtm||' to '||v_cur_end_dtm);
		unit_test_pkg.AssertIsTrue(EXTRACT(MONTH FROM v_cur_start_dtm) = in_start_month, 'Expected pc start month match.');
		unit_test_pkg.AssertIsTrue(EXTRACT(MONTH FROM v_cur_end_dtm) = in_start_month, 'Expected pc end month match.');
	END LOOP;
	
	v_count := 0;
	LOOP
		FETCH v_gas_cur INTO v_gc_factor_id, v_gc_factor_name, v_gc_gas_type_id, v_gc_name, v_gc_value, v_gc_note, v_gc_start_dtm, v_gc_end_dtm, v_gc_unit, v_gc_unit_id;
		EXIT WHEN v_gas_cur%NOTFOUND;
		v_count := v_count + 1;
		Trace('gas '||v_gc_factor_id||', '||v_gc_factor_name||', '||v_gc_gas_type_id||', '||v_gc_name||', '||v_gc_value||', '||v_gc_note||', '||v_gc_start_dtm||', '||v_gc_end_dtm||', '||v_gc_unit||', '||v_gc_unit_id);
		unit_test_pkg.AssertIsTrue(EXTRACT(MONTH FROM v_gc_start_dtm) = in_start_month, 'Expected gc start month match.');
		unit_test_pkg.AssertIsTrue(EXTRACT(MONTH FROM v_gc_end_dtm) = in_start_month, 'Expected gc end month match.');
	END LOOP;

	factor_pkg.DeleteEmissionProfile(v_profile_id);

	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles after delete, found '||v_count);
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile_factor;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profile factors after delete, found '||v_count);
END;


PROCEDURE TestGetAllFactorsStartMonth1
AS
BEGIN
	INT_TestGetAllFactors(1, 'TestGetAllFactorsStartMonth1');
END;

PROCEDURE TestGetAllFactorsStartMonth5
AS
BEGIN
	INT_TestGetAllFactors(5, 'TestGetAllFactorsStartMonth5');
END;


PROCEDURE CreateTestRegions
AS
	v_region_root_sid				security.security_pkg.T_SID_ID;
	v_new_region_sid_a				security.security_pkg.T_SID_ID;
	v_new_region_sid_b				security.security_pkg.T_SID_ID;
BEGIN
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary = 1;
	
	--2
	csr.region_pkg.CreateRegion(in_parent_sid => v_region_root_sid,
		in_name => 'EFTestRegEgrid_US',
		in_description => 'EFTestReg1_Egrid1_US',
		in_geo_country => 'us',
		in_geo_type => region_pkg.REGION_GEO_TYPE_COUNTRY,
		out_region_sid => v_new_region_sid_a
	);

	--3
	csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
		in_name => 'EFTestRegEgrid_Country_Egrid',
		in_description => 'EFTestRegEgrid_Country_Egrid',
		in_geo_country => 'us',
		in_egrid_ref => 'AKGD',
		in_geo_type => region_pkg.REGION_GEO_TYPE_COUNTRY,
		out_region_sid => v_new_region_sid_b
	);

	--4
	csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
		in_name => 'EFTestRegEgrid_EgridUnknown_Country',
		in_description => 'EFTestRegEgrid_EgridUnknown_Country',
		in_geo_country => 'us',
		in_egrid_ref => 'ASCC',
		in_geo_type => region_pkg.REGION_GEO_TYPE_COUNTRY,
		out_region_sid => v_new_region_sid_b
	);

	-- 5
	csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
		in_name => 'EFTestRegEgrid_Region_NoEgrid',
		in_description => 'EFTestRegEgrid_Region_NoEgrid',
		in_geo_country => 'us',
		in_geo_region => 'AZ',
		in_geo_type => region_pkg.REGION_GEO_TYPE_REGION,
		out_region_sid => v_new_region_sid_b
	);

	--6
	csr.region_pkg.CreateRegion(in_parent_sid => v_new_region_sid_a,
		in_name => 'EFTestRegEgrid_Egrid_Country',
		in_description => 'EFTestRegEgrid_Egrid_Country',
		in_geo_country => 'us',
		in_egrid_ref => 'AZNM',
		in_geo_type => region_pkg.REGION_GEO_TYPE_COUNTRY,
		out_region_sid => v_new_region_sid_b
	);
END;

PROCEDURE ValidateGlobalFactorMap(
	in_country				IN	std_factor.geo_country%TYPE,
	in_region				IN	std_factor.geo_region%TYPE,
	in_egrid_ref			IN	std_factor.egrid_ref%TYPE,
	in_region_sid			IN	region.region_sid%TYPE,
	in_fs_val_list			IN	VARCHAR2,
	in_description			IN	VARCHAR2,
	in_country_name			IN	postcode.country.country%TYPE,
	in_region_name			IN	region.name%TYPE,
	in_egrid				IN	egrid.name%TYPE
)
AS
BEGIN
	unit_test_pkg.AssertIsNull(in_country, 'v_country');
	unit_test_pkg.AssertIsNull(in_region, 'v_region');
	unit_test_pkg.AssertIsNull(in_egrid_ref, 'v_egrid_ref');
	unit_test_pkg.AssertIsNull(in_region_sid, 'v_region_sid');
	unit_test_pkg.AssertIsNull(in_fs_val_list, 'v_fs_val_list');
	unit_test_pkg.AssertIsTrue(in_description = 'Global', 'Expected Global, found '||in_description);
	unit_test_pkg.AssertIsNull(in_country_name, 'v_country_name');
	unit_test_pkg.AssertIsNull(in_region_name, 'v_region_name');
	unit_test_pkg.AssertIsNull(in_egrid, 'v_egrid');
END;

PROCEDURE ValidateEmptyFactorType(
	in_factor_type_id		IN	std_factor.factor_type_id%TYPE,
	in_factor_type_name		IN	factor_type.name%TYPE
)
AS
BEGIN
	unit_test_pkg.AssertIsNull(in_factor_type_id, 'v_factor_type_id');
	unit_test_pkg.AssertIsNull(in_factor_type_name, 'v_factor_type_name');
END;

PROCEDURE ValidateFactorType(
	in_expected_ft_id		IN	std_factor.factor_type_id%TYPE,
	in_expected_ft_name		IN	factor_type.name%TYPE,
	in_factor_type_id		IN	std_factor.factor_type_id%TYPE,
	in_factor_type_name		IN	factor_type.name%TYPE
)
AS
BEGIN
	unit_test_pkg.AssertIsTrue(in_factor_type_id = in_expected_ft_id, 'Expected '||in_expected_ft_id||', found '||in_factor_type_id);
	unit_test_pkg.AssertIsTrue(in_factor_type_name = in_expected_ft_name, 'Expected '||in_expected_ft_name||', found '||in_factor_type_name);
END;

PROCEDURE ValidateEmptyFactorSet(
	in_factor_set_id		IN	std_factor_set.std_factor_set_id%TYPE,
	in_factor_set_name		IN	std_factor_set.name%TYPE
)
AS
BEGIN
	unit_test_pkg.AssertIsNull(in_factor_set_id, 'v_factor_set_id');
	unit_test_pkg.AssertIsNull(in_factor_set_name, 'v_factor_set_name');
END;

PROCEDURE ValidateFactorSet(
	in_expected_fs_id		IN	std_factor_set.std_factor_set_id%TYPE,
	in_expected_fs_name		IN	std_factor_set.name%TYPE,
	in_factor_set_id		IN	std_factor_set.std_factor_set_id%TYPE,
	in_factor_set_name		IN	std_factor_set.name%TYPE
)
AS
BEGIN
	unit_test_pkg.AssertIsTrue(in_factor_set_id = in_expected_fs_id, 'Expected '||in_expected_fs_id||', found '||in_factor_set_id);
	unit_test_pkg.AssertIsTrue(in_factor_set_name = in_expected_fs_name, 'Expected '||in_expected_fs_name||', found '||in_factor_set_name);
END;

PROCEDURE TestRegionFactorsMap(
	in_custom IN NUMBER,
	in_count IN NUMBER,
	in_expected_ft_id IN NUMBER,
	in_expected_ft_name IN VARCHAR2,
	in_expected_fs_id IN NUMBER,
	in_expected_fs_name IN VARCHAR2,
	in_factor_set_id IN NUMBER,
	in_factor_set_name IN VARCHAR2,
	in_factor_type_id IN NUMBER,
	in_factor_type_name IN VARCHAR2,
	in_country IN VARCHAR2,
	in_region IN VARCHAR2,
	in_egrid_ref IN VARCHAR2,
	in_region_sid IN NUMBER,
	in_fs_val_list IN VARCHAR2,
	in_description IN VARCHAR2,
	in_country_name IN VARCHAR2,
	in_region_name IN VARCHAR2,
	in_egrid IN VARCHAR2
)
AS
BEGIN
	unit_test_pkg.AssertIsNull(in_region_sid, 'v_region_sid');

	IF in_count = 1 THEN
		ValidateGlobalFactorMap(
			in_country => in_country,
			in_region => in_region,
			in_egrid_ref => in_egrid_ref,
			in_region_sid => in_region_sid,
			in_fs_val_list => in_fs_val_list,
			in_description => in_description,
			in_country_name => in_country_name,
			in_region_name => in_region_name,
			in_egrid => in_egrid
		);
		ValidateFactorType(
			in_expected_ft_id => in_expected_ft_id,
			in_expected_ft_name => in_expected_ft_name,
			in_factor_type_id => in_factor_type_id,
			in_factor_type_name => in_factor_type_name
		);
		ValidateFactorSet(
			in_expected_fs_id => in_expected_fs_id,
			in_expected_fs_name => in_expected_fs_name,
			in_factor_set_id => in_factor_set_id,
			in_factor_set_name => in_factor_set_name
		);
	END IF;

	IF in_country = 'us' THEN
		unit_test_pkg.AssertIsTrue(in_country = 'us', 'Expected us, found '||in_country);

		IF in_egrid_ref IS NULL AND in_region IS NULL THEN
			unit_test_pkg.AssertIsNull(in_region, 'v_region');
			unit_test_pkg.AssertIsNull(in_egrid_ref, 'v_egrid_ref');
			IF in_custom = 0 THEN
				unit_test_pkg.AssertAreEqual(in_fs_val_list, 'CO2: 1299.53 lb/MWh, CO2e: 1306.18 lb/MWh, CH4:  0.02514 lb/MWh, N2O:  0.01974 lb/MWh', 'v_fs_val_list');
			ELSE
				unit_test_pkg.AssertIsNull(in_fs_val_list, 'in_fs_val_list');
			END IF;
			unit_test_pkg.AssertAreEqual(in_description, 'United States of America (the)', 'Expected United States of America (the), found '||in_description);
			unit_test_pkg.AssertAreEqual(in_country_name, 'United States of America (the)', 'Expected United States of America (the), found '||in_country_name);
			unit_test_pkg.AssertIsNull(in_region_name, 'v_region_name');
			unit_test_pkg.AssertIsNull(in_egrid, 'v_egrid');
		END IF;

		IF in_egrid_ref = 'AKGD' THEN
			unit_test_pkg.AssertIsNull(in_region, 'v_region');
			unit_test_pkg.AssertAreEqual(in_egrid_ref, 'AKGD', 'Expected AKGD, found '||in_egrid_ref);
			IF in_custom = 0 THEN
				unit_test_pkg.AssertAreEqual(in_fs_val_list, 'CO2: 1284.72 lb/MWh, CO2e: 1287.6 lb/MWh, CH4:  0.02711 lb/MWh, N2O:  0.00744 lb/MWh', 'v_fs_val_list');
			ELSE
				unit_test_pkg.AssertIsNull(in_fs_val_list, 'in_fs_val_list');
			END IF;
			unit_test_pkg.AssertAreEqual(in_description, 'ASCC Alaska Grid', 'Expected ASCC Alaska Grid, found '||in_description);
			unit_test_pkg.AssertAreEqual(in_country_name, 'United States of America (the)', 'Expected United States of America (the), found '||in_country_name);
			unit_test_pkg.AssertIsNull(in_region_name, 'v_region_name');
			unit_test_pkg.AssertAreEqual(in_egrid, 'ASCC Alaska Grid', 'Expected ASCC Alaska Grid, found '||in_egrid);
		END IF;

		IF in_egrid_ref = 'ASCC' THEN
			unit_test_pkg.AssertIsNull(in_region, 'v_region');
			unit_test_pkg.AssertAreEqual(in_egrid_ref, 'ASCC', 'Expected ASCC, found '||in_egrid_ref);
			unit_test_pkg.AssertIsNull(in_fs_val_list, 'in_fs_val_list');
			unit_test_pkg.AssertAreEqual(in_description, 'ASCC - Subregion unknown', 'Expected ASCC - Subregion unknown, found '||in_description);
			unit_test_pkg.AssertAreEqual(in_country_name, 'United States of America (the)', 'Expected United States of America (the), found '||in_country_name);
			unit_test_pkg.AssertIsNull(in_region_name, 'v_region_name');
			unit_test_pkg.AssertAreEqual(in_egrid, 'ASCC - Subregion unknown', 'Expected ASCC - Subregion unknown, found '||in_egrid);
		END IF;

		IF in_egrid_ref = 'AZNM' THEN
			unit_test_pkg.AssertIsNull(in_region, 'v_region');
			unit_test_pkg.AssertAreEqual(in_egrid_ref, 'AZNM', 'Expected AZNM, found '||in_egrid_ref);
			IF in_custom = 0 THEN
				unit_test_pkg.AssertAreEqual(in_fs_val_list, 'CO2: 1252.61 lb/MWh, CO2e: 1258.14 lb/MWh, CH4:  0.0188 lb/MWh, N2O:  0.01657 lb/MWh', 'v_fs_val_list');
			ELSE
				unit_test_pkg.AssertIsNull(in_fs_val_list, 'in_fs_val_list');
			END IF;
			unit_test_pkg.AssertAreEqual(in_description, 'WECC Southwest', 'Expected WECC Southwest, found '||in_description);
			unit_test_pkg.AssertAreEqual(in_country_name, 'United States of America (the)', 'Expected United States of America (the), found '||in_country_name);
			unit_test_pkg.AssertIsNull(in_region_name, 'v_region_name');
			unit_test_pkg.AssertAreEqual(in_egrid, 'WECC Southwest', 'Expected WECC Southwest, found '||in_egrid);
		END IF;

		IF in_egrid_ref IS NULL AND in_region = 'AZ' THEN
			unit_test_pkg.AssertAreEqual(in_region, 'AZ', 'Expected AZ, found '||in_region);
			unit_test_pkg.AssertIsNull(in_egrid_ref, 'v_egrid_ref');
			unit_test_pkg.AssertIsNull(in_fs_val_list, 'in_fs_val_list');
			unit_test_pkg.AssertAreEqual(in_description, 'Arizona', 'Expected Arizona, found '||in_description);
			unit_test_pkg.AssertAreEqual(in_country_name, 'United States of America (the)', 'Expected United States of America (the), found '||in_country_name);
			unit_test_pkg.AssertAreEqual(in_region_name, 'Arizona', 'Expected Arizona, found '||in_region_name);
			unit_test_pkg.AssertIsNull(in_egrid, 'v_egrid');
		END IF;
		Trace('**in_fs_val_list is '||in_fs_val_list);
	END IF;
END;

PROCEDURE TestGetRegionFactorsMapStd
AS
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;

	v_region_count		NUMBER := 0;
	v_count				NUMBER := 0;
	v_cur				SYS_REFCURSOR;

	v_factor_type_id	std_factor.factor_type_id%TYPE;
	v_factor_type_name	factor_type.name%TYPE;
	v_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_factor_set_name	std_factor_set.name%TYPE;
	v_country			std_factor.geo_country%TYPE;
	v_region			std_factor.geo_region%TYPE;
	v_egrid_ref			std_factor.egrid_ref%TYPE;
	v_region_sid		region.region_sid%TYPE;
	v_fs_val_list		VARCHAR2(4000);
	v_description		VARCHAR2(1000);
	v_custom			NUMBER;
	v_country_name		postcode.country.name%TYPE;
	v_region_name		region.name%TYPE;
	v_egrid				egrid.name%TYPE;

BEGIN
	Trace('TestGetRegionFactorsMapStd');
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles, found '||v_count);
	
	SELECT COUNT(*)
	  INTO v_region_count
	  FROM v$region
	 WHERE geo_country IS NOT NULL
	   AND geo_type = region_pkg.REGION_GEO_TYPE_COUNTRY;

	v_name := 'TestGetRegionFactorsMapStd';
	v_applied := 0;
	v_start_dtm := NULL;
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_start_dtm, v_profile_id);

	v_factor_type_id := 228; -- Grid
	factor_pkg.GetRegionsFactorsMap(0, v_factor_type_id, v_factor_set_id, v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur INTO v_factor_type_id, v_factor_type_name, v_factor_set_id, v_factor_set_name, v_country, v_region, v_egrid_ref, v_region_sid, v_fs_val_list, v_description, v_custom, v_country_name, v_region_name, v_egrid;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
		Trace('F '||v_factor_type_id||', '||v_factor_type_name||', '||v_factor_set_id||', '||v_factor_set_name||', '||v_country||', '||v_region||', '||v_egrid_ref||', '||v_region_sid||', '||v_fs_val_list||', '||v_description||', '||v_custom||', '||v_country_name||', '||v_region_name||', '||v_egrid);
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1+v_region_count, 'Expected 1+'|| v_region_count ||', found '||v_count);
	unit_test_pkg.AssertIsTrue(v_custom = 0, 'v_custom');
	ValidateGlobalFactorMap(
		in_country => v_country,
		in_region => v_region,
		in_egrid_ref => v_egrid_ref,
		in_region_sid => v_region_sid,
		in_fs_val_list => v_fs_val_list,
		in_description => v_description,
		in_country_name => v_country_name,
		in_region_name => v_region_name,
		in_egrid => v_egrid
	);
	ValidateFactorType(
		in_expected_ft_id => 228,
		in_expected_ft_name => 'Grid',
		in_factor_type_id => v_factor_type_id,
		in_factor_type_name => v_factor_type_name
	);
	ValidateEmptyFactorSet(
		in_factor_set_id => v_factor_set_id,
		in_factor_set_name => v_factor_set_name
	);

	
	v_factor_set_id := 2;-- US Environmental Protection Agency eGRID
	factor_pkg.GetRegionsFactorsMap(v_profile_id, v_factor_type_id, v_factor_set_id, v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur INTO v_factor_type_id, v_factor_type_name, v_factor_set_id, v_factor_set_name, v_country, v_region, v_egrid_ref, v_region_sid, v_fs_val_list, v_description, v_custom, v_country_name, v_region_name, v_egrid;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
		Trace('F'||v_count||': ft:'||v_factor_type_id||', fn:'||v_factor_type_name||', fs:'||v_factor_set_id||', fn:'||v_factor_set_name||', c:'||v_country||', r:'||v_region||', egridref:'||v_egrid_ref||', rsid:'||v_region_sid||', val:'||v_fs_val_list||', desc:'||v_description||', cust:'||v_custom||', cn:'||v_country_name||', rn:'||v_region_name||', egrid:'||v_egrid);

		IF v_description = 'Global' THEN
			ValidateGlobalFactorMap(
				in_country => v_country,
				in_region => v_region,
				in_egrid_ref => v_egrid_ref,
				in_region_sid => v_region_sid,
				in_fs_val_list => v_fs_val_list,
				in_description => v_description,
				in_country_name => v_country_name,
				in_region_name => v_region_name,
				in_egrid => v_egrid
			);
			ValidateFactorType(
				in_expected_ft_id => 228,
				in_expected_ft_name => 'Grid',
				in_factor_type_id => v_factor_type_id,
				in_factor_type_name => v_factor_type_name
			);
			ValidateFactorSet(
				in_expected_fs_id => 2,
				in_expected_fs_name => 'US Environmental Protection Agency eGRID',
				in_factor_set_id => v_factor_set_id,
				in_factor_set_name => v_factor_set_name
			);
		END IF;

	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1+v_region_count, 'Expected 1+'|| v_region_count ||', found '||v_count);
	unit_test_pkg.AssertIsTrue(v_custom = 0, 'v_custom');

	-- Add a region with an egrid.
	/*
	REGION_GEO_TYPE_LOCATION	CONSTANT NUMBER(2) := 0;
	REGION_GEO_TYPE_COUNTRY		CONSTANT NUMBER(2) := 1;
	REGION_GEO_TYPE_MAP_ENTITY	CONSTANT NUMBER(2) := 2;
	REGION_GEO_TYPE_REGION		CONSTANT NUMBER(2) := 3;
	REGION_GEO_TYPE_CITY		CONSTANT NUMBER(2) := 4;
	REGION_GEO_TYPE_OTHER		CONSTANT NUMBER(2) := 5;
	REGION_GEO_TYPE_INHERITED	CONSTANT NUMBER(2) := 6;
	*/
	Trace('With regions');
	CreateTestRegions();

	factor_pkg.GetRegionsFactorsMap(v_profile_id, v_factor_type_id, v_factor_set_id, v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur INTO v_factor_type_id, v_factor_type_name, v_factor_set_id, v_factor_set_name, v_country, v_region, v_egrid_ref, v_region_sid, v_fs_val_list, v_description, v_custom, v_country_name, v_region_name, v_egrid;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
		Trace('F'||v_count||': ft:'||v_factor_type_id||', fn:'||v_factor_type_name||', fs:'||v_factor_set_id||', fn:'||v_factor_set_name||', c:'||v_country||', r:'||v_region||', egridref:'||v_egrid_ref||', rsid:'||v_region_sid||', val:'||v_fs_val_list||', desc:'||v_description||', cust:'||v_custom||', cn:'||v_country_name||', rn:'||v_region_name||', egrid:'||v_egrid);

		unit_test_pkg.AssertIsTrue(v_custom = 0, 'v_custom');
		
		TestRegionFactorsMap(
			in_custom => 0,
			in_count => v_count, 
			in_expected_ft_id => 228,
			in_expected_ft_name => 'Grid',
			in_expected_fs_id => 2,
			in_expected_fs_name => 'US Environmental Protection Agency eGRID',
			in_factor_set_id => v_factor_set_id,
			in_factor_set_name => v_factor_set_name,
			in_factor_type_id => v_factor_type_id,
			in_factor_type_name => v_factor_type_name,
			in_country => v_country,
			in_region => v_region,
			in_egrid_ref => v_egrid_ref,
			in_region_sid => v_region_sid,
			in_fs_val_list => v_fs_val_list,
			in_description => v_description,
			in_country_name => v_country_name,
			in_region_name => v_region_name,
			in_egrid => v_egrid
		);

	END LOOP;
	--unit_test_pkg.AssertIsTrue(v_count = 6+v_region_count, 'Expected 6+'|| v_region_count ||', found '||v_count);

	factor_pkg.DeleteEmissionProfile(v_profile_id);

	FOR r IN (SELECT region_sid FROM csr.region WHERE name like 'EFTestRegEgrid%')
	LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, r.region_sid);
	END LOOP;
END;


PROCEDURE TestGetRegionFactorsMapCustom
AS
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;

	v_count				NUMBER := 0;
	v_region_count		NUMBER := 0;
	v_cur				SYS_REFCURSOR;

	v_factor_type_id	std_factor.factor_type_id%TYPE;
	v_factor_type_name	factor_type.name%TYPE;
	v_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_factor_set_name	std_factor_set.name%TYPE;
	v_country			std_factor.geo_country%TYPE;
	v_region			std_factor.geo_region%TYPE;
	v_egrid_ref			std_factor.egrid_ref%TYPE;
	v_region_sid		region.region_sid%TYPE;
	v_fs_val_list		VARCHAR2(4000);
	v_description		VARCHAR2(1000);
	v_custom			NUMBER;
	v_country_name		postcode.country.name%TYPE;
	v_region_name		region.name%TYPE;
	v_egrid				egrid.name%TYPE;

	v_region_root_sid				security.security_pkg.T_SID_ID;
	v_new_region_sid_a				security.security_pkg.T_SID_ID;
	v_new_region_sid_b				security.security_pkg.T_SID_ID;

BEGIN
	Trace('TestGetRegionFactorsMapCustom');
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected no profiles, found '||v_count);
	
	SELECT COUNT(*)
	  INTO v_region_count
	  FROM v$region
	 WHERE geo_country IS NOT NULL
	   AND geo_type = region_pkg.REGION_GEO_TYPE_COUNTRY;
	
	v_name := 'TestGetRegionFactorsMapCustom';
	v_applied := 0;
	v_start_dtm := NULL;
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_start_dtm, v_profile_id);

	v_factor_type_id := 228; -- Grid
	factor_pkg.GetRegionsFactorsMap(0, v_factor_type_id, v_factor_set_id, v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur INTO v_factor_type_id, v_factor_type_name, v_factor_set_id, v_factor_set_name, v_country, v_region, v_egrid_ref, v_region_sid, v_fs_val_list, v_description, v_custom, v_country_name, v_region_name, v_egrid;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
		Trace('F '||v_factor_type_id||', '||v_factor_type_name||', '||v_factor_set_id||', '||v_factor_set_name||', '||v_country||', '||v_region||', '||v_egrid_ref||', '||v_region_sid||', '||v_fs_val_list||', '||v_description||', '||v_custom||', '||v_country_name||', '||v_region_name||', '||v_egrid);
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1+v_region_count, 'Expected 1+'|| v_region_count ||', found '||v_count);
	unit_test_pkg.AssertIsTrue(v_custom = 0, 'v_custom');
	ValidateGlobalFactorMap(
		in_country => v_country,
		in_region => v_region,
		in_egrid_ref => v_egrid_ref,
		in_region_sid => v_region_sid,
		in_fs_val_list => v_fs_val_list,
		in_description => v_description,
		in_country_name => v_country_name,
		in_region_name => v_region_name,
		in_egrid => v_egrid
	);
	ValidateFactorType(
		in_expected_ft_id => 228,
		in_expected_ft_name => 'Grid',
		in_factor_type_id => v_factor_type_id,
		in_factor_type_name => v_factor_type_name
	);
	ValidateEmptyFactorSet(
		in_factor_set_id => v_factor_set_id,
		in_factor_set_name => v_factor_set_name
	);

	
	SELECT COUNT(*)
	  INTO v_region_count
	  FROM v$region
	 WHERE geo_country IS NOT NULL
	   AND geo_type = region_pkg.REGION_GEO_TYPE_COUNTRY;

	v_factor_set_id := factor_pkg.CreateCustomFactorSet(v_name, 0);

	factor_pkg.GetRegionsFactorsMap(v_profile_id, v_factor_type_id, v_factor_set_id, v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur INTO v_factor_type_id, v_factor_type_name, v_factor_set_id, v_factor_set_name, v_country, v_region, v_egrid_ref, v_region_sid, v_fs_val_list, v_description, v_custom, v_country_name, v_region_name, v_egrid;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
		Trace('F'||v_count||': ft:'||v_factor_type_id||', fn:'||v_factor_type_name||', fs:'||v_factor_set_id||', fn:'||v_factor_set_name||', c:'||v_country||', r:'||v_region||', egridref:'||v_egrid_ref||', rsid:'||v_region_sid||', val:'||v_fs_val_list||', desc:'||v_description||', cust:'||v_custom||', cn:'||v_country_name||', rn:'||v_region_name||', egrid:'||v_egrid);

		IF v_description = 'Global' THEN
			ValidateGlobalFactorMap(
				in_country => v_country,
				in_region => v_region,
				in_egrid_ref => v_egrid_ref,
				in_region_sid => v_region_sid,
				in_fs_val_list => v_fs_val_list,
				in_description => v_description,
				in_country_name => v_country_name,
				in_region_name => v_region_name,
				in_egrid => v_egrid
			);
			ValidateFactorType(
				in_expected_ft_id => 228,
				in_expected_ft_name => 'Grid',
				in_factor_type_id => v_factor_type_id,
				in_factor_type_name => v_factor_type_name
			);
			ValidateFactorSet(
				in_expected_fs_id => v_factor_set_id,
				in_expected_fs_name => 'TestGetRegionFactorsMapCustom',
				in_factor_set_id => v_factor_set_id,
				in_factor_set_name => v_factor_set_name
			);
		END IF;

	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1+v_region_count, 'Expected 1+'|| v_region_count ||', found '||v_count);
	unit_test_pkg.AssertIsTrue(v_custom = 1, 'v_custom');

	-- Add a region with an egrid.
	Trace('With regions');
	CreateTestRegions();

	factor_pkg.GetRegionsFactorsMap(v_profile_id, v_factor_type_id, v_factor_set_id, v_cur);
	v_count := 0;
	LOOP
		FETCH v_cur INTO v_factor_type_id, v_factor_type_name, v_factor_set_id, v_factor_set_name, v_country, v_region, v_egrid_ref, v_region_sid, v_fs_val_list, v_description, v_custom, v_country_name, v_region_name, v_egrid;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
		Trace('F'||v_count||': ft:'||v_factor_type_id||', fn:'||v_factor_type_name||', fs:'||v_factor_set_id||', fn:'||v_factor_set_name||', c:'||v_country||', r:'||v_region||', egridref:'||v_egrid_ref||', rsid:'||v_region_sid||', val:'||v_fs_val_list||', desc:'||v_description||', cust:'||v_custom||', cn:'||v_country_name||', rn:'||v_region_name||', egrid:'||v_egrid);

		unit_test_pkg.AssertIsTrue(v_custom = 1, 'v_custom');
		unit_test_pkg.AssertIsNull(v_region_sid, 'v_region_sid');

		TestRegionFactorsMap(
			in_custom => 1,
			in_count => v_count, 
			in_expected_ft_id => 228,
			in_expected_ft_name => 'Grid',
			in_expected_fs_id => v_factor_set_id,
			in_expected_fs_name => 'TestGetRegionFactorsMapCustom',
			in_factor_set_id => v_factor_set_id,
			in_factor_set_name => v_factor_set_name,
			in_factor_type_id => v_factor_type_id,
			in_factor_type_name => v_factor_type_name,
			in_country => v_country,
			in_region => v_region,
			in_egrid_ref => v_egrid_ref,
			in_region_sid => v_region_sid,
			in_fs_val_list => v_fs_val_list,
			in_description => v_description,
			in_country_name => v_country_name,
			in_region_name => v_region_name,
			in_egrid => v_egrid
		);

	END LOOP;
	
	--unit_test_pkg.AssertIsTrue(v_count = 6+v_region_count, 'Expected 1+'|| v_region_count ||', found '||v_count);

	factor_pkg.DeleteEmissionProfile(v_profile_id);

	FOR r IN (SELECT region_sid FROM csr.region WHERE name like 'EFTestRegEgrid%')
	LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, r.region_sid);
	END LOOP;
END;

PROCEDURE TestCanCreateAndGetStdFactorSet
AS
	v_cur					SYS_REFCURSOR;
	v_std_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_varchar_note			VARCHAR2(32767);
	-- FactorSetGroup out cur
	v_factor_set_group_id	factor_set_group.factor_set_group_id%TYPE;
	v_name					factor_set_group.name%TYPE;
	v_custom				factor_set_group.custom%TYPE;	
	-- GetFactorSetsForGroup out cur
	v_factor_set_id			std_factor_set.std_factor_set_id%TYPE;
	-- v_factor_set_group_id	std_factor_set.factor_set_group_id%TYPE;
	v_factor_set_name		std_factor_set.name%TYPE;
	v_created_by_sid		std_factor_set.created_by_sid%TYPE;
	v_created_by			csr_user.full_name%TYPE;
	v_created_dtm			std_factor_set.created_dtm%TYPE;
	v_info_note				std_factor_set.info_note%TYPE;
	v_is_published			std_factor_set.published%TYPE;
	v_published_by_sid		std_factor_set.published_by_sid%TYPE;
	v_published_by			csr_user.full_name%TYPE;
	v_published_dtm			std_factor_set.published_dtm%TYPE;
	v_is_visible			NUMBER(1);
	v_is_custom				NUMBER(1);
	v_profile				VARCHAR2(5000);
	v_order_by1				VARCHAR2(5000);
	v_order_by2				VARCHAR2(5000);
	v_order_by3				VARCHAR2(5000);
	v_order_by4				VARCHAR2(5000);
BEGIN
	Trace('TestCanCreateAndGetStdFactorSet');
	
	factor_set_group_pkg.SaveFactorSetGroup(
		in_factor_set_group_id	=> NULL,
		in_name					=> 'TestCanCreateAndGetStdFactorSet Profile',
		in_custom				=> 0,
		out_factor_set_group	=> v_cur
	);
	
	FETCH v_cur INTO v_factor_set_group_id, v_name, v_custom;
	
	v_std_factor_set_id := factor_pkg.CreateStdFactorSet(
		in_name						=> 'New Std Factor Set',
		in_factor_set_group_id		=> v_factor_set_group_id,
		in_info_note				=> 'A new std factor set with a info note'
	);
	
	factor_set_group_pkg.GetFactorSetsForGroup(
		in_factor_set_group_id		=> v_factor_set_group_id,
		out_cur						=> v_cur
	);
	
	FETCH v_cur INTO v_factor_set_id, v_factor_set_group_id, v_factor_set_name, v_created_by_sid, v_created_by, v_created_dtm,
		v_info_note, v_is_published, v_published_by_sid, v_published_by, v_published_dtm, v_is_visible, v_is_custom, v_profile,
		v_order_by1, v_order_by2, v_order_by3, v_order_by4;
	
	v_varchar_note := SUBSTR(v_info_note, 1, 32767);
	
	unit_test_pkg.AssertAreEqual(v_std_factor_set_id, v_factor_set_id, 'Incorrect Id');
	unit_test_pkg.AssertAreEqual('New Std Factor Set', v_factor_set_name, 'Incorrect name');
	unit_test_pkg.AssertAreEqual('A new std factor set with a info note', v_varchar_note, 'Incorrect note');
END;

PROCEDURE TestCanCreateAndGetCustFactorSet
AS
	v_cur					SYS_REFCURSOR;
	v_cust_factor_set_id	custom_factor_set.custom_factor_set_id%TYPE;
	v_varchar_note			VARCHAR2(32767);
	-- FactorSetGroup out cur
	v_factor_set_group_id	factor_set_group.factor_set_group_id%TYPE;
	v_name					factor_set_group.name%TYPE;
	v_custom				factor_set_group.custom%TYPE;		
	-- GetFactorSetsForGroup out cur
	v_factor_set_id			custom_factor_set.custom_factor_set_id%TYPE;
	-- v_factor_set_group_id	custom_factor_set.factor_set_group_id%TYPE;
	v_factor_set_name		custom_factor_set.name%TYPE;
	v_created_by_sid		custom_factor_set.created_by_sid%TYPE;
	v_created_by			csr_user.full_name%TYPE;
	v_created_dtm			custom_factor_set.created_dtm%TYPE;
	v_info_note				custom_factor_set.info_note%TYPE;
	v_is_published			std_factor_set.published%TYPE;
	v_published_by_sid		std_factor_set.published_by_sid%TYPE;
	v_published_by			csr_user.full_name%TYPE;
	v_published_dtm			std_factor_set.published_dtm%TYPE;
	v_is_visible			NUMBER(1);
	v_is_custom				NUMBER(1);
	v_profile				VARCHAR2(5000);
	v_order_by1				VARCHAR2(5000);
	v_order_by2				VARCHAR2(5000);
	v_order_by3				VARCHAR2(5000);
	v_order_by4				VARCHAR2(5000);
BEGIN
	Trace('TestCanCreateAndGetCustFactorSet');
	
	factor_set_group_pkg.SaveFactorSetGroup(
		in_factor_set_group_id	=> NULL,
		in_name					=> 'TestCanCreateAndGetCustFactorSet Profile',
		in_custom				=> 1,
		out_factor_set_group	=> v_cur
	);
	
	FETCH v_cur INTO v_factor_set_group_id, v_name, v_custom;
	
	v_cust_factor_set_id := factor_pkg.CreateCustomFactorSet(
		in_name						=> 'New Custom Factor Set',
		in_factor_set_group_id		=> v_factor_set_group_id,
		in_info_note				=> 'A new custom factor set with a info note'
	);
	
	factor_set_group_pkg.GetFactorSetsForGroup(
		in_factor_set_group_id		=> v_factor_set_group_id,
		out_cur						=> v_cur
	);
	
	FETCH v_cur INTO v_factor_set_id, v_factor_set_group_id, v_factor_set_name, v_created_by_sid, v_created_by, v_created_dtm,
		v_info_note, v_is_published, v_published_by_sid, v_published_by, v_published_dtm, v_is_visible, v_is_custom, v_profile,
		v_order_by1, v_order_by2, v_order_by3, v_order_by4;
	
	v_varchar_note := SUBSTR(v_info_note, 1, 32767);
	
	unit_test_pkg.AssertAreEqual(v_cust_factor_set_id, v_factor_set_id, 'Incorrect Id');
	unit_test_pkg.AssertAreEqual('New Custom Factor Set', v_factor_set_name, 'Incorrect name');
	unit_test_pkg.AssertAreEqual('A new custom factor set with a info note', v_varchar_note, 'Incorrect note');
END;

PROCEDURE TestCanCreateAndGetFactorType
AS
	v_cur					SYS_REFCURSOR;
	v_parent_id				factor_type.factor_type_id%TYPE;
	v_varchar_note			VARCHAR2(32767);
	v_capability_sid		security.security_pkg.T_SID_ID;
	
	-- Factor type out cur
	v_factor_type_id		factor_type.factor_type_id%TYPE;
	-- v_parent_id				security.security_pkg.T_SID_ID;
	v_name					factor_type.name%TYPE;	
	v_info_note				factor_type.info_note%TYPE;	
	v_level					NUMBER;
	v_is_leaf				NUMBER(1);
	v_is_match				NUMBER(1);
	v_std_measure_id		security.security_pkg.T_SID_ID;
	v_mapped				NUMBER(1);
	v_enabled				NUMBER(1);
	v_visible				NUMBER(1,0);
BEGIN
	Trace('TestCanCreateAndGetFactorType');	
	BEGIN
		security.securableobject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY','ACT'), 
			security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities'), 
			security.class_pkg.GetClassId('CSRCapability'),
			'Can import std factor set',
			v_capability_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	BEGIN
		security.securableobject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY','ACT'), 
			security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities'), 
			security.class_pkg.GetClassId('CSRCapability'),
			'Can delete factor type',
			v_capability_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	SELECT factor_type_id
	  INTO v_parent_id
	  FROM factor_type
	 WHERE parent_id IS NULL;
	
	factor_pkg.AddFactorType(
		in_parent_id			=> v_parent_id,
		in_name					=> 'TestCanCreateAndGetFactorType',
		in_std_measure_id		=> 1,
		in_egrid				=> 0,
		in_enabled				=> 1,
		in_info_note			=> 'A new factor type info note'
	);
	
	factor_pkg.GetTreeWithDepth(
		in_act_id				=> security.security_pkg.GetACT,
		in_parent_sid			=> v_parent_id,
		in_include_root			=> 1,
		in_fetch_depth			=> 10,
		in_display_used_only	=> 0,
		in_display_active_only	=> 0,
		in_display_mapped_only	=> 0,
		in_display_disabled		=> 0,
		out_cur					=> v_cur
	);
	
	LOOP
		FETCH v_cur INTO v_factor_type_id, v_parent_id, v_name, v_info_note, v_level, v_is_leaf, v_is_match, v_std_measure_id, v_mapped, v_enabled, v_visible;
		EXIT WHEN v_name = 'TestCanCreateAndGetFactorType' OR v_cur%notfound;
	END LOOP;
	
	v_varchar_note := SUBSTR(v_info_note, 1, 32767);
	
	unit_test_pkg.AssertAreEqual('TestCanCreateAndGetFactorType', v_name, 'Incorrect name');
	unit_test_pkg.AssertAreEqual('A new factor type info note', v_varchar_note, 'Incorrect note');
	
	factor_pkg.DisableFactorType(v_factor_type_id);
	factor_pkg.DeleteFactorType(v_factor_type_id);
END;

PROCEDURE TestCanCreateAndGetFactorTypeList
AS
	v_cur					SYS_REFCURSOR;
	v_parent_id				factor_type.factor_type_id%TYPE;
	v_ft_id					factor_type.factor_type_id%TYPE;
	v_varchar_note			VARCHAR2(32767);
	v_capability_sid		security.security_pkg.T_SID_ID;
	
	-- Factor type out cur
	v_factor_type_id		factor_type.factor_type_id%TYPE;
	v_path					VARCHAR2(2000);
	v_name					factor_type.name%TYPE;
	v_info_note				factor_type.info_note%TYPE;
	v_level					NUMBER;
	v_is_leaf				NUMBER(1);
	v_is_match				NUMBER(1);
	v_std_measure_id		security.security_pkg.T_SID_ID;
	v_mapped				NUMBER(1);
	v_enabled				NUMBER(1);
	v_visible				NUMBER(1,0);
BEGIN
	Trace('TestCanCreateAndGetFactorTypeList');
	BEGIN
		security.securableobject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY','ACT'), 
			security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities'), 
			security.class_pkg.GetClassId('CSRCapability'),
			'Can import std factor set',
			v_capability_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	BEGIN
		security.securableobject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY','ACT'), 
			security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities'), 
			security.class_pkg.GetClassId('CSRCapability'),
			'Can delete factor type',
			v_capability_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	SELECT factor_type_id
	  INTO v_parent_id
	  FROM factor_type
	 WHERE parent_id IS NULL;

	factor_pkg.AddFactorType(
		in_parent_id			=> v_parent_id,
		in_name					=> 'TestCanCreateAndGetFactorTypeList',
		in_std_measure_id		=> 1,
		in_egrid				=> 0,
		in_enabled				=> 1,
		in_info_note			=> 'A new factor type info note'
	);

	SELECT factor_type_id
	  INTO v_ft_id
	  FROM factor_type
	 WHERE name = 'TestCanCreateAndGetFactorTypeList';

	factor_pkg.GetList(
		in_act_id				=> security.security_pkg.GetACT,
		in_root_sid				=> v_ft_id,
		in_include_root			=> 1,
		in_limit				=> 10,
		in_display_used_only	=> 0,
		in_display_active_only	=> 0,
		in_display_mapped_only	=> 0,
		in_display_disabled		=> 0,
		out_cur					=> v_cur
	);

	LOOP
		FETCH v_cur INTO v_factor_type_id, v_parent_id, v_name, v_level, v_is_leaf, v_is_match, v_path, v_std_measure_id, v_mapped, v_enabled, v_info_note, v_visible;
		EXIT WHEN v_name = 'TestCanCreateAndGetFactorTypeList' OR v_cur%notfound;
	END LOOP;

	v_varchar_note := SUBSTR(v_info_note, 1, 32767);

	unit_test_pkg.AssertAreEqual('TestCanCreateAndGetFactorTypeList', v_name, 'Incorrect name');
	unit_test_pkg.AssertAreEqual('A new factor type info note', v_varchar_note, 'Incorrect note');

	factor_pkg.DisableFactorType(v_factor_type_id);
	factor_pkg.DeleteFactorType(v_factor_type_id);
END;

PROCEDURE TestGetFactorTypeMappedPathsReturnsInfoNote
AS
	v_cur					SYS_REFCURSOR;
	v_custom_factor_id		security.security_pkg.T_SID_ID;
	v_parent_id				factor_type.factor_type_id%TYPE;
	v_varchar_note			VARCHAR2(32767);
	v_cust_factor_set_id	custom_factor_set.custom_factor_set_id%TYPE;
	v_capability_sid		security.security_pkg.T_SID_ID;
	v_ind_sid				security.security_pkg.T_SID_ID;
	-- FactorSetGroup out cur
	v_factor_set_group_id	factor_set_group.factor_set_group_id%TYPE;
	v_name					factor_set_group.name%TYPE;
	v_custom				factor_set_group.custom%TYPE;
	-- Factor type out cur
	v_factor_type_id		factor_type.factor_type_id%TYPE;
	v_path					VARCHAR2(5000);
	v_info_note				factor_type.info_note%TYPE;
BEGIN
	Trace('TestGetFactorTypeMappedPathsReturnsInfoNote');
	
	BEGIN
		security.securableobject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY','ACT'), 
			security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities'), 
			security.class_pkg.GetClassId('CSRCapability'),
			'Can import std factor set',
			v_capability_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	BEGIN
		security.securableobject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY','ACT'), 
			security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities'), 
			security.class_pkg.GetClassId('CSRCapability'),
			'Can delete factor type',
			v_capability_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	SELECT factor_type_id
	  INTO v_parent_id
	  FROM factor_type
	 WHERE parent_id IS NULL;
	
	factor_pkg.AddFactorType(
		in_parent_id			=> v_parent_id,
		in_name					=> 'TestGetFactorTypeMappedPathsReturnsInfoNote',
		in_std_measure_id		=> 1,
		in_egrid				=> 0,
		in_enabled				=> 1,
		in_info_note			=> 'A new factor type info note'
	);
	
	factor_set_group_pkg.SaveFactorSetGroup(
		in_factor_set_group_id	=> NULL,
		in_name					=> 'TestGetFactorTypeMappedPathsReturnsInfoNote Profile',
		in_custom				=> 1,
		out_factor_set_group	=> v_cur
	);
	
	FETCH v_cur INTO v_factor_set_group_id, v_name, v_custom;
	
	v_cust_factor_set_id := factor_pkg.CreateCustomFactorSet(
		in_name						=> 'New Custom Factor Set',
		in_factor_set_group_id		=> v_factor_set_group_id,
		in_info_note				=> 'A new custom factor set with a info note'
	);
	
	SELECT factor_type_id
	  INTO v_factor_type_id
	  FROM factor_type
	 WHERE name = 'TestGetFactorTypeMappedPathsReturnsInfoNote';
	
	factor_pkg.InsertCustomValue(v_factor_type_id, v_cust_factor_set_id, 'us', null, null,
		'01-JAN-1990', '01-JAN-2021', 1, 0.5, 1, '',
		v_custom_factor_id -- out
	);
	
	v_ind_sid := unit_test_pkg.GetOrCreateInd('TGFTMPRIN');
	UPDATE ind SET factor_type_id = v_factor_type_id;
	
	factor_pkg.GetFactorTypeMappedPaths(
		out_mapped_cur => v_cur
	);
	
	LOOP
		FETCH v_cur INTO v_factor_type_id, v_path, v_info_note;
		EXIT WHEN (v_path = 'Factor types > TestGetFactorTypeMappedPathsReturnsInfoNote' OR v_cur%notfound);
	END LOOP;
	
	v_varchar_note := SUBSTR(v_info_note, 1, 32767);
	
	unit_test_pkg.AssertAreEqual('TestGetFactorTypeMappedPathsReturnsInfoNote', v_path, 'Incorrect path');
	unit_test_pkg.AssertAreEqual('A new factor type info note', v_varchar_note, 'Incorrect note');
	
	DELETE FROM csr.custom_factor WHERE factor_type_id = v_factor_type_id;
	UPDATE ind SET factor_type_id = NULL;
	factor_pkg.DisableFactorType(v_factor_type_id);
	factor_pkg.DeleteFactorType(v_factor_type_id);
END;

PROCEDURE TestGetFactorSetInfoNoteReturnsNullWhenNoInfoNoteSet
AS
	v_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_info_note			std_factor_set.info_note%TYPE;
BEGIN
	Trace('TestGetFactorSetInfoNoteReturnsNullWhenNoInfoNoteSet');
	
	INSERT INTO std_factor_set (std_factor_set_id, name, info_note)
	VALUES (factor_set_id_seq.nextval, 'TestGetFactorSetInfoNoteReturnsNullWhenNoInfoNoteSet', NULL)
	RETURNING std_factor_set_id INTO v_factor_set_id;

	v_info_note := factor_pkg.GetFactorSetInfoNote(v_factor_set_id);

	csr.unit_test_pkg.AssertIsTrue(v_info_note IS NULL, 'Expected Info note not found.');

	DELETE FROM std_factor_set
	 WHERE std_factor_set_id = v_factor_set_id;
END;

PROCEDURE TestUpdateStdFactorSetInfoNote
AS
	v_std_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_info_note				std_factor_set.info_note%TYPE;
	v_test_info_note 		std_factor_set.info_note%TYPE := 'Test Info Note';	
	v_factor_set_group_id	factor_set_group.factor_set_group_id%TYPE;
	v_name					factor_set_group.name%TYPE;
	v_custom				factor_set_group.custom%TYPE;
	v_cur					SYS_REFCURSOR;
BEGIN
	Trace('TestUpdateStdFactorSetInfoNote');
	
	FOR r IN (
		SELECT factor_set_group_id
		  FROM factor_set_group
		 WHERE name IN ('TestUpdateStdFactorSetInfoNote Profile')
	)
	LOOP
		DELETE FROM csr.std_factor_set WHERE factor_set_group_id = r.factor_set_group_id;
		factor_set_group_pkg.DeleteFactorSetGroup(r.factor_set_group_id);
	END LOOP;

	factor_set_group_pkg.SaveFactorSetGroup(
		in_factor_set_group_id	=> NULL,
		in_name					=> 'TestUpdateStdFactorSetInfoNote Profile',
		in_custom				=> 0,
		out_factor_set_group	=> v_cur
	);
	
	FETCH v_cur INTO v_factor_set_group_id, v_name, v_custom;
	
	v_std_factor_set_id := factor_pkg.CreateStdFactorSet(
		in_name						=> 'New TestUpdateStdFactorSetInfoNote Factor Set',
		in_factor_set_group_id		=> v_factor_set_group_id,
		in_info_note				=> 'A new std factor set with a info note'
	);

	factor_pkg.UpdateStdFactorSetInfoNote(v_std_factor_set_id, v_test_info_note);

	v_info_note := factor_pkg.GetFactorSetInfoNote(v_std_factor_set_id);

	unit_test_pkg.AssertAreEqual(v_info_note, v_test_info_note, 'Incorrect updated factor set note');
END;

PROCEDURE TestUpdateCustomFactorSetInfoNote
AS
	v_cust_factor_set_id	custom_factor_set.custom_factor_set_id%TYPE;
	v_info_note				custom_factor_set.info_note%TYPE;
	v_test_info_note 		custom_factor_set.info_note%TYPE := 'Test Custom Info Note';
	v_name					factor_set_group.name%TYPE;
	v_custom				factor_set_group.custom%TYPE;
	v_factor_set_group_id	factor_set_group.factor_set_group_id%TYPE;
	v_cur					SYS_REFCURSOR;
BEGIN
	Trace('TestUpdateCustomFactorSetInfoNote');

	FOR r IN (
		SELECT factor_set_group_id
		  FROM factor_set_group
		 WHERE name IN ('TestUpdateCustomFactorSetInfoNote Profile')
	)
	LOOP
		DELETE FROM csr.custom_factor WHERE custom_factor_set_id IN (
			SELECT custom_factor_set_id FROM csr.custom_factor_set WHERE factor_set_group_id = r.factor_set_group_id
		); 
		DELETE FROM csr.custom_factor_set WHERE factor_set_group_id = r.factor_set_group_id;
		factor_set_group_pkg.DeleteFactorSetGroup(r.factor_set_group_id);
	END LOOP;

	factor_set_group_pkg.SaveFactorSetGroup(
		in_factor_set_group_id	=> NULL,
		in_name					=> 'TestUpdateCustomFactorSetInfoNote Profile',
		in_custom				=> 1,
		out_factor_set_group	=> v_cur
	);
	
	FETCH v_cur INTO v_factor_set_group_id, v_name, v_custom;
	
	v_cust_factor_set_id := factor_pkg.CreateCustomFactorSet(
		in_name						=> 'New Custom TestUpdateCustomFactorSetInfoNote Factor Set',
		in_factor_set_group_id		=> v_factor_set_group_id,
		in_info_note				=> 'Test Info Note'
	);
	
	factor_pkg.UpdateCustomFactorSetInfoNote(v_cust_factor_set_id, v_test_info_note);

	v_info_note := factor_pkg.GetFactorSetInfoNote(v_cust_factor_set_id);

	unit_test_pkg.AssertAreEqual(v_info_note, v_test_info_note, 'Incorrect updated custom factor set note');
END;

PROCEDURE TestUnpublishStdFactorSet
AS
	v_count					NUMBER;
	v_std_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_capability_sid		security.security_pkg.T_SID_ID;
	v_published				std_factor_set.published%TYPE;
	v_published_by_sid		std_factor_set.published_by_sid%TYPE;
	v_published_dtm			std_factor_set.published_dtm%TYPE;
BEGIN
	Trace('TestUnpublishStdFactorSet');

	BEGIN
		security.securableobject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY','ACT'), 
			security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities'), 
			security.class_pkg.GetClassId('CSRCapability'),
			'Can publish std factor set',
			v_capability_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	SELECT MAX(std_factor_set_id)
	  INTO v_std_factor_set_id
	  FROM std_factor_set;
	  
	factor_set_group_pkg.UnpublishFactorSet(v_std_factor_set_id);
	
	SELECT published, published_by_sid, published_dtm
	  INTO v_published, v_published_by_sid, v_published_dtm
	  FROM std_factor_set
	 WHERE std_factor_set_id = v_std_factor_set_id;
	  
	unit_test_pkg.AssertIsTrue(v_published = 0, 'StdFactorSet not set unpublished.');
	unit_test_pkg.AssertIsTrue(v_published_by_sid IS NULL, 'StdFactorSet published by not cleared.');
	unit_test_pkg.AssertIsTrue(v_published_dtm IS NULL, 'StdFactorSet published dtm not cleared.');
	
	factor_set_group_pkg.PublishFactorSet(v_std_factor_set_id);
END;

PROCEDURE TestUnpublishStdFactorSetFailsWhenInUseBySameApp
AS
	v_count					NUMBER;
	v_std_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_factor_type_id		std_factor.factor_type_id%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;
	v_capability_sid		security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestUnpublishStdFactorSetFailsWhenInUseBySameApp');

	BEGIN
		security.securableobject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY','ACT'), 
			security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities'), 
			security.class_pkg.GetClassId('CSRCapability'),
			'Can publish std factor set',
			v_capability_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	SELECT MIN(std_factor_set_id)
	  INTO v_std_factor_set_id
	  FROM std_factor_set;
	
	SELECT MIN(factor_type_id)
	  INTO v_factor_type_id
	  FROM std_factor
	 WHERE std_factor_set_id = v_std_factor_set_id;
	
	factor_pkg.CreateEmissionProfile('TestUnpublishStdFactorSetFailsWhenInUseBySameApp', 0, NULL, v_profile_id);

	factor_pkg.AprxSaveProfileFactor(
		in_profile_id				=> v_profile_id,
		in_factor_type_id			=> v_factor_type_id,
		in_std_factor_set_id		=> v_std_factor_set_id,
		in_custom_factor_set_id		=> NULL,
		in_region_sid				=> NULL,
		in_geo_country				=> NULL,
		in_geo_region				=> NULL,
		in_egrid_ref				=> NULL
	);
	
	BEGIN
		factor_set_group_pkg.UnpublishFactorSet(v_std_factor_set_id);
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			RETURN;
	END;	
	
	unit_test_pkg.TestFail('Unpublish exception not thrown');
END;

PROCEDURE TestUnpublishStdFactorSetFailsWhenInUseByDifferentApp
AS
	v_count					NUMBER;
	v_std_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_factor_type_id		std_factor.factor_type_id%TYPE;
	v_profile_id			emission_factor_profile.profile_id%TYPE;
	v_capability_sid		security.security_pkg.T_SID_ID;
	v_act					security.security_pkg.T_ACT_ID;
	v_initial_act			security.security_pkg.T_ACT_ID;
	v_initial_app			security.security_pkg.T_SID_ID;
	v_initial_user			security.security_pkg.T_SID_ID;
	v_initial_company		security.security_pkg.T_SID_ID;
	v_other_app				security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestUnpublishStdFactorSetFailsWhenInUseByDifferentApp');

	BEGIN
		security.securableobject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY','ACT'), 
			security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities'), 
			security.class_pkg.GetClassId('CSRCapability'),
			'Can publish std factor set',
			v_capability_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	SELECT MIN(std_factor_set_id)
	  INTO v_std_factor_set_id
	  FROM std_factor_set;
	
	SELECT MIN(factor_type_id)
	  INTO v_factor_type_id
	  FROM std_factor
	 WHERE std_factor_set_id = v_std_factor_set_id;
	
	v_initial_act := security.security_pkg.getAct;
	v_initial_app := security.security_pkg.getApp;
	v_initial_user := security.security_pkg.getSid;
	v_initial_company := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	BEGIN
		security.user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 5000, NULL, v_act);
		
		SELECT MAX(app_sid)
		  INTO v_other_app
		  FROM customer
		 WHERE host = 'emissionfactorsdbunittest.credit360.com';
		 
		IF v_other_app IS NULL THEN
			csr.csr_app_pkg.CreateApp(
				in_app_name			=> 'emissionfactorsdbunittest.credit360.com',
				in_styles_path		=> '/standardbranding/styles',
				in_start_month		=> 1,
				out_app_sid			=> v_other_app	
			);
		END IF;
		 		
		security.security_pkg.SetApp(v_other_app);
		
		factor_pkg.CreateEmissionProfile('TestUnpublishStdFactorSetFailsWhenInUseByDifferentApp', 0, NULL, v_profile_id);

		factor_pkg.AprxSaveProfileFactor(
			in_profile_id				=> v_profile_id,
			in_factor_type_id			=> v_factor_type_id,
			in_std_factor_set_id		=> v_std_factor_set_id,
			in_custom_factor_set_id		=> NULL,
			in_region_sid				=> NULL,
			in_geo_country				=> NULL,
			in_geo_region				=> NULL,
			in_egrid_ref				=> NULL
		);
		
		security.user_pkg.logoff(v_act);
	EXCEPTION
		WHEN OTHERS THEN			
			security.security_pkg.SetACTAndSID(v_initial_act, v_initial_user);
			IF v_initial_company IS NOT NULL THEN
				security.security_pkg.SetContext('CHAIN_COMPANY', v_initial_company);
			END IF;
			RAISE;
	END;
	
	security.security_pkg.SetACTAndSID(v_initial_act, v_initial_user);
	security.security_pkg.SetApp(v_initial_app);
	IF v_initial_company IS NOT NULL THEN
		security.security_pkg.SetContext('CHAIN_COMPANY', v_initial_company);
	END IF;
	
	BEGIN
		factor_set_group_pkg.UnpublishFactorSet(v_std_factor_set_id);
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			RETURN;
	END;	
	
	unit_test_pkg.TestFail('Unpublish exception not thrown');
END;

PROCEDURE TestCKFACTORDATESConstraintWhenChangingStatusOfProfile
AS
	--emissions profile
	v_name						emission_factor_profile.name%TYPE;
	v_applied					emission_factor_profile.applied%TYPE;
	v_start_dtm					emission_factor_profile.start_dtm%TYPE;
	v_profile_id				emission_factor_profile.profile_id%TYPE;
	v_count 					NUMBER;
	
	--std_factor
	v_std_factor_set_id			std_factor.std_factor_set_id%TYPE;
	v_geo_country				std_factor.geo_country%TYPE;
	v_geo_region				VARCHAR2(200);
	vf_region_sid				factor.region_sid%TYPE;
	v_factor_start_dtm			std_factor.start_dtm%TYPE;
	v_factor_end_dtm			std_factor.end_dtm%TYPE;
	v_gas_type_id				std_factor.gas_type_id%TYPE;
	v_value				 		std_factor.value%TYPE;
	v_std_meas_conv_id			std_factor.std_measure_conversion_id%TYPE;
	v_note						std_factor.note%TYPE;
	v_std_factor_id		 		std_factor.std_factor_id%TYPE;

	--std_factor count
	v_std_factor_count_expected NUMBER;
	v_std_factor_count			NUMBER;
	v_new_std_factor_count		NUMBER;
	--emission profile count
	v_profile_count_expected 	NUMBER;
	v_profile_count 			NUMBER;
	v_new_profile_count 		NUMBER;
	--factor count
	v_factor_count_expected 	NUMBER;
	v_factor_count				NUMBER;
	v_new_factor_count			NUMBER;

BEGIN
	Trace('TestCKFACTORDATESConstraintWhenChangingStatusOfProfile');

	--get count before adding
	SELECT COUNT(*)
	  INTO v_std_factor_count
	  FROM csr.std_factor;
	SELECT COUNT(*)
	  INTO v_profile_count
	  FROM csr.emission_factor_profile;
	SELECT COUNT(*)
	  INTO v_factor_count
	  FROM csr.factor;

	--add emission profile
	v_profile_count_expected := 0;

	v_name := 'TestGetRegionFactorsMapCustom';
	v_applied := 1;
	v_start_dtm := DATE '2201-01-01';
	factor_pkg.CreateEmissionProfile(v_name, v_applied, v_start_dtm, v_profile_id);
	v_profile_count_expected := v_profile_count_expected + 1;

	--add std_factor_set and std_factor
	v_std_factor_count_expected := 0;

	v_std_factor_set_id := factor_pkg.CreateStdFactorSet(v_name, 16); --create the factorset
	v_value:= 1.23;
	v_factor_start_dtm:= DATE '2190-01-01';
	v_factor_end_dtm := DATE '2200-01-01';
	v_gas_type_id := 1;
	v_std_meas_conv_id := 1;
	InsertStandardValue(10485, v_std_factor_set_id, v_geo_country, v_geo_region,
		v_factor_start_dtm, v_factor_end_dtm, v_gas_type_id, v_value, v_std_meas_conv_id, v_note,
		v_std_factor_id -- out
	);
	v_std_factor_count_expected := v_std_factor_count_expected + 1;

	--test to make sure factor and profile have been added
	SELECT COUNT(*)
	  INTO v_new_profile_count
	  FROM csr.emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_new_profile_count - v_profile_count = v_profile_count_expected, 'Expected '||v_profile_count_expected||' emission profiles, found '|| (v_new_profile_count - v_profile_count) );
	SELECT COUNT(*)
	  INTO v_new_std_factor_count
	  FROM csr.std_factor;
	unit_test_pkg.AssertIsTrue(v_new_std_factor_count - v_std_factor_count = v_std_factor_count_expected, 'Expected '||v_std_factor_count_expected||' std factors, found '|| (v_new_std_factor_count - v_std_factor_count) );

	--call UpdateEmisisonProfileStatus to set status to the same year as the end date of the factor
	factor_pkg.UpdateEmissionProfileStatus(v_profile_id, v_applied, DATE '2200-01-01');

	--check if the factor has been added (it should not have been added.)
	SELECT COUNT(*)
	  INTO v_new_factor_count
	  FROM csr.factor;
	unit_test_pkg.AssertIsTrue(v_factor_count = v_new_factor_count, 'Expected no factors, found '|| (v_new_factor_count) );


	--clean up (delete emission profile, std_factor_set and std_factor)
	factor_pkg.DeleteEmissionProfile(v_profile_id);
	DELETE FROM csr.std_factor
	 WHERE std_factor_set_id = v_std_factor_set_id;
	DELETE FROM csr.std_factor_set
	 WHERE std_factor_set_id = v_std_factor_set_id;

	--retest to make sure all was deleted correctly
	SELECT COUNT(*)
	  INTO v_new_profile_count
	  FROM csr.emission_factor_profile;
	unit_test_pkg.AssertIsTrue(v_count = v_new_profile_count, 'Expected no profiles after delete, found '||v_count);
	SELECT COUNT(*)
	  INTO v_new_std_factor_count
	  FROM csr.std_factor;
	unit_test_pkg.AssertIsTrue(v_std_factor_count = v_new_std_factor_count, 'Expected ' || v_std_factor_count || ' std factor count after delete , found '||v_new_std_factor_count);
	SELECT COUNT(*)
	  INTO v_new_factor_count
	  FROM csr.factor;
	unit_test_pkg.AssertIsTrue(v_factor_count = v_new_factor_count, 'Expected no factors after delete, found '||v_count);
END;

END test_emission_factors_pkg;
/
