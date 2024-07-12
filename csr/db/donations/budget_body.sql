-- HACK with CUSTOM_11 as cash_value in this file... need to find a way to avoid this hardcoded value

CREATE OR REPLACE PACKAGE BODY DONATIONS.budget_Pkg
IS

PROCEDURE AmendBudget(
	in_budget_id					IN	budget.budget_id%TYPE,
	in_scheme_sid	 				IN	budget.scheme_sid%TYPE,
	in_description		 		IN	budget.description%TYPE,
	in_management_cost		IN	budget.management_cost%TYPE,
	in_budget_amount			IN	budget.budget_amount%TYPE,
	in_cur_code						IN	budget.currency_code%TYPE,
	in_exrate							IN	budget.exchange_rate%TYPE,
	in_compare_field_num  IN	budget.compare_field_num%TYPE
)
AS
	CURSOR c_values IS
		SELECT start_dtm, end_dtm, description,management_cost, budget_amount, currency_code, exchange_rate, compare_field_num 
			FROM BUDGET
			WHERE budget_id = in_budget_id;
  r_old                     c_values%ROWTYPE;
	r_new                     c_values%ROWTYPE;
	v_act_id 								security_pkg.T_ACT_ID;
	v_app_sid 							security_pkg.T_SID_ID;
BEGIN
	v_act_id := security_pkg.GetACT();
	v_app_sid := security_pkg.GetApp();
	
	-- fetch old data
	OPEN c_values;
		FETCH c_values INTO r_old;
	CLOSE c_values;
	
	
	UPDATE	budget
		 SET 	description = in_description, 
	  	    management_cost = in_management_cost,
					budget_amount = in_budget_amount,
	  			currency_code = in_cur_code,
	  			compare_field_num = in_compare_field_num,
	  			exchange_rate = NVL(in_exrate, currency_pkg.GetDefaultExRate(v_act_id, v_app_sid, in_cur_code))
	  		 WHERE budget_id = in_budget_id
	  		   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, scheme_sid, security_pkg.PERMISSION_WRITE) = 1;

	-- fetch new data
	OPEN c_values;
		FETCH c_values INTO r_new;
	CLOSE c_values;

	-- write Audit log for changed values
	-- description
	 csr.csr_data_pkg.AuditValueChange(v_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_BUDGET, v_app_sid, 
      in_scheme_sid, 'Budget Description', r_old.description, r_new.description, in_budget_id);
	
	-- management_cost
	 csr.csr_data_pkg.AuditValueChange(v_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_BUDGET, v_app_sid, 
      in_scheme_sid, 'Budget Management Cost', r_old.management_cost, r_new.management_cost, in_budget_id);
	
	-- budget_amount
	 csr.csr_data_pkg.AuditValueChange(v_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_BUDGET, v_app_sid, 
      in_scheme_sid, 'Budget Amount', r_old.budget_amount, r_new.budget_amount, in_budget_id);
	
	-- currency_code
	 csr.csr_data_pkg.AuditValueChange(v_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_BUDGET, v_app_sid, 
      in_scheme_sid, 'Budget Currency', r_old.currency_code, r_new.currency_code, in_budget_id);
	
	-- compare_field_num
	 csr.csr_data_pkg.AuditValueChange(v_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      in_scheme_sid, 'Budget compare field', r_old.compare_field_num, r_new.compare_field_num, in_budget_id);
	
	-- exchange_rate
	 csr.csr_data_pkg.AuditValueChange(v_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_BUDGET, v_app_sid, 
      in_scheme_sid, 'Budget exchange rate', r_old.exchange_rate, r_new.exchange_rate, in_budget_id);
	
END;


-- 
-- PROCEDURE: CreateBUDGET 
--
PROCEDURE SetBudgets (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_scheme_sid	 		IN	budget.scheme_sid%TYPE,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm			IN	budget.start_dtm%TYPE,
	in_end_dtm				IN	budget.start_dtm%TYPE,
	in_description	 		IN	budget.description%TYPE,
	in_management_cost		IN	budget.management_cost%TYPE,
	in_budget_amount		IN	budget.budget_amount%TYPE,
	in_cur_code				IN	budget.currency_code%TYPE,
	in_exrate				IN	budget.exchange_rate%TYPE,
	in_compare_field_num    IN	budget.compare_field_num%TYPE
)
AS
	CURSOR c_values IS
	SELECT budget_id, start_dtm, end_dtm, description, budget_amount, region_group_sid, currency_code, exchange_rate, compare_field_num 
	  FROM BUDGET
	  WHERE scheme_sid = in_scheme_sid
	     		AND region_group_sid in (SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_region_group_sids,',')))
	     		AND end_dtm > in_start_dtm 
	     		AND start_dtm < in_end_dtm;

	v_done						boolean;
	v_app_sid 				security_pkg.T_SID_ID;
	v_new_budget_id		NUMBER(10,0);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_Pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding budget to scheme');
	END IF;
	
	-- Get the app_sid (for later)
	v_app_sid := currency_pkg.GetAppSidFromSchemeSid(in_act_id, in_scheme_sid);
	
	-- for each region group
	FOR r IN (
		SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_region_group_sids,','))
		)
	LOOP
		v_done := false;
    -- check for overlaps
    FOR o IN
    	(SELECT budget_id, start_dtm, end_dtm 
	    	 FROM budget
	   		WHERE scheme_sid = in_scheme_sid
	     		AND region_group_sid = r.item
	     		AND end_dtm > in_start_dtm 
	     		AND start_dtm < in_end_dtm
	     )
	  LOOP    
    	-- if exact match then update
	  	IF o.start_dtm = in_start_dtm AND o.end_dtm = in_end_dtm THEN
					AmendBudget(o.budget_id, in_scheme_sid, in_description, in_management_cost, in_budget_amount, in_cur_code, in_exrate, in_compare_field_num);
					v_done := true;
	  	ELSE
    		-- if not exact match then error
    		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_PERIOD_OVERLAPS, 'Period overlaps');
	  	END IF;
	  END LOOP;
    
    -- else insert
    SELECT budget_id_seq.NEXTVAL INTO v_new_budget_id FROM dual;
    
    IF NOT v_done THEN
			INSERT INTO budget
					(budget_id, region_group_sid, description, scheme_sid,
				 	 start_dtm, end_dtm, management_cost, budget_amount, currency_code, exchange_rate, 	compare_field_num)
			 VALUES (v_new_budget_id, r.item, in_description, in_scheme_sid,
				 	 in_start_dtm, in_end_dtm, in_management_cost, in_budget_amount, in_cur_code,
				 	 NVL(in_exrate, NVL(currency_pkg.GetDefaultExRate(in_act_id, v_app_sid, in_cur_code), 1)), in_compare_field_num
					);
					
				csr.csr_data_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_BUDGET, v_app_sid, 
        in_scheme_sid, 'Budget created with id {0}', v_new_budget_id, null, null, v_new_budget_id);
       
		END IF;
	END LOOP;
END;

PROCEDURE AmendDetails (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_scheme_sid	 		IN	budget.scheme_sid%TYPE,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm			IN	budget.start_dtm%TYPE,
	in_end_dtm				IN	budget.start_dtm%TYPE,
	in_description		 	IN	budget.description%TYPE,
	in_management_cost		IN	budget.management_cost%TYPE,
	in_budget_amount		IN	budget.budget_amount%TYPE,
	in_cur_code				IN	budget.currency_code%TYPE,
	in_exrate				IN	budget.exchange_rate%TYPE,
	in_compare_field_num    IN	budget.compare_field_num%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied ameding budget for scheme');
	END IF;	
	
		FOR r IN (
			SELECT budget_id, description, management_cost, budget_amount, currency_code cur_code, exchange_rate exrate, compare_field_num 
			  FROM budget 
			 WHERE SCHEME_SID = in_scheme_sid
				 AND REGION_GROUP_SID IN (
						SELECT item 
						  FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_region_group_sids,','))
				 ) 
				 AND START_DTM = in_start_dtm
				 AND END_DTM = in_end_dtm)
		LOOP
			IF in_description IS NOT NULL THEN
				AmendBudget(r.budget_id, in_scheme_sid, in_description, r.management_cost, r.budget_amount, r.cur_code, r.exrate, r.compare_field_num);
			END IF;
			IF in_management_cost IS NOT NULL THEN
				AmendBudget(r.budget_id, in_scheme_sid, r.description, in_management_cost, r.budget_amount, r.cur_code, r.exrate, r.compare_field_num);
			END IF;
			IF in_budget_amount IS NOT NULL THEN
				AmendBudget(r.budget_id, in_scheme_sid, r.description, r.management_cost, CASE WHEN in_budget_amount = -1 THEN null ELSE in_budget_amount END, r.cur_code, r.exrate, r.compare_field_num);
			END IF;
			IF in_cur_code IS NOT NULL THEN
				AmendBudget(r.budget_id, in_scheme_sid, r.description, r.management_cost, r.budget_amount, in_cur_code, r.exrate, r.compare_field_num);
			END IF;
			IF in_exrate IS NOT NULL THEN
				AmendBudget(r.budget_id, in_scheme_sid, r.description, r.management_cost, r.budget_amount, r.cur_code, in_exrate, r.compare_field_num);
			END IF;
			IF in_compare_field_num IS NOT NULL THEN
				-- special case if in_compare_field_num = -1, that is when the field was empty (to pass IN NOT NULL condition above)
				AmendBudget(r.budget_id, in_scheme_sid, r.description, r.management_cost, r.budget_amount, r.cur_code, r.exrate,  CASE WHEN in_compare_field_num = -1 THEN null ELSE in_compare_field_num END);
			END IF;
		END LOOP;
END;

PROCEDURE SetBudgetsActive(
	in_scheme_sid	 		IN	budget.scheme_sid%TYPE,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm			IN	budget.start_dtm%TYPE,
	in_end_dtm				IN	budget.start_dtm%TYPE,
	in_is_active			IN  budget.is_active%TYPE
)
AS
	v_act_id	security_pkg.T_ACT_ID;
	v_old_val	budget.is_active%TYPE;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_scheme_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied amending budget for scheme');
	END IF;	
	
		FOR r IN (
			SELECT budget_id, is_active
			  FROM budget 
			 WHERE SCHEME_SID = in_scheme_sid
				 AND REGION_GROUP_SID IN (
						SELECT item 
						  FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_region_group_sids,','))
				 ) 
				 AND START_DTM = in_start_dtm
				 AND END_DTM = in_end_dtm)
		LOOP
			v_old_val := r.is_active;
			
			UPDATE budget
			   SET is_active = in_is_active
			 WHERE budget_id = r.budget_id;
			 
			 -- audit
			 csr.csr_data_pkg.AuditValueChange(v_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_BUDGET, SYS_CONTEXT('SECURITY','APP'), 
			  in_scheme_sid, 'Budget Active', v_old_val, in_is_active, r.budget_id);
		END LOOP;
END;

PROCEDURE GetBudgetListForRegionGroups(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_app_sid                      	IN security_pkg.T_SID_ID,
	in_scheme_sid						IN	security_pkg.T_SID_ID,
	in_region_group_sids				IN	VARCHAR2,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme');
	END IF;

	OPEN out_cur FOR
    SELECT   b.start_dtm,
			 To_char(b.start_dtm,'yyyy-mm-dd') start_dtm_fmt,
			 b.end_dtm,
			 To_char(b.end_dtm,'yyyy-mm-dd')   end_dtm_fmt,
			 b.description,
			 b.budget_amount,
			 b.currency_code,
			 b.currency_symbol,
			 b.currency_label,
			 b.exchange_rate,
			 b.compare_field_num,
			 b.is_active,
			 (
			 SELECT label
			   FROM   custom_field
			  WHERE  field_num = compare_field_num
			  	AND app_sid = in_app_sid) compare_field_label,
					Count(* )                         cnt
				 FROM TABLE(csr.utils_pkg.Splitstring(in_region_group_sids,',')) rg,
				 (
					SELECT budget_id, is_active, region_group_sid, start_dtm, end_dtm, budget_amount, description, compare_field_num, bu.currency_code, cu.symbol currency_symbol, cu.label  currency_label, exchange_rate
					  FROM   budget bu, currency cu
			     WHERE  bu.currency_code = cu.currency_code
					 AND scheme_sid = in_scheme_sid
				 ) b
	  WHERE    rg.item = b.region_group_sid
 GROUP BY start_dtm,
			 end_dtm,
			 description,
			 budget_amount,
			 currency_code,
			 currency_symbol,
			 currency_label,
			 exchange_rate,
			 compare_field_num,
			 is_active
 ORDER BY start_dtm,
			 end_dtm; 
END;

PROCEDURE DeleteBudget( 
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	in_end_dtm						IN	budget.end_dtm%TYPE
)
AS
  v_count             NUMBER(10);
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_Pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting budget from scheme');
	END IF;
	
	-- check if there are any donations assigned to budget
	select count(*) INTO v_count from donation
    where budget_id in (
    SELECT budget_id FROM budget WHERE SCHEME_SID = in_scheme_sid
       AND REGION_GROUP_SID IN (SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_region_group_sids,','))) 
       AND START_DTM = in_start_dtm
       AND END_DTM = in_end_dtm
  );
  
  -- if any donations found then raise error
  IF v_count > 0 THEN 
    RAISE_APPLICATION_ERROR(scheme_pkg.ERR_DONATIONS_FOUND, 'Budget has donations assigned');
  END IF;
  
  -- here we can proceed with deletion
  
	-- first delete constants if there are some
	DELETE FROM budget_constant WHERE budget_id IN 
	(
    SELECT budget_id from budget WHERE SCHEME_SID = in_scheme_sid
       AND REGION_GROUP_SID IN (SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_region_group_sids,','))) 
       AND START_DTM = in_start_dtm
       AND END_DTM = in_end_dtm
  );
  
  -- delete budgets finally
	DELETE FROM BUDGET
	 WHERE SCHEME_SID = in_scheme_sid
	   AND REGION_GROUP_SID IN (SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_region_group_sids,','))) 
	   AND START_DTM = in_start_dtm
	   AND END_DTM = in_end_dtm;
END;

-- sort of deprecated - prefer GetBudgetAndConstants 
PROCEDURE GetBudget(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_budget_id					IN	budget.budget_id%TYPE,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_region_group_sid	security_pkg.T_SID_ID;
	v_scheme_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT scheme_sid, region_group_sid INTO v_scheme_sid, v_region_group_sid
	  FROM BUDGET 
	 WHERE budget_id = in_budget_id;
	 
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_region_group_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region group');
	END IF;
	
	OPEN out_cur FOR
		 SELECT budget_id, scheme_sid, region_group_sid, start_dtm, end_dtm, description,
		 		management_cost, budget_amount, currency_code, exchange_rate
		   FROM budget
		  WHERE budget_id = in_budget_id;
END;

PROCEDURE GetBudgetAndConstants(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_budget_id						IN	budget.budget_id%TYPE,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR,
	out_constants						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_region_group_sid	security_pkg.T_SID_ID;
	v_scheme_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT scheme_sid, region_group_sid INTO v_scheme_sid, v_region_group_sid
	  FROM BUDGET 
	 WHERE budget_id = in_budget_id;
	 
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_region_group_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region group');
	END IF;
	
	OPEN out_cur FOR
		 SELECT budget_id, scheme_sid, region_group_sid, start_dtm, end_dtm, description,
		 		management_cost, budget_amount, currency_code, exchange_rate
		   FROM budget
		  WHERE budget_id = in_budget_id;
	
	OPEN out_constants FOR
		 SELECT bc.constant_id, lookup_key, val
		   FROM budget_constant bc, constant c
		  WHERE bc.budget_id = in_budget_id
		    AND bc.constant_id = c.constant_id;
END;

PROCEDURE GetBudgetList(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme');
	END IF;
	
	OPEN out_cur FOR
		 SELECT budget_id, start_dtm, end_dtm, description,
		 		management_cost, budget_amount, exchange_rate, is_active
		   FROM budget
		  WHERE scheme_sid = in_scheme_sid
		    AND region_group_sid = in_region_group_sid
		  ORDER BY start_dtm;
END;


PROCEDURE GetBudgetsByName(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_description						IN	budget.description%TYPE,
	in_scheme_sids						IN  csr.utils_pkg.T_NUMBERS,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_items								csr.T_SPLIT_NUMERIC_TABLE;
BEGIN

	-- sec check

	-- no schemes passed - look at all periods
	IF in_scheme_sids.COUNT = 1 AND in_scheme_sids(1) IS NULL THEN
	
		-- get all budget ID's for these schemes
		OPEN out_cur FOR
			SELECT b.budget_id, b.description, b.start_dtm, b.end_dtm 
			  FROM budget b
			 WHERE lower(b.description) like lower(in_description); --case insensitive
	
	ELSE
		
		-- load up scheme sid table
		t_items := csr.utils_pkg.NumericArrayToTable(in_scheme_sids);
	
		-- get all budget details for these schemes
		OPEN out_cur FOR
			SELECT b.budget_id, b.description, b.start_dtm, b.end_dtm 
			  FROM scheme s, budget b
			 WHERE s.scheme_sid = b.scheme_sid
			   AND s.scheme_sid IN (SELECT item scheme_sid FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) 
			   AND lower(b.description) like lower(in_description); --case insensitive
	
	END IF;

END;


PROCEDURE GetBudgetsForRegionGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check region group access?
	/*
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_group_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region group');
	END IF;
	*/
	
	OPEN out_cur FOR
		 SELECT budget_id, scheme_sid, region_group_sid, start_dtm, end_dtm, description,
		 		management_cost, budget_amount, currency_code, exchange_rate
		   FROM budget
		  WHERE region_group_sid = in_region_group_sid
		  ORDER BY start_dtm;
END;

PROCEDURE GetBudgetsForScheme(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme');
	END IF;
	
	OPEN out_cur FOR
		 SELECT budget_id, scheme_sid, region_group_sid, start_dtm, end_dtm, description,
		 		management_cost, budget_amount, currency_code, exchange_rate
		   FROM budget
		  WHERE scheme_sid = in_scheme_sid
		  ORDER BY start_dtm;
END;

PROCEDURE GetBudgetsForApp(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check access on app?
	/*
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme');
	END IF;
	*/
	
	OPEN out_cur FOR
		 SELECT budget_id, scheme_sid, region_group_sid, start_dtm, end_dtm, description,
		 		management_cost, budget_amount, currency_code, exchange_rate
		   FROM budget
		  WHERE scheme_sid IN (
		  	SELECT scheme_sid 
		  	  FROM scheme
		  	 WHERE app_sid = in_app_sid)
		  ORDER BY start_dtm;
END;

PROCEDURE GetMyBudgetIDs(
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
	v_super_admin_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	-- Allow to see all data if user is csrSuperAdmin
	v_super_admin_sid := securableobject_pkg.GetSIDFromPath(in_act_id, 0, 'csr/SuperAdmins');
	IF user_pkg.IsUserInGroup(in_act_id, v_super_admin_sid) = 0 THEN
		-- not superadmin
		OPEN out_cur FOR
			SELECT budget_id, can_view_all, can_view_mine, can_view_region
			  FROM budget b,  
				(SELECT scheme_sid, 
					security_pkg.SQL_IsAccessAllowedSID(in_act_id, scheme_sid, scheme_pkg.PERMISSION_VIEW_ALL) can_view_all,
					security_pkg.SQL_IsAccessAllowedSID(in_act_id, scheme_sid, scheme_pkg.PERMISSION_VIEW_MINE) can_view_mine,
					security_pkg.SQL_IsAccessAllowedSID(in_act_id, scheme_sid, scheme_pkg.PERMISSION_VIEW_REGION) can_view_region
				   FROM scheme 
				  WHERE app_sid = in_app_sid
				    AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, scheme_sid, security_pkg.PERMISSION_READ) = 1) s,
				(SELECT DISTINCT rg.region_group_sid -- we use DISTINCT because we have to join to region_group_member to get the region_sid, but we're only interested in the region_group_sid
				   FROM region_group rg, csr.region_owner ro, region_group_member rgm		   
				  WHERE rg.app_sid = in_app_sid
				    AND ro.app_sid = in_app_sid
				    AND ro.app_sid = rg.app_sid
				    AND ro.user_sid = v_user_sid
				    AND rgm.region_sid = ro.region_sid
				    AND rgm.region_group_sid = rg.region_group_sid)rg
			 WHERE b.scheme_sid = s.scheme_sid
			   AND b.region_group_sid = rg.region_group_sid;
	ELSE
		-- super admin -> show all, not only for regions that user is owner of
		OPEN out_cur FOR
			SELECT budget_id, can_view_all, can_view_mine, can_view_region
			  FROM budget b,  
				(SELECT scheme_sid,
					1 can_view_all, 
					1 can_view_mine,
					1 can_view_region
				   FROM scheme 
				  WHERE app_sid = in_app_sid)s,
				(SELECT DISTINCT rg.region_group_sid -- we use DISTINCT because we have to join to region_group_member to get the region_sid, but we're only interested in the region_group_sid
				   FROM region_group rg, region_group_member rgm		   
				  WHERE rg.app_sid = in_app_sid 
				    AND rgm.app_sid = in_app_sid
				    AND rg.app_sid = rgm.app_sid
				    AND rgm.region_group_sid = rg.region_group_sid)rg
			 WHERE b.scheme_sid = s.scheme_sid
			   AND b.region_group_sid = rg.region_group_sid;
	END IF;
END;

PROCEDURE GetBudgetId(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	out_budget_id					OUT	budget.budget_id%TYPE
)
AS
BEGIN
	BEGIN		
		SELECT budget_id INTO out_budget_id
		 FROM budget
		WHERE scheme_sid = in_scheme_sid
		  AND region_group_sid = in_region_group_sid
		  AND in_start_dtm >= start_dtm
	    AND in_start_dtm < end_dtm;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN out_budget_id := -1;
	END;
END;


PROCEDURE GetBudgetIdAndDetails(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	out_cur								OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT budget_id, s.name scheme_name, rg.description region_group_description, b.description budget_description
		 FROM budget b, scheme s, region_group rg
		WHERE b.scheme_sid = in_scheme_sid
		  AND b.region_group_sid = in_region_group_sid
		  AND in_start_dtm >= start_dtm
	    AND in_start_dtm < end_dtm
      AND b.scheme_Sid = s.scheme_sid
      AND b.region_group_sid = rg.region_group_sid;
END;

/**
* This is old procedure used in first version of donations, 
* it has hack to use custom_11 as field to compare, which not necessarily will be true
* 
* use GetMyBudgetsNoFormat if you need similiar functionality
*/
PROCEDURE GetMyBudgets(
	in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid			    	IN	security_pkg.T_SID_ID,
	in_permission_set	        IN	security_pkg.T_PERMISSION,
	in_all_years			    IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid 	security_pkg.T_SID_ID;
BEGIN
	user_pkg.getSid(in_act_id, v_user_sid);

	OPEN out_cur FOR
		-- distinct is required as we might be owners of several
		-- regions in a region group
		SELECT distinct s.scheme_sid, s.name scheme_name, 
				rg.region_group_sid, rg.description region_group_description, 
				b.budget_id, b.description budget_description, 
		b.budget_amount,		
        TO_CHAR(b.budget_amount,'L999G9999G999G999G999', 'NLS_CURRENCY = '''||NVL(cur.symbol,'('||cur.currency_code||')')||''' ') budget_amount_fmt,
        (SELECT sum(custom_11) FROM donation d, donation_status ds WHERE d.donation_status_sid = ds.donation_status_sid AND means_donated = 1   AND budget_id = b.budget_id) total_donated,
        TO_CHAR(
        	(SELECT sum(custom_11) FROM donation d, donation_status ds WHERE d.donation_status_sid = ds.donation_status_sid AND means_donated = 1   AND budget_id = b.budget_id)
        	,'L999G9999G999G999G999', 'NLS_CURRENCY = '''||NVL(cur.symbol,'('||cur.currency_code||')')||''' ') total_donated_fmt
          FROM csr.region_owner ro,
		       region_group_member rgm,
		       region_group rg,
		       budget b,
		       scheme s,
		       currency cur
		 WHERE ro.user_sid = v_user_sid
           AND s.app_Sid = in_app_sid
		   AND s.active = 1
		   AND rgm.region_sid = ro.region_sid
		   AND rgm.region_group_sid = rg.region_group_sid
		   AND rgm.region_group_sid = b.region_group_sid
		   AND b.scheme_sid = s.scheme_sid
		   AND cur.currency_code = b.currency_code
		   AND b.is_active = 1
		   AND ((SYSDATE >= b.start_dtm  
		   			AND SYSDATE < b.end_dtm) OR in_all_years = 1)
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, s.scheme_sid, in_permission_set) = 1
		 ORDER BY s.name, scheme_sid, rg.description, rg.region_group_sid, 
		 		b.description, b.budget_id;
END;

/**
*   This procedure returns set of donations info based on budgets with some details about amount of budget and value of currently donated based on budget.COMPARE_FIELD_NUM
*
*/
PROCEDURE GetMyBudgetsNoFormat(
	in_act_id			IN	security_pkg.T_ACT_ID,
    in_app_sid			IN	security_pkg.T_SID_ID,
	in_permission_set	IN	security_pkg.T_PERMISSION,
	in_all_years		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid 	security_pkg.T_SID_ID;
BEGIN
	user_pkg.getSid(in_act_id, v_user_sid);
	
	-- this select statement have specific columns from sr-online.credit360.com setup, this SP is used only on the page c:\cvs\csr\web\site\donations2\reports\schemes.acds to generate report
	OPEN out_cur FOR
        SELECT distinct s.scheme_sid, s.name scheme_name, rg.region_group_sid, rg.description region_group_description, b.budget_id, b.description budget_description, b.budget_amount, cur.symbol cur_symbol,
			(SELECT SUM(custom_11) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id) cash_value, 
			(SELECT SUM(custom_15) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id) in_kind_value,
			(SELECT SUM(custom_13) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id) time_value, 
			(SELECT SUM(custom_16) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id) leverage_amount, 
        case
			when b.compare_field_num is null THEN null
            when b.compare_field_num =1 then (SELECT SUM(custom_1) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =2 then (SELECT SUM(custom_2) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =3 then (SELECT SUM(custom_3) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =4 then (SELECT SUM(custom_4) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =5 then (SELECT SUM(custom_5) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =6 then (SELECT SUM(custom_6) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =7 then (SELECT SUM(custom_7) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =8 then (SELECT SUM(custom_8) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =9 then (SELECT SUM(custom_9) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =10 then (SELECT SUM(custom_10) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =11 then (SELECT SUM(custom_11) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =12 then (SELECT SUM(custom_12) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =13 then (SELECT SUM(custom_13) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =14 then (SELECT SUM(custom_14) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =15 then (SELECT SUM(custom_15) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =16 then (SELECT SUM(custom_16) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =17 then (SELECT SUM(custom_17) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =18 then (SELECT SUM(custom_18) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =19 then (SELECT SUM(custom_19) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =20 then (SELECT SUM(custom_20) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =21 then (SELECT SUM(custom_21) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =22 then (SELECT SUM(custom_22) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =23 then (SELECT SUM(custom_23) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =24 then (SELECT SUM(custom_24) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =25 then (SELECT SUM(custom_25) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =26 then (SELECT SUM(custom_26) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =27 then (SELECT SUM(custom_27) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =28 then (SELECT SUM(custom_28) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =29 then (SELECT SUM(custom_29) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =30 then (SELECT SUM(custom_30) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =31 then (SELECT SUM(custom_31) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =32 then (SELECT SUM(custom_32) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =33 then (SELECT SUM(custom_33) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =34 then (SELECT SUM(custom_34) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =35 then (SELECT SUM(custom_35) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =36 then (SELECT SUM(custom_36) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =37 then (SELECT SUM(custom_37) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =38 then (SELECT SUM(custom_38) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =39 then (SELECT SUM(custom_39) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =40 then (SELECT SUM(custom_40) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =41 then (SELECT SUM(custom_41) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =42 then (SELECT SUM(custom_42) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =43 then (SELECT SUM(custom_43) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =44 then (SELECT SUM(custom_44) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =45 then (SELECT SUM(custom_45) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =46 then (SELECT SUM(custom_46) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =47 then (SELECT SUM(custom_47) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =48 then (SELECT SUM(custom_48) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =49 then (SELECT SUM(custom_49) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =50 then (SELECT SUM(custom_50) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =51 then (SELECT SUM(custom_51) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =52 then (SELECT SUM(custom_52) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =53 then (SELECT SUM(custom_53) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =54 then (SELECT SUM(custom_54) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =55 then (SELECT SUM(custom_55) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =56 then (SELECT SUM(custom_56) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =57 then (SELECT SUM(custom_57) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =58 then (SELECT SUM(custom_58) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =59 then (SELECT SUM(custom_59) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =60 then (SELECT SUM(custom_60) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =61 then (SELECT SUM(custom_61) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =62 then (SELECT SUM(custom_62) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =63 then (SELECT SUM(custom_63) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =64 then (SELECT SUM(custom_64) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =65 then (SELECT SUM(custom_65) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =66 then (SELECT SUM(custom_66) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =67 then (SELECT SUM(custom_67) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =68 then (SELECT SUM(custom_68) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =69 then (SELECT SUM(custom_69) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =70 then (SELECT SUM(custom_70) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =71 then (SELECT SUM(custom_71) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =72 then (SELECT SUM(custom_72) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =73 then (SELECT SUM(custom_73) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =74 then (SELECT SUM(custom_74) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =75 then (SELECT SUM(custom_75) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =76 then (SELECT SUM(custom_76) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =77 then (SELECT SUM(custom_77) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =78 then (SELECT SUM(custom_78) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =79 then (SELECT SUM(custom_79) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =80 then (SELECT SUM(custom_80) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =81 then (SELECT SUM(custom_81) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =82 then (SELECT SUM(custom_82) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =83 then (SELECT SUM(custom_83) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =84 then (SELECT SUM(custom_84) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =85 then (SELECT SUM(custom_85) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =86 then (SELECT SUM(custom_86) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =87 then (SELECT SUM(custom_87) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =88 then (SELECT SUM(custom_88) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =89 then (SELECT SUM(custom_89) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =90 then (SELECT SUM(custom_90) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
            when b.compare_field_num =91 then (SELECT SUM(custom_91) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =92 then (SELECT SUM(custom_92) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =93 then (SELECT SUM(custom_93) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =94 then (SELECT SUM(custom_94) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =95 then (SELECT SUM(custom_95) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =96 then (SELECT SUM(custom_96) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =97 then (SELECT SUM(custom_97) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =98 then (SELECT SUM(custom_98) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =99 then (SELECT SUM(custom_99) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =100 then (SELECT SUM(custom_100) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =101 then (SELECT SUM(custom_101) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =102 then (SELECT SUM(custom_102) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =103 then (SELECT SUM(custom_103) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =104 then (SELECT SUM(custom_104) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =105 then (SELECT SUM(custom_105) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =106 then (SELECT SUM(custom_106) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =107 then (SELECT SUM(custom_107) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =108 then (SELECT SUM(custom_108) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =109 then (SELECT SUM(custom_109) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =110 then (SELECT SUM(custom_110) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =111 then (SELECT SUM(custom_111) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =112 then (SELECT SUM(custom_112) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =113 then (SELECT SUM(custom_113) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =114 then (SELECT SUM(custom_114) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =115 then (SELECT SUM(custom_115) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =116 then (SELECT SUM(custom_116) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =117 then (SELECT SUM(custom_117) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =118 then (SELECT SUM(custom_118) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =119 then (SELECT SUM(custom_119) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =120 then (SELECT SUM(custom_120) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =121 then (SELECT SUM(custom_121) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =122 then (SELECT SUM(custom_122) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =123 then (SELECT SUM(custom_123) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =124 then (SELECT SUM(custom_124) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =125 then (SELECT SUM(custom_125) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =126 then (SELECT SUM(custom_126) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =127 then (SELECT SUM(custom_127) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =128 then (SELECT SUM(custom_128) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =129 then (SELECT SUM(custom_129) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =130 then (SELECT SUM(custom_130) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =131 then (SELECT SUM(custom_131) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =132 then (SELECT SUM(custom_132) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =133 then (SELECT SUM(custom_133) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =134 then (SELECT SUM(custom_134) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =135 then (SELECT SUM(custom_135) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =136 then (SELECT SUM(custom_136) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =137 then (SELECT SUM(custom_137) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =138 then (SELECT SUM(custom_138) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =139 then (SELECT SUM(custom_139) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =140 then (SELECT SUM(custom_140) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =141 then (SELECT SUM(custom_141) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =142 then (SELECT SUM(custom_142) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =143 then (SELECT SUM(custom_143) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =144 then (SELECT SUM(custom_144) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =145 then (SELECT SUM(custom_145) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =146 then (SELECT SUM(custom_146) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =147 then (SELECT SUM(custom_147) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =148 then (SELECT SUM(custom_148) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =149 then (SELECT SUM(custom_149) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =150 then (SELECT SUM(custom_150) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =151 then (SELECT SUM(custom_151) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =152 then (SELECT SUM(custom_152) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =153 then (SELECT SUM(custom_153) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =154 then (SELECT SUM(custom_154) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =155 then (SELECT SUM(custom_155) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =156 then (SELECT SUM(custom_156) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =157 then (SELECT SUM(custom_157) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =158 then (SELECT SUM(custom_158) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =159 then (SELECT SUM(custom_159) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =160 then (SELECT SUM(custom_160) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =161 then (SELECT SUM(custom_161) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =162 then (SELECT SUM(custom_162) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =163 then (SELECT SUM(custom_163) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =164 then (SELECT SUM(custom_164) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =165 then (SELECT SUM(custom_165) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =166 then (SELECT SUM(custom_166) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =167 then (SELECT SUM(custom_167) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =168 then (SELECT SUM(custom_168) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =169 then (SELECT SUM(custom_169) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =170 then (SELECT SUM(custom_170) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =171 then (SELECT SUM(custom_171) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =172 then (SELECT SUM(custom_172) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =173 then (SELECT SUM(custom_173) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =174 then (SELECT SUM(custom_174) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =175 then (SELECT SUM(custom_175) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =176 then (SELECT SUM(custom_176) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =177 then (SELECT SUM(custom_177) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =178 then (SELECT SUM(custom_178) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =179 then (SELECT SUM(custom_179) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =180 then (SELECT SUM(custom_180) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =181 then (SELECT SUM(custom_181) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =182 then (SELECT SUM(custom_182) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =183 then (SELECT SUM(custom_183) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =184 then (SELECT SUM(custom_184) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =185 then (SELECT SUM(custom_185) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =186 then (SELECT SUM(custom_186) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =187 then (SELECT SUM(custom_187) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =188 then (SELECT SUM(custom_188) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =189 then (SELECT SUM(custom_189) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =190 then (SELECT SUM(custom_190) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =191 then (SELECT SUM(custom_191) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =192 then (SELECT SUM(custom_192) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =193 then (SELECT SUM(custom_193) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =194 then (SELECT SUM(custom_194) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =195 then (SELECT SUM(custom_195) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =196 then (SELECT SUM(custom_196) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =197 then (SELECT SUM(custom_197) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =198 then (SELECT SUM(custom_198) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =199 then (SELECT SUM(custom_199) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =200 then (SELECT SUM(custom_200) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =201 then (SELECT SUM(custom_201) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =202 then (SELECT SUM(custom_202) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =203 then (SELECT SUM(custom_203) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =204 then (SELECT SUM(custom_204) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =205 then (SELECT SUM(custom_205) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =206 then (SELECT SUM(custom_206) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =207 then (SELECT SUM(custom_207) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =208 then (SELECT SUM(custom_208) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =209 then (SELECT SUM(custom_209) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =210 then (SELECT SUM(custom_210) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =211 then (SELECT SUM(custom_211) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =212 then (SELECT SUM(custom_212) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =213 then (SELECT SUM(custom_213) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =214 then (SELECT SUM(custom_214) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =215 then (SELECT SUM(custom_215) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =216 then (SELECT SUM(custom_216) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =217 then (SELECT SUM(custom_217) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =218 then (SELECT SUM(custom_218) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =219 then (SELECT SUM(custom_219) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =220 then (SELECT SUM(custom_220) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =221 then (SELECT SUM(custom_221) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =222 then (SELECT SUM(custom_222) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =223 then (SELECT SUM(custom_223) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =224 then (SELECT SUM(custom_224) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =225 then (SELECT SUM(custom_225) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =226 then (SELECT SUM(custom_226) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =227 then (SELECT SUM(custom_227) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =228 then (SELECT SUM(custom_228) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =229 then (SELECT SUM(custom_229) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =230 then (SELECT SUM(custom_230) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =231 then (SELECT SUM(custom_231) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =232 then (SELECT SUM(custom_232) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =233 then (SELECT SUM(custom_233) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =234 then (SELECT SUM(custom_234) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =235 then (SELECT SUM(custom_235) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =236 then (SELECT SUM(custom_236) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =237 then (SELECT SUM(custom_237) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =238 then (SELECT SUM(custom_238) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =239 then (SELECT SUM(custom_239) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =240 then (SELECT SUM(custom_240) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =241 then (SELECT SUM(custom_241) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =242 then (SELECT SUM(custom_242) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =243 then (SELECT SUM(custom_243) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =244 then (SELECT SUM(custom_244) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =245 then (SELECT SUM(custom_245) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =246 then (SELECT SUM(custom_246) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =247 then (SELECT SUM(custom_247) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =248 then (SELECT SUM(custom_248) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =249 then (SELECT SUM(custom_249) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =250 then (SELECT SUM(custom_250) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =251 then (SELECT SUM(custom_251) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =252 then (SELECT SUM(custom_252) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =253 then (SELECT SUM(custom_253) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =254 then (SELECT SUM(custom_254) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =255 then (SELECT SUM(custom_255) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =256 then (SELECT SUM(custom_256) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =257 then (SELECT SUM(custom_257) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =258 then (SELECT SUM(custom_258) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =259 then (SELECT SUM(custom_259) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
			when b.compare_field_num =260 then (SELECT SUM(custom_260) FROM donation d, donation_status ds  WHERE d.donation_status_sid = ds.donation_status_sid  AND means_donated = 1 AND budget_id = b.budget_id)
        end total_donated        
    FROM csr.region_owner ro,region_group_member rgm,region_group rg,budget b,scheme s,currency cur
    WHERE ro.user_sid = v_user_sid AND s.app_Sid = in_app_sid AND s.active = 1 AND rgm.region_sid = ro.region_sid
    AND rgm.region_group_sid = rg.region_group_sid AND rgm.region_group_sid = b.region_group_sid
    AND b.scheme_sid = s.scheme_sid AND cur.currency_code = b.currency_code
    AND ((SYSDATE >= b.start_dtm  AND SYSDATE < b.end_dtm) OR in_all_years = 1)
    AND security_pkg.SQL_IsAccessAllowedSID( in_act_id, s.scheme_sid, in_permission_set ) = 1
    ORDER BY s.name, scheme_sid, rg.description, rg.region_group_sid, b.description, b.budget_id;
END;

PROCEDURE GetAllSchemeData(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- outer join on budget, so budget_id might be null (i.e. no budgets yet defined)
	-- sorted by scheme_sid, region_group_sid, budget.Start_dtm
	OPEN out_cur FOR
		SELECT rgs.scheme_sid, rgs.name scheme_name, sd.donation_count,
	 		rgs.region_group_sid, rgs.description region_group_description, 
	    	b.budget_id, b.description budget_description, b.start_dtm, 
	    	b.end_dtm, b.budget_amount, b.currency_code, b.exchange_rate
	    FROM budget b,
	   	(SELECT s.scheme_sid, s.name, rg.region_group_sid, rg.description
		     FROM region_group rg, scheme s
		 		WHERE s.app_sid = in_app_sid
		   		AND rg.app_sid = in_app_sid)rgs,
   		(SELECT s.scheme_sid, COUNT(*) donation_count 
			   FROM donation d, scheme s 
			  WHERE d.scheme_sid = s.scheme_sid 
			    AND s.app_sid = in_app_sid 
			  GROUP BY s.scheme_sid)sd
		 WHERE b.scheme_sid(+) = rgs.scheme_sid
		   AND b.region_group_sid(+) = rgs.region_group_sid
			 AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, rgs.scheme_sid, security_pkg.PERMISSION_READ) = 1
			 AND sd.scheme_sid(+) = rgs.scheme_sid
		 ORDER BY rgs.scheme_sid, rgs.region_group_sid, b.start_dtm;
END;

PROCEDURE GetSchemeData(
	in_act_id			IN	security_pkg.T_ACT_ID,
  in_app_sid		IN	security_pkg.T_SID_ID,
  in_scheme_sid			IN	security_pkg.T_SID_ID,
  out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- outer join on budget, so budget_id might be null (i.e. no budgets yet defined)
	-- sorted by scheme_sid, region_group_sid, budget.Start_dtm
	OPEN out_cur FOR
		SELECT rgs.scheme_sid, rgs.name scheme_name, sd.donation_count,
	 		rgs.region_group_sid, rgs.description region_group_description, 
	    	b.budget_id, b.description budget_description, b.start_dtm, 
	    	b.end_dtm, b.budget_amount, b.currency_code, b.exchange_rate
	    FROM budget b,
	   	(SELECT s.scheme_sid, s.name, rg.region_group_sid, rg.description
		     FROM region_group rg, scheme s
		 		WHERE s.app_sid = in_app_sid
		   		AND rg.app_sid = in_app_sid)rgs,
   		(SELECT s.scheme_sid, COUNT(*) donation_count 
			   FROM donation d, scheme s 
			  WHERE d.scheme_sid = s.scheme_sid 
			    AND s.app_sid = in_app_sid 
			  GROUP BY s.scheme_sid)sd
		 WHERE b.scheme_sid(+) = rgs.scheme_sid
		   AND b.region_group_sid(+) = rgs.region_group_sid
			 AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, rgs.scheme_sid, security_pkg.PERMISSION_READ) = 1
			 AND sd.scheme_sid(+) = rgs.scheme_sid
			 AND rgs.scheme_sid = in_scheme_sid
		 ORDER BY rgs.scheme_sid, rgs.region_group_sid, b.start_dtm;
END;


PROCEDURE GetSchemeList(
    in_act_id			IN	security_pkg.T_ACT_ID,
    in_app_sid		IN	security_pkg.T_SID_ID,
    out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT s.name scheme_name, s.scheme_sid, (
            select count(*) from region_group
            ) regions_count 
        FROM scheme s 
        WHERE   security_pkg.SQL_IsAccessAllowedSID(in_act_id, s.scheme_sid, security_pkg.PERMISSION_READ) = 1 
          AND   app_sid = in_app_sid
        ORDER BY s.name;

END;        


PROCEDURE GetConstantsForBudget(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	in_end_dtm						IN	budget.end_dtm%TYPE,
  out_cur				        OUT security_pkg.T_OUTPUT_CUR
)
AS
  v_app_sid         security_pkg.T_SID_ID;
BEGIN
  v_app_sid := security_pkg.getApp;
  OPEN out_cur FOR
    SELECT x.constant_id,
           x.lookup_key,
           bc.val
    FROM   budget_constant bc,
           (SELECT b.budget_id,
                   c.constant_id,
                   c.lookup_key
            FROM   scheme s,
                   CONSTANT c,
                   budget b
            WHERE  c.app_sid = v_app_sid
                   AND s.app_sid = v_app_sid
                   AND s.scheme_sid = b.scheme_sid
                   AND b.budget_id IN (
                      SELECT budget_id 
                        FROM budget 
                        WHERE SCHEME_SID = in_scheme_sid
                         AND REGION_GROUP_SID IN (SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_region_group_sids,','))) 
                         AND START_DTM = in_start_dtm
                         AND END_DTM = in_end_dtm
                   )) x
    WHERE  x.budget_id = bc.budget_id (+)
           AND x.constant_id = bc.constant_id (+)
    GROUP BY
      x.constant_id, x.lookup_key, bc.val;
END;

PROCEDURE SetConstantForBudgets(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_region_group_sids	IN	VARCHAR2,
	in_start_dtm					IN	budget.start_dtm%TYPE,
	in_end_dtm						IN	budget.end_dtm%TYPE,
	in_constant_id        IN  constant.constant_id%TYPE,
	in_val                IN  budget_constant.val%TYPE
)
AS
BEGIN
    -- delete all entries first with this constant and budget
    DELETE FROM budget_constant
    WHERE       constant_id = in_constant_id
                AND budget_id IN (SELECT budget_id
                                  FROM   budget
                                  WHERE  scheme_sid = in_scheme_sid
                                         AND region_group_sid IN (SELECT item
                                                                  FROM   TABLE(csr.utils_pkg.Splitstring(in_region_group_sids,',')))
                                         AND start_dtm = in_start_dtm
                                         AND end_dtm = in_end_dtm); 

    -- now add entries
    INSERT INTO budget_constant
               (budget_id,
                constant_id,
                val)
    SELECT budget_id,
           in_constant_id,
           in_val
    FROM   budget
    WHERE  scheme_sid = in_scheme_sid
           AND region_group_sid IN (SELECT item
                                    FROM   TABLE(csr.utils_pkg.Splitstring(in_region_group_sids,',')))
           AND start_dtm = in_start_dtm
           AND end_dtm = in_end_dtm; 

  
END;

PROCEDURE GetConstants(
  out_cur OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
  OPEN out_cur FOR
    SELECT lookup_key FROM constant where app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

END budget_Pkg;
/
