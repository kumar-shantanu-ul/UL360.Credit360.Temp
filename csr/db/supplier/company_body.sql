CREATE OR REPLACE PACKAGE BODY SUPPLIER.company_pkg
IS

FUNCTION TrySetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN number
AS
	v_company_sid			security_pkg.T_SID_ID default NVL(in_company_sid, 0);
BEGIN
	-- if v_company_sid is 0, try to get the existing company sid out of the context
	IF v_company_sid = 0 THEN
		v_company_sid := NVL(SYS_CONTEXT('SECURITY', 'SUPPLY_CHAIN_COMPANY'), 0);
	END IF;

	-- if we've got a company sid, verify that the user is a member
	IF v_company_sid <> 0 THEN
		-- verify that the user is a member of this company
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM company_user
			 WHERE app_sid = security_pkg.GetApp
			   AND csr_user_sid = security_pkg.GetSid
			   AND company_sid = v_company_sid;
		EXCEPTION
			-- ok, they're not a member of the company -> clear their request
			WHEN NO_DATA_FOUND THEN
				v_company_sid := 0;
		END;
	END IF;

	-- if it's an initial request (0) or the request has been cleared...
	IF v_company_sid = 0 THEN
		-- most users will belong to one company
		-- super users / admins may belong to more than 1
		-- might as well just sort them alphabetically by company name and
		-- 		pick the first, at least it's predictable
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM (
				SELECT c.company_sid
				  FROM company_user cu, all_company c
				 WHERE c.app_sid = security_pkg.GetApp
				   AND c.app_sid = cu.app_sid
				   AND cu.company_sid = c.company_sid
				   AND cu.csr_user_sid = security_pkg.GetSid
				 ORDER BY LOWER(c.name)
					)
			 WHERE rownum = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- set it to null this time - the user doesn't belong to any company
				v_company_sid := NULL;
		END;
	END IF;

	-- set the company sid in the context
	security_pkg.SetContext('SUPPLY_CHAIN_COMPANY', v_company_sid);
	-- return the company sid (or 0 if it's been cleared)
	RETURN NVL(v_company_sid, 0);
END;

-- We'll allow the company_sid to exist in the context. It will need to be set on logon,
-- but I don't think this should be a problem and it saves us from needing to pass it around.
-- It should also makes life a bit easier if we implement a ClimateSmart style
-- "SuperAdmin Choose your company" combo box
PROCEDURE SetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF in_company_sid IS NOT NULL THEN
		BEGIN
			-- verify that the user is a member of this company, if not, throw a fit
			SELECT company_sid
			  INTO v_company_sid
			  FROM company_user
			 WHERE app_sid = security_pkg.GetApp
			   AND csr_user_sid = security_pkg.GetSid
			   AND company_sid = in_company_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- clear the current session value to deter people from messing around
				security_pkg.SetContext('SUPPLY_CHAIN_COMPANY', null);
				-- throw a fit
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could set the company sid to '||in_company_sid);
		END;
	END IF;

	security_pkg.SetContext('SUPPLY_CHAIN_COMPANY', v_company_sid);
END;

FUNCTION GetCompany
RETURN security_pkg.T_SID_ID
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	v_company_sid := SYS_CONTEXT('SECURITY', 'SUPPLY_CHAIN_COMPANY');
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The company sid is not set in the session context');
	END IF;
	RETURN v_company_sid;
END;

FUNCTION GetCompanyName
RETURN security_pkg.T_SO_NAME
AS
	v_company_name 			security_pkg.T_SO_NAME;
BEGIN
	SELECT name
	  INTO v_company_name
	  FROM all_company
	 WHERE company_sid = GetCompany
	   AND app_sid = security_pkg.GetApp;

	RETURN v_company_name;
END;

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_class_id				IN	security_pkg.T_CLASS_ID,
	in_name					IN	security_pkg.T_SO_NAME,
	in_parent_sid_id		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_new_name				IN	security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM company_user
	  WHERE company_sid = in_sid_id;

	DELETE FROM company
	 WHERE company_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE CreateCompany(
	in_act					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	company.name%TYPE,
	in_addr1				IN	company.address_1%TYPE,
	in_addr2				IN	company.address_2%TYPE,
	in_addr3				IN	company.address_3%TYPE,
	in_addr4				IN	company.address_4%TYPE,
	in_town					IN	company.town%TYPE,
	in_state				IN	company.state%TYPE,
	in_postcode				IN	company.postcode%TYPE,
	in_phone				IN	company.phone%TYPE,
	in_phone_alt			IN	company.phone_alt%TYPE,
	in_fax					IN	company.fax%TYPE,
	in_internal_supplier	IN	company.internal_supplier%TYPE,
	in_country_code			IN	company.country_code%TYPE,
	out_company_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_parent_sid			security_pkg.T_SID_ID;
BEGIN
	v_parent_sid := securableobject_pkg.GetSIDFromPath(in_act, in_app_sid, 'Supplier/Companies');
	SecurableObject_Pkg.CreateSO(in_act, v_parent_sid, class_pkg.getClassID('SupplierCompany'), REPLACE(in_name, '/', '\'), out_company_sid);

	INSERT INTO company
		(app_sid, company_sid, name, address_1, address_2, address_3, address_4,
			town, state, postcode, phone, phone_alt, fax, internal_supplier, country_code, active, deleted, company_status_id)
		VALUES (in_app_sid, out_company_sid, in_name, in_addr1, in_addr2, in_addr3, in_addr4,
			in_town, in_state, in_postcode, in_phone, in_phone_alt, in_fax, in_internal_supplier, in_country_code, COMPANY_ACTIVE, COMPANY_NOT_DELETED, COMPANY_DATA_BEING_ENTERED);

	audit_pkg.WriteAuditLogEntry(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_CREATED, in_app_sid, out_company_sid,
		'Company created. Name: {0}',
		in_name, NULL, NULL);
END;

PROCEDURE DeleteMultipleCompanies(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sids			IN	security_pkg.T_SID_IDS,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid 			security_pkg.T_SID_ID;
	v_name					VARCHAR2(256);
BEGIN
	IF in_company_sids.COUNT = 1 AND in_company_sids(1) IS NULL THEN
		-- do nothing
		OPEN out_cur for
			SELECT company_sid, name, deleted
			  FROM TEMP_COMPANY;
	END IF;

	FOR i IN in_company_sids.FIRST .. in_company_sids.LAST
	LOOP
		BEGIN
			v_company_sid := in_company_sids(i);
			DeleteCompany(in_act_id, v_company_sid);
		EXCEPTION
			-- TO DO could treat these differently but I don't think that's priority
			WHEN COMPANY_IS_SUPPLIER THEN
				INSERT INTO temp_company (company_sid, name, deleted)
				SELECT company_sid, name, deleted FROM all_company
				 WHERE company_sid = v_company_sid;

			WHEN COMPANY_IS_APPROVER THEN
				INSERT INTO temp_company (company_sid, name, deleted)
				SELECT company_sid, name, deleted FROM all_company
				 WHERE company_sid = v_company_sid;

			WHEN COMPANY_HAS_USERS THEN
				INSERT INTO temp_company (company_sid, name, deleted)
				SELECT company_sid, name, deleted FROM all_company
				 WHERE company_sid = v_company_sid;
		END;
	END LOOP;

	OPEN out_cur for
		SELECT DISTINCT name FROM TEMP_COMPANY;
END;

-- Set a deleted flag against the company - don't actually remove the company
PROCEDURE DeleteCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID
)
AS
	v_product_count			NUMBER;
	v_user_count			NUMBER;
	v_app_sid 				security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT COUNT(*)
	  INTO v_product_count
	  FROM product_questionnaire_approver pqa, product p, company_user cu
	 WHERE p.product_id = pqa.product_id
	   AND pqa.approver_sid = cu.csr_user_sid
	   AND cu.company_sid = in_company_sid;

	IF v_product_count > 0 THEN
		RAISE_APPLICATION_ERROR(ERR_COMPANY_IS_APPROVER, 'The company with sid '|| in_company_sid ||' could not be deleted as a user from this company is the data approver for one or more questionnaires.');
	END IF;

	SELECT COUNT(*)
	  INTO v_product_count
	  FROM product
	 WHERE supplier_company_sid = in_company_sid;

	IF v_product_count > 0 THEN
		RAISE_APPLICATION_ERROR(ERR_COMPANY_IS_SUPPLIER, 'The company with sid '|| in_company_sid ||' could not be deleted as it is the supplier company for one or more products.');
	END IF;

	SELECT COUNT(*)
	  INTO v_product_count
	  FROM product_questionnaire_provider pqp, product p, company_user cu
	 WHERE p.product_id = pqp.product_id
	   AND pqp.provider_sid = cu.csr_user_sid
	   AND cu.company_sid = in_company_sid;

	IF v_product_count > 0 THEN
		RAISE_APPLICATION_ERROR(ERR_COMPANY_IS_SUPPLIER, 'The company with sid '|| in_company_sid ||' could not be deleted as a user from this company is the data provider for one or more questionnaires.');
	END IF;

	SELECT COUNT(*)
	  INTO v_user_count
	  FROM company_user
	 WHERE company_sid = in_company_sid;

	IF v_user_count > 0 THEN
		RAISE_APPLICATION_ERROR(ERR_COMPANY_HAS_USERS, 'The company with sid '|| in_company_sid ||' could not be deleted as it has one or more users linked to it.');
	END IF;

	SELECT app_sid
	  INTO v_app_sid
	  FROM all_company
	 WHERE company_sid = in_company_sid;

	UPDATE company
	   SET deleted = COMPANY_DELETED
	 WHERE company_sid = in_company_sid;

	-- Don't need to check if company was found / deleted here because that will have failed already on scurity check is sec obj doesn't exist

	-- Set the securable object to have a NULL name to prevent name conflicts
	securableobject_pkg.RenameSO(in_act_id, in_company_sid, NULL);

	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_SUPP_DELETED, v_app_sid, in_company_sid,
		'Company deleted.',
		NULL, NULL, NULL);
END;

PROCEDURE UndeleteCompany(
	in_act					IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID
)
AS
	v_name					all_company.name%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT name
 	  INTO v_name
	  FROM all_company
	 WHERE company_sid = in_company_sid;

	UPDATE all_company
	   SET deleted = 0
	 WHERE company_sid = in_company_sid;

	-- Restore the security name
	securableobject_pkg.RenameSO(in_act, in_company_sid, REPLACE(v_name, '/', '\'));
END;

PROCEDURE UpdateCompany (
	in_act					IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_name					IN	company.name%TYPE,
	in_addr1				IN	company.address_1%TYPE,
	in_addr2				IN	company.address_2%TYPE,
	in_addr3				IN	company.address_3%TYPE,
	in_addr4				IN	company.address_4%TYPE,
	in_town					IN	company.town%TYPE,
	in_state				IN	company.state%TYPE,
	in_postcode				IN	company.postcode%TYPE,
	in_phone				IN	company.phone%TYPE,
	in_phone_alt			IN	company.phone_alt%TYPE,
	in_fax					IN	company.fax%TYPE,
	in_internal_supplier	IN	company.internal_supplier%TYPE,
	in_active				IN	company.active%TYPE,
	in_country_code			IN	company.country_code%TYPE
)
AS
	CURSOR c IS
        SELECT app_sid, name, address_1, address_2, address_3, address_4, town, state,
        postcode, phone, phone_alt, fax, c.country,
            CASE active WHEN 1 THEN 'Active' ELSE 'Inactive' END active,
            CASE internal_supplier WHEN 1 THEN 'Internal' ELSE 'External' END internal_supplier
           FROM all_company ac, country c
          WHERE ac.country_code = c.country_code
            AND company_sid = in_company_sid;
	r c%ROWTYPE;
	v_new_val			VARCHAR2(1024);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- read some bits about the old company
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		CLOSE c;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The company with sid '||in_company_sid||' was not found');
	END IF;
	CLOSE c;

	UPDATE company
	   SET company_sid = company_sid,
	       name = in_name,
	       address_1 = in_addr1,
	       address_2 = in_addr2,
	       address_3 = in_addr3,
	       address_4 = in_addr4,
	       town = in_town,
	       state = in_state,
	       postcode = in_postcode,
	       phone = in_phone,
	       phone_alt = in_phone_alt,
	       fax = in_fax,
	       internal_supplier = in_internal_supplier,
	       country_code = in_country_code,
	       active = in_active
	 WHERE company_sid = in_company_sid;

	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The company with sid '|| in_company_sid ||'  was not found');
	END IF;

	-- update the name in security here
	securableobject_pkg.RenameSO(in_act, in_company_sid, REPLACE(in_name, '/', '\'));

	-- Audit changes
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Company name', r.name, in_name);
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Address line 1', r.address_1, in_addr1);
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Address lLine 2', r.address_2, in_addr2);
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Address line 3', r.address_3, in_addr3);
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Address line 4', r.address_4, in_addr4);
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Town', r.town, in_town);
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'State', r.state, in_state);
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Postcode', r.postcode, in_postcode);
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Phone num.', r.phone, in_phone);
	-- don't use fax and phone alt atm
	SELECT CASE in_active WHEN 1 THEN 'Active' ELSE 'Inactive' END active
    	INTO v_new_val FROM DUAL;
 	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Company active', r.active, v_new_val);
	SELECT CASE in_internal_supplier WHEN 1 THEN 'Internal' ELSE 'External' END internal_supplier
        INTO v_new_val FROM DUAL;
 	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Company internal', r.internal_supplier, v_new_val);
	SELECT country INTO v_new_val FROM country WHERE country_code = in_country_code;
 	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_SUPP_UPDATED, r.app_sid, in_company_sid,
		'Country', r.country, v_new_val);
END;

PROCEDURE GetCompany (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT company_sid, name, active, address_1, address_2, address_3, address_4,
			town, state, postcode, c.country_code, cty.country country_name, phone, internal_supplier
		  FROM company c, country cty
		 WHERE c.country_code = cty.country_code
		   AND company_sid = in_company_sid;
END;

PROCEDURE SearchCompanyCount(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	company.name%TYPE,
	in_country_code			IN	company.country_code%TYPE,
	in_active				IN	company.active%TYPE,
	out_count				OUT	NUMBER
)
IS
	v_name					VARCHAR2(1024) DEFAULT '%' || LOWER(in_name) || '%';
	v_companies_sid 		security_pkg.T_SID_ID;
BEGIN
	-- check read permission on companies folder in security
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT COUNT(*)
	  INTO out_count
	  FROM company c
	 WHERE c.app_sid = in_app_sid
	   AND (in_name IS NULL OR LOWER (c.name) LIKE v_name)
	   AND c.country_code = NVL(in_country_code, c.country_code)
	   AND c.active = NVL(in_active, c.active);
END;

PROCEDURE SearchCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	company.name%TYPE,
	in_country_code			IN	company.country_code%TYPE,
	in_active				IN	company.active%TYPE,
	in_order_by				IN	VARCHAR2,
	in_order_direction		IN	VARCHAR2,
	in_start				IN	NUMBER,
	in_page_size			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_name					VARCHAR2(1024) DEFAULT '%' || LOWER(in_name) || '%';
	v_companies_sid 		security_pkg.T_SID_ID;
	v_SQL					VARCHAR2(2048);
BEGIN
	-- check read permission on companies folder in security
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF LOWER(in_order_by) NOT IN ('company_sid', 'name', 'active', 'address_1',
		'address_2', 'address_3', 'address_4', 'town', 'state', 'postcode', 'country_code',
		'phone', 'internal_supplier', 'company_status_id', 'description', 'status_description') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_by not in the allowed list');
	END IF;
	IF LOWER(in_order_direction) NOT IN ('asc', 'desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_direction not asc or desc');
	END IF;

    v_SQL := v_SQL || 		'  SELECT * FROM ';
    v_SQL := v_SQL || 		' ( ';
    v_SQL := v_SQL || 		'     SELECT ROWNUM rn, company_sid, name, active, address_1, address_2, address_3, address_4, town, state, postcode, country_code, phone, internal_supplier, company_status_id, status_description FROM   ';
    v_SQL := v_SQL || 		'     (   ';
    v_SQL := v_SQL || 		'        SELECT company_sid, name, active, address_1, address_2, address_3, address_4, town, state, postcode, country_code, phone, internal_supplier, company_status_id, status_description FROM   ';
    v_SQL := v_SQL || 		'        (   ';
    v_SQL := v_SQL || 		'          SELECT company_sid, name, active, address_1, address_2, address_3, address_4, town, state, postcode, country_code, phone, internal_supplier, c.company_status_id, cs.description status_description  ';
    v_SQL := v_SQL || 		'                    FROM company c, company_status cs   ';
    v_SQL := v_SQL || 		'                   WHERE c.app_sid = :1 ';
    v_SQL := v_SQL || 		'                     AND (:2 IS NULL OR LOWER (c.NAME) LIKE :3 )   ';
    v_SQL := v_SQL || 		'                     AND c.country_code = NVL(:4, c.country_code)   ';
    v_SQL := v_SQL || 		'                     AND c.active = NVL(:5, c.active)   ';
    v_SQL := v_SQL || 		'                     AND cs.company_status_id = c.company_status_id   ';
    v_SQL := v_SQL || 		'        )   ';
    v_SQL := v_SQL || 		'        ORDER BY LOWER(' || in_order_by || ') ' || in_order_direction;
    v_SQL := v_SQL || 		'     )   ';
    v_SQL := v_SQL || 		'     WHERE rownum <= NVL(:6, rownum) ';
    v_SQL := v_SQL || 		' ) WHERE rn > NVL(:7, 0) ';

	OPEN out_cur FOR v_SQL
		USING in_app_sid, in_name, v_name, in_country_code, in_active, in_start + in_page_size, in_start;
END;

-- used for company edit screen
PROCEDURE SearchCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_search				IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_search				VARCHAR2(1024) DEFAULT '%' || LOWER(in_search) || '%';
	v_companies_sid 		security_pkg.T_SID_ID;
BEGIN
	-- check read permission on companies folder in security
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

    OPEN out_cur FOR
		SELECT c.company_sid, c.name, active, c.address_1, c.address_2, c.address_3, c.address_4,
		       c.town, c.state, c.postcode, c.country_code, c.phone, c.internal_supplier,
		       co.country, ps.estimated_annual_spend, ps.currency_code, ps.currency_label
		  FROM company c, country co, (
			SELECT aps.*, c.label currency_label
			  FROM all_procurer_supplier aps, currency c
			 WHERE aps.procurer_company_sid = SYS_CONTEXT('SECURITY', 'SUPPLY_CHAIN_COMPANY')
			   AND c.currency_code = aps.currency_code
		  ) ps
		 WHERE c.app_sid = in_app_sid
		   AND c.country_code = co.country_code
		   AND ps.supplier_company_sid(+) = c.company_sid
		   AND (
				in_search IS NULL
				OR LOWER (c.name) LIKE v_search
				OR LOWER (c.address_1) LIKE v_search
				OR LOWER (c.address_2) LIKE v_search
				OR LOWER (c.address_3) LIKE v_search
				OR LOWER (c.address_4) LIKE v_search
				OR LOWER (c.town) LIKE v_search
				OR LOWER (c.state) LIKE v_search
				OR LOWER (c.postcode) LIKE v_search
			)
		 ORDER BY LOWER(name);
END;

PROCEDURE AddContact(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_contact_sid			IN	security_pkg.T_SID_ID
)
AS
	v_access_perms security_pkg.T_PERMISSION;
	v_name					VARCHAR2(1024);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INSERT INTO company_user
		(company_sid, csr_user_sid)
	VALUES (in_company_sid, in_contact_sid);

	-- add user to the DACL of the Company's SO - so that this user has read and write permissions
	v_access_perms := security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_DELETE +
		security_pkg.PERMISSION_ADD_CONTENTS + security_pkg.PERMISSION_WRITE;

	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(in_company_sid), security_pkg.ACL_INDEX_LAST,
		security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, in_contact_sid, v_access_perms);

	SELECT user_name INTO v_name FROM csr.csr_user WHERE csr_user_sid = in_contact_sid;
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_SUPP_USER_ASS, in_app_sid, in_company_sid,
		'Added contact {0}', v_name, NULL, NULL);

	SELECT name INTO v_name FROM all_company WHERE company_sid = in_company_sid;
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_SUPP_USER_ASS, in_app_sid, in_contact_sid,
		'Linked to company {0}', v_name, NULL, NULL);
END;

PROCEDURE SearchForUnassignedUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	csr.csr_user.full_name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_users_sid				security_pkg.T_SID_ID;
	v_name					VARCHAR2(1024) DEFAULT '%' || LOWER(in_name) || '%';
BEGIN
	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Users');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.user_name, cu.full_name, cu.email
		  FROM csr.csr_user cu, security.securable_object so, security.user_table ut
		 WHERE ut.sid_id = cu.csr_user_sid
		   AND so.sid_id = ut.sid_id
		   AND cu.csr_user_sid = so.sid_id
		   AND app_sid = in_app_sid
		   AND so.parent_sid_id = v_users_sid
		   AND ut.account_enabled = 1
		   and cu.hidden = 0
		   AND (in_name IS NULL OR LOWER (cu.user_name) LIKE v_name OR LOWER (cu.full_name) LIKE v_name)
		   AND cu.csr_user_sid NOT IN (SELECT csr_user_sid FROM company_user)
		 ORDER BY LOWER(full_name);
END;

PROCEDURE RemoveContact(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_contact_sid			IN	security_pkg.T_SID_ID
)
AS
	v_name					VARCHAR2(1024);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	DELETE FROM company_user
	 WHERE company_sid = in_company_sid
	   AND csr_user_sid = in_contact_sid;

	acl_pkg.RemoveACEsForSid(in_act_id, acl_pkg.GetDACLIDForSID(in_company_sid), in_contact_sid);

	SELECT user_name INTO v_name FROM csr.csr_user WHERE csr_user_sid = in_contact_sid;
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_SUPP_USER_UNASS, in_app_sid, in_company_sid,
		'Removed contact {0}', v_name, NULL, NULL);

	SELECT name INTO v_name FROM all_company WHERE company_sid = in_company_sid;
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_SUPP_USER_UNASS, in_app_sid, in_contact_sid,
		'Unlinked from company {0}', v_name, NULL, NULL);
END;

PROCEDURE GetContacts(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT cu.csr_user_sid, u.user_name, u.full_name, u.email
		  FROM company_user cu, csr.csr_user u
		 WHERE cu.company_sid = in_company_sid
		   AND cu.csr_user_Sid = u.csr_user_sid
		 ORDER BY LOWER(u.full_name);
END;

FUNCTION MakeFullAddress(
	in_address_1			IN	VARCHAR2,
	in_address_2			IN	VARCHAR2,
	in_address_3			IN	VARCHAR2,
	in_address_4			IN	VARCHAR2,
	in_town					IN	VARCHAR2,
	in_state				IN	VARCHAR2,
	in_postcode				IN	VARCHAR2
) RETURN VARCHAR2
IS
	v_full_address			VARCHAR2(2048);
BEGIN
	v_full_address := in_address_1 || ',' || in_address_2 || ',' || in_address_3 || ',' || in_address_4 || in_town || ',' || in_state || ',' || in_postcode;

	RETURN v_full_address;
END;

FUNCTION IsCompanyAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN 	company.company_sid%TYPE,
	in_perms				IN 	security_pkg.T_PERMISSION
) RETURN BOOLEAN
IS
BEGIN
	-- Return the check result form security
	RETURN security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, in_perms);
END;

FUNCTION IsCompanyAccessAllowed(
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN 	company.company_sid%TYPE,
	in_perms				IN 	security_pkg.T_PERMISSION
) RETURN BOOLEAN
IS
	v_access_allowed 		BOOLEAN;
	v_act					security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(in_user_sid, 500, v_act);

	-- Return the check result form security
	v_access_allowed := security_pkg.IsAccessAllowedSID(v_act, in_company_sid, in_perms);

	user_pkg.Logoff(v_act);

	RETURN v_access_allowed;
END;

FUNCTION IsCompaniesAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_user_to_check_sid	IN	security_pkg.T_SID_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_perms				IN 	security_pkg.T_PERMISSION
) RETURN BOOLEAN
IS
	v_companies_sid			security_pkg.T_SID_ID;
	v_act 					security_Pkg.T_ACT_ID;
	v_access_allowed 		BOOLEAN;
BEGIN
	user_pkg.LogonAuthenticated(in_user_to_check_sid, 500, v_act);

	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	-- Return the check result form security
	v_access_allowed := security_pkg.IsAccessAllowedSID(v_act, v_companies_sid, in_perms);

	user_pkg.Logoff(v_act);

	RETURN v_access_allowed;
END;

FUNCTION IsCompanyWriteAccessAllowed(
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	company.company_sid%TYPE
) RETURN NUMBER
IS
BEGIN
	IF IsCompanyAccessAllowed(in_user_sid, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RETURN 0;
	ELSE
		RETURN -1;
	END IF;
END;

FUNCTION GetNameFromSid(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
IS
	v_name				company.name%TYPE;
BEGIN
	SELECT name INTO v_name FROM all_company -- may want to get for deleted companies
		WHERE company_sid = in_company_sid;

	RETURN v_name;
END;

PROCEDURE GetAllowedCompForProduct (
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_product_id			IN	product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT company_sid, name
			  FROM company
			 WHERE app_sid = in_app_sid
			   AND active = 1
			 UNION
			SELECT c.company_sid, c.name
			  FROM product p, company c
			 WHERE p.supplier_company_sid = c.company_sid
			   AND p.product_id = in_product_id
			 UNION
			SELECT c.company_sid, c.name
			  FROM company c, product_questionnaire_approver pqa, company_user cu
			 WHERE c.company_sid = cu.company_sid
			   AND cu.csr_user_sid = pqa.approver_sid
			   AND pqa.product_id = in_product_id
			 UNION
			SELECT c.company_sid, c.name
			  FROM company c, product_questionnaire_provider pqp, company_user cu
			 WHERE c.company_sid = cu.company_sid
			   AND cu.csr_user_sid = pqp.provider_sid
			   AND pqp.product_id = in_product_id
		)
		ORDER BY LOWER(name) ASC;
END;

PROCEDURE GetAllowedIntCompForProduct (
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_product_id			IN	product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT company_sid, name
			  FROM company
			 WHERE app_sid = in_app_sid
			   AND active = 1
			   AND internal_supplier = 1 -- only difference from the query above
			 UNION
			SELECT c.company_sid, c.name
			  FROM product p, company c
			 WHERE p.supplier_company_sid = c.company_sid
			   AND p.product_id = in_product_id
			 UNION
			SELECT c.company_sid, c.name
			  FROM company c, product_questionnaire_approver pqa, company_user cu
			 WHERE c.company_sid = cu.company_sid
			   AND cu.csr_user_sid = pqa.approver_sid
			   AND pqa.product_id = in_product_id
			 UNION
			SELECT c.company_sid, c.name
			  FROM company c, product_questionnaire_provider pqp, company_user cu
			 WHERE c.company_sid = cu.company_sid
			   AND cu.csr_user_sid = pqp.provider_sid
			   AND pqp.product_id = in_product_id
		)
		ORDER BY LOWER(name) ASC;
END;

PROCEDURE GetMyCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	-- Get current user sid
	user_pkg.GetSID(in_act_id, v_user_sid);

	OPEN out_cur FOR
		SELECT c.company_sid, c.name, c.address_1, c.address_2, c.address_3, c.address_4,
			c.town, c.state, c.country_code, c.phone, c.phone_alt, c.fax, c.internal_supplier,
			c.active, c.company_status_id, cs.description status_description, cnt.country country_name
		  FROM company c, company_user cu, company_status cs, country cnt
		 WHERE cu.company_sid = c.company_sid
		   AND c.company_status_id = cs.company_status_id
		   AND cnt.country_code = c.country_code
		   AND cu.csr_user_sid = v_user_sid;
END;

-------------------------------------------------

PROCEDURE GetCompanyTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_name		IN	tag_group.name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF in_tag_group_name IS NULL THEN
		OPEN out_cur FOR
			SELECT tag_id, note, num
			  FROM company_tag
			 WHERE company_sid = in_company_sid;
	ELSE
		OPEN out_cur FOR
			SELECT ct.tag_id, ct.note, ct.num
			  FROM company_tag ct, tag_group_member tgm, tag_group tg
			 WHERE tg.name = in_tag_group_name
			   AND tgm.tag_group_sid = tg.tag_group_sid
			   AND ct.tag_id = tgm.tag_id
			   AND ct.company_sid = in_company_sid
			 ORDER BY tgm.pos ASC;
	END IF;
END;

PROCEDURE SetCompanyTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_name		IN	tag_group.name%TYPE,
	in_tag_ids				IN	tag_pkg.T_TAG_IDS,
	in_tag_numbers			IN	T_TAG_NUMBERS,
	in_tag_notes			IN	T_TAG_NOTES
)
AS
	v_tag_group_sid			security_pkg.T_SID_ID;
	v_tag_group_description	tag_group.description%TYPE;
	v_old_tag_ids			tag_pkg.T_TAG_IDS;
	v_index					NUMBER;
	v_number				company_tag.num%TYPE;
	v_note					company_tag.note%TYPE;
BEGIN
	-- Check for NULL array
	IF in_tag_ids IS NULL OR (in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_tag_group_sid := NULL;
	IF in_tag_group_name IS NOT NULL THEN
		SELECT tag_group_sid, description
		  INTO v_tag_group_sid, v_tag_group_description
		  FROM tag_group
		 WHERE name = in_tag_group_name
		   AND app_sid = in_app_sid;
	END IF;

	-- Delete old tag groups
	v_index := 1;
	IF v_tag_group_sid IS NOT NULL THEN
		-- need to do audit logging here as deleteing old tags before inserting new tags
		FOR r IN (
			SELECT tag_id FROM company_tag
			 WHERE company_sid = in_company_sid
			   AND tag_id IN (
				SELECT tag_id
				  FROM tag_group_member
				 WHERE tag_group_sid = v_tag_group_sid
				)
		)
		LOOP
			v_old_tag_ids(v_index) := r.tag_id;
			v_index := v_index + 1;
		END LOOP;

		audit_pkg.AuditTagChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_SUPP_TAG_CHANGED, in_app_sid, in_company_sid, v_tag_group_description,
			v_old_tag_ids, in_tag_ids, 1, in_company_sid);

		DELETE FROM company_tag
		 WHERE company_sid = in_company_sid
		   AND tag_id IN (
			SELECT tag_id
			  FROM tag_group_member
			 WHERE tag_group_sid = v_tag_group_sid
			);
	ELSE
		-- need to do audit logging here as deleteing old tags before inserting new tags
		FOR r IN (
			SELECT tag_id FROM company_tag WHERE company_sid = in_company_sid
		)
		LOOP
			v_old_tag_ids(v_index) := r.tag_id;
			v_index := v_index + 1;
		END LOOP;

		audit_pkg.AuditTagChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_SUPP_TAG_CHANGED, in_app_sid, in_app_sid, v_tag_group_description,
			v_old_tag_ids, in_tag_ids, 1, in_company_sid);

		DELETE FROM company_tag
		 WHERE company_sid = in_company_sid;
	END IF;

	-- Insert the tag ids
	FOR t IN in_tag_ids.FIRST..in_tag_ids.LAST LOOP
		-- Can't get the following to work, so horrid check for existance before-hand
		--CASE WHEN in_tag_numbers.EXISTS(t) THEN in_tag_numbers(t) ELSE NULL END,
	    --CASE WHEN in_tag_notes.EXISTS(t) THEN in_tag_notes(t) ELSE NULL END

	    v_number := NULL;
	    IF in_tag_numbers.EXISTS(t) THEN
	    	v_number := in_tag_numbers(t);
	    END IF;

	    v_note := NULL;
	    IF in_tag_notes.EXISTS(t) THEN
	    	v_note := in_tag_notes(t);
	    END IF;

	    INSERT INTO company_tag
	        (company_sid, tag_id, num, note)
	    VALUES
	        (in_company_sid, in_tag_ids(t), v_number, v_note);
	END LOOP;
END;

PROCEDURE SetCompanyTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_name		IN	tag_group.name%TYPE,
	in_tag_ids				IN	tag_pkg.T_TAG_IDS
)
AS
	v_numbers		T_TAG_NUMBERS;
	v_notes			T_TAG_NOTES;
BEGIN
	SetCompanyTags(in_act_id, in_app_sid, in_company_sid,
		in_tag_group_name, in_tag_ids, v_numbers, v_notes);
END;

PROCEDURE GetCountries(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT country, country_code
		  FROM country
		 ORDER BY country;
END;

PROCEDURE GetCompanies(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT company_sid, name
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY lower(name) ASC;
END;

END company_pkg;
/
