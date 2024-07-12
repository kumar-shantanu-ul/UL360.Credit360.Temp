CREATE OR REPLACE PACKAGE BODY SUPPLIER.supplier_user_pkg
IS

-- security interface procs
PROCEDURE CreateObject(
	in_act 				IN	security_pkg.T_ACT_ID,
	in_sid_id			IN	security_pkg.T_SID_ID,
	in_class_id			IN	security_pkg.T_CLASS_ID,
	in_name				IN	security_pkg.T_SO_NAME,
	in_parent_sid_id	IN  security_pkg.T_SID_ID)
IS
BEGIN
	-- call back to base class
	csr.csr_user_pkg.CreateObject(in_act, in_sid_id, in_class_id, in_name, in_parent_sid_Id);		
END CreateObject;


PROCEDURE RenameObject(
	in_act 		IN	security_pkg.T_ACT_ID,
	in_sid_id 	IN	security_pkg.T_SID_ID,
	in_new_name IN	security_pkg.T_SO_NAME)
IS
BEGIN
	-- call back to base class
	csr.csr_user_pkg.RenameObject(in_act, in_sid_id, in_new_name);
END RenameObject;


PROCEDURE DeleteObject(
	in_act 		IN	security_pkg.T_ACT_ID,
	in_sid_id 	IN	security_pkg.T_SID_ID)
IS
BEGIN
	-- clean up our end
	DELETE FROM COMPANY_USER
	 WHERE CSR_USER_SID = in_sid_id;
	
	-- call back to base class
	csr.csr_user_pkg.DeleteObject(in_act, in_sid_id);
END DeleteObject;


PROCEDURE MoveObject(
	in_act 					IN	security_pkg.T_ACT_ID,
	in_sid_id 				IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id 	IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN	security_pkg.T_SID_ID
)
IS
BEGIN
	-- call back to base class
	csr.csr_user_pkg.MoveObject(in_act, in_sid_id, in_new_parent_sid_id, in_old_parent_sid_id);
END MoveObject;


-- User callbacks
PROCEDURE LogOff(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- call back to base class
	csr.csr_user_pkg.Logoff(in_act_id, in_sid_id);
END;


PROCEDURE LogOn(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_act_timeout			IN security_pkg.T_ACT_TIMEOUT,
	in_logon_type			IN security_pkg.T_LOGON_TYPE
)
AS
BEGIN
	-- call back to base class
	csr.csr_user_pkg.Logon(in_act_id, in_sid_id, in_act_timeout, in_logon_type);
END;



PROCEDURE LogonFailed(
	in_sid_id				IN security_pkg.T_SID_ID,
	in_error_code			IN NUMBER,
	in_message			    IN VARCHAR2
)
AS
BEGIN
	-- call back to base class
	csr.csr_user_pkg.LogonFailed(in_sid_id, in_error_code, in_message);
END;


PROCEDURE GetAccountPolicy(
	in_sid_id				IN	security_pkg.T_SID_ID,
	out_policy_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	-- call back to base class
	csr.csr_user_pkg.GetAccountPolicy(in_sid_id, out_policy_sid);
END;




-- adds, or updates the company assigned to a supplier user
PROCEDURE UpdateUserCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_new_company_sid		IN	security_pkg.T_SID_ID,
	in_user_sid				IN	security_pkg.T_SID_ID
)
AS
	v_old_company_sid 		security_pkg.T_SID_ID;
BEGIN

	-- User upsert pattern - only do so with SP 
	BEGIN	
		company_pkg.AddContact(in_act_id, in_app_sid, in_new_company_sid, in_user_sid);	
	EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
    
		-- Get the old user company sid
		SELECT company_sid INTO v_old_company_sid  
			  FROM company_user
		     WHERE csr_user_sid = in_user_sid;
	    
	   company_pkg.RemoveContact(in_act_id, in_app_sid, v_old_company_sid, in_user_sid);   
	   
	   company_pkg.AddContact(in_act_id, in_app_sid, in_new_company_sid, in_user_sid);	 
	    
	END;
					
END;

PROCEDURE ClearUserCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_user_sid				IN	security_pkg.T_SID_ID
)
AS
	v_old_company_sid 		security_pkg.T_SID_ID;
BEGIN
		
	BEGIN
		-- Get the old user company sid
		SELECT company_sid INTO v_old_company_sid  
			  FROM company_user
		     WHERE csr_user_sid = in_user_sid;
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
    	-- no data to clear
    	RETURN;
    END;
   
   	company_pkg.RemoveContact(in_act_id, in_app_sid, v_old_company_sid, in_user_sid);   
   
END;


PROCEDURE DeleteMultipleSupplierUsers(
	in_act_id				IN security_pkg.T_ACT_ID,	
	in_user_sids			IN security_pkg.T_SID_IDS,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid 			security_pkg.T_SID_ID;
BEGIN

	IF in_user_sids.COUNT = 1 AND in_user_sids(1) IS NULL THEN
		-- do nothing 
		OPEN out_cur for 
			SELECT csr_user_sid, name
			  FROM TEMP_SUPPLIER_USER;
	END IF;
	
	FOR i IN in_user_sids.FIRST .. in_user_sids.LAST
	LOOP
		BEGIN
			v_user_sid := in_user_sids(i);
			DeleteSupplierUser(in_act_id, v_user_sid);

		EXCEPTION
						
			-- TO DO could treat these differently but I don't think that's priority
			WHEN USER_IS_PROVIDER THEN 
				INSERT INTO TEMP_SUPPLIER_USER (csr_user_sid, name)
					SELECT csr_user_sid, full_name FROM csr.csr_user
						WHERE csr_user_sid = v_user_sid;
		 
			WHEN USER_IS_APPROVER THEN  
				INSERT INTO TEMP_SUPPLIER_USER (csr_user_sid, name)
					SELECT csr_user_sid, full_name FROM csr.csr_user
						WHERE csr_user_sid = v_user_sid;
		END;
	END LOOP;

	OPEN out_cur for 
		SELECT DISTINCT name FROM TEMP_SUPPLIER_USER;

END;

-- Trashes the user if not assigned to an (undeleted) product
-- If assigned to a deleted product won't cause a problem as trashed not removed
PROCEDURE DeleteSupplierUser(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_user_sid				IN security_pkg.T_SID_ID
)
AS
	v_product_count			NUMBER;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT COUNT(*) INTO v_product_count FROM product_questionnaire_provider pqp, product p, product_questionnaire pq
		WHERE p.product_id = pq.product_id 
		AND pq.product_id = pqp.product_id
		AND pq.questionnaire_id = pqp.questionnaire_id
		AND provider_sid = in_user_sid;
		
	IF v_product_count > 0 THEN
		RAISE_APPLICATION_ERROR(ERR_USER_IS_PROVIDER, 'The user with sid '|| in_user_sid ||' could not be deleted as they are the data provider for one or more products.');
	END IF;
	
	SELECT COUNT(*) INTO v_product_count FROM product_questionnaire_approver pqa, product p, product_questionnaire pq
		WHERE p.product_id = pq.product_id 
		AND pq.product_id = pqa.product_id
		AND pq.questionnaire_id = pqa.questionnaire_id
		AND approver_sid = in_user_sid;
		
	IF v_product_count > 0 THEN
		RAISE_APPLICATION_ERROR(ERR_USER_IS_APPROVER, 'The user with sid '|| in_user_sid ||' could not be deleted as they are the data approver for one or more products.');
	END IF;
			
	-- breaks link between company and user - deactivates csr user and puts csr user in trash
	DELETE FROM company_user WHERE csr_user_sid = in_user_sid;
	csr.csr_user_pkg.DeleteUser(in_act_id, in_user_sid);
END;

PROCEDURE SearchSupplierUser(
    in_act_id       	IN  security_pkg.T_ACT_ID,
	in_app_sid 	IN  security_pkg.T_SID_ID,	 
	in_group_sid		IN 	security_pkg.T_SID_ID, 
	in_filter_name		IN	csr.csr_user.full_name%TYPE,
	in_company_sid		IN 	security_pkg.T_SID_ID,	
	in_excluded_users	IN 	security_pkg.T_SID_IDS,
	in_work_to_do		IN	NUMBER, 
	in_internal_comp_only IN NUMBER,
	in_order_by 		IN	VARCHAR2, 
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
IS	   

	v_users_sid			security_pkg.T_SID_ID;
	v_order_by			VARCHAR2(1000);
	v_where				VARCHAR2(2000);
	v_work_to_do		VARCHAR2(1000);	
	t_excluded_users	security.T_SID_TABLE;
BEGIN
	t_excluded_users := security_pkg.SidArrayToTable(in_excluded_users);
		   		
	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'user_name,full_name,email,company_sid,company_name,'||
			'last_logon_dtm,last_logon_formatted,active,csr_user_sid');
		v_order_by := ' ORDER BY ' || REPLACE(LOWER(in_order_by), 'full_name', 'LOWER(full_name)') || ' ';
	END IF;

	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	IF in_work_to_do >= 1 THEN
		--v_work_to_do := 'AND cu.csr_user_sid IN (SELECT DISTINCT DECODE(p.product_status_id, 1, pqp.provider_sid, 2, pq.approver_sid, 4, pqp.provider_sid) user_sid '
		--|| ' FROM product p, product_questionnaire pq, product_questionnaire_provider pqp WHERE pq.product_id = pqp.product_id AND pq.questionnaire_id = pqp.questionnaire_id '
		--|| ' AND p.product_id = pq.product_id AND p.app_sid = :in_app_sid AND p.active = 1 AND p.product_status_id IN (1,2,4) AND pq.questionnaire_status_id = 1 '; -- TO DO - using constants here is not a great one
		
		v_work_to_do := 'AND cu.csr_user_sid IN (SELECT DISTINCT (user_sid) FROM ';
		v_work_to_do := v_work_to_do || '( ';
		v_work_to_do := v_work_to_do || 'SELECT DECODE(pqg.group_status_id, 1, pqp.provider_sid, 2, pqa.approver_sid, 4, pqp.provider_sid) user_sid  ';
		v_work_to_do := v_work_to_do || 'FROM product p, product_questionnaire pq, product_questionnaire_provider pqp, product_questionnaire_approver pqa, product_questionnaire_group pqg ';
		v_work_to_do := v_work_to_do || 'WHERE pq.product_id = pqp.product_id AND pq.questionnaire_id = pqp.questionnaire_id  ';
		v_work_to_do := v_work_to_do || 'AND p.product_id = pqg.product_id ';
		v_work_to_do := v_work_to_do || 'AND pq.product_id = pqa.product_id AND pq.questionnaire_id = pqa.questionnaire_id  ';
		v_work_to_do := v_work_to_do || 'AND p.product_id = pq.product_id AND p.app_sid = :in_app_sid AND p.active = 1 AND pqg.group_status_id IN (1,2,4) AND pq.questionnaire_status_id = 1 ';

				
		IF in_work_to_do = 2 THEN
			v_work_to_do := v_work_to_do || ' AND pq.due_date < sysdate ';
		END IF;
		v_work_to_do := v_work_to_do || ' ) ';		
		v_work_to_do := v_work_to_do || ' ) ';
		
		
	ELSE 
		-- redundant but gets round issue of different numbers of bind vars
		v_work_to_do := ' AND app_sid = :in_app_sid ';
	END IF;
	
	-- we always want to include the filters so we can use bind variables
	IF in_filter_name IS NULL THEN
		v_where := ' AND :in_filter_name IS NULL  AND :in_filter_name IS NULL ';
	ELSE
		v_where := ' AND ( lower(full_name) LIKE ''%''||:in_filter_name||''%'' OR lower(user_name) LIKE ''%''||:in_filter_name||''%'' ) ';
	END IF;
	
	IF in_company_sid IS NULL OR in_company_sid=-1 THEN
		v_where := v_where || ' AND NVL(:in_company_sid, -1) = -1 ';
		
		-- if we have a specific company sid requested ignore this interal supplier param
		IF in_internal_comp_only IS NULL OR in_internal_comp_only = 0 THEN
			v_where := v_where || ' AND NVL(:in_internal_comp_only, 0) = 0 ';
		ELSE
			v_where := v_where || ' AND NVL(cmp.internal_supplier, 0) = :in_internal_comp_only ';
		END IF;		

	ELSE
		v_where := v_where || ' AND cmp.company_sid = :in_company_sid ';
		v_where := v_where || ' AND ((1=1) OR (:in_internal_comp_only = 1)) '; -- always true - we always want to include the filters so we can use bind variables
	END IF;

	-- pass in -1 as the excluded users if want to ignore  - as in_excluded_users can't be passed as NULL
	v_where := v_where || ' AND cu.csr_user_sid NOT IN (SELECT column_value FROM TABLE(:t_excluded_users)) ';		
	
	IF in_group_sid IS NULL OR in_group_sid=-1 THEN
		OPEN out_cur FOR
			'SELECT DISTINCT cu.user_name, cu.full_name, cu.email, cmp.company_sid, cmp.company_name, ut.last_logon last_logon_dtm, REPLACE(TO_CHAR(ut.last_logon,''yyyy-mm-dd hh24:mi:ss''),'' '',''T'') last_logon_formatted, ut.account_enabled active, cu.csr_user_sid ' 
			||' FROM csr.csr_user cu, security.securable_object so, security.user_table ut, (SELECT u.csr_user_sid, c.company_sid, c.name company_name, c.internal_supplier FROM company_user u, company c WHERE u.company_sid = c.company_sid) cmp '
			||' WHERE cu.hidden = 0 AND ut.sid_id = cu.csr_user_sid AND so.sid_id = ut.sid_id AND cu.csr_user_sid = so.sid_id AND cu.csr_user_sid = cmp.csr_user_sid(+) AND so.parent_sid_id = :v_parent_sid  '
			||v_work_to_do||v_where||v_order_by USING v_users_sid, in_app_sid, LOWER(in_filter_name), LOWER(in_filter_name), in_company_sid, in_internal_comp_only, t_excluded_users;
	ELSE						
		OPEN out_cur FOR
			'SELECT DISTINCT cu.user_name, cu.full_name, cu.email, cmp.company_sid, cmp.company_name, ut.last_logon last_logon_dtm, REPLACE(TO_CHAR(ut.last_logon,''yyyy-mm-dd hh24:mi:ss''),'' '',''T'') last_logon_formatted, ut.account_enabled active, cu.csr_user_sid' 
			||' FROM csr.csr_user cu, security.securable_object so, (SELECT u.csr_user_sid, c.company_sid, c.name company_name, c.internal_supplier FROM company_user u, company c WHERE u.company_sid = c.company_sid) cmp, '
			||' TABLE(security.Group_Pkg.GetMembersAsTable(:act_id, :group_sid))g, security.user_table ut '
			||' WHERE cu.hidden = 0 AND ut.sid_id = cu.csr_user_sid AND so.sid_id = ut.sid_id AND cu.csr_user_sid = so.sid_id AND cu.csr_user_sid = cmp.csr_user_sid(+) AND so.parent_sid_id = :v_parent_sid AND g.sid_id = cu.csr_user_sid '
			||v_work_to_do||v_where||v_order_by USING in_act_id, in_group_sid, v_users_sid, in_app_sid, LOWER(in_filter_name), LOWER(in_filter_name), in_company_sid, in_internal_comp_only, t_excluded_users;
	END IF;	
END;

PROCEDURE SearchSupplierUserForExport(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid IN  security_pkg.T_SID_ID,	 
	in_group_sid	IN 	security_pkg.T_SID_ID, 
	in_filter_name	IN	csr.csr_user.full_name%TYPE,
	in_work_to_do	IN	NUMBER,
	in_order_by 	IN	VARCHAR2, 
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS	   
	v_null_sid_list	security_pkg.T_SID_IDS;
BEGIN	
	
	-- The SP SearchSupplierUser is assigned as an SPDataSource for the search funcionality on supplierUserList.acds
	-- Calling SearchSupplierUser when doing export seems to cause a problem with the SPDataSource where as calling SearchSupplierUserForExport
	-- doesnt - even though all is does is the below.
	SearchSupplierUser(
	in_act_id,
	in_app_sid,
	in_group_sid,
	in_filter_name,
	NULL, 
	v_null_sid_list,
	in_work_to_do,
	0,
	in_order_by, 
	out_cur);
	
END;

PROCEDURE GetUserCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS

BEGIN
	OPEN out_cur FOR
        SELECT company_sid FROM company_user 
            WHERE csr_user_sid = in_user_sid;
END;

-- Check if the user passed in has approver permission 
-- (all admins are approvers too)
FUNCTION IsUserApproverRetNum(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_app_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER
IS 
BEGIN

	IF IsUserApprover(in_act_id, in_user_sid, in_app_sid) THEN
		RETURN 0;
	ELSE
		RETURN -1;
	END IF;

END;

-- Check if the user passed in has approver permission 
-- (all admins are approvers too)
FUNCTION IsUserApprover(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_app_sid			IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
IS
BEGIN

	RETURN company_pkg.IsCompaniesAccessAllowed(in_act_id, in_user_sid, in_app_sid, security_pkg.PERMISSION_WRITE);

END;

END supplier_user_pkg;
/

