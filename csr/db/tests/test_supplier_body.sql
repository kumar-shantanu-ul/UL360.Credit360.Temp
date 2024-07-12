CREATE OR REPLACE PACKAGE BODY CSR.test_supplier_pkg AS

v_site_name			VARCHAR2(50) := 'supplier-test.credit360.com';

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	--NULL;
END;


PROCEDURE TestGetSupplierFlowAggregatesNoData
AS
	v_aggregate_ind_group_id	NUMBER;
	v_start_dtm					DATE;
	v_end_dtm					DATE;
	v_cur						SYS_REFCURSOR;

	v_count						NUMBER;

	v_cur_ind_sid				NUMBER;
	v_cur_region_sid			NUMBER;
	v_cur_period_start_dtm		DATE;
	v_cur_period_end_dtm		DATE;
	v_cur_source_type_id		NUMBER;
	v_cur_val_number			NUMBER;
	v_cur_error_code			NUMBER;
BEGIN
	supplier_pkg.GetSupplierFlowAggregates(
		in_aggregate_ind_group_id	=>	v_aggregate_ind_group_id,
		in_start_dtm				=>	v_start_dtm,
		in_end_dtm					=>	v_end_dtm,
		out_cur						=>	v_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_cur INTO 
			v_cur_ind_sid,
			v_cur_region_sid,
			v_cur_period_start_dtm,
			v_cur_period_end_dtm,
			v_cur_source_type_id,
			v_cur_val_number,
			v_cur_error_code
		;
		EXIT WHEN v_cur%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_cur_period_start_dtm||'('||v_cur_period_end_dtm||')');
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');

END;

PROCEDURE TestGetSupplierFlowAggregatesWithDates
AS
	v_start_dtm					DATE;
	v_end_dtm					DATE;
	v_cur						SYS_REFCURSOR;

	v_count						NUMBER;

	v_cur_ind_sid				NUMBER;
	v_cur_region_sid			NUMBER;
	v_cur_period_start_dtm		DATE;
	v_cur_period_end_dtm		DATE;
	v_cur_source_type_id		NUMBER;
	v_cur_val_number			NUMBER;
	v_cur_error_code			NUMBER;

	--v_app_sid					NUMBER := SYS_CONTEXT('SECURITY','APP');
	v_user_sid					NUMBER;
	v_ind_1_sid					NUMBER;
	v_region_1_sid				NUMBER;
	v_region_2_sid				NUMBER;
	v_aggregate_ind_group_id	NUMBER;

	v_wf_ct_sid					NUMBER;

	v_flow_sid					NUMBER;
	v_flow_state_id				NUMBER;
	v_flow_item_id				NUMBER;
	v_flow_state_log_id			NUMBER;
	v_company_type_id			NUMBER;
	v_company_a_sid				NUMBER;
	v_company_b_sid				NUMBER;
BEGIN

	v_start_dtm := DATE '2022-01-01';
	v_end_dtm := DATE '2022-02-01';

	-- practically criminal way of constructing some data for the SP to use.
	v_user_sid := unit_test_pkg.GetOrCreateUser('supplier.test.user');

	BEGIN
		SELECT ind_sid
		INTO v_ind_1_sid
		FROM csr.ind
		WHERE lookup_key = 'SUPPLIER_FLOW_STATE_DTM_1_LK';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;
	IF v_ind_1_sid IS NULL THEN
		v_ind_1_sid := unit_test_pkg.GetOrCreateInd('SUPPLIER_FLOW_STATE_DTM_1');
		UPDATE ind
		SET lookup_key = 'SUPPLIER_FLOW_STATE_DTM_1_LK'
		WHERE ind_sid = v_ind_1_sid;
	END IF;

	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('SUPPLIER_REGION_1');
	v_region_2_sid := unit_test_pkg.GetOrCreateRegion('SUPPLIER_REGION_2');

	v_aggregate_ind_group_id := 1234;
	BEGIN
		insert into csr.aggregate_ind_group (aggregate_ind_group_id, helper_proc, label) values (v_aggregate_ind_group_id, 'test-supplier-proc', 'test-supplier-name');
		insert into csr.aggregate_ind_group_member (aggregate_ind_group_id, ind_sid) values (v_aggregate_ind_group_id, v_ind_1_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	v_flow_sid := 999;
	v_flow_state_id := 1;
	v_flow_item_id := 2;
	v_flow_state_log_id := 3;
	
	v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');
	BEGIN
		SELECT flow_sid
		  INTO v_flow_sid
		  FROM csr.flow
		 WHERE label = 'test-supplier-flow';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			csr.flow_pkg.CreateFlow('test-supplier-flow', v_wf_ct_sid, v_flow_sid);
	END;

	update csr.flow
	   SET aggregate_ind_group_id = v_aggregate_ind_group_id
	 WHERE flow_sid = v_flow_sid;

	BEGIN
		SELECT flow_state_id
		  INTO v_flow_state_id
		  FROM csr.flow_state
		 WHERE lookup_key = 'SUPPLIER_FLOW_STATE_DTM_1_LK';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			insert into csr.flow_state (flow_state_id, flow_sid, label, lookup_key) values (v_flow_state_id, v_flow_sid, 'test-supplier-state', 'SUPPLIER_FLOW_STATE_DTM_1_LK');
	END;
	update csr.flow
	   SET default_state_id = v_flow_state_id
	 WHERE flow_sid = v_flow_sid;

	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM csr.flow_item
		 WHERE flow_sid = v_flow_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			insert into csr.flow_item (flow_item_id, flow_sid, current_state_id) values (v_flow_item_id, v_flow_sid, v_flow_state_id);
	END;

	BEGIN
		SELECT flow_state_log_id
		  INTO v_flow_state_log_id
		  FROM csr.flow_state_log
		 WHERE flow_item_id = v_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			insert into csr.flow_state_log (flow_state_log_id, flow_item_id, flow_state_id, set_by_user_sid, set_dtm) values (v_flow_state_log_id, v_flow_item_id, v_flow_state_id, v_user_sid, DATE '2022-01-03');
	END;

	update csr.flow_item
	   SET last_flow_state_log_id = v_flow_state_log_id
	 WHERE flow_item_id = v_flow_item_id;

	v_company_type_id := 4;
	v_company_a_sid := 997;
	v_company_b_sid := 996;
	BEGIN
		insert into chain.company_type (company_type_id, lookup_key, singular, plural) values (v_company_type_id, 'COMPANY_TYPE_SUPPLIER_TEST_LK', 'ctst1 s', 'ctst1 p');
		insert into chain.company (company_sid, parent_sid, company_type_id, name, country_code, signature) values (v_company_a_sid, null, v_company_type_id, 'test-cname-supplier-test-a', 'gb', 'sig-supplier-test-a');
		insert into chain.company (company_sid, parent_sid, company_type_id, name, country_code, signature) values (v_company_b_sid, null, v_company_type_id, 'test-cname-supplier-test-b', 'gb', 'sig-supplier-test-b');
		insert into csr.supplier (company_sid, region_sid) values (v_company_a_sid, v_region_1_sid);
		insert into csr.supplier (company_sid, region_sid) values (v_company_b_sid, v_region_2_sid);
		insert into chain.supplier_relationship (purchaser_company_sid, supplier_company_sid, flow_item_id) values (v_company_a_sid, v_company_b_sid, v_flow_item_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;


	supplier_pkg.GetSupplierFlowAggregates(
		in_aggregate_ind_group_id	=>	v_aggregate_ind_group_id,
		in_start_dtm				=>	v_start_dtm,
		in_end_dtm					=>	v_end_dtm,
		out_cur						=>	v_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_cur INTO 
			v_cur_ind_sid,
			v_cur_region_sid,
			v_cur_period_start_dtm,
			v_cur_period_end_dtm,
			v_cur_source_type_id,
			v_cur_val_number,
			v_cur_error_code
		;
		EXIT WHEN v_cur%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_cur_ind_sid||','||v_cur_region_sid||','||v_cur_period_start_dtm||','||v_cur_period_end_dtm||','
			||v_cur_source_type_id||','||v_cur_val_number||','||v_cur_error_code);

		unit_test_pkg.AssertAreEqual(v_cur_ind_sid, v_ind_1_sid, 'Expected matching ind sid');
		unit_test_pkg.AssertAreEqual(v_cur_region_sid, v_region_2_sid, 'Expected matching region sid');
		unit_test_pkg.AssertAreEqual(v_cur_source_type_id, csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP, 'Expected matching source_type_id');

		IF v_count = 1 THEN
			unit_test_pkg.AssertAreEqual(v_cur_period_start_dtm, DATE '2022-01-01', 'Expected matching start date');
			unit_test_pkg.AssertAreEqual(v_cur_period_end_dtm, DATE '2022-02-01', 'Expected matching start date');
		END IF;
		IF v_count = 2 THEN
			unit_test_pkg.AssertAreEqual(v_cur_period_start_dtm, DATE '2022-02-01', 'Expected matching start date');
			unit_test_pkg.AssertAreEqual(v_cur_period_end_dtm, DATE '2022-03-01', 'Expected matching start date');
		END IF;
	END LOOP;

	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 results');


	-- tidy up
	delete from chain.supplier_relationship where flow_item_id = v_flow_item_id;
	delete from csr.supplier where company_sid IN (v_company_a_sid, v_company_b_sid);
	delete from chain.company where company_sid IN (v_company_a_sid, v_company_b_sid);
	delete from chain.company_type where company_type_id = v_company_type_id;

	delete from csr.flow_state_log where flow_state_log_id = v_flow_state_log_id;
	delete from csr.flow_item where flow_item_id = v_flow_item_id;
	delete from csr.flow_state where flow_state_id = v_flow_state_id;
	IF v_flow_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_flow_sid);
		v_flow_sid := NULL;
	END IF;


	delete from csr.aggregate_ind_group_member where aggregate_ind_group_id = v_aggregate_ind_group_id;
	delete from csr.aggregate_ind_group where aggregate_ind_group_id = v_aggregate_ind_group_id;

	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;
	
	IF v_region_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_2_sid);
		v_region_2_sid := NULL;
	END IF;
	
	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;
	
	IF v_user_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_sid);
		v_user_sid := NULL;
	END IF;

END;

-------------------------------------------------------------------------------

FUNCTION AppExists
RETURN BOOLEAN
IS
	out_app_exists			NUMBER;
BEGIN
	security.user_pkg.LogonAdmin;

	SELECT COUNT(host)
	  INTO out_app_exists
	  FROM csr.customer
	 WHERE host = v_site_name;

	RETURN out_app_exists != 0;
END;

PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
END;

PROCEDURE TearDown
AS
BEGIN
	NULL;
END;


PROCEDURE SetUpFixture
AS
	v_app_sid				security.security_pkg.T_SID_ID;
BEGIN
	TearDownFixture;
	security.user_pkg.LogonAdmin;
	csr.csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);

	security.user_pkg.LogonAdmin(v_site_name);

	-- this also sets up two tier 
	csr.unit_test_pkg.EnableChain;
	enable_pkg.EnableWorkflow;

END;

PROCEDURE TearDownFixture
AS
BEGIN
	IF AppExists THEN
		security.user_pkg.LogonAdmin(v_site_name);

		chain.test_chain_utils_pkg.TearDownTwoTier;
		csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	END IF;
END;

END test_supplier_pkg;
/
