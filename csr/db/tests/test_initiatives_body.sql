CREATE OR REPLACE PACKAGE BODY CSR.test_initiatives_pkg AS

v_site_name					VARCHAR2(200);
v_ind_1_sid					security_pkg.T_SID_ID;
v_measure_1_sid				security_pkg.T_SID_ID;
v_flow_state_group_1_id		csr.flow_state_group.flow_state_group_id%TYPE;
v_flow_state_group_ids		security_pkg.T_SID_IDS;
v_metric_1_id				csr.initiative_metric.initiative_metric_id%TYPE;
out_metric_id 				csr.initiative_metric.initiative_metric_id%TYPE;
out_prj_sid					security_pkg.T_SID_ID;
out_aggr_tag_group_id		security_pkg.T_SID_ID;

PROCEDURE AssertIndicatorType(
	in_ind_sid 				IN csr.ind.ind_sid%TYPE,
	in_expected_ind_type	IN csr.ind.ind_type%TYPE
)
AS
	v_lookup_key			   csr.ind.lookup_key%TYPE;
	v_actual_ind_type		   csr.ind.ind_type%TYPE;
BEGIN
	SELECT ind_type, lookup_key
	  INTO v_actual_ind_type, v_lookup_key
	  FROM csr.ind
	 WHERE ind_sid = in_ind_sid;
	
	csr.unit_test_pkg.AssertAreEqual(
		in_expected_ind_type,
		v_actual_ind_type,
		'Incorrect indicator ind_type ' || v_lookup_key);
END;

PROCEDURE AssertIndicatorIsManaged(
	in_ind_sid 				IN csr.ind.ind_sid%TYPE,
	in_expected_managed		IN csr.ind.is_system_managed%TYPE
)
AS
	v_lookup_key			   csr.ind.lookup_key%TYPE;
	v_actual_managed		   csr.ind.ind_type%TYPE;
BEGIN
	SELECT is_system_managed, lookup_key
	  INTO v_actual_managed, v_lookup_key
	  FROM csr.ind
	 WHERE ind_sid = in_ind_sid;
	
	csr.unit_test_pkg.AssertAreEqual(
		in_expected_managed,
		v_actual_managed,
		'Incorrect indicator is_system_managed ' || v_lookup_key);
END;

PROCEDURE InitiativeAdminAddMetricMapping
AS
	v_aggr_tag_group_ids security_pkg.T_SID_IDS;
BEGIN
	csr.initiative_metric_pkg.SaveInitiativeMetricMapping(
		in_metric_id			=> v_metric_1_id,
		in_ind_sid				=> v_ind_1_sid,
		in_flow_state_group_ids => v_flow_state_group_ids,
		in_aggr_tag_group_ids	=> v_aggr_tag_group_ids
	);
	
	AssertIndicatorType(v_ind_1_sid, 3);
	AssertIndicatorIsManaged(v_ind_1_sid, 1);
END;

PROCEDURE InitiativeAdminRemoveMetricMapping
AS
	v_aggr_tag_group_ids security_pkg.T_SID_IDS;
BEGIN
	csr.initiative_metric_pkg.DeleteInitiativeMetricMapping(
		in_metric_id			=> v_metric_1_id,
		in_ind_sid				=> v_ind_1_sid
	);
	
	AssertIndicatorType(v_ind_1_sid, 0);
	AssertIndicatorIsManaged(v_ind_1_sid, 0);
END;

PROCEDURE InitiativeAdminAddMetric
AS
	v_measure_sid				security_pkg.T_SID_ID;
	v_label						csr.initiative_metric.label%TYPE;
	in_label						csr.initiative_metric.label%TYPE;
    v_lookup_key				csr.initiative_metric.lookup_key%TYPE;
BEGIN	
	SELECT dbms_random.string('p',10)
	  INTO v_lookup_key
	  FROM dual;
	SELECT dbms_random.string('p',10)
	  INTO v_label
	  FROM dual;

	SELECT measure_sid
	  INTO v_measure_sid
	  FROM csr.measure 
	  WHERE name = 'GJ'
	  ORDER BY measure_sid DESC
	  FETCH FIRST ROW ONLY;

	csr.initiative_metric_pkg.AddInitiativeMetric(
		in_measure_sid				=> v_measure_sid,
		in_label					=> v_label,
		in_is_during				=> 1,
		in_is_running				=> 0,
		in_is_rampable				=> 0,
		in_per_period_duration		=> 0,
		in_one_off_period			=> 0,
		in_divisibility				=> 1,
		in_lookup_key				=> v_lookup_key,
		in_is_external				=> 0,
		out_initiative_metric_id	=> out_metric_id
	);

	SELECT label
	  INTO in_label
	  FROM csr.initiative_metric
	 WHERE initiative_metric_id = out_metric_id;

	csr.unit_test_pkg.AssertAreEqual(
		v_label,
		in_label,
		'Incorrect label. Expected : ' || v_label || ' Actual : ' || in_label);
END;

PROCEDURE InitiativeAdminRemoveMetric
AS
	v_initiative_metric_count	NUMBER;
BEGIN	
	csr.initiative_metric_pkg.DeleteInitiativeMetric(
		in_initiative_metric_id	=> out_metric_id
	);

	SELECT COUNT(initiative_metric_id)
	  INTO v_initiative_metric_count
	  FROM csr.initiative_metric
	 WHERE initiative_metric_id = out_metric_id;

	csr.unit_test_pkg.AssertAreEqual(0, v_initiative_metric_count, 'Expected metric count: 0. Actual: ' || v_initiative_metric_count);
END;


PROCEDURE InitiativeAdminAddType
AS
	v_project_name				csr.initiative_project.name%TYPE;
	v_name						csr.initiative_project.name%TYPE;
	in_name						csr.initiative_project.name%TYPE;
	v_flow_state_id				csr.initiative_project.live_flow_state_id%TYPE;
BEGIN	

	SELECT dbms_random.string('p',10)
	  INTO v_project_name
	  FROM dual;

	SELECT flow_sid
	  INTO v_flow_state_id
	  FROM flow
	 FETCH FIRST ROW ONLY;

	csr.initiative_project_pkg.CreateProject(
			in_name					=> v_project_name,
			in_flow_sid				=> v_flow_state_id,
			in_live_flow_state_id	=> NULL,
			in_start_dtm			=> NULL,
			in_end_dtm				=> NULL,
			in_icon					=> 'energy_bulb',
			in_abbreviation			=> 'A',
			in_fields_xml			=> XMLType('<fields/>'),
			in_period_fields_xml	=> XMLType('<fields/>'),
			in_pos_group			=> 1,
			in_pos					=> 1,
			out_project_sid			=> out_prj_sid
	);

	SELECT name
	  INTO in_name
	  FROM csr.initiative_project
	 WHERE project_sid	= out_prj_sid;

	csr.unit_test_pkg.AssertAreEqual(
		v_project_name,
		in_name,
		'Incorrect name. Expected : ' || v_project_name || ' Actual : ' || in_name);
END;

PROCEDURE InitiativeAdminRemoveType
AS
	v_project_count	NUMBER;
BEGIN	
	csr.initiative_project_pkg.TryDeleteProject(
		in_project_sid	=> out_prj_sid
	);

	SELECT COUNT(project_sid)
	  INTO v_project_count
	  FROM csr.initiative_project
	 WHERE project_sid = out_prj_sid;

	csr.unit_test_pkg.AssertAreEqual(0, v_project_count, 'Expected project type count: 0. Actual: ' || v_project_count);
END;

PROCEDURE InitiativeAdminAddAggregateTagGroups
AS
	v_aggr_group_label				VARCHAR2(50);
	in_aggr_group_label 			VARCHAR2(50);
	v_members 						security.security_pkg.T_SID_IDS;
BEGIN
	SELECT dbms_random.string('p',10)
	  INTO v_aggr_group_label
	  FROM dual;

	csr.initiative_metric_pkg.SaveAggregateTagGroup(
			in_aggr_tag_group_id			=> 0,
			in_label						=> v_aggr_group_label,
			in_lookup_key					=> 'lkp',
			in_aggr_tag_group_members		=>  v_members
	);

	SELECT  label,aggr_tag_group_id
	  INTO  in_aggr_group_label,out_aggr_tag_group_id
	  FROM csr.aggr_tag_group
	 ORDER BY aggr_tag_group_id DESC
	FETCH FIRST ROW ONLY;

	csr.unit_test_pkg.AssertAreEqual(
		v_aggr_group_label,
		in_aggr_group_label,
		'Incorrect name. Expected : ' || v_aggr_group_label || ' Actual : ' || in_aggr_group_label);
END;


PROCEDURE InitiativeAdminRemoveAggregateTagGroups
AS
	v_aggr_group_count	NUMBER;
BEGIN
	csr.initiative_metric_pkg.DeleteAggregateTagGroup(
		in_aggr_tag_group_id	=> out_aggr_tag_group_id
	);

	SELECT COUNT(aggr_tag_group_id)
	INTO v_aggr_group_count
	  FROM csr.aggr_tag_group
	 WHERE aggr_tag_group_id = out_aggr_tag_group_id;

	csr.unit_test_pkg.AssertAreEqual(0, v_aggr_group_count, 'Expected project type count: 0. Actual: ' || v_aggr_group_count);
END;

PROCEDURE TestCreateInitiative
AS
	v_initiative_label		VARCHAR2(50);
	in_initiative_label		VARCHAR2(50);
	v_start_date 			initiative.project_start_dtm%TYPE;
	v_end_date				initiative.project_end_dtm%TYPE;
	v_init_project_sid 		security_pkg.T_SID_ID;
	v_cur_profile 			security_pkg.T_OUTPUT_CUR;
BEGIN
	SELECT dbms_random.string('p',10)
	  INTO v_initiative_label
	  FROM dual;
	SELECT project_sid
	  INTO v_init_project_sid
	  FROM initiative_project
	 ORDER BY project_sid DESC
	 FETCH FIRST ROW ONLY;

	v_start_date := DATE '2022-01-01';
	v_end_date := DATE '2024-01-01';

	csr.initiative_pkg.CreateInitiative(
		in_project_sid				=> v_init_project_sid,
		in_parent_initiative_sid	=> NULL,

		in_name						=> v_initiative_label,
		in_ref						=> NULL,

		in_project_start_dtm		=> v_start_date,
		in_project_end_dtm			=> v_end_date,
		in_running_start_dtm		=> v_start_date,
		in_running_end_dtm			=> v_end_date,

		in_period_duration			=> 1,
		in_created_by_sid			=> NULL,
		in_created_dtm				=> NULL,
		in_is_ramped				=> 0,
		in_saving_type_id			=> 1,

		out_cur 					=> v_cur_profile
	);

	SELECT name
	  INTO in_initiative_label
	  FROM initiative
	 ORDER BY initiative_sid DESC
	 FETCH FIRST ROW ONLY;

	csr.unit_test_pkg.AssertAreEqual(
		v_initiative_label,
		in_initiative_label, 
		'Incorrect name. Expected : ' || v_initiative_label || ' Actual : ' || in_initiative_label);
END;

PROCEDURE TestEditInitiative
AS
	v_initiative_sid 		security_pkg.T_SID_ID;
	v_initiative_label		VARCHAR2(50);
	in_initiative_label		VARCHAR2(50);
	v_start_date 			initiative.project_start_dtm%TYPE;
	v_end_date				initiative.project_end_dtm%TYPE;
	v_init_project_sid 		security_pkg.T_SID_ID;
	v_cur_profile 			security_pkg.T_OUTPUT_CUR;
BEGIN
	SELECT dbms_random.string('p',10)
	  INTO v_initiative_label
	  FROM dual;
	SELECT project_sid
	  INTO v_init_project_sid
	  FROM initiative_project
	 ORDER BY project_sid DESC
	 FETCH FIRST ROW ONLY;
	SELECT initiative_sid
	  INTO  v_initiative_sid
	  FROM initiative
	 ORDER BY initiative_sid DESC
	 FETCH FIRST ROW ONLY;

	v_start_date := DATE '2023-01-01';
	v_end_date := DATE '2025-01-01';

	csr.initiative_pkg.AmendInitiative(
		in_initiative_sid			=> v_initiative_sid,
		in_project_sid				=> v_init_project_sid,
		in_parent_initiative_sid	=> NULL,

		in_name						=> v_initiative_label,
		in_ref						=> NULL,

		in_project_start_dtm		=> v_start_date,
		in_project_end_dtm			=> v_end_date,
		in_running_start_dtm		=> v_start_date,
		in_running_end_dtm			=> v_end_date,
		
		in_period_duration			=> 1,
		in_created_by_sid			=> NULL,
		in_created_dtm				=> NULL,
		in_is_ramped				=> 0,
		in_saving_type_id			=> 1,

		out_cur 					=> v_cur_profile
	);

	SELECT name
	  INTO in_initiative_label
	  FROM initiative
	 WHERE initiative_sid = v_initiative_sid;

	csr.unit_test_pkg.AssertAreEqual(
		v_initiative_label,
		in_initiative_label, 
		'Incorrect name.');
END;

PROCEDURE TestRemoveInitiative
AS
	v_int_count			NUMBER;
	v_initiative_sid 	security_pkg.T_SID_ID;
BEGIN	
	SELECT initiative_sid
	  INTO v_initiative_sid
	  FROM initiative
	 ORDER BY initiative_sid DESC
	 FETCH FIRST ROW ONLY;

	csr.initiative_pkg.DeleteObject(security.security_pkg.getACT,v_initiative_sid);
	security.securableobject_pkg.DeleteSO(security.security_pkg.getACT, v_initiative_sid);

	SELECT COUNT(initiative_sid)
	  INTO v_int_count
	  FROM csr.initiative
	 WHERE initiative_sid = v_initiative_sid;

	csr.unit_test_pkg.AssertAreEqual(0, v_int_count,'TestRemoveInitiative');
END;



PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_number	NUMBER;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	v_number := 0;

	SELECT v_number + COUNT(*)
	  INTO v_number
	  FROM initiative_project
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT v_number + COUNT(*)
	  INTO v_number
	  FROM initiative_metric
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_number = 0 THEN
		csr.enable_pkg.EnableInitiatives(
			in_setup_base_data => 'Y',
			in_metrics_end_year => 2030
		);
	END IF;

	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('INITIATIVES_METRIC_IND_1', 'GJ');

	SELECT initiative_metric_id
	  INTO v_metric_1_id
	  FROM csr.initiative_metric
	 WHERE lookup_key = 'ENERGY';

	csr.flow_pkg.SaveStateGroup(
		in_flow_state_group_id => NULL,
		in_label => 'Flow state group 1',
		in_lookup_key => 'flwstgrp1',
		out_flow_state_group_id => v_flow_state_group_1_id
	);
	
	SELECT v_flow_state_group_1_id
	  BULK COLLECT INTO v_flow_state_group_ids
	  FROM DUAL;
END;

PROCEDURE TearDownFixture
AS
	v_act security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;
END;

END;
/
