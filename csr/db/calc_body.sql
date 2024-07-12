CREATE OR REPLACE PACKAGE BODY CSR.Calc_Pkg AS

PROCEDURE GetCalcDateAdjustments( --forward declaration
	in_node	    					  IN  dbms_xmldom.domnode,
	out_start_dtm_adjust  			  OUT NUMBER,
	out_end_dtm_adjust				  OUT NUMBER,
	out_fixed_start_dtm				  OUT DATE,
	out_fixed_end_dtm				  OUT DATE
);

PROCEDURE CheckLeftRight(
	in_left							IN	dbms_xmldom.domnode,
	in_right						IN	dbms_xmldom.domnode
)
AS
BEGIN
	IF dbms_xmldom.isnull(in_left) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing left node');
	END IF;

	IF dbms_xmldom.isnull(in_right)THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing right node');
	END IF;
END;

FUNCTION GetConditionDependencies(
	in_node							IN  			dbms_xmldom.domnode,
	io_deps							IN OUT NOCOPY	CalcDependencies
)
RETURN NUMBER
AS
	v_left							dbms_xmldom.domnode;
	v_right							dbms_xmldom.domnode;
	v_name							VARCHAR2(100);
	v_tag_id						VARCHAR2(100);
	v_result						NUMBER;
BEGIN
	v_left := dbms_xslprocessor.selectSingleNode(in_node, 'left');
	v_right := dbms_xslprocessor.selectSingleNode(in_node, 'right');

	v_name := LOWER(dbms_xmldom.getNodeName(in_node));
	--dbms_output.put_line('node is '||v_name);
	CASE 
		WHEN v_name IN (
			'test',
			'test-old'
		) THEN
			IF dbms_xmldom.isnull(v_left) THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing left node');
			END IF;
	
			v_result := GetCalcDependencies(dbms_xslprocessor.selectSingleNode(v_left, '*'), io_deps);
			-- right node can be missing for a null test
			IF NOT dbms_xmldom.isnull(v_right) THEN
				v_result := LEAST(v_result, GetCalcDependencies(dbms_xslprocessor.selectSingleNode(v_right, '*'), io_deps));
			END IF;

			RETURN v_result;

		WHEN v_name = 'tag' THEN
			v_tag_id := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'tagId');
			IF v_tag_id IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing tagId attribute');
			END IF;
			io_deps.tags(v_tag_id) := 1;
			RETURN 0;

		WHEN v_name IN ('and', 'or') THEN
			CheckLeftRight(v_left, v_right);
			RETURN LEAST(
				GetConditionDependencies(dbms_xslprocessor.selectSingleNode(v_left, '*'), io_deps),
				GetConditionDependencies(dbms_xslprocessor.selectSingleNode(v_right, '*'), io_deps));

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown test node '||v_name);
	END CASE;
END;

FUNCTION GetCalcDependencies(
	in_node							IN  			dbms_xmldom.domnode,
	io_deps							IN OUT NOCOPY	CalcDependencies
)
RETURN NUMBER
AS
	v_left							dbms_xmldom.domnode;
	v_right							dbms_xmldom.domnode;
	v_then							dbms_xmldom.domnode;
	v_else							dbms_xmldom.domnode;
	v_cond							dbms_xmldom.domnode;
	v_name							VARCHAR2(100);
	v_sid							VARCHAR2(100);
	v_tag_id						VARCHAR2(100);
	v_years							VARCHAR2(100);
	v_intervals						VARCHAR2(100);
	v_config_id						VARCHAR2(100);
BEGIN
	v_left := dbms_xslprocessor.selectSingleNode(in_node, 'left');
	v_right := dbms_xslprocessor.selectSingleNode(in_node, 'right');

	v_name := LOWER(dbms_xmldom.getNodeName(in_node));
	--dbms_output.put_line('node is '||v_name);
	CASE 
		WHEN v_name IN (
			'add',
			'subtract',
			'multiply',
			'divide',
			'dividez',
			'add-old',
			'subtract-old',
			'multiply-old',
			'divide-old',
			'power'
		) THEN
			CheckLeftRight(v_left, v_right);
			RETURN LEAST(
				GetCalcDependencies(dbms_xslprocessor.selectSingleNode(v_left, '*'), io_deps),
				GetCalcDependencies(dbms_xslprocessor.selectSingleNode(v_right, '*'), io_deps));

		WHEN v_name IN (
			'if',
			'tagif'
		) THEN
			v_then := dbms_xslprocessor.selectSingleNode(in_node, 'then');
			IF dbms_xmldom.isnull(v_then) THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing then node');
			END IF; 
			
			v_else := dbms_xslprocessor.selectSingleNode(in_node, 'else');
			IF dbms_xmldom.isnull(v_else) THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing else node');
			END IF; 

			v_cond := dbms_xslprocessor.selectSingleNode(in_node, 'condition');
			IF dbms_xmldom.isnull(v_cond) THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing condition node');
			END IF;

			RETURN LEAST(
				GetCalcDependencies(dbms_xslprocessor.selectSingleNode(v_then, '*'), io_deps),
				GetCalcDependencies(dbms_xslprocessor.selectSingleNode(v_else, '*'), io_deps),
				GetConditionDependencies(dbms_xslprocessor.selectSingleNode(v_cond, '*'), io_deps));

		WHEN v_name IN (
			'sum',
			'average',
			'min',
			'max'
		) THEN
			v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'sid');
			IF v_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing sid attribute');
			END IF;
			
			-- ok - we've got a dependency on this sid's children
			io_deps.inds(v_sid)(csr_data_pkg.DEP_ON_CHILDREN) := 1;
			RETURN 0;
			
		WHEN v_name IN (
			'gasfactor',
			'literal',
			'nop',
			'null',
			'script',
			'lookup'
		) OR v_name IS NULL THEN
			RETURN 0;
			
		WHEN v_name = 'rank' THEN
			v_tag_id := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'tagId');
			IF v_tag_id IS NOT NULL THEN
				io_deps.tags(v_tag_id) := 1;
			END IF;
			
			v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'sid');
			IF v_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing sid attribute');
			END IF;
			io_deps.inds(v_sid)(csr_data_pkg.DEP_ON_INDICATOR) := 1;
			RETURN 0;

		WHEN v_name = 'baselineyear' THEN
			v_config_id := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'configId');
			IF v_config_id IS NOT NULL THEN
				io_deps.baselines(v_config_id) := 1;
			END IF;

			v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'sid');
			IF v_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing sid attribute');
			END IF;
			io_deps.inds(v_sid)(csr_data_pkg.DEP_ON_INDICATOR) := 1;			
			RETURN 0;
			
		WHEN v_name IN (
			'path',
			'round',
			'ytd',
			'compareytd',
			'std',
			'fye',
			'rollingyear',
			'previousperiod',
			'periodpreviousyear',
			'percentchange',
			'percentchange_periodpreviousyear',
			'percentchange_ytd_periodpreviousyear'
		) THEN
			-- ok - we got a dependency on this sid - factor in start dtm
			-- adjustment of 12 months for fye, std, ytd, rolling year, previous period etc
			v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'sid');
			IF v_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing sid attribute');
			END IF;
			io_deps.inds(v_sid)(csr_data_pkg.DEP_ON_INDICATOR) := 1;			
			RETURN CASE WHEN v_name NOT IN ('path', 'round') THEN -12 ELSE 0 END;

		WHEN v_name IN (
			'periodpreviousnyears',
			'rollingperiod'
		) THEN
			-- ok - we got a dependency on this sid - factor in start dtm
			-- adjustment of 12 months for fye, std, ytd, rolling year, previous period etc
			v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'sid');
			IF v_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing sid attribute');
			END IF;
			
			v_years := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'years');
			IF v_years IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing years attribute');
			END IF;

			-- ok - we got a dependency on this sid - factor in start dtm
			io_deps.inds(v_sid)(csr_data_pkg.DEP_ON_INDICATOR) := 1;
			RETURN -12 * v_years;
		
		WHEN v_name IN (
			'rollingnintervalsavg',
			'rollingnintervals'
		) THEN
			-- adjustment of n intervals (months)
			v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'sid');
			IF v_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing sid attribute');
			END IF;
			
			v_intervals := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'intervals');
			IF v_intervals IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing intervals attribute');
			END IF;

			-- we got a dependency on this sid
			io_deps.inds(v_sid)(csr_data_pkg.DEP_ON_INDICATOR) := 1;
			RETURN -1 * v_intervals;

		/*
		WHEN v_name = 'modelrun' THEN -- Looks like this will never been needed, but if it is then it should probably look like this.
			io_deps.inds(v_sid)(csr_data_pkg.DEP_ON_MODEL) := 1;
			RETURN 0;
		*/

		WHEN v_name = 'model' THEN
			-- No SID is fine, it just means that there's no model loaded into the calculation engine that's exporting to this indicator at the moment.
			v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'sid');
			IF v_sid IS NOT NULL THEN
				io_deps.inds(v_sid)(csr_data_pkg.DEP_ON_INDICATOR) := 1;
			END IF;
			RETURN 0;

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown node '||v_name||' in calculation xml');    
	END CASE;
END;

PROCEDURE GetConditionDateAdjustments(
	in_node							  IN  dbms_xmldom.domnode,	
	out_start_dtm_adjust  OUT NUMBER,
	out_end_dtm_adjust    OUT NUMBER,
	out_fixed_start_dtm   OUT DATE,
	out_fixed_end_dtm     OUT DATE
)
AS
	v_left							dbms_xmldom.domnode;
	v_right							dbms_xmldom.domnode;
	v_name							VARCHAR2(100);

	v_left_out_start_dtm_adjust		NUMBER(6);
	v_left_out_end_dtm_adjust		NUMBER(6);
	v_left_out_fixed_start_dtm		DATE;
	v_left_out_fixed_end_dtm		DATE;

	v_right_out_start_dtm_adjust	NUMBER(6);
	v_right_out_end_dtm_adjust		NUMBER(6);
	v_right_out_fixed_start_dtm		DATE;
	v_right_out_fixed_end_dtm		DATE;

BEGIN
	v_left := dbms_xslprocessor.selectSingleNode(in_node, 'left');
	v_right := dbms_xslprocessor.selectSingleNode(in_node, 'right');

	v_name := LOWER(dbms_xmldom.getNodeName(in_node));
	--dbms_output.put_line('node is '||v_name);
	CASE
		WHEN v_name IN (
			'test',
			'test-old'
		) THEN
			IF dbms_xmldom.isnull(v_left) THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing left node');
			END IF;

			GetCalcDateAdjustments(dbms_xslprocessor.selectSingleNode(v_left, '*'),
			                 v_left_out_start_dtm_adjust, v_left_out_end_dtm_adjust,
			                 v_left_out_fixed_start_dtm,  v_left_out_fixed_end_dtm);

			GetCalcDateAdjustments(dbms_xslprocessor.selectSingleNode(v_right, '*'),
			                 v_right_out_start_dtm_adjust, v_right_out_end_dtm_adjust,
			                 v_right_out_fixed_start_dtm,  v_right_out_fixed_end_dtm);

			out_start_dtm_adjust := LEAST(v_left_out_start_dtm_adjust,  v_right_out_start_dtm_adjust);
			out_end_dtm_adjust   := GREATEST(v_left_out_end_dtm_adjust, v_right_out_end_dtm_adjust);
			out_fixed_start_dtm  := LEAST(v_left_out_fixed_start_dtm,   v_right_out_fixed_start_dtm);
			out_fixed_end_dtm    := GREATEST(v_left_out_fixed_end_dtm,  v_right_out_fixed_end_dtm);
			RETURN;

		WHEN v_name = 'tag' THEN
			out_start_dtm_adjust := 0;
			out_end_dtm_adjust   := 0;
			out_fixed_start_dtm  := null;
			out_fixed_end_dtm    := null;
			RETURN;

		WHEN v_name = 'baselineyear' THEN	-- In progress UD-17124 will do the remaining implementaion
			RETURN;

		WHEN v_name IN ('and', 'or') THEN
			CheckLeftRight(v_left, v_right);
			GetConditionDateAdjustments(dbms_xslprocessor.selectSingleNode(v_left, '*'),
			                 v_left_out_start_dtm_adjust, v_left_out_end_dtm_adjust,
			                 v_left_out_fixed_start_dtm,  v_left_out_fixed_end_dtm);

			GetConditionDateAdjustments(dbms_xslprocessor.selectSingleNode(v_right, '*'),
			                 v_right_out_start_dtm_adjust, v_right_out_end_dtm_adjust,
			                 v_right_out_fixed_start_dtm,  v_right_out_fixed_end_dtm);

			out_start_dtm_adjust := LEAST(v_left_out_start_dtm_adjust,  v_right_out_start_dtm_adjust);
			out_end_dtm_adjust   := GREATEST(v_left_out_end_dtm_adjust, v_right_out_end_dtm_adjust);
			out_fixed_start_dtm  := LEAST(v_left_out_fixed_start_dtm,   v_right_out_fixed_start_dtm);
			out_fixed_end_dtm    := GREATEST(v_left_out_fixed_end_dtm,  v_right_out_fixed_end_dtm);

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown test node '||v_name);
	END CASE;
END;

PROCEDURE GetCalcDateAdjustments(
	in_node							  IN  dbms_xmldom.domnode,
	out_start_dtm_adjust			  OUT NUMBER,
	out_end_dtm_adjust				  OUT NUMBER,
	out_fixed_start_dtm				  OUT DATE,
	out_fixed_end_dtm				  OUT DATE
)
AS
	v_left							dbms_xmldom.domnode;
	v_right							dbms_xmldom.domnode;
	v_then							dbms_xmldom.domnode;
	v_else							dbms_xmldom.domnode;
	v_cond							dbms_xmldom.domnode;
	v_name							VARCHAR2(100);
	v_years							VARCHAR2(100);
	v_intervals						VARCHAR2(100);

	v_left_out_start_dtm_adjust		NUMBER(6);
	v_left_out_end_dtm_adjust		NUMBER(6);
	v_left_out_fixed_start_dtm		DATE;
	v_left_out_fixed_end_dtm		DATE;

	v_right_out_start_dtm_adjust	NUMBER(6);
	v_right_out_end_dtm_adjust		NUMBER(6);
	v_right_out_fixed_start_dtm		DATE;
	v_right_out_fixed_end_dtm		DATE;

	v_then_out_start_dtm_adjust		NUMBER(6);
	v_then_out_end_dtm_adjust		NUMBER(6);
	v_then_out_fixed_start_dtm		DATE;
	v_then_out_fixed_end_dtm		DATE;

	v_else_out_start_dtm_adjust 	NUMBER(6);
	v_else_out_end_dtm_adjust		NUMBER(6);
	v_else_out_fixed_start_dtm		DATE;
	v_else_out_fixed_end_dtm		DATE;

	v_cond_out_start_dtm_adjust		NUMBER(6);
	v_cond_out_end_dtm_adjust		NUMBER(6);
	v_cond_out_fixed_start_dtm		DATE;
	v_cond_out_fixed_end_dtm		DATE;

BEGIN
	v_left := dbms_xslprocessor.selectSingleNode(in_node, 'left');
	v_right := dbms_xslprocessor.selectSingleNode(in_node, 'right');

	v_name := LOWER(dbms_xmldom.getNodeName(in_node));
	--dbms_output.put_line('node is '||v_name);
	CASE
		WHEN v_name IN (
			'add',
			'subtract',
			'multiply',
			'divide',
			'dividez',
			'add-old',
			'subtract-old',
			'multiply-old',
			'divide-old',
			'power'
		) THEN

		GetCalcDateAdjustments(dbms_xslprocessor.selectSingleNode(v_left, '*'),
		                       v_left_out_start_dtm_adjust, v_left_out_end_dtm_adjust,
		                       v_left_out_fixed_start_dtm,  v_left_out_fixed_end_dtm);
		GetCalcDateAdjustments(dbms_xslprocessor.selectSingleNode(v_right, '*'),
		                       v_right_out_start_dtm_adjust, v_right_out_end_dtm_adjust,
		                       v_right_out_fixed_start_dtm,  v_right_out_fixed_end_dtm);

		out_start_dtm_adjust := LEAST(v_left_out_start_dtm_adjust, v_right_out_start_dtm_adjust);
		out_end_dtm_adjust   := GREATEST(v_left_out_end_dtm_adjust,    v_right_out_end_dtm_adjust);
		out_fixed_start_dtm  := LEAST(v_left_out_fixed_start_dtm,  v_right_out_fixed_start_dtm);
		out_fixed_end_dtm    := GREATEST(v_left_out_fixed_end_dtm,     v_right_out_fixed_end_dtm);
		RETURN;

		WHEN v_name IN (
			'if',
			'tagif'
		) THEN
			v_then := dbms_xslprocessor.selectSingleNode(in_node, 'then');
			IF dbms_xmldom.isnull(v_then) THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing then node');
			END IF;

			v_else := dbms_xslprocessor.selectSingleNode(in_node, 'else');
			IF dbms_xmldom.isnull(v_then) THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing else node');
			END IF;

			v_cond := dbms_xslprocessor.selectSingleNode(in_node, 'condition');
			IF dbms_xmldom.isnull(v_then) THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing condition node');
			END IF;

			GetCalcDateAdjustments(dbms_xslprocessor.selectSingleNode(v_then, '*'),
			                       v_then_out_start_dtm_adjust, v_then_out_end_dtm_adjust,
			                       v_then_out_fixed_start_dtm, v_then_out_fixed_end_dtm);
	
			GetCalcDateAdjustments(dbms_xslprocessor.selectSingleNode(v_else, '*'),
			                       v_else_out_start_dtm_adjust, v_else_out_end_dtm_adjust,
			                       v_else_out_fixed_start_dtm, v_else_out_fixed_end_dtm);
	
			GetConditionDateAdjustments(dbms_xslprocessor.selectSingleNode(v_cond, '*'),
			                       v_cond_out_start_dtm_adjust, v_cond_out_end_dtm_adjust,
			                       v_cond_out_fixed_start_dtm, v_cond_out_fixed_end_dtm);
	
			out_start_dtm_adjust := LEAST(v_then_out_start_dtm_adjust, v_else_out_start_dtm_adjust, v_cond_out_start_dtm_adjust);
			out_end_dtm_adjust   := GREATEST(v_then_out_end_dtm_adjust, v_else_out_end_dtm_adjust, v_cond_out_end_dtm_adjust);
			out_fixed_start_dtm  := LEAST(v_then_out_fixed_start_dtm, v_else_out_fixed_start_dtm, v_cond_out_fixed_start_dtm);
			out_fixed_end_dtm    := GREATEST(v_then_out_fixed_end_dtm, v_else_out_fixed_end_dtm, v_cond_out_fixed_end_dtm);
			RETURN;

		WHEN v_name IN (
			'sum',
			'average',
			'min',
			'max',
			'gasfactor',
			'literal',
			'nop',
			'path',
			'round',
			'model',
			'modelrun',
			'rank',
			'null',
			'lookup'
		) OR v_name IS NULL THEN
			out_start_dtm_adjust := 0;
			out_end_dtm_adjust   := 0;
			out_fixed_start_dtm  := null;
			out_fixed_end_dtm    := null;
			RETURN;

		WHEN v_name IN (
			'ytd',
			'std',
			'fye',
			'rollingyear',
			'previousperiod',
			'periodpreviousyear',
			'percentchange',
			'percentchange_periodpreviousyear',
			'percentchange_ytd_periodpreviousyear'
		) THEN
			out_start_dtm_adjust := -12;
			out_end_dtm_adjust   := 0;
			out_fixed_start_dtm  := null;
			out_fixed_end_dtm    := null;
			RETURN;

		WHEN v_name IN (
			'rollingnintervalsavg',
			'rollingnintervals'
		) THEN
			v_intervals := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'intervals');
			IF v_intervals IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing intervals attribute');
			END IF;

			out_start_dtm_adjust := -1 * v_intervals;
			out_end_dtm_adjust   := 0;
			out_fixed_start_dtm  := null;
			out_fixed_end_dtm    := null;
			RETURN;

		WHEN v_name IN (
			'compareytd'
		) THEN
			out_start_dtm_adjust := -12;
			out_end_dtm_adjust   := 12;
			out_fixed_start_dtm  := null;
			out_fixed_end_dtm    := null;
			RETURN;
			
		WHEN v_name IN (  -- In progress UD-17124 will do the full implementaion
			'baselineyear'
		) THEN
			out_start_dtm_adjust := 0;
			out_end_dtm_adjust   := 0;
			out_fixed_start_dtm  := null;
			out_fixed_end_dtm    := null;
			RETURN;

		WHEN v_name IN (
			'periodpreviousnyears',
			'rollingperiod'
		) THEN
			v_years := dbms_xmldom.getattribute(dbms_xmldom.makeelement(in_node), 'years');
			IF v_years IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Missing years attribute');
			END IF;

			out_start_dtm_adjust := -12 * v_years;
			out_end_dtm_adjust   := 0;
			out_fixed_start_dtm  := null;
			out_fixed_end_dtm    := null;
			RETURN;

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown node '||v_name||' in calculation xml');
	END CASE;
END;

PROCEDURE AddJobsForIndWithoutActions(
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_ind_type						IN	ind.ind_type%TYPE
)
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	-- if this is a normal ind then we can just write the region/period for the values
	-- for this indicator and the dependents will be worked out later (which is cheaper)
	IF in_ind_type = csr_data_pkg.IND_TYPE_NORMAL THEN
		MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
		USING (SELECT NVL(MIN(period_start_dtm), v_calc_start_dtm) period_start_dtm, 
					  NVL(MAX(period_end_dtm), v_calc_end_dtm) period_end_dtm
		  		 FROM val
		  		WHERE ind_sid = in_ind_sid) v
		   ON (vcl.ind_sid = in_ind_sid)
		 WHEN MATCHED THEN
			UPDATE 
			   SET vcl.start_dtm = LEAST(vcl.start_dtm, v.period_start_dtm),
				   vcl.end_dtm = GREATEST(vcl.end_dtm, v.period_end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
			VALUES (in_ind_sid, v.period_start_dtm, v.period_end_dtm);

	-- otherwise if it's a calc then we need to write jobs for all periods
	-- this is to cover weird cases like 1+indicator (n=z) which has a value
	-- even if we have no stored data for indicator and also the calcs which have
	-- a constant value
	ELSE
		MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
		USING (SELECT v_calc_start_dtm period_start_dtm, v_calc_end_dtm period_end_dtm
		  		 FROM dual) r
		   ON (vcl.ind_sid = in_ind_sid)
		 WHEN MATCHED THEN
			UPDATE 
			   SET vcl.start_dtm = LEAST(vcl.start_dtm, r.period_start_dtm),
				   vcl.end_dtm = GREATEST(vcl.end_dtm, r.period_end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
			VALUES (in_ind_sid, r.period_start_dtm, r.period_end_dtm);
	END IF;
END;
	
PROCEDURE AddJobsForIndWithoutActions(
	in_ind_sid		IN	security_pkg.T_SID_ID
)
AS
	v_ind_type						ind.ind_type%TYPE;
BEGIN
	SELECT ind_type
	  INTO v_ind_type
	  FROM ind
	 WHERE ind_sid = in_ind_sid;
	
	AddJobsForIndWithoutActions(in_ind_sid, v_ind_type);
END;
 
/* something about this indicator as a whole has changed so 
   add in a ton of jobs for all the calculations that use its 
   values (e.g. divisible field maybe changed?) */
PROCEDURE AddJobsForInd(
	in_ind_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	AddJobsForIndWithoutActions(in_ind_sid);
	
	-- add calculations for gas indicators that doesn't depend on the current indicator
	FOR r IN (
		SELECT ii.ind_sid
		  FROM ind i
		  JOIN ind ii ON i.ind_sid = ii.map_to_ind_sid
		 WHERE i.ind_sid = in_ind_sid
		   AND i.factor_type_id = 3 -- Unspecified
		   AND i.map_to_ind_sid IS NULL
	)
	LOOP
		AddJobsForIndWithoutActions(r.ind_sid);
	END LOOP;
	
	-- Add jobs for actions that depend on the indicator
	actions.dependency_pkg.CreateJobsFromInd(security_pkg.GetApp, in_ind_sid);
END;

/* a specific value has changed, so just add in any relevant jobs for this value
   Note: called internally
 */
PROCEDURE AddJobsForVal(
	in_ind_sid			IN	ind.ind_sid%TYPE,
	in_region_sid		IN	region.region_sid%TYPE,
	in_start_dtm		IN	val.period_start_dtm%TYPE,
	in_end_dtm			IN	val.period_end_dtm%TYPE
)
AS
BEGIN
	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
	USING (SELECT 1
	  		 FROM DUAL)
	   ON (vcl.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND vcl.ind_sid = in_ind_sid)
	 WHEN MATCHED THEN
		UPDATE 
		   SET vcl.start_dtm = LEAST(vcl.start_dtm, in_start_dtm),
			   vcl.end_dtm = GREATEST(vcl.end_dtm, in_end_dtm)
	 WHEN NOT MATCHED THEN
		INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
		VALUES (in_ind_sid, in_start_dtm, in_end_dtm);
END;

/* something about our calculated indicator has changed 
   so shove in bunch of jobs to recalculate it */
PROCEDURE AddJobsForCalc(
	in_calc_ind_sid		IN	security_pkg.T_SID_ID
)
AS
	v_ind_type						ind.ind_type%TYPE; 
BEGIN
	-- only do this if the calc_ind_sid is for stored things
	SELECT ind_type 
	  INTO v_ind_type 
	  FROM ind 
	 WHERE ind_sid = in_calc_ind_sid;

	IF v_ind_type = Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN
		AddJobsForIndWithoutActions(in_calc_ind_sid, v_ind_type);
	END IF;
	
	-- XXX: this is a little odd, if we can move it up into the IF block above
	-- AddJobsForIndWithoutActions can go (it's the only case where recalc jobs 
	-- are not added to csr, but they are to actions)
	-- Add jobs for actions that depend on the indicator
	actions.dependency_pkg.CreateJobsFromInd(security_pkg.GetApp, in_calc_ind_sid);
END;

/* gas factor for this factor type has changed, add calc jobs for all ind that map to this factor type */
PROCEDURE AddJobsForFactorType(
	in_factor_type_id		IN	factor_type.factor_type_id%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT i.ind_sid
		  FROM ind i
		  JOIN factor_type ft ON i.factor_type_id = ft.factor_type_id
		 WHERE ft.factor_type_id = in_factor_type_id
		   AND i.map_to_ind_sid IS NULL
		   AND i.active = 1 -- XXX: this really ought to say !deleted
	)
	LOOP
		calc_pkg.AddJobsForInd(r.ind_sid);
	END LOOP;
END;

PROCEDURE AddCalcJobsForAggregateIndGroup(
	in_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
)
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;	
BEGIN
	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	SELECT LEAST(calc_end_dtm, GREATEST(calc_start_dtm, NVL(in_start_dtm, calc_start_dtm))),
		   LEAST(calc_end_dtm, GREATEST(calc_start_dtm, NVL(in_end_dtm, calc_end_dtm)))
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	MERGE /*+ALL_ROWS*/ INTO aggregate_ind_calc_job aicj
	USING (SELECT 1
			 FROM dual) r
		   ON (aicj.aggregate_ind_group_id = in_aggregate_ind_group_id)
		 WHEN MATCHED THEN
			UPDATE
			   SET aicj.start_dtm = LEAST(aicj.start_dtm, v_calc_start_dtm),
				   aicj.end_dtm = GREATEST(aicj.end_dtm, v_calc_end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (aicj.aggregate_ind_group_id, aicj.start_dtm, aicj.end_dtm)
			VALUES (in_aggregate_ind_group_id, v_calc_start_dtm, v_calc_end_dtm);
END;

PROCEDURE AddJobsForAggregateIndGroup(
	in_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
)
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
	v_bucket_sid					aggregate_ind_group.data_bucket_sid%TYPE;
	v_batch_job_id					batch_job.batch_job_id%TYPE;
BEGIN

	SELECT data_bucket_sid
	  INTO v_bucket_sid
	  FROM aggregate_ind_group
	 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	
	IF v_bucket_sid IS NULL THEN
		calc_pkg.AddCalcJobsForAggregateIndGroup(
			in_aggregate_ind_group_id		=> in_aggregate_ind_group_id,
			in_start_dtm					=> in_start_dtm,
			in_end_dtm						=> in_end_dtm
		);
	ELSE
		aggregate_ind_pkg.TriggerDataBucketJob(
			in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
			out_batch_job_id 			=> v_batch_job_id
		);
	END IF;
	
END;

PROCEDURE AddJobsForAggregateIndGroup(
	in_name							aggregate_ind_group.name%TYPE,
	in_start_dtm					aggregate_ind_calc_job.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						aggregate_ind_calc_job.end_dtm%TYPE DEFAULT NULL
)
AS
	v_aggregate_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
	BEGIN
		SELECT aggregate_ind_group_id
		  INTO v_aggregate_ind_group_id
		  FROM aggregate_ind_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND upper(name) = upper(in_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'No aggregate_ind_group of name: '||in_name);
	END;
	
	AddJobsForAggregateIndGroup(v_aggregate_ind_group_id, in_start_dtm, in_end_dtm);
END;

/**
 * Sets XML and removes rows from the calc dependency table
 *
 * @param	in_act_id			Access token
 * @param	in_calc_ind_sid		The indicator
 * @param	in_calc_xml			The xml (null to set to normal indicator)
 */ 
PROCEDURE SetCalcXML(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_calc_ind_sid					IN 	security_pkg.T_SID_ID,
	in_calc_xml						IN 	ind.calc_xml%TYPE,
	in_is_stored					IN 	NUMBER, 
	in_period_set_id				IN	ind.period_set_id%TYPE,
	in_period_interval_id			IN	ind.period_interval_id%TYPE,	
	in_do_temporal_aggregation		IN 	ind.do_temporal_aggregation%TYPE,
	in_calc_description				IN	ind.calc_description%TYPE
)	
AS
	v_ind_type						ind.ind_type%TYPE;
	v_lock_start_dtm				customer.lock_start_dtm%TYPE;
	v_lock_end_dtm					customer.lock_end_dtm%TYPE;
	v_equal							NUMBER(1);
	v_calc_xml						ind.calc_xml%TYPE;
	v_factor_type_id				ind.factor_type_id%TYPE;
	v_map_to_ind_sid				security_pkg.T_SID_ID;
	v_is_in_reporting_tree			NUMBER;
	v_is_in_trash					NUMBER;
	CURSOR c IS
		SELECT app_sid, calc_xml, ind_type, period_set_id, period_interval_id, 
			   do_temporal_aggregation, calc_description, measure_sid 
		  FROM ind 
		 WHERE ind_sid = in_calc_ind_sid;
	r	c%ROWTYPE; 
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_calc_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;
	
	OPEN c;
	FETCH c INTO r;
	
	-- check it's not a container
	IF r.measure_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_WRONG_IND_TYPE_FOR_CALC, 'Calculations cannot be used for Categories or Factor indicators');
	END IF;
	
	-- check it's not an aggregate indicator
	IF r.ind_type = csr_data_pkg.IND_TYPE_AGGREGATE THEN
		RAISE_APPLICATION_ERROR(-20001, 'Calculations can not be set on system calculated indicators.');
	END IF;
	
	-- what indicator type is this?
	v_is_in_reporting_tree := indicator_pkg.IsInReportingIndTree(in_calc_ind_sid);

	v_calc_xml := in_calc_xml;
	IF in_calc_xml IS NULL OR xmltype(in_calc_xml).existsNode('/nop') = 1 THEN
		v_ind_type := Csr_Data_Pkg.IND_TYPE_NORMAL;
		v_calc_xml := NULL;
	ELSIF in_is_stored = 1 AND v_is_in_reporting_tree = 0 THEN
		v_ind_type := Csr_Data_Pkg.IND_TYPE_STORED_CALC;
		-- are they changing the interval?
		IF r.period_set_id != in_period_set_id OR r.period_interval_id != in_period_interval_id THEN
			-- get lock
			SELECT lock_start_dtm, lock_end_dtm
			  INTO v_lock_start_dtm, v_lock_end_dtm
			  FROM customer
			 WHERE app_sid = r.app_sid;			 
			-- go and clear down stored-calc values
			DELETE FROM val
			 WHERE ind_sid = in_calc_ind_sid
			   AND source_type_id IN (csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr_data_pkg.SOURCE_TYPE_AGGREGATOR)
			   AND (period_end_dtm < v_lock_start_dtm OR period_start_dtm > v_lock_end_dtm);
		END IF;
	ELSIF v_is_in_reporting_tree != 0 THEN
		v_ind_type := Csr_Data_Pkg.IND_TYPE_REPORT_CALC;
	ELSE
		SELECT COUNT(*)
		  INTO v_is_in_trash
		  FROM security.securable_object
		 WHERE sid_id = in_calc_ind_sid
			   START WITH sid_id = (SELECT trash_sid FROM csr.customer)
			   CONNECT BY PRIOR sid_id = parent_sid_id;
		IF v_is_in_trash != 0 THEN
			v_ind_type := r.ind_type;
		ELSE
			v_ind_type := Csr_Data_Pkg.IND_TYPE_CALC;
		END IF;
	END IF;
	
	UPDATE ind 
	   SET calc_xml = v_calc_xml,
	   	   ind_type = v_ind_type, 
	   	   period_set_id = in_period_set_id,
	   	   period_interval_id = in_period_interval_id,
	   	   do_temporal_aggregation = in_do_temporal_aggregation,
	   	   calc_description = in_calc_description,
	   	   last_modified_dtm = SYSDATE
	 WHERE ind_sid = in_calc_ind_sid;

	-- Update gas indicators if required
	SELECT factor_type_id, map_to_ind_sid
	  INTO v_factor_type_id, v_map_to_ind_sid
	  FROM ind
	 WHERE ind_sid = in_calc_ind_sid;
	 
	IF v_factor_type_id IS NOT NULL AND
	   v_map_to_ind_sid	IS NULL THEN
		indicator_pkg.CreateGasIndicators(in_calc_ind_sid);
	END IF;

	-- write to audit log
	IF v_ind_type = Csr_Data_Pkg.IND_TYPE_NORMAL AND r.ind_type != Csr_Data_Pkg.IND_TYPE_NORMAL THEN
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, in_calc_ind_sid,
			'Calculation removed');		
	ELSE
		-- extract only works in SQL
		SELECT dbms_lob.compare(r.calc_xml, in_calc_xml)
		  INTO v_equal
		  FROM dual;
		IF v_equal != 0 THEN
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, in_calc_ind_sid,
				'Calculation changed');
		END IF;
		IF v_ind_type = Csr_Data_Pkg.IND_TYPE_STORED_CALC AND r.ind_type != Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, in_calc_ind_sid,
				'Set to stored calculation');
		ELSIF v_ind_type = Csr_Data_Pkg.IND_TYPE_CALC AND r.ind_type != Csr_Data_Pkg.IND_TYPE_CALC THEN
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, in_calc_ind_sid,
				'Set to non-stored calculation');
		END IF;
	END IF;
	
	IF null_pkg.ne(in_calc_description, r.calc_description) THEN
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, in_calc_ind_sid,
			'Description changed');		
	END IF;
	 
	DELETE FROM calc_dependency 
	 WHERE calc_ind_sid = in_calc_ind_sid;

	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	DELETE FROM val_change_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_sid = in_calc_ind_sid;
END;

/**
 * Adds	a row to the calc dependency table
 *
 * @param	in_act_id		Access token
 * @param	in_calc_ind_sid		The indicator
 * @param	in_ind_sid	The region
 */ 
PROCEDURE AddCalcDependency(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_calc_ind_sid			IN security_pkg.T_SID_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_dep_type				IN CALC_DEPENDENCY.dep_type%TYPE
)
AS
	v_measure_sid		security_pkg.T_SID_ID;
	v_depends_on_model	security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_calc_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- check that the depended on indicator acually sxists
	BEGIN
		SELECT measure_sid INTO v_measure_sid FROM ind WHERE ind_sid = in_ind_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20001, 'Could not find indicator with sid '||in_ind_sid);
	END;
	
	-- check it's not a measure (and not a parent dependency - SUM(a category) is ok)
	IF v_measure_sid IS NULL AND in_dep_type = csr_data_pkg.DEP_ON_INDICATOR THEN
		SELECT COUNT(*) INTO v_depends_on_model
		  FROM model
		 WHERE model_sid = in_ind_sid;
		 
		IF v_depends_on_model = 0 THEN
			RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_WRONG_IND_TYPE_FOR_CALC, 
				'A calculation cannot be performed on the indicator with sid '||in_ind_sid||' because it has no measure and it''s not a model surrogate');
		END IF;
	END IF;
	-- check for duplicates and ignore if already set
	BEGIN
		INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
			VALUES (in_calc_ind_sid, in_ind_sid, in_dep_type);	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;

-- just get a really simple list of dependencies
PROCEDURE GetDependencies(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_calc_ind_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_calc_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT ind_sid, dep_type 
		  FROM calc_dependency 
		 WHERE calc_ind_sid = in_calc_ind_sid;
END;

-- used mostly by CopyIndicator code
PROCEDURE UpdateDependency(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_calc_ind_sid			IN security_pkg.T_SID_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_dep_type				IN CALC_DEPENDENCY.dep_type%TYPE,
	in_new_ind_sid			IN security_pkg.T_SID_ID
)
AS
	v_measure_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_calc_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	UPDATE calc_dependency
	   SET ind_sid = in_new_ind_sid
	 WHERE calc_ind_sid = in_calc_ind_sid
	   AND ind_sid = in_ind_sid
	   AND dep_type = in_dep_type;
END;


-- used by script calculed indicator setup to remove out-of-date dependencies
PROCEDURE DeleteCalcDependency(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_calc_ind_sid			IN security_pkg.T_SID_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_dep_type				IN CALC_DEPENDENCY.dep_type%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_calc_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	DELETE FROM calc_dependency
	 WHERE calc_ind_sid = in_calc_ind_sid AND ind_sid = in_ind_sid AND dep_type = in_dep_type;
END;

/* get which indicators are used for a given calculation  */
FUNCTION GetIndsUsedByCalcAsTable(
	in_calc_ind_sid	IN  security_pkg.T_SID_ID
) RETURN T_CALC_DEP_TABLE
AS
	v_table		T_CALC_DEP_TABLE;
BEGIN
	SELECT T_CALC_DEP_ROW(dep_type, ind_sid, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment)
	  BULK COLLECT INTO v_table
	  FROM (
		SELECT cd.dep_type, cd.ind_sid, i.ind_type, ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
		  FROM calc_dependency cd, ind i, ind ci
		 WHERE cd.calc_ind_sid = in_calc_ind_sid
		   AND cd.calc_ind_sid = ci.ind_sid
		   AND cd.ind_sid = i.ind_sid
		   AND i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
		   AND cd.dep_type = csr_data_pkg.DEP_ON_INDICATOR
		 UNION
		SELECT cd.dep_type, i.ind_sid, i.ind_type, ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
		  FROM calc_dependency cd, ind i, ind ci
		 WHERE cd.calc_ind_sid = in_calc_ind_sid
		   AND cd.calc_ind_sid = ci.ind_sid
		   AND cd.ind_sid = i.parent_sid
		   AND cd.dep_type = csr_data_pkg.DEP_ON_CHILDREN
		   AND i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
		   AND i.map_to_ind_sid IS NULL -- not gas indicators
	);
	RETURN v_table;
END;

PROCEDURE GetIndsUsedByCalc(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_calc_ind_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
) IS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_calc_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT dep_type, ind_sid 
		  FROM TABLE(GetIndsUsedByCalcAsTable(in_calc_ind_sid));
END;

-- a 'run' is a complete scan from top to bottom
PROCEDURE INTERNAL_GetAllIndsUsedByCalc(
	in_calc_ind_sid				IN		CALC_DEPENDENCY.calc_ind_sid%TYPE,
	in_include_stored_calcs		IN		NUMBER,
	in_dep_scan_table			IN OUT	T_DATASOURCE_DEP_TABLE,
	in_base_calc_start_dtm_adj	IN		ind.calc_start_dtm_adjustment%TYPE DEFAULT 0,
	in_base_calc_end_dtm_adj	IN		ind.calc_end_dtm_adjustment%TYPE DEFAULT 0,
	in_path						IN		VARCHAR2 DEFAULT ',',
	in_lev						IN		NUMBER	 DEFAULT 0
)
AS
BEGIN
	-- get cursor containing things that we depend on
	FOR r IN (
		SELECT ind_sid, dep_type, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment
		  FROM TABLE(GetIndsUsedByCalcAsTable(in_calc_ind_sid))
	)
	LOOP
		-- have we already visited this one on this run (i.e. circular ref)?
		IF INSTR(in_path, ','||r.ind_sid||',') > 0 THEN
			RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_CIRCULAR_REFERENCE, 'Circular dependency (calc ind sid '||r.ind_sid||') for indicator sid '||in_calc_ind_sid);
		END IF;
		-- ok, shove a row in the table to say we've visited this
		in_dep_scan_table.extend;
		in_dep_scan_table(in_dep_scan_table.COUNT) := T_DATASOURCE_DEP_ROW(in_calc_ind_sid, r.dep_type, r.ind_sid, in_lev, 
			in_base_calc_start_dtm_adj + r.calc_start_dtm_adjustment, in_base_calc_end_dtm_adj + r.calc_end_dtm_adjustment);
		-- go off and hunt for other children in this run
		IF r.ind_type = csr_data_pkg.IND_TYPE_CALC OR
			(r.ind_type = csr_data_pkg.IND_TYPE_STORED_CALC AND in_include_stored_calcs = 1) THEN
			INTERNAL_GetAllIndsUsedByCalc(r.ind_sid, in_include_stored_calcs, in_dep_scan_table, 
				in_base_calc_start_dtm_adj + r.calc_start_dtm_adjustment, in_base_calc_end_dtm_adj + r.calc_end_dtm_adjustment,
				in_path||r.ind_sid||',', in_lev+1);
		END IF;
	END LOOP;
END;

FUNCTION GetAllIndsUsedByCalcAsTable(
	in_calc_ind_sid		IN	CALC_DEPENDENCY.calc_ind_sid%TYPE
) RETURN T_DATASOURCE_DEP_TABLE
AS
	v_table						T_DATASOURCE_DEP_TABLE := T_DATASOURCE_DEP_TABLE();
BEGIN
	INTERNAL_GetAllIndsUsedByCalc(in_calc_ind_sid, 1, v_table);
	RETURN v_table;
END;

PROCEDURE GetAllIndsUsedByCalc(
	in_calc_ind_sid		IN	CALC_DEPENDENCY.calc_ind_sid%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+  USE_NL (dep,i) */ dep.max_lev, dep.dep_ind_sid ind_sid, i.ind_type, i.calc_xml,
		 NVL(i.scale, m.scale) scale 
		  FROM 
			(SELECT MAX(lvl) max_lev, DEP_IND_SID 
			  FROM TABLE(Calc_Pkg.GetAllIndsUsedByCalcAsTable(in_calc_ind_sid))
		 	  GROUP BY DEP_IND_SID)dep,
			IND I, MEASURE M
		 WHERE I.ind_sid = dep.dep_ind_sid AND I.MEASURE_SID = M.MEASURE_SID
		 ORDER BY max_lev DESC;		
END;

-- This is GetAllIndsUsedByCalcAsTable, but for multiple indicators
FUNCTION GetAllIndsUsedAsTable(
	in_ind_list				IN	security_pkg.T_SID_IDS,
	in_include_stored_calcs	IN	NUMBER
) RETURN T_DATASOURCE_DEP_TABLE
AS
	t_items				security.T_SID_TABLE;
	v_table				T_DATASOURCE_DEP_TABLE := T_DATASOURCE_DEP_TABLE();
BEGIN
	t_items := security_Pkg.SidArrayToTable(in_ind_list);
		
	SELECT T_DATASOURCE_DEP_ROW(seek_ind_sid, calc_dep_type, dep_ind_sid, lvl, calc_start_dtm_adjustment, calc_end_dtm_adjustment)
	  BULK COLLECT INTO v_table
	  FROM (
			SELECT cd.calc_ind_sid seek_ind_sid, cd.ind_sid dep_ind_sid, cd.dep_type calc_dep_type, LEVEL lvl,
                   cd.calc_start_dtm_adjustment calc_start_dtm_adjustment,
                   cd.calc_end_dtm_adjustment calc_end_dtm_adjustment
			  FROM v$calc_dependency cd
			 START WITH cd.calc_ind_sid IN (SELECT column_value FROM TABLE(t_items))
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
			CONNECT BY (
					PRIOR cd.ind_sid = cd.calc_ind_sid
				AND PRIOR cd.app_sid = cd.app_sid
			)
	);
	
	RETURN v_table;
END;

/* ------------------------------------------------ 
   get which calculations use a specific indicator 
   ------------------------------------------------ */  
FUNCTION GetCalcsUsingIndAsTable(
	in_ind_sid	IN  security_pkg.T_SID_ID
) RETURN T_CALC_DEP_TABLE
AS
	v_table		T_CALC_DEP_TABLE;
BEGIN
	SELECT T_CALC_DEP_ROW(dep_type, calc_ind_sid, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment)
	  BULK COLLECT INTO v_table
	  FROM (
		SELECT cd.dep_type, cd.calc_ind_sid, i.ind_type, ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
		  FROM calc_dependency cd, ind i, ind ci
		 WHERE cd.ind_sid = in_ind_sid
		   AND cd.dep_type = csr_data_pkg.DEP_ON_INDICATOR
		   AND cd.ind_sid = i.ind_sid
		   AND cd.calc_ind_sid = ci.ind_sid
		 UNION
		SELECT cd.dep_type, cd.calc_ind_sid, i.ind_type, ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
		  FROM calc_dependency cd, ind i, ind ci
		 WHERE i.ind_sid = in_ind_sid
		   AND i.parent_sid = cd.ind_sid 
		   AND cd.calc_ind_sid = ci.ind_sid
		   AND cd.dep_type = csr_data_pkg.DEP_ON_CHILDREN
		   AND i.map_to_ind_sid IS NULL -- not gas indicators
	);
	RETURN v_table;
END;

PROCEDURE GetCalcsUsingInd(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
) IS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT dep_type, ind_sid 
		  FROM TABLE(GetCalcsUsingIndAsTable(in_ind_sid));
END;

-- a 'run' is a complete scan from top to bottom
PROCEDURE INTERNAL_GetCalcsUsingInd(
	in_ind_sid			IN	CALC_DEPENDENCY.ind_sid%TYPE,
	in_dep_scan_table	IN OUT	T_DATASOURCE_DEP_TABLE,
	in_path				IN	VARCHAR2 DEFAULT ',',
	in_lev				IN	NUMBER	DEFAULT 0
)
AS
BEGIN
	-- get cursor containing things that we depend on
	FOR r IN (
		SELECT ind_sid, dep_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment
		  FROM TABLE(GetCalcsUsingIndAsTable(in_ind_sid))
	)
	LOOP
		-- have we already visited this one on this run (i.e. circular ref)?
		IF INSTR(in_path, ','||r.ind_sid||',') > 0 THEN
			RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_CIRCULAR_REFERENCE, 'Circular dependency (calc ind sid '||r.ind_sid||') for indicator sid '||in_ind_sid);
		END IF;
		-- ok, shove a row in the table to say we've visited this
		in_dep_scan_table.extend;
		in_dep_scan_table(in_dep_scan_table.COUNT) := T_DATASOURCE_DEP_ROW(in_ind_sid, r.dep_type, r.ind_sid, in_lev, r.calc_start_dtm_adjustment, r.calc_end_dtm_adjustment);
		-- go off and hunt for other children in this run
		INTERNAL_GetCalcsUsingInd(r.ind_sid, in_dep_scan_table, in_path||r.ind_sid||',', in_lev+1);
	END LOOP;
END;

FUNCTION GetAllCalcsUsingIndAsTable(
	in_ind_sid		IN	CALC_DEPENDENCY.calc_ind_sid%TYPE
) RETURN T_DATASOURCE_DEP_TABLE
AS
	v_table					T_DATASOURCE_DEP_TABLE := T_DATASOURCE_DEP_TABLE();
BEGIN
	INTERNAL_GetCalcsUsingInd(in_ind_sid, v_table);
	RETURN v_table;
END;

PROCEDURE GetAllCalcsUsingInd(
	in_ind_sid		IN	calc_dependency.ind_sid%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ USE_NL (dep,i) */ dep.max_lev, dep.dep_ind_sid ind_sid, i.ind_type, 
			   i.calc_xml, NVL(i.scale, m.scale) scale 
		  FROM (SELECT MAX(LVL) max_lev, dep_ind_sid 
			      FROM TABLE(Calc_Pkg.GetAllCalcsUsingIndAsTable(in_ind_sid))
		 	  	 GROUP BY dep_ind_sid) dep,
			   ind i, measure m
		 WHERE i.ind_sid = dep.dep_ind_sid AND i.measure_sid = m.measure_sid
		 ORDER BY max_lev DESC;		
END;

PROCEDURE CheckCircularDependencies(
	in_ind_sid						IN	calc_dependency.ind_sid%TYPE
)
AS
	v_cycles						NUMBER;
BEGIN
	SELECT sum(cycles)
	  INTO v_cycles
	  FROM (SELECT COUNT(CASE WHEN connect_by_iscycle = 1 THEN 1 ELSE NULL END) cycles
			   FROM v$calc_dependency
				     START WITH calc_ind_sid = in_ind_sid
				     CONNECT BY NOCYCLE PRIOR ind_sid = calc_ind_sid 
			  UNION ALL
			 SELECT COUNT(CASE WHEN connect_by_iscycle = 1 THEN 1 ELSE NULL END) cycles
			   FROM v$calc_dependency
				     START WITH ind_sid = in_ind_sid
				     CONNECT BY NOCYCLE PRIOR ind_sid = calc_ind_sid);
	IF v_cycles > 0 THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_CIRCULAR_REFERENCE, 
			'Circular dependency for calc ind sid '||in_ind_sid);
	END IF;
END;

/* critical means that it's used directly by a calculation,
 not just in a sum-children type thing */ 
FUNCTION IsIndicatorCritical(
	in_ind_sid		IN security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	CURSOR c IS
		SELECT cd.calc_ind_sid
		  FROM calc_dependency cd, ind ci
		 WHERE cd.ind_sid = in_ind_sid
		   AND cd.dep_type = csr_data_pkg.DEP_ON_INDICATOR -- find calcs that depend on this indicator
		   AND cd.calc_ind_sid = ci.ind_sid -- filter calcs that are active
		   AND ci.active = 1; -- XXX: this really ought to say "!deleted"
	r c%ROWTYPE; 
BEGIN
	OPEN c;
	FETCH c INTO r;
	RETURN c%FOUND;
END;

/* get which indicators are directly used by a given calculation (i.e. for sum(children) we still 
   get the top level indicator, not the children)
   this is just used to annotate the calculation for display purposes
 */
PROCEDURE GetCalcDependencies(
	in_calc_ind_sid					IN  security_pkg.T_SID_ID,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_calc_tag_cur				OUT	SYS_REFCURSOR,
	out_calc_baseline_config_cur	OUT	SYS_REFCURSOR
)
AS
	v_app							security_pkg.T_SID_ID;
BEGIN
	v_app := SYS_CONTEXT('SECURITY', 'APP');

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_calc_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on indicator '||in_calc_ind_sid);
	END IF;
	
	OPEN out_ind_cur FOR
		SELECT cd.dep_type, i.ind_sid, i.description, i.ind_type
		  FROM calc_dependency cd, v$ind i
		 WHERE cd.calc_ind_sid = in_calc_ind_sid
		   AND cd.app_sid = i.app_sid
		   AND cd.ind_sid = i.ind_sid;
		   
	OPEN out_calc_tag_cur FOR
		SELECT ctd.tag_id, t.tag, t.explanation, t.lookup_key, tgm.tag_group_id
		  FROM calc_tag_dependency ctd, v$tag t
		  JOIN csr.tag_group_member tgm ON tgm.tag_id = t.tag_id AND tgm.app_sid = v_app
		 WHERE t.app_sid = v_app
		   AND ctd.app_sid = v_app
		   AND ctd.tag_id = t.tag_id
		   AND ctd.calc_ind_sid = in_calc_ind_sid;
	
	OPEN out_calc_baseline_config_cur FOR
		SELECT bcd.baseline_config_id, bc.baseline_name, bc.baseline_lookup_key
		  FROM calc_baseline_config_dependency bcd
		  JOIN csr.baseline_config bc ON bc.baseline_config_id = bcd.baseline_config_id AND bc.app_sid = v_app
		 WHERE bcd.app_sid = v_app
		   AND bcd.calc_ind_sid = in_calc_ind_sid;
END;

PROCEDURE GetAllCalcDependencies(
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	out_ind_cur						OUT	SYS_REFCURSOR
)
AS
	v_ordered_ind_sids				security.T_ORDERED_SID_TABLE;
	v_allowed_ind_sids				security.T_SO_TABLE;
	v_act							security_pkg.T_ACT_ID;
BEGIN
	v_act := SYS_CONTEXT('SECURITY', 'ACT');

    -- This assumes that if you're allowed to see an ind, you're allowed to see its dependencies.
	v_ordered_ind_sids := security_pkg.SidArrayToOrderedTable(in_ind_sids);
	v_allowed_ind_sids := securableObject_pkg.GetSIDsWithPermAsTable(
		v_act, 
		security_pkg.SidArrayToTable(in_ind_sids), 
		security_pkg.PERMISSION_READ
	);
	
	OPEN out_ind_cur FOR
		SELECT calc_ind_sid, ind_sid FROM (
			SELECT cd.calc_ind_sid, cd.ind_sid
				FROM v$calc_dependency cd, v$ind i
				WHERE cd.app_sid = i.app_sid
				AND cd.ind_sid = i.ind_sid
		)
		START WITH calc_ind_sid IN (SELECT sid_id FROM TABLE(v_allowed_ind_sids))
		CONNECT BY NOCYCLE calc_ind_sid = PRIOR ind_sid;
END;

PROCEDURE GetTpl(
	in_ind_sid		IN	security_pkg.T_SID_ID,
	out_calc_xml	OUT	XMLTYPE
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT XMLElement(
		"inds", (
			SELECT DBMS_XMLGEN.getxmltype(
				DBMS_XMLGEN.newcontextfromhierarchy('
					SELECT level, XMLElement(
						"ind", XMLAttributes(
							i.ind_sid AS "sid", 
							i.ind_type AS "ind-type", 
							i.period_set_id AS "period-set-id",
							i.period_interval_id AS "period-interval-id",
							i.tolerance_type AS "tolerance-type",
							i.pct_upper_tolerance AS "pct-upper-tolerance",
							i.pct_lower_tolerance AS "pct-lower-tolerance",
							i.measure_sid AS "measure-sid",
							i.scale AS "scale",
							i.format_mask AS "format-mask",
							i.active AS "active",
							i.target_direction AS "target-direction",
							i.start_month AS "start-month",
							NVL(i.divisibility, m.divisibility) AS "divisibility",
							i.aggregate AS "aggregate",
							i.gri AS "gri",
							i.roll_forward AS "roll-forward",
							i.factor_type_id AS "factor-type-id",
							i.map_to_ind_sid AS "map-to-ind-sid",
							i.gas_measure_sid AS "gas-measure-sid",
							i.gas_type_id AS "gas-type-id",
							i.normalize AS "normalize",
							i.do_temporal_aggregation AS "do-temporal-aggregation",
							i.calc_output_round_dp AS "calc-output-round-dp",
							i.description AS "description"
						), 
						CASE WHEN i.calc_xml IS NULL THEN NULL ELSE EXTRACT(XMLTYPE(i.calc_xml), ''/'') END, --XMLTYPE(NULL) does not work, also both DECODE and NVL2 do not work with CLOB
						EXTRACT(i.info_xml,''/'') 
					)
					FROM v$ind i
					LEFT JOIN measure m ON i.measure_sid = m.measure_sid
				   WHERE i.map_to_ind_sid IS NULL
						 START WITH i.ind_sid = '||in_ind_sid||'
						 CONNECT BY PRIOR i.ind_sid = i.parent_sid
				')
			) FROM DUAL
		)
	) INTO out_calc_xml
	  FROM dual
	 ;
END;

PROCEDURE GetAppSid(
	in_host					IN	customer.host%TYPE,
	out_app_sid				OUT	customer.app_sid%TYPE
)
AS
BEGIN
	BEGIN
		SELECT app_sid
		  INTO out_app_sid
		  FROM customer
		 WHERE lower(host) = lower(in_host);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The CSR application with host '||in_host||' could not be found');
	END;
END;

PROCEDURE SetCalcXMLAndDeps(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_calc_ind_sid					IN 	security_pkg.T_SID_ID,
	in_calc_xml						IN 	ind.calc_xml%TYPE,
	in_is_stored 					IN 	NUMBER, 
	in_period_set_id				IN	ind.period_set_id%TYPE,
	in_period_interval_id			IN	ind.period_interval_id%TYPE,		
	in_do_temporal_aggregation		IN 	ind.do_temporal_aggregation%TYPE,
	in_calc_description				IN	ind.calc_description%TYPE
)
AS
    v_adjustment        			ind.calc_start_dtm_adjustment%TYPE := 0;
    
    v_start_dtm_adjust  			NUMBER(6) := 0;
    v_end_dtm_adjust    			NUMBER(6) := 0;
    v_fixed_start_dtm   			DATE := null;
    v_fixed_end_dtm     			DATE := null;
  
    v_calc_ind_type					ind.ind_type%TYPE;
    v_ind_type						ind.ind_type%TYPE;
    v_deps							CalcDependencies;
    v_doc                           dbms_xmldom.domdocument;
    v_node                          dbms_xmldom.domnode;
    v_tag_id						binary_integer;
	v_baseline_config_id			binary_integer;
    v_ind_sid						binary_integer;
    v_dep_type						binary_integer;
    v_measure_sid					ind.measure_sid%TYPE;
	v_calc_xml						ind.calc_xml%TYPE;
BEGIN
	IF in_calc_xml IS NULL OR xmltype(in_calc_xml).existsNode('/nop') = 1 THEN
		v_calc_xml := NULL;
	ELSE
		v_calc_xml := in_calc_xml;
		v_doc := dbms_xmldom.newdomdocument(v_calc_xml);
		v_node := dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(v_doc));
	END IF;

	-- Calc jiggery
	SetCalcXML(in_act_id, in_calc_ind_sid, v_calc_xml,
		in_is_stored, in_period_set_id, in_period_interval_id, in_do_temporal_aggregation,
		in_calc_description); 

	-- Fetch the calc ind type for checking dependency validities
	SELECT ind_type
	  INTO v_calc_ind_type
	  FROM ind
	 WHERE ind_sid = in_calc_ind_sid;

	-- Get dependencies + start date adjustment
	IF v_calc_xml IS NOT NULL THEN
		v_adjustment := calc_pkg.GetCalcDependencies(v_node, v_deps);

		GetCalcDateAdjustments(v_node, v_start_dtm_adjust, v_end_dtm_adjust,
									   v_fixed_start_dtm, v_fixed_end_dtm);
	END IF;

	UPDATE ind
	   SET calc_start_dtm_adjustment = v_start_dtm_adjust,
           calc_end_dtm_adjustment = v_end_dtm_adjust,
           calc_fixed_start_dtm = v_fixed_start_dtm,
           calc_fixed_end_dtm= v_fixed_end_dtm
	 WHERE ind_sid = in_calc_ind_sid;

	-- Indicator dependencies	
	DELETE FROM calc_dependency
	 WHERE calc_ind_sid = in_calc_ind_sid;

	v_ind_sid := v_deps.inds.FIRST;
	WHILE v_ind_sid IS NOT NULL LOOP
		v_dep_type := v_deps.inds(v_ind_sid).FIRST;
		WHILE v_dep_type IS NOT NULL LOOP
			IF v_dep_type = csr_data_pkg.DEP_ON_INDICATOR THEN
				BEGIN
					SELECT measure_sid
					  INTO v_measure_sid
					  FROM ind
					 WHERE ind_sid = v_ind_sid;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
			            RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_WRONG_IND_TYPE_FOR_CALC, 
			                'A calculation cannot be performed on the indicator with sid '||v_ind_sid||' because it has no measure');
				END;
			END IF;
	
			-- It's an error for a normal or stored calculation to depend on a calculation
			-- that's marked for reporting only
			IF v_calc_ind_type != csr_data_pkg.IND_TYPE_REPORT_CALC THEN
				SELECT ind_type
				  INTO v_ind_type
				  FROM ind
				 WHERE ind_sid = v_ind_sid;
	
				IF v_ind_type = csr_data_pkg.IND_TYPE_REPORT_CALC THEN		 
	            	RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CALC_DEPENDS_ON_REP_IND, 
	                	'The calculation with ind sid '||in_calc_ind_sid||' and type '||v_calc_ind_type||
	                	' cannot depend on the reporting calculation with ind sid '||v_ind_sid);
				END IF;
			END IF;

	        INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
	        VALUES (in_calc_ind_sid, v_ind_sid, v_dep_type);

			v_dep_type := v_deps.inds(v_ind_sid).NEXT(v_dep_type);
		END LOOP;
		v_ind_sid := v_deps.inds.NEXT(v_ind_sid);
	END LOOP;
	
	-- fix up dependencies on tags
	DELETE FROM calc_tag_dependency
	 WHERE calc_ind_sid = in_calc_ind_sid;

	-- Note that can't use FORALL as you can't reference the index (in this case
	-- the interesting bit) in the insert statement
	v_tag_id := v_deps.tags.FIRST;
	WHILE v_tag_id IS NOT NULL LOOP
		INSERT INTO calc_tag_dependency (calc_ind_sid, tag_id)
		VALUES (in_calc_ind_sid, v_tag_id);
		v_tag_id := v_deps.tags.NEXT(v_tag_id);
	END LOOP;

	-- fix up dependencies on baselines
	DELETE FROM calc_baseline_config_dependency
	 WHERE calc_ind_sid = in_calc_ind_sid;

	v_baseline_config_id := v_deps.baselines.FIRST;
	WHILE v_baseline_config_id IS NOT NULL LOOP
		INSERT INTO calc_baseline_config_dependency (calc_ind_sid, baseline_config_id)
		VALUES (in_calc_ind_sid, v_baseline_config_id);
		v_baseline_config_id := v_deps.baselines.NEXT(v_baseline_config_id);
	END LOOP;

	-- check for circular dependencies     
	CheckCircularDependencies(in_calc_ind_sid);

	-- add jobs
	calc_pkg.AddJobsForCalc(in_calc_ind_sid);
	calc_pkg.AddJobsForInd(in_calc_ind_sid);
END;

/**
* Return if an indicator is used in calculations
* Used in indicator_pkg.IsIndicatorUsed
*/ 
FUNCTION IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID	
)RETURN BOOLEAN
AS
BEGIN
	 FOR x IN (SELECT COUNT(*) found 
				 FROM dual 
				WHERE EXISTS(SELECT 1 
				               FROM calc_dependency 
							  WHERE ind_sid = in_ind_sid
							)
				)
	LOOP
		 RETURN (x.found = 1);
	 END LOOP;
END;

END Calc_Pkg;
/
