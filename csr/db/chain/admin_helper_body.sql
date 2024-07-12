CREATE OR REPLACE PACKAGE BODY CHAIN.admin_helper_pkg
IS

/* ***************************************
	ALL FUNCTIONS IN THIS PACKAGE SHOULD ENFORCE THE FOLLOWING CHECK - AS THEY EXPOSE THINGS ONLY SUPERADMINS SHOULD BE ALLOWED TO SEE

	IF NOT (security.user_pkg.IsSuperAdmin() = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'XXX can only be run as CSR Super Admin');
	END IF;

**************************************** */

PROCEDURE GetInviteFromGUID (
	in_guid							IN	invitation.guid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT (security.user_pkg.IsSuperAdmin() = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetInviteFromGUID can only be run as CSR Super Admin');
	END IF;

	OPEN out_cur FOR
		SELECT tc.company_sid to_company_sid, tc.name to_company_name, tu.full_name to_full_name, tu.user_name to_user_name, tu.email to_user_email,
				fc.name from_company_name, fc.company_sid from_company_sid, fu.full_name from_full_name, fu.user_name from_user_name, fu.email from_user_email,
				obo.company_sid on_behalf_of_company_sid, obo.name on_behalf_of_company_name, i.guid,
				i.invitation_status_id, ist.description invitation_status, i.sent_dtm, i.expiration_dtm, i.accepted_dtm, i.invitation_type_id, it.description invitation_type,
				i.cancelled_by_user_sid, cu.full_name cancelled_by_full_name, i.cancelled_dtm
		  FROM invitation i, company tc, csr.csr_user tu, company fc, csr.csr_user fu, company obo, invitation_status ist, invitation_type it, csr.csr_user cu
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = tc.app_sid
		   AND i.app_sid = tu.app_sid
		   AND i.app_sid = fc.app_sid(+)
		   AND i.app_sid = fu.app_sid(+)
		   AND i.app_sid = cu.app_sid(+)
		   AND i.app_sid = obo.app_sid(+)
		   AND i.to_company_sid = tc.company_sid
		   AND i.to_user_sid = tu.csr_user_sid
		   AND i.invitation_status_id = ist.invitation_status_id
		   AND i.invitation_type_id = it.invitation_type_id
		   AND i.from_company_sid = fc.company_sid(+)
		   AND i.from_user_sid = fu.csr_user_sid(+)
		   AND i.cancelled_by_user_sid = cu.csr_user_sid(+)
		   AND i.on_behalf_of_company_sid = obo.company_sid(+)
		   AND LOWER(i.guid) = LOWER(in_guid)
	  ORDER BY i.sent_dtm DESC;
END;

PROCEDURE GetCustomerOptions (
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_val							VARCHAR2(4000);
	v_data_type						VARCHAR2(100);
	v_param_tbl						T_CUSTOMER_OPTIONS_PARAM_TABLE;
BEGIN

	IF NOT (security.user_pkg.IsSuperAdmin() = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetCustomerOptions can only be run as CSR Super Admin');
	END IF;

	-- build the list of cols we want to query
	-- this means newly added cols will appear
	FOR r IN (
		SELECT column_id, column_name, data_scale, data_precision, data_type,nullable FROM all_tab_columns WHERE table_name = 'CUSTOMER_OPTIONS' AND owner = 'CHAIN'
	)
	LOOP
		EXECUTE IMMEDIATE 'SELECT NVL(CAST(' || r.column_name || ' AS VARCHAR2(4000)), ''(NULL)'') FROM customer_options WHERE app_sid = :app_sid' INTO v_val USING security_pkg.getApp;

		--determine (simplified) data type
		IF r.data_precision = 1 AND r.data_scale = 0 AND r.data_type = 'NUMBER' THEN
			v_data_type := 'bool';
		ELSIF r.data_type = 'NUMBER' THEN
			v_data_type := 'number';
		ELSIF r.data_type LIKE 'TIMESTAMP%' OR r.data_type = 'DATE' THEN
			v_data_type := 'date';
		ELSE
			v_data_type := 'string';
		END IF;

		INSERT INTO TT_CUSTOMER_OPTIONS_PARAM (id, name, value, data_type, nullable) VALUES(0, r.column_name, v_val, v_data_type, DECODE(r.nullable, 'Y', 1, 'N', 0, 0));
	END LOOP;
	
	SELECT T_CUSTOMER_OPTIONS_PARAM_ROW(id, name, value, data_type, nullable)
	  BULK COLLECT INTO v_param_tbl
	  FROM (SELECT id, name, value, data_type, nullable	FROM TT_CUSTOMER_OPTIONS_PARAM);
	
	OPEN OUT_CUR FOR
		SELECT column_name, description, val, data_type, nullable FROM (
				SELECT cols.name column_name, cols.value val, description, show_in_admin_page, cols.data_type data_type, cols.nullable nullable
				  FROM TABLE(v_param_tbl) cols
			 LEFT JOIN chain.customer_options_columns coc ON UPPER(cols.name) = UPPER(coc.column_name)
			 	 WHERE cols.name != 'APP_SID'
		)
		WHERE NVL(show_in_admin_page, 1) = 1
		ORDER BY column_name;
END;

PROCEDURE SaveCustomerOption(
	in_col_name						IN	VARCHAR2,
	in_val							IN	VARCHAR2,
	in_data_type					IN	VARCHAR2
)
AS
	v_val							VARCHAR2(4000);
BEGIN
	IF NOT (security.user_pkg.IsSuperAdmin() = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SaveCustomerOption can only be run as CSR Super Admin');
	END IF;

	SELECT DECODE(in_val, '(NULL)', null, in_val) INTO v_val FROM dual;

	IF (in_data_type = 'string'  OR in_data_type = 'date') AND in_val IS NOT NULL THEN
		EXECUTE IMMEDIATE 'UPDATE chain.customer_options SET '||in_col_name||'='''||v_val||''' WHERE app_sid = :app_sid' USING security_pkg.getApp;
	ELSE
		EXECUTE IMMEDIATE 'UPDATE chain.customer_options SET '||in_col_name||'='||v_val||' WHERE app_sid = :app_sid' USING security_pkg.getApp;
	END IF;
END;

END admin_helper_pkg;
/
