CREATE OR REPLACE PACKAGE BODY CHAIN.uninvited_pkg
IS

/***********************************************************
		PRIVATE CollectSearchResults
***********************************************************/
PROCEDURE CollectSearchResults (
	in_existing_results		IN  security.T_SID_TABLE,
	in_page   				IN  number,
	in_page_size    		IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 0 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
	      FROM TABLE(in_existing_results);
	
	OPEN out_result_cur FOR 
		select sub.* from (
			SELECT sub_union.*, row_number() OVER (ORDER BY LOWER(sub_union.name)) rn, ctry.name as country_name
			  FROM (
				SELECT c.company_sid, c.name, c.country_code, c.active, 0 never_invited, sr.supp_rel_code /*assumption here is any company that has been create properly has had someone invited before*/
				  FROM v$company c
				  JOIN TABLE(CAST(in_existing_results AS security.T_SID_TABLE)) T ON c.company_sid = T.column_value
				  LEFT JOIN supplier_relationship sr ON c.company_sid = sr.supplier_company_sid AND c.app_sid = sr.app_sid
				 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION
				SELECT u.uninvited_supplier_sid, u.name, u.country_code, 0 active, NVL2(created_as_company_sid, 0, 1) never_invited, supp_rel_code /*assumption here is any company that has been create properly has had someone invited before*/
				  FROM uninvited_supplier u
				  JOIN TABLE(CAST(in_existing_results AS security.T_SID_TABLE)) r 
					ON u.uninvited_supplier_sid = r.column_value
			  ) sub_union
			  JOIN postcode.country ctry on ctry.country = sub_union.country_code
		  ORDER BY rn
		  ) sub
		 WHERE rn-1 BETWEEN ((in_page-1) * in_page_size) AND (in_page * in_page_size) - 1;

	
END;

/***********************************************************
		CreateObject
***********************************************************/
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- CASEY: You need to validate the new name, and set it in your table
	NULL;
END;

/***********************************************************
		RenameObject
***********************************************************/
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	-- CASEY: You need to validate the new name, and set it in your table
	NULL;
END;

/***********************************************************
		DeleteObject
***********************************************************/
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS	
BEGIN
	-- Remove links in purchased component
	UPDATE purchased_component
	   SET component_supplier_type_id = 0, uninvited_supplier_sid = NULL
	 WHERE uninvited_supplier_sid = in_sid_Id
	   AND app_sid = security_pkg.GetApp;
	DELETE FROM uninvited_supplier
	 WHERE uninvited_supplier_sid = in_sid_Id
	   AND app_sid = security_pkg.GetApp;
END;

/***********************************************************
		MoveObject
***********************************************************/
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS   
BEGIN		 
	NULL;
END;

/***********************************************************
		IsUninvitedSupplier
***********************************************************/


FUNCTION IsUninvitedSupplier (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN
	
	--TODO: what if the supplier has been invited (i.e. created_as_company_sid is not null)?
	--      ideally we should return the created_as sid for code using this to carry on
	--      this would currently only happen if someone were to set up the supplier between the user
	--      searching for a supplier and saving the component in the wizard.
	SELECT COUNT(*)
	  INTO v_count
	  FROM uninvited_supplier
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	   AND uninvited_supplier_sid = in_uninvited_supplier_sid
	   AND created_as_company_sid IS NULL;
	
	RETURN v_count > 0;
END;

FUNCTION IsUninvitedSupplier (
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsUninvitedSupplier(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_uninvited_supplier_sid);
END;

FUNCTION IsUninvitedSupplierRetNum (
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
	IF IsUninvitedSupplier(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_uninvited_supplier_sid) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;


FUNCTION SupplierExists (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE, 
	in_supp_rel_code		IN 	supplier_relationship.supp_rel_code%TYPE
) RETURN NUMBER
AS
	v_company_sid				security_pkg.T_SID_ID DEFAULT NULL;
	v_uninvited_supplier_sid	security_pkg.T_SID_ID DEFAULT NULL;
BEGIN
	-- Only being used by rainforest-alliance custom invites. Don't bother changing it to use the region layout for identifying dupes
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM company
	 	 WHERE LOWER(helper_pkg.NormaliseCompanyName(name)) = LOWER(helper_pkg.NormaliseCompanyName(in_company_name))
	 	   AND LOWER(country_code) = LOWER(in_country_code);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	-- Only check companies that supply the current company
	BEGIN
		SELECT supplier_company_sid
		  INTO v_company_sid
		  FROM supplier_relationship /* don't use the v$supplier_relationship view as we want inactive relationships too*/ 
		 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ((supplier_company_sid = v_company_sid) OR (LOWER(supp_rel_code) = LOWER(in_supp_rel_code)))
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND deleted = 0;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_company_sid := NULL;
	END;
	
	-- check if the code already exists
	IF v_uninvited_supplier_sid IS NULL THEN
		BEGIN
			SELECT uninvited_supplier_sid
			  INTO v_uninvited_supplier_sid
			  FROM uninvited_supplier
			 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND LOWER(supp_rel_code) = LOWER(in_supp_rel_code)
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND created_as_company_sid IS NULL;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;
	
	RETURN CASE WHEN v_company_sid IS NOT NULL OR v_uninvited_supplier_sid IS NOT NULL THEN 1 ELSE 0 END;
END;


/***********************************************************
		SearchUninvited
***********************************************************/
PROCEDURE SearchUninvited (
	in_search					IN	VARCHAR2,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_results		security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN

	-- Removed security check as people can see their own uninvited suppliers
	
	-- Find all IDs that match the search criteria
	SELECT uninvited_supplier_sid
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT ui.uninvited_supplier_sid
		  FROM uninvited_supplier ui
		 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ui.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ((LOWER(ui.name) LIKE v_search) OR (LOWER(supp_rel_code) = LOWER(TRIM(in_search))))
		   AND ui.created_as_company_sid IS NULL
	  );
	  
	-- Return the count
	SELECT COUNT(1)
	  INTO out_row_count
	  FROM TABLE(v_results);

	-- Return a single page ordered by name
	OPEN out_cur FOR
		SELECT sub.* FROM (
			SELECT ui.uninvited_supplier_sid as company_sid, ui.app_sid, ctry.name as country_name, ui.name, ui.supp_rel_code,
			       csr.stragg(pc.description) as purchased_components,
			       ui.country_code, row_number() OVER (ORDER BY LOWER(ui.name)) rn
			  FROM uninvited_supplier ui
			  JOIN TABLE(v_results) r ON ui.uninvited_supplier_sid = r.column_value
			  JOIN postcode.country ctry on ctry.country = ui.country_code
			  LEFT JOIN v$purchased_component pc ON ui.uninvited_supplier_sid = pc.uninvited_supplier_sid AND pc.deleted=0
			 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY ui.uninvited_supplier_sid, ui.app_sid, ctry.name, ui.name, ui.country_code, ui.supp_rel_code
		  ) sub
		 WHERE rn-1 BETWEEN in_start AND in_start + in_page_size - 1
		 ORDER BY rn;

END;

/***********************************************************
		MigrateUninvitedToCompany
***********************************************************/
PROCEDURE MigrateUninvitedToCompany (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID,
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE
)
AS
	v_key						supplier_relationship.virtually_active_key%TYPE;
	v_company_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	IF NOT capability_pkg.CheckPotentialCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE)
	   AND NOT capability_pkg.CheckPotentialCapability(chain_pkg.SEND_INVITE_ON_BEHALF_OF) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied applying company_sid to uninvited supplier');
	END IF;
	
	-- blank the supplier rel code - as this is a full company now and the code on the full company can be updated (could get out of sync - cause warnings about a company already existing with a code where there's no issue etc)
	UPDATE uninvited_supplier
	   SET created_as_company_sid = in_created_as_company_sid, 
		   supp_rel_code = null
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = v_company_sid
	   AND uninvited_supplier_sid = in_uninvited_supplier_sid;
	      
	company_pkg.ActivateVirtualRelationship(v_company_sid, in_created_as_company_sid, v_key);
	
	UPDATE supplier_relationship
	   SET supp_rel_code = in_supp_rel_code
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = v_company_sid
	   AND purchaser_company_sid = in_created_as_company_sid;
	
	--TODO: Should we do some error checking here before attempting to migrate?
	
	purchased_component_pkg.MigrateUninvitedComponents(in_uninvited_supplier_sid, in_created_as_company_sid);
	
	--TODO: Actual migration of tasks
	
	company_pkg.DeactivateVirtualRelationship(v_key);
	
END;

/***********************************************************
		CreateUninvited
***********************************************************/
PROCEDURE CreateUninvited (
	in_name						IN	uninvited_supplier.name%TYPE,
	in_country_code				IN	uninvited_supplier.country_code%TYPE,
	in_supp_rel_code			IN  uninvited_supplier.supp_rel_code%TYPE,
	out_uninvited_supplier_sid	OUT security_pkg.T_SID_ID
)
AS
	v_container_sid					security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.UNINVITED_SUPPLIERS);
BEGIN
	SecurableObject_Pkg.CreateSO(security_pkg.GetAct, v_container_sid, class_pkg.getClassID('Chain Uninvited Supplier'), NULL, out_uninvited_supplier_sid);
	
	UPDATE security.securable_object 
	   SET name = helper_pkg.GenerateSOName(in_company_name => in_name, in_company_sid => out_uninvited_supplier_sid) 
	 WHERE sid_id = out_uninvited_supplier_sid;
	
	-- TODO: would this be better moved to the CreateObject method as per chain company?
	-- CASEY: YES - you need to do that as this type of object is now creatable through SecMgr
	-- (even tho it's rather unlikely that people will add uninvited suppliers this way, it's still go practice to ensure that it works)
	INSERT INTO uninvited_supplier(uninvited_supplier_sid, company_sid, name, country_code, supp_rel_code)
	VALUES (out_uninvited_supplier_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_name, in_country_code, in_supp_rel_code);
END;


/***********************************************************
		SearchSuppliers
***********************************************************/
PROCEDURE SearchSuppliers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_only_active			IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_supplier_results		security.T_SID_TABLE;
BEGIN
	-- CASEY: I think that you should alter the existing SearchSuppliers in company_pkg to include a flag
	-- of in_include_uninvited_suppliers rather than duplicating the code here
	IF NOT capability_pkg.CheckPotentialCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ) THEN
		OPEN out_count_cur FOR
			SELECT 0 total_count, 0 total_pages FROM DUAL;
		
		OPEN out_result_cur FOR
			SELECT * FROM DUAL WHERE 0 = 1;
		
		RETURN;
	END IF;
	
	-- bulk collect company sid's that match our search result
	SELECT company_sid
	  BULK COLLECT INTO v_supplier_results
	  FROM (
	  	SELECT DISTINCT c.company_sid
		  FROM v$company c, supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		   AND c.company_sid = sr.supplier_company_sid 
		   AND ((in_only_active = chain_pkg.active AND sr.active = chain_pkg.active) OR (in_only_active = chain_pkg.inactive))
		   AND ((LOWER(name) LIKE v_search) OR (LOWER(supp_rel_code) = LOWER(TRIM(in_search_term))))
		   AND sr.deleted <> chain_pkg.DELETED
		 UNION
		SELECT ui.uninvited_supplier_sid
		  FROM uninvited_supplier ui
		 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ui.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ((LOWER(ui.name) LIKE v_search) OR (LOWER(supp_rel_code) = LOWER(TRIM(in_search_term))))
		   AND ui.created_as_company_sid IS NULL
		   AND in_only_active = chain_pkg.inactive
	  );
	
	CollectSearchResults(v_supplier_results,  in_page, in_page_size, out_count_cur, out_result_cur);
END;

FUNCTION HasUninvitedSupsWithComponents (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM uninvited_supplier us
	  JOIN v$purchased_component c ON us.app_sid = c.app_sid AND us.uninvited_supplier_sid = c.uninvited_supplier_sid
	 WHERE us.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND us.company_sid = in_company_sid
	   AND us.created_as_company_sid IS NULL
	   AND c.deleted = 0;
	
	RETURN v_count > 0;
END;


END uninvited_pkg;
/
