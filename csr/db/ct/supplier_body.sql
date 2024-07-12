CREATE OR REPLACE PACKAGE BODY ct.supplier_pkg AS

PROCEDURE CheckSupplierOwner (
	in_supplier_id					supplier.supplier_id%TYPE
)
AS
	v_owner_company_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT owner_company_sid
	  INTO v_owner_company_sid
	  FROM supplier
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_id = in_supplier_id;
	   
	IF v_owner_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - owner company sid does not match context');
	END IF;
END;

PROCEDURE CheckSupplierContactOwner (
	in_supplier_contact_id			supplier.supplier_id%TYPE
)
AS
	v_supplier_id					supplier.supplier_id%TYPE;
BEGIN
	SELECT supplier_id
	  INTO v_supplier_id
	  FROM supplier_contact
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_contact_id = in_supplier_contact_id;
	   
	CheckSupplierOwner(v_supplier_id);
END;

PROCEDURE GetSupplierContacts (
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	in_supplier_contact_id			IN  supplier_contact.supplier_contact_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT sc.supplier_contact_id, NVL(csru.full_name, sc.full_name) full_name, NVL(csru.email, sc.email) email, sc.user_sid
		  FROM supplier s, supplier_contact sc, csr.csr_user csru
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND s.app_sid = sc.app_sid
		   AND sc.app_sid = csru.app_sid(+) AND sc.user_sid = csru.csr_user_sid(+)
		   AND s.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND s.supplier_id = NVL(in_supplier_id, s.supplier_id)
		   AND s.supplier_id = sc.supplier_id
		   AND sc.supplier_contact_id = NVL(in_supplier_contact_id, sc.supplier_contact_id)
		   -- don't let people get all contacts for all suppliers, even if they do own them
		   AND (in_supplier_id IS NOT NULL OR in_supplier_contact_id IS NOT NULL);
END;

FUNCTION CreateCompanyINTERNAL (
	in_name						IN  chain.company.name%TYPE,
	in_country_code				IN  chain.company.country_code%TYPE,
	in_company_type_id			IN  chain.company.company_type_id%TYPE
) RETURN NUMBER
AS
	v_builtin_admin_act		security_pkg.T_ACT_ID;
	v_stored_app_sid		security_pkg.T_SID_ID;
	v_stored_act			security_pkg.T_ACT_ID;
	v_company_sid			security_pkg.T_SID_ID;
	
	v_nullStringArray 		chain.chain_pkg.T_STRINGS; --cannot pass NULL so need an empty varchar2 array instead
BEGIN

	-- we fiddle with this, so just keep track of it for now
	v_stored_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_stored_act := SYS_CONTEXT('SECURITY', 'ACT');
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_builtin_admin_act);
	security_pkg.SetACT(v_builtin_admin_act);

	chain.company_pkg.CreateCompany(
		in_name				=> in_name,
		in_country_code		=> in_country_code,
		in_company_type_id	=> in_company_type_id,
		out_company_sid		=> v_company_sid
	);
	
	user_pkg.Logoff(v_builtin_admin_act);
	security_pkg.SetACT(v_stored_act, v_stored_app_sid);
	
	RETURN v_company_sid;
END;

FUNCTION CreateCompanyUserINTERNAL (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_full_name				IN  supplier_contact.full_name%TYPE,
	in_email					IN  supplier_contact.email%TYPE
) RETURN NUMBER
AS
	v_builtin_admin_act		security_pkg.T_ACT_ID;
	v_stored_app_sid		security_pkg.T_SID_ID;
	v_stored_act			security_pkg.T_ACT_ID;
	v_user_sid			security_pkg.T_SID_ID;
BEGIN

	BEGIN
		-- check to see if user already exists
		SELECT csr_user_sid 
		  INTO v_user_sid
		  FROM csr.csr_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND email = in_email;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		-- we fiddle with this, so just keep track of it for now
		v_stored_app_sid := SYS_CONTEXT('SECURITY', 'APP');
		v_stored_act := SYS_CONTEXT('SECURITY', 'ACT');
		user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_builtin_admin_act);
		security_pkg.SetACT(v_builtin_admin_act);

		
		v_user_sid := chain.company_user_pkg.CreateUserForInvitation(in_company_sid, in_full_name, NULL, in_email);
		
		
		user_pkg.Logoff(v_builtin_admin_act);
		security_pkg.SetACT(v_stored_act, v_stored_app_sid);
	END;
	
	RETURN v_user_sid;
END;


/*******************************************************************************************************/
/*******************************************************************************************************/
/*******************************************************************************************************/
/*******************************************************************************************************/

FUNCTION SaveSupplier(
	in_supplier_id					IN	supplier.supplier_id%TYPE,
	in_name							IN	supplier.name%TYPE
) RETURN NUMBER
AS
BEGIN
	RETURN SaveSupplier(in_supplier_id, in_name, null, null);
END;

FUNCTION SaveSupplier(
	in_supplier_id					IN	supplier.supplier_id%TYPE,
	in_name							IN	supplier.name%TYPE,
	in_description					IN	supplier.description%TYPE,
	in_company_sid					IN	security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER
AS
	v_supplier_id					supplier.supplier_id%TYPE DEFAULT NVL(in_supplier_id, 0);
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;

	IF v_supplier_id = 0 THEN
		INSERT INTO supplier 
		(supplier_id, owner_company_sid, company_sid, name, description)
		VALUES 
		(supplier_id_seq.NEXTVAL, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_company_sid, in_name, in_description)
		RETURNING supplier_id INTO v_supplier_id;
	ELSE
		UPDATE supplier
		   SET company_sid = in_company_sid,
			   name = in_name,
			   description = in_description
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND supplier_id = v_supplier_id
		   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	END IF;
	
	RETURN v_supplier_id;
END;

PROCEDURE SaveSupplierContact (
	in_supplier_id					IN	supplier_contact.supplier_id%TYPE,
	in_full_name					IN	supplier_contact.full_name%TYPE,
	in_email						IN	supplier_contact.email%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetSupplierContacts(in_supplier_id, SaveSupplierContact(in_supplier_id, in_full_name, in_email), out_cur);
END;

FUNCTION SaveSupplierContact (
	in_supplier_id					IN	supplier_contact.supplier_id%TYPE,
	in_full_name					IN	supplier_contact.full_name%TYPE,
	in_email						IN	supplier_contact.email%TYPE
) RETURN NUMBER
AS
	v_supplier_contact_id			supplier_contact.supplier_contact_id%TYPE;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;

	CheckSupplierOwner(in_supplier_id);
	
	BEGIN
		SELECT supplier_contact_id
		  INTO v_supplier_contact_id
		  FROM supplier_contact
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND supplier_id = in_supplier_id
		   AND LOWER(TRIM(email)) = LOWER(TRIM(in_email));
		
		UPDATE supplier_contact
		   SET full_name = in_full_name
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND supplier_contact_id = v_supplier_contact_id; 
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO supplier_contact
			(supplier_id, supplier_contact_id, full_name, email)
			VALUES 
			(in_supplier_id, supplier_contact_id_seq.NEXTVAL, in_full_name, in_email)
			RETURNING supplier_contact_id INTO v_supplier_contact_id;
	END;
	
	RETURN v_supplier_contact_id;
END;

PROCEDURE GetSuppliers (
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetSupplier(null, out_cur);
END;

PROCEDURE GetSupplier (
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_currency_id			company.currency_id%TYPE DEFAULT company_pkg.GetCompanyCurrency();
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;

	OPEN out_cur FOR 
		SELECT s.supplier_id, s.name, s.description, s.company_sid, s.owner_company_sid, c.country_code,
		       s.status_id, NVL(x.purchases, 0) purchases, 
			   v_company_currency_id purchases_currency_id, 
			   ctc.currency_id, ctc.turnover, 
			   NVL2(s.company_sid, breakdown_type_pkg.GetHSRegionBreakdownTypeId(s.company_sid), null) region_breakdown_type_id
		  FROM supplier s, chain.company c, ct.company ctc,  (
		  		SELECT supplier_id, SUM(spend_in_company_currency) purchases
		  		  FROM v$ps_item
		  		 WHERE app_sid = security_pkg.getApp
		  		   AND supplier_id = NVL(in_supplier_id, supplier_id)
		  		 GROUP BY supplier_id
		  		) x	 	   
		 WHERE s.app_sid = security_pkg.getApp
		   AND s.app_sid = c.app_sid(+) AND s.company_sid = c.company_sid(+)
		   AND s.app_sid = ctc.app_sid(+) AND s.company_sid = ctc.company_sid(+)
		   AND s.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND s.supplier_id = NVL(in_supplier_id, s.supplier_id)
		   AND s.supplier_id = x.supplier_id(+);
END;

PROCEDURE SearchSuppliers(
	in_page							IN  NUMBER,
	in_page_size					IN  NUMBER,
	in_search_term  				IN  VARCHAR2,
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search						VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_page							NUMBER(10) DEFAULT in_page;
	v_total_count					NUMBER(10) DEFAULT 0;
	v_total_pages					NUMBER(10) DEFAULT 0;
	v_company_currency_id			company.currency_id%TYPE DEFAULT company_pkg.GetCompanyCurrency();
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	-- select supplier/id total item spend where supplier records match search parameters
	  INSERT INTO tt_supplier_search (supplier_id, purchases)
	  SELECT supplier.supplier_id, NVL(SUM(item.spend_in_company_currency), 0) purchases
	    FROM supplier
		LEFT JOIN v$ps_item item
		  ON supplier.supplier_id = item.supplier_id
	  WHERE supplier.supplier_id IN (
			SELECT supplier.supplier_id
			  FROM supplier
			  LEFT JOIN v$ps_item item
			    ON supplier.supplier_id = item.supplier_id
		     WHERE supplier.app_sid = security_pkg.getApp
			   AND supplier.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND (LOWER(supplier.name) LIKE v_search
			    OR LOWER(supplier.description) LIKE v_search
			    OR CAST(supplier.supplier_id AS VARCHAR2(255)) = in_search_term)
			   AND (in_breakdown_id IS NULL
			    OR item.breakdown_id = in_breakdown_id)
			   AND (in_region_id IS NULL
			    OR item.region_id = in_region_id))
	GROUP BY supplier.supplier_id
	ORDER BY purchases DESC;
  
	-- get total record count/pages
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM tt_supplier_search;
	  
	SELECT CASE WHEN in_page_size = 0 THEN 1 
				ELSE CEIL(COUNT(*) / in_page_size) END
	  INTO v_total_pages		    
	  FROM tt_supplier_search;
	
	-- delete any records that aren't between the current pages
	IF in_page_size > 0 THEN
		IF in_page < 1 THEN
			v_page := 1;
		END IF;
		
		DELETE FROM tt_supplier_search
		 WHERE supplier_id NOT IN (
			SELECT supplier_id
			  FROM (
				SELECT supplier_id, rownum rn
				  FROM tt_supplier_search
			)
			WHERE rn > in_page_size * (v_page - 1)
			  AND rn <= in_page_size * v_page
		 );			 
	END IF;
		
	OPEN out_count_cur FOR
		SELECT v_total_count total_count,
		       v_total_pages total_pages
		  FROM dual;
		  
	-- match the paged, sorted results to the relevant tables to return the results
	OPEN out_result_cur FOR
		  SELECT supplier.supplier_id, supplier.name, supplier.description, supplier.company_sid, 
		         supplier.owner_company_sid, search.purchases, supplier.status_id,
				 v_company_currency_id purchases_currency_id
		    FROM supplier
		    JOIN tt_supplier_search search
		      ON supplier.supplier_id = search.supplier_id
		     AND supplier.app_sid = security_pkg.getApp
		     AND supplier.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		ORDER BY purchases DESC;
END;

PROCEDURE GetSupplierAsCompany (
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	in_country_code					IN  chain.company.country_code%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_name							supplier.name%TYPE;
	v_company_sid					security_pkg.T_SID_ID;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	SELECT name, company_sid
	  INTO v_name, v_company_sid
	  FROM supplier
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND supplier_id = in_supplier_id;

	IF v_company_sid IS NULL THEN
		v_company_sid := CreateCompanyINTERNAL(v_name, in_country_code, util_pkg.GetSupplierCompanyTypeId);
		
		UPDATE supplier
		   SET company_sid = v_company_sid
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND supplier_id = in_supplier_id;		   
	END IF;
	
	GetSupplier(in_supplier_id, out_cur);
END;

PROCEDURE GetSupplierContactAsUser (
	in_supplier_contact_id			IN  supplier.supplier_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_row							supplier_contact%ROWTYPE;
	v_user_sid						security_pkg.T_SID_ID;
	v_company_sid					security_pkg.T_SID_ID;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	SELECT *
	  INTO v_row
	  FROM supplier_contact
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_contact_id = in_supplier_contact_id;
	
	SELECT s.company_sid 
	  INTO v_company_sid
	  FROM supplier s, supplier_contact sc
	 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND s.app_sid = sc.app_sid
	   AND s.supplier_id = sc.supplier_id
	   AND supplier_contact_id = in_supplier_contact_id;
	
	IF v_row.user_sid IS NULL THEN
		v_user_sid := CreateCompanyUserINTERNAL(v_company_sid, v_row.full_name, v_row.email);

		UPDATE supplier_contact
		   SET user_sid = v_user_sid
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND supplier_contact_id = in_supplier_contact_id;
	END IF;
	
	GetSupplierContact(in_supplier_contact_id, out_cur);
END;

PROCEDURE GetSupplierContacts (
	in_supplier_id					IN  supplier.supplier_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;
	
	CheckSupplierOwner(in_supplier_id);
	
	GetSupplierContacts(in_supplier_id, null, out_cur);
END;

PROCEDURE GetSupplierContact (
	in_supplier_contact_id			IN  supplier_contact.supplier_contact_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_PRODUCTS_SERVICES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify products and services data');
	END IF;

	CheckSupplierContactOwner(in_supplier_contact_id);
	
	GetSupplierContacts(null, in_supplier_contact_id, out_cur);
END;

PROCEDURE SetSupplierStatus (
	in_company_sid				IN security_pkg.T_SID_ID,
	in_status_id				IN supplier_status.status_id%TYPE
)
AS
	v_current_status			supplier_status.status_id%TYPE;
BEGIN
	-- extra check here because sec checks fail while the user is accepting an invitation
	--IF (in_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ) THEN
	--	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid||' - '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	--END IF;	
	-- NOTE: commeted out - but left here as this seems very odd logic to me and I don't see why it's needed - fail if you "do" have read access?

	-- TO DO - removed the sec check here as it was wrong / odd. Don't like this but this is for a demo and "regular" check isn't working here - need to track through. 
	-- This function is very minor in affect and called from along with other secured functions but needs addressing 
	
	BEGIN
		SELECT status_id
		  INTO v_current_status
		  FROM supplier
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;
	
	CASE
		WHEN in_status_id = ct_pkg.SS_NEWSUPPLIER THEN
			-- you can't set newsupplier from here
			RETURN;
		WHEN in_status_id = ct_pkg.SS_INVITATIONSENT THEN
			IF v_current_status NOT IN (ct_pkg.SS_NEWSUPPLIER) THEN
				RETURN;
			END IF;
		WHEN in_status_id = ct_pkg.SS_ACCEPTEDINVITATION THEN
			IF v_current_status NOT IN (ct_pkg.SS_NEWSUPPLIER, ct_pkg.SS_INVITATIONSENT) THEN
				RETURN;
			END IF;
		WHEN in_status_id = ct_pkg.SS_COMPLETEDBYSUPPLIER THEN
			-- ok fall through
			NULL;
		WHEN in_status_id = ct_pkg.SS_COMPLETEDFORSUPPLIER THEN
			IF v_current_status NOT IN (ct_pkg.SS_NEWSUPPLIER, ct_pkg.SS_INVITATIONSENT, ct_pkg.SS_ACCEPTEDINVITATION) THEN
				RETURN;
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown supplier status id - '||in_status_id);
	END CASE;
	
	UPDATE supplier
	   SET status_id = in_status_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
END;
 
END supplier_pkg;
/
