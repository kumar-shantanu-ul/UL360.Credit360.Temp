CREATE OR REPLACE PACKAGE BODY csr.test_int_api_tags_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_primary_root_sid				security.security_pkg.T_SID_ID;
	v_cust_comp_sid					security.security_pkg.T_SID_ID;
	v_xml							CLOB;
	v_str 							VARCHAR2(2000);
	v_r0 							security.security_pkg.T_SID_ID;
	v_s0							security.security_pkg.T_SID_ID;
	v_s1							security.security_pkg.T_SID_ID;
BEGIN
	v_site_name	:= in_site_name;
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE SetUp AS
	v_company_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
END;

PROCEDURE TearDown AS
BEGIN
	NULL;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	NULL;
END;


PROCEDURE INT_CheckGetTGrpsCursorCounts(in_descriptions_cur		security_pkg.T_OUTPUT_CUR, 
									 in_tags_cur				security_pkg.T_OUTPUT_CUR,
									 in_tag_descriptions_cur	security_pkg.T_OUTPUT_CUR,
									 in_d_count NUMBER, in_t_count NUMBER, in_td_count NUMBER)
AS
	v_tag_group_id						NUMBER; 
	v_name								tag_group_description.name%TYPE; 
	v_lang								tag_group_description.lang%TYPE;
	
	v_tag_id							NUMBER; 
	v_tag								tag_description.tag%TYPE;
	v_explanation						tag_description.explanation%TYPE;
	v_pos								NUMBER; 
	v_tag_lookup_key					tag.lookup_key%TYPE;
	v_exclude_from_dv_grouping			NUMBER; 
	v_active							NUMBER; 
	v_excld_from_dataview_grouping		NUMBER;
	v_tag_lang							tag_description.lang%TYPE;
	v_last_changed_dtm					tag_description.last_changed_dtm%TYPE;
	
	v_actual_count						NUMBER;
BEGIN
	v_actual_count := 0;
	LOOP
		FETCH in_descriptions_cur INTO 
				v_tag_group_id, v_name, v_lang, v_last_changed_dtm
		;
		EXIT WHEN in_descriptions_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(in_d_count = v_actual_count, 'Expected count (descriptions) got '||v_actual_count||' expected '||in_d_count);
	
	v_actual_count := 0;
	LOOP
		FETCH in_tags_cur INTO 
				v_tag_id, v_tag, v_explanation, v_tag_lookup_key, v_tag_group_id, v_pos, v_active, v_excld_from_dataview_grouping
		;
		EXIT WHEN in_tags_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(in_t_count = v_actual_count, 'Expected count (tags) got '||v_actual_count||' expected '||in_t_count);

	v_actual_count := 0;
	LOOP
		FETCH in_tag_descriptions_cur INTO 
				v_tag_id, v_tag, v_explanation, v_lang, v_last_changed_dtm
		;
		EXIT WHEN in_tag_descriptions_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(in_td_count = v_actual_count, 'Expected count (tag descriptions) got '||v_actual_count||' expected '||in_td_count);
END;

PROCEDURE TestGetTagGroupsBase AS
	v_cur					security_pkg.T_OUTPUT_CUR;
	v_descriptions_cur		security_pkg.T_OUTPUT_CUR;
	v_tags_cur				security_pkg.T_OUTPUT_CUR;
	v_tag_descriptions_cur	security_pkg.T_OUTPUT_CUR;
	
	v_count	 							NUMBER; 
	v_total_count	 					NUMBER; 
	v_tag_group_id						NUMBER; 
	v_name								tag_group_description.name%TYPE; 
	v_lookup_key						tag_group.lookup_key%TYPE;
	v_mandatory							NUMBER;
	v_multi_select						NUMBER;
	v_applies_to_inds					NUMBER;
	v_applies_to_regions				NUMBER;
	v_applies_to_non_compliances		NUMBER;
	v_applies_to_suppliers				NUMBER;
	v_applies_to_chain					NUMBER;
	v_applies_to_chain_activities		NUMBER;
	v_applies_to_initiatives			NUMBER;
	v_applies_to_chn_product_types		NUMBER;
	v_applies_to_chn_products			NUMBER;
	v_applies_to_chn_product_supps		NUMBER;
	v_applies_to_quick_survey			NUMBER;
	v_applies_to_audits					NUMBER;
	v_applies_to_compliances			NUMBER;
	v_is_hierarchical					NUMBER;
BEGIN

	-- Check that the baseline tags are what we would expect.
	
	integration_api_pkg.GetTagGroups(
		out_cur						=> v_cur,
		out_descriptions_cur		=> v_descriptions_cur,
		out_tags_cur				=> v_tags_cur,
		out_tag_descriptions_cur	=> v_tag_descriptions_cur
	);
	
	v_count := 0;
	LOOP
		FETCH v_cur INTO 
				v_total_count, v_tag_group_id, v_name, v_lookup_key, v_mandatory, v_multi_select,
				v_applies_to_inds, v_applies_to_regions,  
				v_applies_to_non_compliances, v_applies_to_suppliers, 
				v_applies_to_chain, v_applies_to_chain_activities, v_applies_to_initiatives,
				v_applies_to_chn_product_types,
				v_applies_to_chn_products,
				v_applies_to_chn_product_supps,
				v_applies_to_quick_survey, v_applies_to_audits, v_applies_to_compliances,
				v_is_hierarchical
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
		unit_test_pkg.TestFail('Unexpected tag groups', 'Unexpected tag group found (should be none)');
	END LOOP;
	unit_test_pkg.AssertIsTrue(0 = v_count, 'Expected count 0, got '||v_count);
	
	INT_CheckGetTGrpsCursorCounts(v_descriptions_cur, v_tags_cur, v_tag_descriptions_cur, 0, 0, 0);
	
	unit_test_pkg.AssertIsTrue(0 = v_total_count, 'Expected total count');
END;


PROCEDURE TestGetTagGroups AS
	v_cur					security_pkg.T_OUTPUT_CUR;
	v_descriptions_cur		security_pkg.T_OUTPUT_CUR;
	v_tags_cur				security_pkg.T_OUTPUT_CUR;
	v_tag_descriptions_cur	security_pkg.T_OUTPUT_CUR;
	
	v_total_count	 					NUMBER; 
	v_tag_group_id						NUMBER; 
	v_name								tag_group_description.name%TYPE; 
	v_lookup_key						tag_group.lookup_key%TYPE;
	v_mandatory							NUMBER;
	v_multi_select						NUMBER;
	v_applies_to_inds					NUMBER;
	v_applies_to_regions				NUMBER;
	v_applies_to_non_compliances		NUMBER;
	v_applies_to_suppliers				NUMBER;
	v_applies_to_chain					NUMBER;
	v_applies_to_chain_activities		NUMBER;
	v_applies_to_initiatives			NUMBER;
	v_applies_to_chn_product_types		NUMBER;
	v_applies_to_chn_products			NUMBER;
	v_applies_to_chn_product_supps		NUMBER;
	v_applies_to_quick_survey			NUMBER;
	v_applies_to_audits					NUMBER;
	v_applies_to_compliances			NUMBER;
	v_is_hierarchical					NUMBER;
	v_lang								tag_group_description.lang%TYPE; 

	v_tag_id							NUMBER; 
	v_tag								tag_description.tag%TYPE;
	v_explanation						tag_description.explanation%TYPE;
	v_pos								NUMBER; 
	v_tag_lookup_key					tag.lookup_key%TYPE;
	v_exclude_from_dv_grouping			NUMBER; 
	v_active							NUMBER; 
	v_tag_lang							tag_description.lang%TYPE;
	v_last_changed_dtm					tag_description.last_changed_dtm%TYPE;
	
	TYPE t_ids IS TABLE OF tag_group.tag_group_id%TYPE;
	v_tag_group_ids t_ids := t_ids();

	v_actual_count						NUMBER;
BEGIN

	-- Check that the GetTagGroups function returns the correct information and pages as expected.

	-- Add some tag groups
	FOR i IN 1..22 LOOP
		integration_api_pkg.UpsertTagGroup(
			in_name	=> 'TG'||i,
			in_lookup_key => 'TESTGETTAGGROUPS_TG'||i,
			out_tag_group_id => v_tag_group_id
		);
		
		v_tag_group_ids.extend;
		v_tag_group_ids(i) := v_tag_group_id;
	END LOOP;

	integration_api_pkg.GetTagGroups(
		out_cur						=> v_cur,
		out_descriptions_cur		=> v_descriptions_cur,
		out_tags_cur				=> v_tags_cur,
		out_tag_descriptions_cur	=> v_tag_descriptions_cur
	);
	
	v_actual_count := 0;
	LOOP
		FETCH v_cur INTO 
				v_total_count, v_tag_group_id, v_name, v_lookup_key, v_mandatory, v_multi_select,
				v_applies_to_inds, v_applies_to_regions,  
				v_applies_to_non_compliances, v_applies_to_suppliers, 
				v_applies_to_chain, v_applies_to_chain_activities, v_applies_to_initiatives,
				v_applies_to_chn_product_types,
				v_applies_to_chn_products,
				v_applies_to_chn_product_supps,
				v_applies_to_quick_survey, v_applies_to_audits, v_applies_to_compliances,
				v_is_hierarchical
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
		IF v_lookup_key LIKE 'TESTGETTAGGROUPS_TG%' THEN
			unit_test_pkg.AssertIsTrue(v_name LIKE 'TG%', 'Expected tag group');
		ELSE
			unit_test_pkg.TestFail('Only expected tag groups', 'Unexpected tag group found: '||v_lookup_key);
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(20 = v_actual_count, 'Expected count (actual)');
	unit_test_pkg.AssertIsTrue(22 = v_total_count, 'Expected count (total)');
	
	INT_CheckGetTGrpsCursorCounts(v_descriptions_cur, v_tags_cur, v_tag_descriptions_cur, 20, 0, 0);


	integration_api_pkg.GetTagGroups(
		in_skip						=> 2,
		in_take						=> 10,
		out_cur						=> v_cur,
		out_descriptions_cur		=> v_descriptions_cur,
		out_tags_cur				=> v_tags_cur,
		out_tag_descriptions_cur	=> v_tag_descriptions_cur
	);
	
	v_actual_count := 0;
	LOOP
		FETCH v_cur INTO 
				v_total_count, v_tag_group_id, v_name, v_lookup_key, v_mandatory, v_multi_select,
				v_applies_to_inds, v_applies_to_regions,  
				v_applies_to_non_compliances, v_applies_to_suppliers, 
				v_applies_to_chain, v_applies_to_chain_activities, v_applies_to_initiatives,
				v_applies_to_chn_product_types,
				v_applies_to_chn_products,
				v_applies_to_chn_product_supps,
				v_applies_to_quick_survey, v_applies_to_audits, v_applies_to_compliances,
				v_is_hierarchical
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
		IF /*v_lookup_key = 'FACILITY_TYPE' THEN
			unit_test_pkg.AssertIsTrue(v_name = 'Facility type', 'Expected tag group');
		ELSIF v_lookup_key = 'OWNERSHIP_TYPE' THEN
			unit_test_pkg.AssertIsTrue(v_name = 'Ownership type', 'Expected tag group');
		ELSIF*/ v_lookup_key LIKE 'TESTGETTAGGROUPS_TG%' THEN
			unit_test_pkg.AssertIsTrue(v_name LIKE 'TG%', 'Expected tag group');
		ELSE
			unit_test_pkg.TestFail('Only expected tag groups', 'Unexpected tag group found');
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(10 = v_actual_count, 'Expected count (actual)');
	unit_test_pkg.AssertIsTrue(22 = v_total_count, 'Expected count (total)');

	INT_CheckGetTGrpsCursorCounts(v_descriptions_cur, v_tags_cur, v_tag_descriptions_cur, 10, 0, 0);
	
	FOR i IN 1..22 LOOP
		tag_pkg.DeleteTagGroup(
			in_act_id => security.security_pkg.getact,
			in_tag_group_id => v_tag_group_ids(i)
		);
	END LOOP;

END;


PROCEDURE INT_CheckGetTGrpCursorCounts(in_descriptions_cur		security_pkg.T_OUTPUT_CUR, 
									 in_tags_cur				security_pkg.T_OUTPUT_CUR,
									 in_tag_descriptions_cur	security_pkg.T_OUTPUT_CUR,
									 in_d_count NUMBER, in_t_count NUMBER, in_td_count NUMBER)
AS
	v_tag_group_id						NUMBER; 
	v_name								tag_group_description.name%TYPE; 
	v_lang								tag_group_description.lang%TYPE;
	
	v_tag_id							NUMBER; 
	v_tag								tag_description.tag%TYPE;
	v_explanation						tag_description.explanation%TYPE;
	v_pos								NUMBER; 
	v_tag_lookup_key					tag.lookup_key%TYPE;
	v_exclude_from_dv_grouping			NUMBER; 
	v_active							NUMBER; 
	v_tag_lang							tag_description.lang%TYPE;
	v_last_changed_dtm					tag_description.last_changed_dtm%TYPE;
	v_parent_id							NUMBER;
	
	v_actual_count						NUMBER;
BEGIN
	v_actual_count := 0;
	LOOP
		FETCH in_descriptions_cur INTO 
				v_tag_group_id, v_lang, v_name, v_last_changed_dtm
		;
		EXIT WHEN in_descriptions_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(in_d_count = v_actual_count, 'Expected count (descriptions) got '||v_actual_count||' expected '||in_d_count);
	
	v_actual_count := 0;
	LOOP
		FETCH in_tags_cur INTO 
				v_tag_id, v_tag, v_explanation, v_pos, v_tag_lookup_key, v_exclude_from_dv_grouping, v_active, v_tag_group_id, v_parent_id
		;
		EXIT WHEN in_tags_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(in_t_count = v_actual_count, 'Expected count (tags) got '||v_actual_count||' expected '||in_t_count);

	v_actual_count := 0;
	LOOP
		FETCH in_tag_descriptions_cur INTO 
				v_tag_id, v_lang, v_tag, v_explanation, v_last_changed_dtm
		;
		EXIT WHEN in_tag_descriptions_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(in_td_count = v_actual_count, 'Expected count (tag descriptions) got '||v_actual_count||' expected '||in_td_count);
END;


PROCEDURE TestGetTagGroup AS
	v_cur					security_pkg.T_OUTPUT_CUR;
	v_descriptions_cur		security_pkg.T_OUTPUT_CUR;
	v_tags_cur				security_pkg.T_OUTPUT_CUR;
	v_tag_descriptions_cur	security_pkg.T_OUTPUT_CUR;
	
	v_total_count	 					NUMBER;
	v_tag_group_id						NUMBER;
	v_name								tag_group_description.name%TYPE;
	v_lookup_key						tag_group.lookup_key%TYPE;
	v_mandatory							NUMBER;
	v_multi_select						NUMBER;
	v_applies_to_inds					NUMBER;
	v_applies_to_regions				NUMBER;
	v_applies_to_non_compliances		NUMBER;
	v_applies_to_suppliers				NUMBER;
	v_applies_to_chain					NUMBER;
	v_applies_to_chain_activities		NUMBER;
	v_applies_to_initiatives			NUMBER;
	v_applies_to_chn_product_types		NUMBER;
	v_applies_to_chn_products			NUMBER;
	v_applies_to_chn_product_supps		NUMBER;
	v_applies_to_quick_survey			NUMBER;
	v_applies_to_audits					NUMBER;
	v_applies_to_compliances			NUMBER;
	v_is_hierarchical					NUMBER;
	
	v_test_tag_group_id					NUMBER;
	v_actual_count						NUMBER;
	
	v_tag_id							tag.tag_id%TYPE;
	v_tag								tag_description.tag%TYPE;
	v_explanation						tag_description.explanation%TYPE;
	v_tag_lookup_key					tag.lookup_key%TYPE;
	v_lang								tag_description.lang%TYPE;
	v_pos								NUMBER;
	v_exclude_from_dv_grouping			NUMBER;
	v_active							NUMBER;
	v_tag_lang							tag_description.lang%TYPE;
	v_last_changed_dtm					tag_description.last_changed_dtm%TYPE;
	
BEGIN

	-- Check that the GetTagGroup function returns the correct information and a single row.


	integration_api_pkg.UpsertTagGroup(
		in_name	=> 'TG1',
		in_lookup_key => 'TESTGETTAGGROUPS_TG1',
		out_tag_group_id => v_test_tag_group_id
	);


	integration_api_pkg.GetTagGroup(
		in_tag_group_id				=> v_test_tag_group_id,
		out_cur						=> v_cur,
		out_descriptions_cur		=> v_descriptions_cur,
		out_tags_cur				=> v_tags_cur,
		out_tag_descriptions_cur	=> v_tag_descriptions_cur
	);
	
	v_actual_count := 0;
	LOOP
		FETCH v_cur INTO
				v_tag_group_id, v_name, v_lookup_key, v_mandatory, v_multi_select,
				v_applies_to_inds, v_applies_to_regions,  
				v_applies_to_non_compliances, v_applies_to_suppliers, 
				v_applies_to_chain, v_applies_to_chain_activities, v_applies_to_initiatives,
				v_applies_to_chn_product_types,
				v_applies_to_chn_products,
				v_applies_to_chn_product_supps,
				v_applies_to_quick_survey, v_applies_to_audits, v_applies_to_compliances,
				v_is_hierarchical
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
		IF v_lookup_key = 'TESTGETTAGGROUPS_TG1' THEN
			unit_test_pkg.AssertIsTrue(v_name = 'TG1', 'Expected tag group');
		ELSE
			unit_test_pkg.TestFail('Only expected tag groups', 'Unexpected tag group found');
		END IF;
	END LOOP;
	
	unit_test_pkg.AssertIsTrue(3 = v_total_count, 'Expected count');

	INT_CheckGetTGrpCursorCounts(v_descriptions_cur, v_tags_cur, v_tag_descriptions_cur, 1, 0, 0);

	tag_pkg.DeleteTagGroup(
		in_act_id => security.security_pkg.getact,
		in_tag_group_id => v_test_tag_group_id
	);
END;


PROCEDURE INT_CheckTagGroupUpsertResult(
	in_test_tag_group_id NUMBER,
	in_name VARCHAR2,
	in_lookup_key VARCHAR2,
	in_flag_val NUMBER,
	in_d_count NUMBER, in_t_count NUMBER, in_td_count NUMBER
)
AS
	v_cur					security_pkg.T_OUTPUT_CUR;
	v_descriptions_cur		security_pkg.T_OUTPUT_CUR;
	v_tags_cur				security_pkg.T_OUTPUT_CUR;
	v_tag_descriptions_cur	security_pkg.T_OUTPUT_CUR;

	v_total_count	 					NUMBER;
	v_tag_group_id						NUMBER;
	v_name								tag_group_description.name%TYPE;
	v_lookup_key						tag_group.lookup_key%TYPE;
	v_mandatory							NUMBER;
	v_multi_select						NUMBER;
	v_applies_to_inds					NUMBER;
	v_applies_to_regions				NUMBER;
	v_applies_to_non_compliances		NUMBER;
	v_applies_to_suppliers				NUMBER;
	v_applies_to_chain					NUMBER;
	v_applies_to_chain_activities		NUMBER;
	v_applies_to_initiatives			NUMBER;
	v_applies_to_chn_product_types		NUMBER;
	v_applies_to_chn_products			NUMBER;
	v_applies_to_chn_product_supps		NUMBER;
	v_applies_to_quick_survey			NUMBER;
	v_applies_to_audits					NUMBER;
	v_applies_to_compliances			NUMBER;
	v_is_hierarchical					NUMBER;
	
	v_actual_count						NUMBER;
BEGIN
	integration_api_pkg.GetTagGroup(
		in_tag_group_id				=> in_test_tag_group_id,
		out_cur						=> v_cur,
		out_descriptions_cur		=> v_descriptions_cur,
		out_tags_cur				=> v_tags_cur,
		out_tag_descriptions_cur	=> v_tag_descriptions_cur
	);
	
	v_actual_count := 0;
	LOOP
		FETCH v_cur INTO
				v_tag_group_id, v_name, v_lookup_key, v_mandatory, v_multi_select,
				v_applies_to_inds, v_applies_to_regions,  
				v_applies_to_non_compliances, v_applies_to_suppliers, 
				v_applies_to_chain, v_applies_to_chain_activities, v_applies_to_initiatives,
				v_applies_to_chn_product_types,
				v_applies_to_chn_products,
				v_applies_to_chn_product_supps,
				v_applies_to_quick_survey, v_applies_to_audits, v_applies_to_compliances,
				v_is_hierarchical
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
		IF v_lookup_key = in_lookup_key THEN
			unit_test_pkg.AssertIsTrue(v_name = in_name 
				AND v_mandatory = in_flag_val AND v_multi_select = 0 
				AND v_applies_to_inds = in_flag_val AND v_applies_to_regions = 0,
				'Expected tag group');
		ELSE
			unit_test_pkg.TestFail('Only expected tag groups', 'Unexpected tag group found');
		END IF;
	END LOOP;

	INT_CheckGetTGrpCursorCounts(v_descriptions_cur, v_tags_cur, v_tag_descriptions_cur, in_d_count, in_t_count, in_td_count);
	
	unit_test_pkg.AssertIsTrue(3 = v_total_count, 'Expected count');
END;

PROCEDURE TestUpsertTagGroup AS
	v_test_tag_group_id					NUMBER;
	v_count								NUMBER;
BEGIN
	integration_api_pkg.UpsertTagGroup(
		in_name	=> 'TG1',
		in_lookup_key => 'TESTGETTAGGROUPS_TG1',
		in_mandatory => 1,
		in_applies_to_inds => 1,
		out_tag_group_id => v_test_tag_group_id
	);

	INT_CheckTagGroupUpsertResult(v_test_tag_group_id, 'TG1', 'TESTGETTAGGROUPS_TG1', 1, 1, 0, 0);
	
	integration_api_pkg.UpsertTagGroupDescription(
		in_tag_group_id	=> v_test_tag_group_id,
		in_name				=> 'TG1-en',
		in_lang => 'en'
	);

	integration_api_pkg.UpsertTagGroupDescription(
		in_tag_group_id	=> v_test_tag_group_id,
		in_name				=> 'TG1-fr',
		in_lang => 'fr'
	);

	integration_api_pkg.UpsertTagGroupDescription(
		in_tag_group_id	=> v_test_tag_group_id,
		in_name				=> 'TG1-es',
		in_lang => 'es'
	);
	
	INT_CheckTagGroupUpsertResult(v_test_tag_group_id, 'TG1-en', 'TESTGETTAGGROUPS_TG1', 1, 3, 0, 0);
	
	v_count := 0;
	FOR r IN (SELECT * FROM tag_group_description WHERE tag_group_id = v_test_tag_group_id) LOOP
		v_count := v_count + 1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(3 = v_count, 'Expected count (tgd)');


	integration_api_pkg.UpsertTagGroup(
		in_tag_group_id => v_test_tag_group_id,
		in_name	=> 'TG2',
		in_lookup_key => 'TESTGETTAGGROUPS_TG2',
		in_mandatory => 0,
		in_applies_to_inds => 0,
		out_tag_group_id => v_test_tag_group_id
	);

	INT_CheckTagGroupUpsertResult(v_test_tag_group_id, 'TG2', 'TESTGETTAGGROUPS_TG2', 0, 3, 0, 0);
	
	integration_api_pkg.UpsertTagGroupDescription(
		in_tag_group_id	=> v_test_tag_group_id,
		in_name				=> 'TG2-en',
		in_lang => 'en'
	);

	integration_api_pkg.UpsertTagGroupDescription(
		in_tag_group_id	=> v_test_tag_group_id,
		in_name				=> 'TG2-fr',
		in_lang => 'fr'
	);

	integration_api_pkg.UpsertTagGroupDescription(
		in_tag_group_id	=> v_test_tag_group_id,
		in_name				=> 'TG2-es',
		in_lang => 'es'
	);
	
	INT_CheckTagGroupUpsertResult(v_test_tag_group_id, 'TG2-en', 'TESTGETTAGGROUPS_TG2', 0, 3, 0, 0);

	
	tag_pkg.DeleteTagGroup(
		in_act_id => security.security_pkg.getact,
		in_tag_group_id => v_test_tag_group_id
	);
END;

PROCEDURE INTERNAL_CheckTagUpsertResult(in_test_tag_group_id NUMBER, in_name VARCHAR2, in_lookup_key VARCHAR2, in_marker VARCHAR2 := '')
AS
	v_cur					security_pkg.T_OUTPUT_CUR;
	v_descriptions_cur		security_pkg.T_OUTPUT_CUR;
	v_tags_cur				security_pkg.T_OUTPUT_CUR;
	v_tag_descriptions_cur	security_pkg.T_OUTPUT_CUR;

	v_total_count	 					NUMBER; 
	v_tag_group_id						NUMBER; 
	v_name								tag_group_description.name%TYPE; 
	v_lookup_key						tag_group.lookup_key%TYPE;
	v_mandatory							NUMBER;
	v_multi_select						NUMBER;
	v_applies_to_inds					NUMBER;
	v_applies_to_regions				NUMBER;
	v_applies_to_non_compliances		NUMBER;
	v_applies_to_suppliers				NUMBER;
	v_applies_to_chain					NUMBER;
	v_applies_to_chain_activities		NUMBER;
	v_applies_to_initiatives			NUMBER;
	v_applies_to_chn_product_types		NUMBER;
	v_applies_to_chn_products			NUMBER;
	v_applies_to_chn_product_supps		NUMBER;
	v_applies_to_quick_survey			NUMBER;
	v_applies_to_audits					NUMBER;
	v_applies_to_compliances			NUMBER;
	v_is_hierarchical					NUMBER;

	v_tag_id							NUMBER; 
	v_tag								tag_description.tag%TYPE;
	v_explanation						tag_description.explanation%TYPE;
	v_pos								NUMBER; 
	v_tag_lookup_key					tag.lookup_key%TYPE;
	v_exclude_from_dv_grouping			NUMBER; 
	v_active							NUMBER; 
	v_lang								tag_description.lang%TYPE;
	v_last_changed_dtm					tag_description.last_changed_dtm%TYPE;
	v_parent_id							NUMBER;

	v_actual_count						NUMBER;
BEGIN
	integration_api_pkg.GetTagGroup(
		in_tag_group_id				=> in_test_tag_group_id,
		out_cur						=> v_cur,
		out_descriptions_cur		=> v_descriptions_cur,
		out_tags_cur				=> v_tags_cur,
		out_tag_descriptions_cur	=> v_tag_descriptions_cur
	);
	
	v_actual_count := 0;
	LOOP
		FETCH v_cur INTO 
				v_tag_group_id, v_name,
				v_lookup_key, v_mandatory, v_multi_select,
				v_applies_to_inds, v_applies_to_regions,  
				v_applies_to_non_compliances, v_applies_to_suppliers, 
				v_applies_to_chain, v_applies_to_chain_activities, v_applies_to_initiatives,
				v_applies_to_chn_product_types,
				v_applies_to_chn_products,
				v_applies_to_chn_product_supps,
				v_applies_to_quick_survey, v_applies_to_audits, v_applies_to_compliances,
				v_is_hierarchical
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
		IF v_lookup_key = in_lookup_key THEN
			unit_test_pkg.AssertIsTrue(v_name = in_marker||in_name,
				'Expected tag group '||in_marker||in_name||' got '||v_name);
		ELSE
			unit_test_pkg.TestFail('Only expected tag groups', 'Unexpected tag group found');
		END IF;
	END LOOP;

	unit_test_pkg.AssertIsTrue(1 = v_actual_count, 'Expected count (tag group) is '||v_actual_count||' not 1');
	
	v_actual_count := 0;
	LOOP
		FETCH v_descriptions_cur INTO 
				v_tag_group_id, v_lang, v_name, v_last_changed_dtm
		;
		EXIT WHEN v_descriptions_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
		IF v_name LIKE in_marker||in_name||'%' THEN
			unit_test_pkg.AssertIsTrue(v_lang = 'en', 'Expected tag group lang');
		ELSE
			unit_test_pkg.TestFail('Only expected tag group langs', 'Unexpected tag lang group found');
		END IF;
	END LOOP;
	
	unit_test_pkg.AssertIsTrue(1 = v_actual_count, 'Expected count (tag group descriptions) is '||v_actual_count||' not 1');
	
	v_actual_count := 0;
	LOOP
		FETCH v_tags_cur INTO 
				v_tag_id, v_tag, v_explanation, v_pos, v_tag_lookup_key, v_exclude_from_dv_grouping, v_active, v_tag_group_id, v_parent_id;
		EXIT WHEN v_tags_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
		IF v_tag_lookup_key LIKE in_marker||'Tag LK%' THEN
			unit_test_pkg.AssertIsTrue(v_active = 1 AND (v_pos >= 1 AND v_pos <= 5) AND v_tag_group_id = in_test_tag_group_id,
				'Expected tag pos');
		ELSE
			unit_test_pkg.TestFail('Only expected tags', 'Unexpected tag found');
		END IF;
	END LOOP;
	
	unit_test_pkg.AssertIsTrue(5 = v_actual_count, 'Expected count (tags) is '||v_actual_count||' not 5');
	
	v_actual_count := 0;
	LOOP
		FETCH v_tag_descriptions_cur INTO 
				v_tag_id, v_lang, v_tag, v_explanation, v_last_changed_dtm
		;
		EXIT WHEN v_tag_descriptions_cur%NOTFOUND;
		v_actual_count := v_actual_count + 1;
		IF v_tag_lookup_key LIKE in_marker||'Tag LK%' THEN
			unit_test_pkg.AssertIsTrue(v_lang = 'en' OR v_lang = 'fr', 'Expected tag lang');
		ELSE
			unit_test_pkg.TestFail('Only expected tags', 'Unexpected tag found');
		END IF;
	END LOOP;
	
	unit_test_pkg.AssertIsTrue(10 = v_actual_count, 'Expected count (tags descriptions) is '||v_actual_count||' not 10');
END;


PROCEDURE TestUpsertTag AS
	v_test_tag_group_id					NUMBER;
	v_tag_id							tag.tag_id%TYPE;
	v_count								NUMBER;

	TYPE t_ids IS TABLE OF tag.tag_id%TYPE;
	v_tag_ids t_ids := t_ids();

	BEGIN
	integration_api_pkg.UpsertTagGroup(
		in_name	=> 'TG1',
		in_lookup_key => 'TESTGETTAGGROUPS_TG1',
		in_mandatory => 1,
		in_applies_to_inds => 1,
		out_tag_group_id => v_test_tag_group_id
	);

	INT_CheckTagGroupUpsertResult(v_test_tag_group_id, 'TG1', 'TESTGETTAGGROUPS_TG1', 1, 1, 0, 0);
	
	integration_api_pkg.UpsertTagGroupDescription(
		in_tag_group_id	=> v_test_tag_group_id,
		in_name				=> 'TG1-en',
		in_lang => 'en'
	);

	INT_CheckTagGroupUpsertResult(v_test_tag_group_id, 'TG1-en', 'TESTGETTAGGROUPS_TG1', 1, 1, 0, 0);
	
	v_count := 0;
	SELECT COUNT(*) INTO v_count FROM tag_group_description WHERE tag_group_id = v_test_tag_group_id;
	unit_test_pkg.AssertIsTrue(1 = v_count, 'Expected count (tgd)');
	
	FOR i IN 1..5 LOOP
		integration_api_pkg.UpsertTag(
			in_tag_group_id				=> v_test_tag_group_id,
			in_tag						=> 'Tag '||i,
			in_explanation				=> 'Explanation '||i,
			in_lookup_key				=> 'Tag LK '||i,
			in_pos						=> i,
			in_active					=> 1,
			out_tag_id					=> v_tag_id
		);

		v_tag_ids.extend;
		v_tag_ids(i) := v_tag_id;
		
		integration_api_pkg.UpsertTagDescription(
			in_tag_id					=> v_tag_id,
			in_tag						=> 'Tag-en '||i,
			in_explanation				=> 'Explanation-en '||i,
			in_lang						=> 'en'
		);

		integration_api_pkg.UpsertTagDescription(
			in_tag_id					=> v_tag_id,
			in_tag						=> 'Tag-fr '||i,
			in_explanation				=> 'Explanation-fr '||i,
			in_lang						=> 'fr'
		);

		v_count := 0;
		SELECT COUNT(*) INTO v_count FROM tag_group_member WHERE tag_group_id = v_test_tag_group_id;
		unit_test_pkg.AssertIsTrue(i = v_count, 'Expected count (tgm)');
		
		v_count := 0;
		SELECT COUNT(*) INTO v_count FROM tag_description WHERE tag_id = v_tag_id;
		unit_test_pkg.AssertIsTrue(2 = v_count, 'Expected count (td)');
		
	END LOOP;

	INTERNAL_CheckTagUpsertResult(v_test_tag_group_id, 'TG1-en', 'TESTGETTAGGROUPS_TG1');
	
	integration_api_pkg.UpsertTagGroupDescription(
		in_tag_group_id	=> v_test_tag_group_id,
		in_name				=> 'UTG1-en',
		in_lang => 'en'
	);

	FOR i IN 1..5 LOOP
		integration_api_pkg.UpsertTag(
			in_tag_group_id				=> v_test_tag_group_id,
			in_tag_id					=> v_tag_ids(i),
			in_tag						=> 'UTag '||i,
			in_explanation				=> 'UExplanation '||i,
			in_lookup_key				=> 'UTag LK '||i,
			in_pos						=> i,
			in_active					=> 1,
			out_tag_id					=> v_tag_id
		);

		integration_api_pkg.UpsertTagDescription(
			in_tag_id					=> v_tag_id,
			in_tag						=> 'UTag-en '||i,
			in_explanation				=> 'Explanation-en '||i,
			in_lang						=> 'en'
		);

		integration_api_pkg.UpsertTagDescription(
			in_tag_id					=> v_tag_id,
			in_tag						=> 'UTag-fr '||i,
			in_explanation				=> 'Explanation-fr '||i,
			in_lang						=> 'fr'
		);

		v_count := 0;
		SELECT COUNT(*) INTO v_count FROM tag_group_member WHERE tag_group_id = v_test_tag_group_id;
		unit_test_pkg.AssertIsTrue(5 = v_count, 'Expected count (tgm)');
		
		v_count := 0;
		SELECT COUNT(*) INTO v_count FROM tag_description WHERE tag_id = v_tag_id;
		unit_test_pkg.AssertIsTrue(2 = v_count, 'Expected count (td)');
		
	END LOOP;

	INTERNAL_CheckTagUpsertResult(v_test_tag_group_id, 'TG1-en', 'TESTGETTAGGROUPS_TG1', 'U');


	tag_pkg.DeleteTagGroup(
		in_act_id => security.security_pkg.getact,
		in_tag_group_id => v_test_tag_group_id
	);
END;

END test_int_api_tags_pkg;
/
