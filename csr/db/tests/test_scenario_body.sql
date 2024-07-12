CREATE OR REPLACE PACKAGE BODY csr.test_scenario_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDownFixture
AS
	v_sids		security.T_SID_TABLE;
	v_count		NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE GetRuleIndTreeWithSelect
AS
	v_in_indicators						security_pkg.T_SID_IDS;
	v_in_parent_sids					security_pkg.T_SID_IDS;
	v_in_include_root					NUMBER;
	v_in_select_sid						security_pkg.T_SID_ID;
	v_in_fetch_depth					NUMBER;
	v_cur								SYS_REFCURSOR;
	-- the cursor contents...
	v_cur_app_sid						NUMBER;
	v_cur_ind_sid						NUMBER;
	v_cur_description					VARCHAR2(100);
	v_cur_ind_type						NUMBER(10, 0);
	v_cur_measure_sid					NUMBER;
	v_cur_measure_description			VARCHAR2(100);
	v_cur_format_mask					varchar2(255);
	v_cur_active						NUMBER;
	v_cur_class_name					VARCHAR2(255);
	v_cur_level							NUMBER;
	v_cur_is_leaf						NUMBER(1,0);

	v_count								NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.scenario_pkg.GetRuleIndTreeWithSelect');
	
	v_in_indicators(1) := unit_test_pkg.GetOrCreateInd('RULE_IND_TREE_1_GetRuleIndTreeWithSelect');
	SELECT ind_root_sid
	  INTO v_in_parent_sids(1)
	  FROM csr.customer;

	v_in_include_root := 1;
	v_in_select_sid := 1;
	v_in_fetch_depth := 1;

	scenario_pkg.GetRuleIndTreeWithSelect(
		in_indicators => v_in_indicators,
		in_parent_sids => v_in_parent_sids,
		in_include_root => v_in_include_root,
		in_select_sid => v_in_select_sid,
		in_fetch_depth => v_in_fetch_depth,
		out_cur => v_cur
	);

	COMMIT; --To simulate ORA-01002: fetch out of sequence

	v_count := 0;
	LOOP
		FETCH v_cur INTO 
			v_cur_ind_sid,
			v_cur_description,
			v_cur_class_name,
			v_cur_ind_type,
			v_cur_measure_sid,
			v_cur_measure_description,
			v_cur_level,
			v_cur_is_leaf,
			v_cur_active,
			v_cur_format_mask
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 result');

	indicator_pkg.DeleteObject(security.security_pkg.getACT, v_in_indicators(1));
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_in_indicators(1));
END;

PROCEDURE GetRuleIndListTagFiltered
AS
	v_in_indicators						security_pkg.T_SID_IDS;
	v_in_parent_sids					security_pkg.T_SID_IDS;
	v_in_include_root					NUMBER;
	v_in_search_phrase					varchar2(255);
	v_in_tag_group_count				NUMBER;
	v_in_fetch_limit					NUMBER;
	v_cur								SYS_REFCURSOR;
	-- the cursor contents...
	v_cur_app_sid						NUMBER;
	v_cur_sid							NUMBER;
	v_cur_description					VARCHAR2(100);
	v_cur_ind_type						NUMBER(10, 0);
	v_cur_measure_sid					NUMBER;
	v_cur_measure_description			VARCHAR2(100);
	v_cur_format_mask					varchar2(255);
	v_cur_active						NUMBER;
	v_cur_class_name					varchar2(255);
	v_cur_level							NUMBER;
	v_cur_is_leaf						NUMBER(1,0);
	v_cur_path							varchar2(255);
	v_cur_rownum						NUMBER(1,0);
	v_count								NUMBER;

	v_tag_group_id						security_pkg.T_SID_ID;
	v_tags								security_pkg.T_SID_IDS;
	v_app_sid							security.security_pkg.T_SID_ID;
	v_act_id							security.security_pkg.T_ACT_ID;
	v_search_tag_table					T_SEARCH_TAG_TABLE;
BEGIN
	unit_test_pkg.StartTest('csr.scenario_pkg.GetRuleIndListTagFiltered');
	
	v_in_indicators(1) := unit_test_pkg.GetOrCreateInd('RULE_IND_TREE_1_GetRuleIndListTagFiltered');

	SELECT ind_root_sid
	  INTO v_in_parent_sids(1)
	  FROM csr.customer;

	v_tag_group_id :=	unit_test_pkg.GetOrCreateTagGroup(
			in_lookup_key			=>	'TAG_GRP_1_RuleIndList',
			in_multi_select			=>	0,
			in_applies_to_inds		=>	1,
			in_applies_to_regions	=>	0,
			in_tag_members			=>	'TAG_1_RuleIndListTag'
		);

	v_tags(1) := unit_test_pkg.GetOrCreateTag('TAG_1_RuleIndListTag', v_tag_group_id);
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');

	INSERT INTO IND_TAG (app_sid, tag_id, ind_sid)
		VALUES (v_app_sid, v_tags(1), v_in_indicators(1));
		
	INSERT INTO search_tag (set_id,tag_id)
		VALUES ( 1, v_tags(1));

	v_in_include_root := 1;
	v_in_search_phrase := 'GetRuleIndListTagFiltered';
	v_in_tag_group_count := 1;
	v_in_fetch_limit := 1;
	
	scenario_pkg.GetRuleIndListTagFiltered(
		in_indicators => v_in_indicators,
		in_parent_sids => v_in_parent_sids,
		in_include_root => v_in_include_root,
		in_search_phrase => v_in_search_phrase,
		in_tag_group_count => v_in_tag_group_count,
		in_fetch_limit => v_in_fetch_limit,
		out_cur => v_cur
	);

	COMMIT; --To simulate ORA-01002: fetch out of sequence

	v_count := 0;
	LOOP
		FETCH v_cur INTO
			v_cur_sid,
			v_cur_class_name,
			v_cur_description,
			v_cur_ind_type,
			v_cur_measure_sid,
			v_cur_level,
			v_cur_is_leaf,
			v_cur_path,
			v_cur_active,
			v_cur_rownum,
			v_cur_measure_description,
			v_cur_format_mask
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 result');

	-- --Clean-up
	indicator_pkg.DeleteObject(security.security_pkg.getACT, v_in_indicators(1));
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_in_indicators(1));
	tag_pkg.DeleteTagGroup(
			in_act_id			=> v_act_id,
			in_tag_group_id		=> v_tag_group_id
		);
	DELETE FROM ind_tag WHERE tag_id = v_tags(1) AND app_sid = v_app_sid;
END;

PROCEDURE GetRuleIndTreeWithDepth
AS
	v_in_indicators						security_pkg.T_SID_IDS;
	v_in_parent_sids					security_pkg.T_SID_IDS;
	v_in_include_root					NUMBER;
	v_in_fetch_depth					NUMBER;
	v_cur								SYS_REFCURSOR;
	-- the cursor contents...
	v_cur_app_sid						NUMBER;
	v_cur_ind_sid						NUMBER;
	v_cur_description					VARCHAR2(100);
	v_cur_ind_type						NUMBER(10, 0);
	v_cur_measure_sid					NUMBER;
	v_cur_measure_description			VARCHAR2(100);
	v_cur_format_mask					varchar2(255);
	v_cur_active						NUMBER;
	v_cur_class_name					varchar2(255);
	v_cur_level							NUMBER;
	v_cur_is_leaf						NUMBER(1,0);
	v_rowNum							NUMBER(1,0);

	v_count								NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.scenario_pkg.GetRuleIndTreeWithDepth');
	
	v_in_indicators(1) := unit_test_pkg.GetOrCreateInd('RULE_IND_TREE_1_GetRuleIndTreeWithDepth');
	SELECT ind_root_sid
	  INTO v_in_parent_sids(1)
	  FROM csr.customer;

	v_in_include_root := 1;
	v_in_fetch_depth := 1;
	
	scenario_pkg.GetRuleIndTreeWithDepth(
		in_indicators => v_in_indicators,
		in_parent_sids => v_in_parent_sids,
		in_include_root => v_in_include_root,
		in_fetch_depth => v_in_fetch_depth,
		out_cur => v_cur
	);

	COMMIT; --To simulate ORA-01002: fetch out of sequence

	v_count := 0;
	LOOP
		FETCH v_cur INTO
			v_cur_ind_sid,
			v_cur_description,
			v_cur_ind_type,
			v_cur_measure_sid,
			v_cur_measure_description,
			v_cur_level,
			v_cur_active,
			v_cur_is_leaf,
			v_cur_class_name,
			v_cur_format_mask
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 result');

	indicator_pkg.DeleteObject(security.security_pkg.getACT, v_in_indicators(1));
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_in_indicators(1));
END;

PROCEDURE GetRuleIndTreeTextFiltered
AS
	v_in_indicators						security_pkg.T_SID_IDS;
	v_in_parent_sids					security_pkg.T_SID_IDS;
	v_in_include_root					NUMBER;
	v_in_search_phrase					varchar2(255);
	v_cur								SYS_REFCURSOR;
	-- the cursor contents...
	v_cur_app_sid						NUMBER;
	v_cur_ind_sid						NUMBER;
	v_cur_description					VARCHAR2(100);
	v_cur_ind_type						varchar2(255);
	v_cur_measure_sid					NUMBER;
	v_cur_measure_description			VARCHAR2(100);
	v_cur_format_mask					varchar2(255);
	v_cur_active						NUMBER;
	v_cur_class_name					varchar2(255);
	v_cur_level							NUMBER;
	v_cur_is_leaf						NUMBER(1,0);
	v_rowNum							NUMBER(1,0);

	v_count								NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.scenario_pkg.GetRuleIndTreeTextFiltered');
	
	v_in_indicators(1) := unit_test_pkg.GetOrCreateInd('RULE_IND_TREE_1_GetRuleIndTreeTextFiltered');
	SELECT ind_root_sid
	  INTO v_in_parent_sids(1)
	  FROM csr.customer;

	v_in_include_root := 1;
	v_in_search_phrase := 'GetRuleIndTreeTextFiltered';
	
	scenario_pkg.GetRuleIndTreeTextFiltered(
		in_indicators => v_in_indicators,
		in_parent_sids => v_in_parent_sids,
		in_include_root => v_in_include_root,
		in_search_phrase => v_in_search_phrase,
		out_cur => v_cur
	);

	COMMIT; --To simulate ORA-01002: fetch out of sequence

	v_count := 0;
	LOOP
		FETCH v_cur INTO
			v_cur_ind_sid,
			v_cur_description,
			v_cur_ind_type,
			v_cur_measure_sid,
			v_cur_measure_description,
			v_cur_level,
			v_cur_active,
			v_cur_is_leaf,
			v_cur_class_name,
			v_cur_format_mask
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 results');

	indicator_pkg.DeleteObject(security.security_pkg.getACT, v_in_indicators(1));
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_in_indicators(1));
END;

PROCEDURE GetRuleIndTreeTagFiltered
AS
	v_in_indicators						security_pkg.T_SID_IDS;
	v_in_parent_sids					security_pkg.T_SID_IDS;
	v_in_include_root					NUMBER;
	v_in_search_phrase					varchar2(255);
	v_in_tag_group_count				NUMBER;
	v_cur								SYS_REFCURSOR;
	-- the cursor contents...
	v_cur_app_sid						NUMBER;
	v_cur_sid							NUMBER;
	v_cur_description					VARCHAR2(100);
	v_cur_ind_type						NUMBER(10, 0);
	v_cur_measure_sid					NUMBER;
	v_cur_measure_description			VARCHAR2(100);
	v_cur_format_mask					varchar2(255);
	v_cur_active						NUMBER;
	v_cur_class_name					varchar2(255);
	v_cur_level							NUMBER;
	v_cur_is_leaf						NUMBER(1,0);
	v_rowNum							NUMBER(1,0);
	v_count								NUMBER;

	v_tag_group_id						security_pkg.T_SID_ID;
	v_tags								security_pkg.T_SID_IDS;
	v_app_sid							security.security_pkg.T_SID_ID;
	v_act_id							security.security_pkg.T_ACT_ID;
	
BEGIN
	unit_test_pkg.StartTest('csr.scenario_pkg.GetRuleIndTreeTagFiltered');
	
	v_in_indicators(1) := unit_test_pkg.GetOrCreateInd('RULE_IND_TREE_1_GetRuleIndTreeTagFiltered');
	SELECT ind_root_sid
	  INTO v_in_parent_sids(1)
	  FROM csr.customer;

	v_tag_group_id :=	unit_test_pkg.GetOrCreateTagGroup(
			in_lookup_key			=>	'TAG_GRP_1_RuleIndTree',
			in_multi_select			=>	0,
			in_applies_to_inds		=>	1,
			in_applies_to_regions	=>	0,
			in_tag_members			=>	'TAG_1_GetRuleIndTreeTag'
		);

	v_tags(1) := unit_test_pkg.GetOrCreateTag('TAG_1_GetRuleIndTreeTag', v_tag_group_id);
	
	v_in_include_root := 1;
	v_in_search_phrase := 'GetRuleIndTreeTagFiltered';
	v_in_tag_group_count := 1;
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');

	INSERT INTO ind_tag (app_sid, tag_id, ind_sid)
		VALUES (v_app_sid, v_tags(1), v_in_indicators(1));

	INSERT INTO search_tag (set_id,tag_id) 
		VALUES ( 1, v_tags(1));

	scenario_pkg.GetRuleIndTreeTagFiltered(
		in_indicators => v_in_indicators,
		in_parent_sids => v_in_parent_sids,
		in_include_root => v_in_include_root,
		in_search_phrase => v_in_search_phrase,
		in_tag_group_count => v_in_tag_group_count,
		out_cur => v_cur
	);

	COMMIT; --To simulate ORA-01002: fetch out of sequence

	v_count := 0;
	LOOP
		FETCH v_cur INTO
			v_cur_sid,
			v_cur_class_name,
			v_cur_description,
			v_cur_ind_type,
			v_cur_measure_sid,
			v_cur_level,
			v_cur_is_leaf,
			v_cur_active,
			v_cur_measure_description,
			v_cur_format_mask
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
		
	IF v_cur_level = 1 THEN
		unit_test_pkg.AssertAreEqual(v_in_parent_sids(1), v_cur_sid, 'Parent sid of the indicator should match');
	END IF;

	IF v_cur_level = 2 THEN
		unit_test_pkg.AssertAreEqual(v_in_indicators(1), v_cur_sid, 'Indicator sid, at child level should match');
	END IF;
	END LOOP;

	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 result');

	--Clean-up
	indicator_pkg.DeleteObject(security.security_pkg.getACT, v_in_indicators(1));
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_in_indicators(1));
	tag_pkg.DeleteTagGroup(
			in_act_id			=> v_act_id,
			in_tag_group_id		=> v_tag_group_id
		);
	DELETE FROM ind_tag WHERE tag_id = v_tags(1) AND app_sid = v_app_sid;
END;

PROCEDURE GetRuleIndListTextFiltered
AS
	v_in_indicators						security_pkg.T_SID_IDS;
	v_in_parent_sids					security_pkg.T_SID_IDS;
	v_in_include_root					NUMBER;
	v_in_search_phrase					varchar2(255);
	v_in_fetch_limit					NUMBER;
	v_cur								SYS_REFCURSOR;
	-- the cursor contents...
	v_cur_app_sid						NUMBER;
	v_cur_ind_sid						NUMBER;
	v_cur_description					VARCHAR2(100);
	v_cur_ind_type						NUMBER(10, 0);
	v_cur_measure_sid					NUMBER;
	v_cur_measure_description			VARCHAR2(100);
	v_cur_format_mask					varchar2(255);
	v_cur_active						NUMBER;
	v_cur_class_name					varchar2(255);
	v_cur_level							NUMBER;
	v_cur_is_leaf						NUMBER(1,0);
	v_rowNum							NUMBER(1,0);

	v_count								NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.scenario_pkg.GetRuleIndListTextFiltered');
	
	v_in_indicators(1) := unit_test_pkg.GetOrCreateInd('RULE_IND_TREE_1_GetRuleIndListTextFiltered');
	SELECT ind_root_sid
	  INTO v_in_parent_sids(1)
	  FROM csr.customer;

	v_in_include_root := 1;
	v_in_search_phrase := 'GetRuleIndListTextFiltered';
	v_in_fetch_limit := 1;
	
	scenario_pkg.GetRuleIndListTextFiltered(
		in_indicators => v_in_indicators,
		in_parent_sids => v_in_parent_sids,
		in_include_root => v_in_include_root,
		in_search_phrase => v_in_search_phrase,
		in_fetch_limit => v_in_fetch_limit,
		out_cur => v_cur
	);

	COMMIT; --To simulate ORA-01002: fetch out of sequence

	v_count := 0;
	LOOP
		FETCH v_cur INTO
			v_cur_ind_sid,
			v_cur_class_name,
			v_cur_description,
			v_cur_ind_type,
			v_cur_measure_sid,
			v_cur_level,
			v_cur_is_leaf,
			v_cur_measure_description,
			v_cur_active,
			v_cur_measure_description,
			v_cur_format_mask
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 result');

	-- Test with no match on search
	v_in_include_root := 1;
	v_in_search_phrase := 'Unmatched search string';
	v_in_fetch_limit := 1;
	
	scenario_pkg.GetRuleIndListTextFiltered(
		in_indicators => v_in_indicators,
		in_parent_sids => v_in_parent_sids,
		in_include_root => v_in_include_root,
		in_search_phrase => v_in_search_phrase,
		in_fetch_limit => v_in_fetch_limit,
		out_cur => v_cur
	);

	COMMIT; --To simulate ORA-01002: fetch out of sequence

	v_count := 0;
	LOOP
		FETCH v_cur INTO
			v_cur_ind_sid,
			v_cur_class_name,
			v_cur_description,
			v_cur_ind_type,
			v_cur_measure_sid,
			v_cur_level,
			v_cur_is_leaf,
			v_cur_measure_description,
			v_cur_active,
			v_cur_measure_description,
			v_cur_format_mask
		;
		EXIT WHEN v_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');

	indicator_pkg.DeleteObject(security.security_pkg.getACT, v_in_indicators(1));
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_in_indicators(1));
END;

END;
/
