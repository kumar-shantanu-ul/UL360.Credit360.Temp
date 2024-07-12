CREATE OR REPLACE PACKAGE BODY csr.test_region_metric_pkg AS

v_site_name				VARCHAR2(200);
v_regs					security_pkg.T_SID_IDS;
v_inds					security_pkg.T_SID_IDS;
v_measures				security_pkg.T_SID_IDS;

v_calc_start_dtm		DATE;
v_calc_end_dtm			DATE;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_region_root_sid			security_pkg.T_SID_ID;
BEGIN
	Trace('SetUpFixture');
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	v_regs(1) := unit_test_pkg.GetOrCreateRegion('RegTestRegMetric_1');
	v_inds(1) := unit_test_pkg.GetOrCreateInd('IndTestRegMetric_1');

	measure_pkg.CreateMeasure(in_name => 'RegTestRegMetric_1', in_description => 'RegTestRegMetric_1', 
		out_measure_sid => v_measures(1));
	UPDATE ind
	   SET measure_sid = v_measures(1)
	 WHERE ind_sid = v_inds(1);

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	Trace('...Calc Start Dtm '||v_calc_start_dtm);
	Trace('...Calc End Dtm '||v_calc_end_dtm);
	Trace('...Region '||v_regs(1));
	Trace('...Ind '||v_inds(1));
END;

PROCEDURE SetUp AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;



-- HELPER PROCS
PROCEDURE CheckRegionMetric(
	in_region_sid		IN	NUMBER,
	in_ind_sid			IN	NUMBER,
	in_effective_dtm	IN	DATE,
	in_val				IN	NUMBER,
	in_silent			IN	NUMBER DEFAULT 0,
	in_index_to_check	IN	NUMBER DEFAULT 1,
	in_expected_count	IN	NUMBER DEFAULT 1
)
AS
	v_count			NUMBER;
BEGIN
	IF in_silent = 0 THEN
		TRACE('CheckRegionMetric: '||in_region_sid||' '||in_ind_sid||' '||in_effective_dtm||' '||in_val||' '||in_index_to_check||' '||in_expected_count);
	END IF;
	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM region_metric_val
		 WHERE region_sid = in_region_sid
		   AND ind_sid = in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		IF in_silent = 0 THEN
			TRACE('...region_metric_val: '||r.val||' eff:'||r.effective_dtm||' note:'||r.note);
		END IF;
		IF in_index_to_check = 1 THEN
			unit_test_pkg.AssertIsTrue(r.effective_dtm = in_effective_dtm, 'Unexpected effective_dtm, got '||r.effective_dtm);
			unit_test_pkg.AssertIsTrue(r.val = in_val, 'Unexpected val, got '||r.val);
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = in_expected_count, 'Expected '||in_expected_count||', got '||v_count);
END;


-- Tests

PROCEDURE TestSetMetricOnMonthBoundary AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetMetricOnMonthBoundary');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '2022-01-01';
	v_in_val := 123;
	v_in_note := 'Note 123';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);


	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val: '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		unit_test_pkg.AssertIsTrue(r.period_start_dtm = v_in_effective_dtm, 'Unexpected period_start_dtm, got '||r.period_start_dtm);
		unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
		unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1, got '||v_count);

	-- test changing it
	v_in_replace_dtm := v_in_effective_dtm;
	v_in_effective_dtm := DATE '2022-04-01';
	v_in_val := 234;
	v_in_note := 'Note 234';
	Trace('Test data (change): effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val: '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		unit_test_pkg.AssertIsTrue(r.period_start_dtm = v_in_effective_dtm, 'Unexpected period_start_dtm, got '||r.period_start_dtm);
		unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
		unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
END;

PROCEDURE TestSetMetricOnMiddleOfMonthJan AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetMetricOnMiddleOfMonth');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '2022-01-15';
	v_in_val := 345;
	v_in_note := 'Note 345';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val: '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = TRUNC(v_in_effective_dtm, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1, got '||v_count);

	-- test changing it
	v_in_replace_dtm := v_in_effective_dtm;
	v_in_effective_dtm := DATE '2022-04-16';
	v_in_val := 456;
	v_in_note := 'Note 456';
	Trace('Test data (change): effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val: '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		unit_test_pkg.AssertIsTrue(r.period_start_dtm = TRUNC(v_in_effective_dtm, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
		unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
		unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
END;

PROCEDURE TestSetMetricOnMiddleOfMonthDec AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetMetricOnMiddleOfMonthDec');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '2021-12-15';
	v_in_val := 567;
	v_in_note := 'Note 567';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val: '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm =  TRUNC(v_in_effective_dtm, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1, got '||v_count);

	-- test changing it
	v_in_replace_dtm := v_in_effective_dtm;
	v_in_effective_dtm := DATE '2022-12-13';
	v_in_val := 678;
	v_in_note := 'Note 678';
	Trace('Test data (change): effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val: '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		unit_test_pkg.AssertIsTrue(r.period_start_dtm = TRUNC(v_in_effective_dtm, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
		unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
		unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
END;

PROCEDURE TestSetDualMetricOnMonthBoundary AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

	v_in_effective_dtm_2				region_metric_val.effective_dtm%TYPE;
	v_in_val_2							region_metric_val.val%TYPE;
	v_in_note_2							region_metric_val.note%TYPE;
	v_out_region_metric_val_id_2		region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetDualMetricOnMonthBoundary');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '2022-01-01';
	v_in_val := 789;
	v_in_note := 'Note 789';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	v_in_effective_dtm_2 := DATE '2023-01-01';
	v_in_val_2 := 890;
	v_in_note_2 := 'Note 890';
	Trace('Test data 2: effective_dtm='||v_in_effective_dtm_2||', val='||v_in_val_2||', note='||v_in_note_2);

	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val,
		in_silent => 1
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm_2,
		in_val							=>	v_in_val_2,
		in_note							=>	v_in_note_2,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id_2
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id_2 IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm_2,
		in_val => v_in_val_2,
		in_silent => 0,
		in_index_to_check => 2,
		in_expected_count => 2
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val: '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = v_in_effective_dtm, 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_in_effective_dtm_2, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
		END IF;
		IF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = v_in_effective_dtm_2, 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val_2, 'Unexpected val, got '||r.val_number);
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 2, 'Expected 2, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id_2,
		in_audit_delete			=>	0
	);
END;


PROCEDURE TestSetDualMetricOnMiddleOfMonthJan AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

	v_in_effective_dtm_2				region_metric_val.effective_dtm%TYPE;
	v_in_val_2							region_metric_val.val%TYPE;
	v_in_note_2							region_metric_val.note%TYPE;
	v_out_region_metric_val_id_2		region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetDualMetricOnMiddleOfMonthJan');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '2022-01-15';
	v_in_val := 901;
	v_in_note := 'Note 901';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	v_in_effective_dtm_2 := DATE '2023-02-16';
	v_in_val_2 := 902;
	v_in_note_2 := 'Note 902';
	Trace('Test data 2: effective_dtm='||v_in_effective_dtm_2||', val='||v_in_val_2||', note='||v_in_note_2);

	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val,
		in_silent => 1
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm_2,
		in_val							=>	v_in_val_2,
		in_note							=>	v_in_note_2,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id_2
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id_2 IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm_2,
		in_val => v_in_val_2,
		in_silent => 0,
		in_index_to_check => 2,
		in_expected_count => 2
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val('||v_count||'): '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = TRUNC(v_in_effective_dtm, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = TRUNC(v_in_effective_dtm_2, 'MONTH'), 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
		END IF;
		IF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = TRUNC(v_in_effective_dtm_2, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = DATE '2023-03-01', 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number > v_in_val AND r.val_number < v_in_val_2, 'Unexpected val, got '||r.val_number);
		END IF;
		IF v_count = 3 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = DATE '2023-03-01', 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val_2, 'Unexpected val, got '||r.val_number);
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 3, 'Expected 3, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id_2,
		in_audit_delete			=>	0
	);
END;


PROCEDURE TestSetDualMetricOnMiddleOfMonthDec AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

	v_in_effective_dtm_2				region_metric_val.effective_dtm%TYPE;
	v_in_val_2							region_metric_val.val%TYPE;
	v_in_note_2							region_metric_val.note%TYPE;
	v_out_region_metric_val_id_2		region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetDualMetricOnMiddleOfMonthDec');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '2021-12-15';
	v_in_val := 903;
	v_in_note := 'Note 903';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	v_in_effective_dtm_2 := DATE '2022-11-14';
	v_in_val_2 := 904;
	v_in_note_2 := 'Note 904';
	Trace('Test data 2: effective_dtm='||v_in_effective_dtm_2||', val='||v_in_val_2||', note='||v_in_note_2);

	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val,
		in_silent => 1
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm_2,
		in_val							=>	v_in_val_2,
		in_note							=>	v_in_note_2,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id_2
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id_2 IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm_2,
		in_val => v_in_val_2,
		in_silent => 0,
		in_index_to_check => 2,
		in_expected_count => 2
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val('||v_count||'): '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = TRUNC(v_in_effective_dtm, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = TRUNC(v_in_effective_dtm_2, 'MONTH'), 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
		END IF;
		IF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = TRUNC(v_in_effective_dtm_2, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = DATE '2022-12-01', 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number > v_in_val AND r.val_number < v_in_val_2, 'Unexpected val, got '||r.val_number);
		END IF;
		IF v_count = 3 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = DATE '2022-12-01', 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val_2, 'Unexpected val, got '||r.val_number);
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 3, 'Expected 3, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id_2,
		in_audit_delete			=>	0
	);
END;

PROCEDURE TestSetDoubleMonthMetric AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

	v_in_effective_dtm_2				region_metric_val.effective_dtm%TYPE;
	v_in_val_2							region_metric_val.val%TYPE;
	v_in_note_2							region_metric_val.note%TYPE;
	v_out_region_metric_val_id_2		region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetDoubleMonthMetric');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '2021-12-15';
	v_in_val := 907;
	v_in_note := 'Note 907';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	v_in_effective_dtm_2 := DATE '2021-12-30';
	v_in_val_2 := 908;
	v_in_note_2 := 'Note 908';
	Trace('Test data 2: effective_dtm='||v_in_effective_dtm_2||', val='||v_in_val_2||', note='||v_in_note_2);

	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val,
		in_silent => 1
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm_2,
		in_val							=>	v_in_val_2,
		in_note							=>	v_in_note_2,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id_2
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id_2 IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm_2,
		in_val => v_in_val_2,
		in_silent => 0,
		in_index_to_check => 2,
		in_expected_count => 2
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val('||v_count||'): '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = TRUNC(v_in_effective_dtm, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = DATE '2022-01-01', 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number > v_in_val AND r.val_number < v_in_val_2, 'Unexpected val, got '||r.val_number);
		END IF;
		IF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = DATE '2022-01-01', 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val_2, 'Unexpected val, got '||r.val_number);
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 2, 'Expected 2, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id_2,
		in_audit_delete			=>	0
	);
END;


PROCEDURE TestSetTripleMonthMetric AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

	v_in_effective_dtm_2				region_metric_val.effective_dtm%TYPE;
	v_in_val_2							region_metric_val.val%TYPE;
	v_in_note_2							region_metric_val.note%TYPE;
	v_out_region_metric_val_id_2		region_metric_val.region_metric_val_id%TYPE;

	v_in_effective_dtm_3				region_metric_val.effective_dtm%TYPE;
	v_in_val_3							region_metric_val.val%TYPE;
	v_in_note_3							region_metric_val.note%TYPE;
	v_out_region_metric_val_id_3		region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetMultipleMonthMetric');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '2021-12-01';
	v_in_val := 1000;
	v_in_note := 'Note 1000';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);

	v_in_effective_dtm_2 := DATE '2021-12-15';
	v_in_val_2 := 1500;
	v_in_note_2 := 'Note 1500';
	Trace('Test data 2: effective_dtm='||v_in_effective_dtm_2||', val='||v_in_val_2||', note='||v_in_note_2);

	v_in_effective_dtm_3 := DATE '2021-12-20';
	v_in_val_3 := 2000;
	v_in_note_3 := 'Note 2000';
	Trace('Test data 3: effective_dtm='||v_in_effective_dtm_3||', val='||v_in_val_3||', note='||v_in_note_3);

	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val,
		in_silent => 1
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm_2,
		in_val							=>	v_in_val_2,
		in_note							=>	v_in_note_2,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id_2
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id_2 IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm_2,
		in_val => v_in_val_2,
		in_silent => 0,
		in_index_to_check => 2,
		in_expected_count => 2
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm_3,
		in_val							=>	v_in_val_3,
		in_note							=>	v_in_note_3,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id_3
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id_3 IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm_3,
		in_val => v_in_val_3,
		in_silent => 0,
		in_index_to_check => 3,
		in_expected_count => 3
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val('||v_count||'): '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		IF v_count = 1 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = TRUNC(v_in_effective_dtm, 'MONTH'), 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = DATE '2022-01-01', 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number > v_in_val AND r.val_number < v_in_val_2, 'Unexpected val, got '||r.val_number);
		END IF;
		IF v_count = 2 THEN
			unit_test_pkg.AssertIsTrue(r.period_start_dtm = DATE '2022-01-01', 'Unexpected period_start_dtm, got '||r.period_start_dtm);
			unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
			unit_test_pkg.AssertIsTrue(r.val_number = v_in_val_3, 'Unexpected val, got '||r.val_number);
		END IF;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 2, 'Expected 2, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id_2,
		in_audit_delete			=>	0
	);
	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id_3,
		in_audit_delete			=>	0
	);
END;


PROCEDURE TestSetMetricBeforeCalcStart AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetMetricBeforeCalcStart');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '1980-01-01';
	v_in_val := 905;
	v_in_note := 'Note 905';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);


	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);
	unit_test_pkg.AssertIsTrue(v_out_region_metric_val_id IS NOT NULL, 'Expected a val id, got null');

	CheckRegionMetric(
		in_region_sid => v_in_region_sid,
		in_ind_sid => v_in_ind_sid,
		in_effective_dtm => v_in_effective_dtm,
		in_val => v_in_val
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val: '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
		unit_test_pkg.AssertIsTrue(r.period_start_dtm = v_calc_start_dtm, 'Unexpected period_start_dtm, got '||r.period_start_dtm);
		unit_test_pkg.AssertIsTrue(r.period_end_dtm = v_calc_end_dtm, 'Unexpected period_end_dtm, got '||r.period_end_dtm);
		unit_test_pkg.AssertIsTrue(r.val_number = v_in_val, 'Unexpected val, got '||r.val_number);
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
END;

PROCEDURE TestSetMetricAfterCalcEnd AS
	v_count					NUMBER;

	v_in_region_sid						security_pkg.T_SID_ID;
	v_in_ind_sid						security_pkg.T_SID_ID;
	v_in_effective_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_val							region_metric_val.val%TYPE;
	v_in_note							region_metric_val.note%TYPE;
	v_in_replace_dtm					region_metric_val.effective_dtm%TYPE;
	v_in_entry_measure_conversion_id	region_metric_val.entry_measure_conversion_id%TYPE;
	v_in_source_type_id					region_metric_val.source_type_id%TYPE;
	v_out_region_metric_val_id			region_metric_val.region_metric_val_id%TYPE;

BEGIN
	Trace('TestSetMetricAfterCalcEnd');

	v_in_region_sid := v_regs(1);
	v_in_ind_sid := v_inds(1);
	v_in_effective_dtm := DATE '2035-01-01';
	v_in_val := 906;
	v_in_note := 'Note 906';
	Trace('Test data: effective_dtm='||v_in_effective_dtm||', val='||v_in_val||', note='||v_in_note);


	region_metric_pkg.SetMetric(
		in_ind_sid				=>	v_in_ind_sid
	);

	BEGIN
		region_metric_pkg.SetMetricValue(
			in_region_sid					=>	v_in_region_sid,
			in_ind_sid						=>	v_in_ind_sid,
			in_effective_dtm				=>	v_in_effective_dtm,
			in_val							=>	v_in_val,
			in_note							=>	v_in_note,
			in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
			in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
			in_source_type_id				=>	v_in_source_type_id,
			out_region_metric_val_id		=>	v_out_region_metric_val_id
		);
		unit_test_pkg.TestFail('Should fail with ORA-02290: check constraint (CSR.CK_VAL_CHANGE_LOG_DATES) violated');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN NULL;
	END;

	INSERT INTO val_change_log (ind_sid, start_dtm, end_dtm)
	VALUES (v_in_ind_sid, DATE '2022-01-01', DATE '2023-01-01');

	region_metric_pkg.SetMetricValue(
		in_region_sid					=>	v_in_region_sid,
		in_ind_sid						=>	v_in_ind_sid,
		in_effective_dtm				=>	v_in_effective_dtm,
		in_val							=>	v_in_val,
		in_note							=>	v_in_note,
		in_replace_dtm					=>	v_in_replace_dtm, -- Set this if the metric is to be replaced with a different dtm
		in_entry_measure_conversion_id	=>	v_in_entry_measure_conversion_id,
		in_source_type_id				=>	v_in_source_type_id,
		out_region_metric_val_id		=>	v_out_region_metric_val_id
	);

	v_count := 0;
	FOR r IN (
		SELECT *
		  FROM val
		 WHERE region_sid = v_in_region_sid
		   AND ind_sid = v_in_ind_sid
	)
	LOOP
		v_count := v_count + 1;
		TRACE('val: '||r.val_number||' psdtm:'||r.period_start_dtm||' pedtm:'||r.period_end_dtm||' note:'||r.note);
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0, got '||v_count);

	region_metric_pkg.DeleteMetricValue(
		in_region_metric_val_id	=>	v_out_region_metric_val_id,
		in_audit_delete			=>	0
	);
END;


--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');

	region_metric_pkg.DeleteMetricValues(
		in_region_sid => v_regs(1),
		in_ind_sid => v_inds(1)
	);

	delete from val_change_log;
END;

PROCEDURE RemoveSids(
	v_sids					security_pkg.T_SID_IDS
)
AS
BEGIN
	IF v_sids.COUNT > 0 THEN
		FOR i IN v_sids.FIRST..v_sids.LAST
		LOOP
			security.securableobject_pkg.deleteso(security_pkg.getact, v_sids(i));
		END LOOP;
	END IF;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);

	RemoveSids(v_regs);
	RemoveSids(v_inds);
	RemoveSids(v_measures);
END;

END test_region_metric_pkg;
/
