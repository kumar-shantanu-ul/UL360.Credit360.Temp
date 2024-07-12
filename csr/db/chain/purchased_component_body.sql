CREATE OR REPLACE PACKAGE BODY CHAIN.purchased_component_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/

PROCEDURE RefeshSupplierActions (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_supplier_company_sid	IN  security_pkg.T_SID_ID
)
AS
	v_count					NUMBER(10);
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM purchased_component pc, v$supplier_relationship sr
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = sr.app_sid
	   AND pc.company_sid = in_company_sid
	   AND pc.company_sid = sr.purchaser_company_sid
	   AND pc.supplier_company_sid = in_supplier_company_sid
	   AND pc.supplier_company_sid = sr.supplier_company_sid
	   AND pc.acceptance_status_id = chain_pkg.ACCEPT_PENDING;

	IF v_count = 0 THEN
		
		message_pkg.CompleteMessageIfExists (
			in_primary_lookup 			=> chain_pkg.PRODUCT_MAPPING_REQUIRED,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid	  	 	=> in_supplier_company_sid,
			in_re_company_sid	  	 	=> in_company_sid
		);
			
	ELSE
	
		message_pkg.TriggerMessage (
			in_primary_lookup 			=> chain_pkg.PRODUCT_MAPPING_REQUIRED,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid	  	 	=> in_supplier_company_sid,
			in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
			in_re_company_sid	  	 	=> in_company_sid
		);
		
	END IF;
	
	IF product_pkg.HasMappedUnpublishedProducts(in_supplier_company_sid) THEN
		message_pkg.TriggerMessage (
			in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
			in_to_company_sid	  	 	=> in_supplier_company_sid
		);
	ELSE
		message_pkg.CompleteMessageIfExists (
			in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
			in_to_company_sid	  	 	=> in_supplier_company_sid
		);
	END IF;
END;

PROCEDURE RefeshCompanyActions (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_count					NUMBER(10);
BEGIN
	
	IF uninvited_pkg.HasUninvitedSupsWithComponents(in_company_sid) THEN
		message_pkg.TriggerMessage (
			in_primary_lookup 			=> chain_pkg.UNINVITED_SUPPLIERS_TO_INVITE,
			in_to_company_sid	  	 	=> in_company_sid
		);
	ELSE
		message_pkg.CompleteMessageIfExists (
			in_primary_lookup 			=> chain_pkg.UNINVITED_SUPPLIERS_TO_INVITE,
			in_to_company_sid	  	 	=> in_company_sid
		);
	END IF;
	
END;

PROCEDURE CollectToCursor (
	in_component_ids		IN  T_NUMERIC_TABLE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_amount_unit_id	amount_unit.amount_unit_id%TYPE;
	v_amount_unit		amount_unit.description%TYPE;
	v_purch_mismatch_ids			T_NUMERIC_TABLE;
BEGIN

	component_pkg.GetDefaultAmountUnit(v_amount_unit_id, v_amount_unit);
	
	-- COLLECT PRODUCT IDS BASED ON INPUT
	v_purch_mismatch_ids := chain_link_pkg.FindProdWithUnitMismatch;

	OPEN out_cur FOR
		SELECT pc.component_id, pc.description, pc.component_code, pc.component_notes, pc.company_sid, 
				pc.created_by_sid, pc.created_dtm, pc.component_supplier_type_id,
				pc.acceptance_status_id, pc.supplier_product_id, 
				-- supplier data
				pcs.supplier_company_sid, pcs.uninvited_supplier_sid, 
				pcs.supplier_name, pc.uninvited_name, pcs.supplier_country_code, pcs.supplier_country_name, 
				v_amount_unit_id amount_unit_id, v_amount_unit amount_unit,
				pc.supplier_product_description, pc.supplier_product_code1, pc.supplier_product_code2, pc.supplier_product_code3, 
				pc.supplier_product_published, pc.supplier_product_published_dtm, pc.purchases_locked, NVL2(mm.item, 1, 0) purchase_unit_mismatch,
				pc.supplier_root_component_id,
				CASE 
					WHEN iqtc.component_id IS NOT NULL THEN 
						CASE WHEN q.component_id IS NOT NULL THEN 1 /* Created*/ ELSE 0 /* Not created*/ END
					ELSE -1 /* N/A */
				END product_questionnaire_status,
				CASE 
					WHEN q.component_id IS NOT NULL THEN 
						qs.share_status_id
					ELSE
						0 /* Undefined */
				END product_qnr_share_status				
		  FROM v$purchased_component pc, v$purchased_component_supplier pcs, TABLE(in_component_ids) i, TABLE(v_purch_mismatch_ids) mm, invitation_qnr_type_component iqtc, questionnaire q, v$questionnaire_share qs
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = pcs.app_sid
		   AND pc.component_id = i.item
		   AND pc.component_id = pcs.component_id
		   AND pc.deleted = chain_pkg.NOT_DELETED
		   AND pc.component_id = mm.item(+)
		   AND pc.supplier_product_id = iqtc.component_id(+)
		   AND pc.supplier_product_id = q.component_id(+)
		   AND q.questionnaire_id = qs.questionnaire_id(+)
		 ORDER BY i.pos;
END;

-- note that this procedure could be called by either the supplier or purchaser 
-- (if the purcher component is being deleted)
-- i.e. - be careful about getting the company sid from sys context
PROCEDURE SetSupplier (
	in_component_id			IN  component.component_id%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_purchaser_company_sid IN security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
)
AS
	v_cur_data				purchased_component%ROWTYPE;
	v_supplier_type_id		component_supplier_type.component_supplier_type_id%TYPE;
	v_company_sid 			security_pkg.T_SID_ID;
	v_accpetance_status_id	chain_pkg.T_ACCEPTANCE_STATUS;
	v_key					supplier_relationship.virtually_active_key%TYPE;
BEGIN
	
	
	-- figure out which type of supplier we're attaching to...
	IF NVL(in_supplier_sid, 0) > 0 THEN
		v_company_sid := component_pkg.GetCompanySid(in_component_id);
		
		-- activate the virtual relationship so that we can attach to companies with pending relationships as well
		company_pkg.ActivateVirtualRelationship(v_company_sid, in_supplier_sid, v_key);
		
		IF uninvited_pkg.IsUninvitedSupplier(v_company_sid, in_supplier_sid) THEN
			v_supplier_type_id := chain_pkg.UNINVITED_SUPPLIER;
		ELSIF company_pkg.IsSupplier(v_company_sid, in_supplier_sid) THEN
			v_supplier_type_id := chain_pkg.EXISTING_SUPPLIER;
		ELSIF company_pkg.IsPurchaser(v_company_sid, in_supplier_sid) THEN 
			v_supplier_type_id := chain_pkg.EXISTING_PURCHASER;
		END IF;
		
		company_pkg.DeactivateVirtualRelationship(v_key);
		
		IF v_supplier_type_id IS NULL THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied attaching to company with sid ('||in_supplier_sid||') - they are not a current purchaser or supplier of company with sid ('||v_company_sid||')');
		END IF;
	ELSE
		v_supplier_type_id := chain_pkg.SUPPLIER_NOT_SET;
	END IF;
	
	BEGIN
		-- try to setup minimum data in case it doesn't exist already
		INSERT INTO purchased_component
		(component_id, component_supplier_type_id, company_sid)
		VALUES
		(in_component_id, chain_pkg.SUPPLIER_NOT_SET, in_purchaser_company_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- get the current data
	SELECT *
	  INTO v_cur_data
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	-- this is a bit of a strange way, but I think we're best to have an update statement per 
	-- supplier_type entry as the data that we need is highly dependant on this state
	
	IF v_supplier_type_id = chain_pkg.SUPPLIER_NOT_SET THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   mapped_dtm = NULL, 
			   mapped_by_user_sid = NULL, 
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

	
	ELSIF v_supplier_type_id = chain_pkg.UNINVITED_SUPPLIER THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   mapped_dtm = NULL, 
			   mapped_by_user_sid = NULL, 
			   uninvited_supplier_sid = in_supplier_sid,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

		   
	ELSIF v_supplier_type_id = chain_pkg.EXISTING_PURCHASER THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   mapped_dtm = NULL, 
			   mapped_by_user_sid = NULL, 
			   company_sid = in_supplier_sid,	
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

		   
	ELSIF v_supplier_type_id = chain_pkg.EXISTING_SUPPLIER THEN
	  
	  	IF v_cur_data.component_supplier_type_id <> chain_pkg.EXISTING_SUPPLIER OR v_cur_data.supplier_company_sid <> in_supplier_sid THEN
	  		v_accpetance_status_id := chain_pkg.ACCEPT_PENDING;
	  	ELSE
	  		v_accpetance_status_id := NVL(v_cur_data.acceptance_status_id, chain_pkg.ACCEPT_PENDING);
	  	END IF;
		
		-- if the supplier company was set and has now changed then we clear the product mapping
		IF ((v_cur_data.supplier_company_sid IS NOT NULL) AND (v_cur_data.supplier_company_sid <> in_supplier_sid)) THEN 
			UPDATE purchased_component
		       SET 
				   mapped_dtm = NULL, 
				   mapped_by_user_sid = NULL, 
				   supplier_product_id = NULL
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND component_id = in_component_id;	
		END IF;
	  	
	  	UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = v_accpetance_status_id,
			   supplier_company_sid = in_supplier_sid, 
			   uninvited_supplier_sid = NULL	   
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;
	  	
	  	RefeshSupplierActions(v_cur_data.company_sid, in_supplier_sid);
	END IF;
	
	RefeshCompanyActions(v_cur_data.company_sid);
END;

/*************************************************************************************
 * Checks the uniqueness of the SKU (component_code) against the not marked as deleted 
 * existing purchased components of the company */
PROCEDURE CheckUniquePurchasedSKU(
	in_component_id			IN  component.component_id%TYPE,
	in_component_code		IN  chain_pkg.T_COMPONENT_CODE
)
AS
	v_count					NUMBER;
	v_isTopLevelCompany     NUMBER DEFAULT helper_pkg.IsTopCompany;
BEGIN
	--Validate unique purchased SKU only for top level companies
	IF v_isTopLevelCompany = 0 THEN
		RETURN;
	END IF;
	
	--count of the not marked as deleted existing purchased components with the same SKU (component_code)
	SELECT COUNT(*)
	  INTO v_count  
      FROM v$purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id != NVL(in_component_id, 0)
	   AND lower(component_code) = lower(in_component_code)	   
	   AND deleted = 0;
		
	IF v_count > 0 THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A purchased product with the same SKU code exists already');
	END IF;
END;

/**********************************************************************************
	PUBLIC -- ICOMPONENT HANDLER PROCEDURES
**********************************************************************************/
PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	in_tag_sids				IN  security_pkg.T_SID_IDS,
	out_cur					OUT security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_id			component.component_id%TYPE;
BEGIN
	IF in_component_code IS NOT NULL THEN
		-- check if the SKU is unique per company for products, not transaction safe	
		CheckUniquePurchasedSKU(in_component_id, in_component_code); --in_component_id will be < 1 for a new row
	END IF;
	
	v_component_id := component_pkg.SaveComponent(in_component_id, chain_pkg.PURCHASED_COMPONENT, in_description, in_component_code, in_component_notes, in_tag_sids);
	
	SetSupplier(v_component_id, in_supplier_sid);
	
	GetComponent(v_component_id, out_cur);

END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;

	SELECT T_NUMERIC_ROW(in_component_id, null)
	  BULK COLLECT INTO v_component_ids
	  FROM v$purchased_component pc
	 WHERE pc.app_sid = security.security_pkg.GetApp
	   AND pc.component_id = in_component_id
	   AND pc.deleted = chain_pkg.NOT_DELETED;
	
	CollectToCursor(v_component_ids, out_cur);
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids				T_NUMERIC_TABLE;
	v_show_supplier_names		NUMBER := 0;
BEGIN
	component_pkg.RecordTreeSnapshot(in_top_component_id);
	
	IF ((component_pkg.CanSeeComponentAsChainTrnsprnt(in_top_component_id)) OR (component_pkg.GetCompanySid(in_top_component_id) = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))) THEN
		v_show_supplier_names := 1;
	END IF;	
	
	-- Don't use collect to cursor as we need more info than that provides and info about the relationship with parent component
	OPEN out_cur FOR
		SELECT  pc.component_id, pc.description, pc.component_code, pc.component_notes, pc.company_sid, 
				pc.created_by_sid, pc.created_dtm, pc.component_supplier_type_id,
				pc.acceptance_status_id, pc.supplier_product_id, 
				pcs.supplier_company_sid, pcs.uninvited_supplier_sid, 
				DECODE(v_show_supplier_names, 1, pcs.supplier_name, 0, NULL) supplier_name, 
				DECODE(v_show_supplier_names, 1, pc.uninvited_name, 0, NULL) uninvited_name, 
				pcs.supplier_country_code, pcs.supplier_country_name,
				NVL(ct.amount_child_per_parent,0) amount_child_per_parent, 
				NVL(ct.amount_unit_id,1) amount_unit_id, 
				au.description amount_unit,
				pc.supplier_product_description, pc.supplier_product_code1, pc.supplier_product_code2, pc.supplier_product_code3, pc.supplier_product_published, pc.supplier_product_published_dtm,
				pc.supplier_root_component_id
		  FROM v$purchased_component pc
		  JOIN v$purchased_component_supplier pcs ON pc.app_sid = pcs.app_sid AND pc.component_id = pcs.component_id
		  JOIN TT_COMPONENT_TREE ct ON pc.component_id = ct.child_component_id
		  JOIN chain.amount_unit au ON pc.app_sid = au.app_sid AND NVL(ct.amount_unit_id,1) = au.amount_unit_id
		 WHERE pc.app_sid = security.security_pkg.GetApp
		   AND ct.top_component_id = in_top_component_id
		   AND in_type_id = chain_pkg.PURCHASED_COMPONENT
		   AND pc.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position;
END;

FUNCTION GetComponentIdByCode(
	in_component_code		IN  component.component_code%TYPE
)RETURN NUMBER
AS
	v_component_id		component.component_id%TYPE;
BEGIN
	BEGIN
		SELECT cmp.component_id
		  INTO v_component_id
		  FROM purchased_component pc
		  JOIN component cmp ON pc.app_sid = cmp.app_sid AND pc.component_id = cmp.component_id
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND UPPER(cmp.component_code) = UPPER(in_component_code)
		   AND cmp.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND cmp.deleted = chain_pkg.NOT_DELETED;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_component_id := -1;
	END;

	RETURN v_component_id;
END;

PROCEDURE GetComponentFromCode (
	in_component_code		IN  component.component_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	SELECT T_NUMERIC_ROW(component_id, null)
	  BULK COLLECT INTO v_component_ids
	  FROM v$purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_code = in_component_code --TODO: case insensitive compare?
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND deleted = chain_pkg.NOT_DELETED;
	   
	CollectToCursor(v_component_ids, out_cur);
END;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
) 
AS
BEGIN
	SetSupplier(in_component_id, NULL);
	
	FOR r IN (
		SELECT c.component_id
		  FROM component c
		  JOIN validated_purchased_component vpc ON c.app_sid = vpc.app_sid AND c.component_id = vpc.component_id
		 WHERE c.deleted = chain_pkg.NOT_DELETED
		   AND vpc.mapped_purchased_component_id = in_component_id
	) LOOP
		validated_purch_component_pkg.DeleteComponent(r.component_id);
	END LOOP;
END;

/**********************************************************************************
	PUBLIC
**********************************************************************************/

PROCEDURE ClearSupplier (
	in_component_id				IN  component.component_id%TYPE
) 
AS
	v_count						NUMBER(10);
BEGIN
	-- make sure that the company clearing the supplier is either the supplier company, or the component owner company
	SELECT COUNT(*)
	  INTO v_count
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND component_id = in_component_id
	   AND (	company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	   		 OR supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   	   );

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied clearing the supplier for purchased component with id '||in_component_id||' where you are niether the owner or supplier company');
	END IF;
	
	SetSupplier(in_component_id, NULL);	
END;

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT component_id
		  FROM purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_purchaser_company_sid
		   AND supplier_company_sid = in_supplier_company_sid
	) LOOP
		SetSupplier(r.component_id, in_supplier_company_sid, in_purchaser_company_sid);	
	END LOOP;
END;

PROCEDURE SearchProductMappings (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_accept_status			IN  chain_pkg.T_ACCEPTANCE_STATUS,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_total_count				NUMBER(10);
BEGIN
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	-- fill the id table with all valid purchased components, owned by the purchaser company, and supplied by our company
	DELETE FROM TT_ID;

	INSERT INTO TT_ID
	(id, position)
	SELECT component_id, rownum
	  FROM (
		SELECT pc.component_id
		  FROM v$purchased_component pc
		  JOIN v$company c ON pc.app_sid = c.app_sid AND pc.company_sid = c.company_sid
		  LEFT JOIN v$product p ON pc.app_sid = p.app_sid
				AND pc.supplier_product_id = p.product_id
				AND p.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
				AND p.deleted = chain_pkg.NOT_DELETED
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND (in_purchaser_company_sid IS NULL OR pc.company_sid = in_purchaser_company_sid)
		   AND pc.deleted = chain_pkg.NOT_DELETED
		   AND pc.acceptance_status_id = NVL(in_accept_status, pc.acceptance_status_id)
		   AND (
					LOWER(pc.description) LIKE v_search
		   		 OR LOWER(pc.component_code) LIKE v_search
		   		 OR LOWER(p.description) LIKE v_search
		   		 OR LOWER(p.code1) LIKE v_search
		   		 OR LOWER(p.code2) LIKE v_search
		   		 OR LOWER(p.code3) LIKE v_search
		       )
		 ORDER BY LOWER(c.name), LOWER(pc.description)
		);

	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE FROM TT_ID
	 WHERE position <= NVL(in_start, 0)
		OR position > NVL(in_start + in_page_size, v_total_count);
		
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
	
	OPEN out_results_cur FOR
		SELECT c.name purchaser_company_name, pc.component_id, pc.description component_description, pc.component_code, pc.component_notes, pc.acceptance_status_id, 
				p.product_id, p.description product_description, p.code1, p.code2, p.code3, pc.mapped, 
					-- "new" if mapped in tha last day - and only show stuff mapped by this user
					CASE 
						WHEN ((pc.mapped_dtm > sysdate-1) AND (pc.mapped_by_user_sid=SYS_CONTEXT('SECURITY', 'SID'))) THEN 1
					ELSE 0
					END AS recent
		  FROM v$purchased_component pc, TT_ID i, v$product p, v$company c
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = c.app_sid
		   AND pc.app_sid = p.app_sid(+)
		   AND pc.component_id = i.id
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_company_sid = p.company_sid(+)
		   AND pc.supplier_product_id = p.product_id(+)
		 ORDER BY LOWER(c.name), mapped ASC, LOWER(pc.description); -- puts unmapped first
END;

PROCEDURE ClearMapping (
	in_component_id			IN  component.component_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/
	
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	UPDATE purchased_component
	   SET supplier_product_id = NULL,
	       acceptance_status_id = chain_pkg.ACCEPT_PENDING
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;

	RefeshSupplierActions(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

PROCEDURE RejectMapping (
	in_component_id			IN  component.component_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	UPDATE purchased_component
	   SET supplier_product_id = NULL,
	   	   acceptance_status_id = chain_pkg.ACCEPT_REJECTED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;
END;

PROCEDURE SetMapping (
	in_component_id			IN  component.component_id%TYPE,
	in_product_id			IN  product.product_id%TYPE
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	UPDATE purchased_component
	   SET supplier_product_id = in_product_id,
		   acceptance_status_id = chain_pkg.ACCEPT_ACCEPTED,
		   mapped_dtm = SYSDATE, 
		   mapped_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;
	
	RefeshSupplierActions(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	
	chain_link_pkg.OnProductMapped(in_component_id, in_product_id);
END;

-- Attempts to create a product with the same information as the provided purchased component for the provided supplier, then maps the purchased component to the new product.
FUNCTION AutoMap (
	in_component_id			IN  component.component_id%TYPE,
	in_supplier_sid				IN security.security_pkg.T_SID_ID
) RETURN product.product_id%TYPE
AS
	v_product_id			product.product_id%TYPE := 0;
	v_description			component.description%TYPE;
	v_component_code		component.component_code%TYPE;
	v_user_sid				security.security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'); -- Store a reference for logging the user created a product
BEGIN
	
	SELECT description, NVL(component_code, to_char(in_component_id))
	  INTO v_description, v_component_code
	  FROM component
	 WHERE component_id = in_component_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		 
	BEGIN		 
		--switch the context over to the supplier company for this bit
		helper_pkg.LogonUCD(in_supplier_sid);
		
		--pass the user_sid
		v_product_id := chain.product_pkg.SaveProduct(
			in_product_id	=>	-1, 
			in_description	=>	v_description, 
			in_code1		=>	v_component_code, 
			in_code2		=>	NULL, 
			in_code3		=>	NULL, 
			in_notes		=>	NULL, 
			in_user_sid		=>	v_user_sid
		);
		
		SetMapping(in_component_id, v_product_id);
		
		helper_pkg.RevertLogonUCD;
		
		RETURN v_product_id;
	EXCEPTION
		WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
	END;
END;

-- try to get the mapped product to a pc from a supplier
FUNCTION TryGetMappedProduct (
	in_component_id			IN  component.component_id%TYPE, --the pc
	in_supplier_sid				IN security.security_pkg.T_SID_ID -- the supplier
) RETURN product.product_id%TYPE
AS
	v_product_id 			product.product_id%TYPE;
BEGIN

	SELECT supplier_product_id
	  INTO v_product_id
	  FROM purchased_component
	 WHERE component_id = in_component_id
	   AND supplier_company_sid = in_supplier_sid
	   AND acceptance_status_id = chain_pkg.ACCEPT_ACCEPTED;
		  
	RETURN v_product_id;
		  
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
END;

PROCEDURE MigrateUninvitedComponents (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT component_id, created_by_sid, company_sid
		  FROM v$purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND uninvited_supplier_sid = in_uninvited_supplier_sid
	) LOOP
		SetSupplier(r.component_id, in_created_as_company_sid);	
		-- any user who created a product for this uninvited supplier added as follower by default
		company_pkg.AddSupplierFollower(r.company_sid, in_created_as_company_sid, r.created_by_sid);
	END LOOP;
END;

PROCEDURE GetPurchaseChannels (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing purchase channels. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
	END IF;
	
	OPEN out_cur FOR
		SELECT NULL id, 'General' description
		  FROM dual
		UNION ALL
		SELECT purchase_channel_id id, description
		  FROM purchase_channel
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		 ORDER BY id;
END;

PROCEDURE SavePurchase (
	in_purchase_id			IN  purchase.purchase_id%TYPE,
	in_component_id			IN  purchase.component_id%TYPE,
	in_start_date			IN  purchase.start_date%TYPE,
	in_end_date				IN  purchase.end_date%TYPE,
	in_invoice_number		IN  purchase.invoice_number%TYPE,
	in_purchase_order		IN  purchase.purchase_order%TYPE,
	in_note					IN  purchase.note%TYPE,
	in_amount				IN  purchase.amount%TYPE,
	in_amount_unit_id		IN  purchase.amount_unit_id%TYPE,
	in_purchase_channel_id	IN  purchase.purchase_channel_id%TYPE,
	in_tag_sids				IN  security_pkg.T_SID_IDS
) AS
	v_tag_ids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tag_sids);
	v_purchase_id			purchase.purchase_id%TYPE;
	v_cnt					NUMBER;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving purchase for purchased component '||in_component_id||'. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
	END IF;
	
	IF NOT capability_pkg.CheckCapability(chain.component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on purchases for  purchased component '||in_component_id||' belonging to company with sid '||chain.component_pkg.GetCompanySid(in_component_id));
	END IF;
	
	IF NVL(in_purchase_id, 0) < 1 THEN
		INSERT INTO purchase	(purchase_id, component_id, start_date, end_date, invoice_number,
								purchase_order, note, amount, amount_unit_id, purchase_channel_id)
		     VALUES				(purchase_id_seq.NEXTVAL, in_component_id, in_start_date, in_end_date, in_invoice_number,
								in_purchase_order, in_note, in_amount, in_amount_unit_id, in_purchase_channel_id)
		  RETURNING purchase_id INTO v_purchase_id;
	ELSE
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM purchase pur
		  JOIN ( --Get the full tree of purchases
			SELECT app_sid, component_id
			  FROM chain.purchased_component
			 START WITH component_id = in_component_id
		   CONNECT BY NOCYCLE PRIOR component_id = previous_purch_component_id OR PRIOR previous_purch_component_id = component_id
		  ) pc ON pur.app_sid = pc.app_sid AND pur.component_id = pc.component_id
		 WHERE pur.app_sid = security_pkg.GetApp
		   AND pur.purchase_id = in_purchase_id;
		
		IF v_cnt = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot find purchase '||in_purchase_id||' on purchased component '||in_component_id||' or one of its revisions.');
		END IF;
		
		UPDATE purchase
		   SET start_date = in_start_date,
		       end_date = in_end_date,
		       invoice_number = in_invoice_number,
		       purchase_order = in_purchase_order,
		       note = in_note,
		       amount = in_amount,
		       amount_unit_id = in_amount_unit_id,
		       purchase_channel_id = in_purchase_channel_id
		 WHERE app_sid = security_pkg.GetApp
		   AND purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		   AND purchase_id = in_purchase_id;
		   
		   v_purchase_id := in_purchase_id;
	END IF;
	
	DELETE FROM purchase_tag
	 WHERE purchase_id = v_purchase_id
	   AND tag_id NOT IN (
			SELECT column_value FROM TABLE(v_tag_ids)
		)
	   AND tag_id IN (
			SELECT tgm.tag_id
			  FROM csr.tag_group_member tgm
			  JOIN company_tag_group tg ON tgm.tag_group_id = tg.tag_group_id
			 WHERE tg.applies_to_purchase = 1
		);

	INSERT INTO purchase_tag (purchase_id, tag_id)
	SELECT v_purchase_id, column_value
	  FROM TABLE(v_tag_ids)
	 WHERE column_value NOT IN (
		SELECT tag_id
		  FROM purchase_tag
		 WHERE purchase_id = v_purchase_id
	);
	
	
	chain_link_pkg.OnPurchaseSaved(v_purchase_id);
END;

PROCEDURE DeletePurchase (
	in_purchase_id			purchase.purchase_id%TYPE,
	in_component_id			purchase.component_id%TYPE
) AS
	v_cnt	NUMBER;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting purchase for purchased component '||in_component_id||'. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
	END IF;
	
	IF NOT capability_pkg.CheckCapability(chain.component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on purchases for purchased component '||in_component_id||' belonging to company with sid '||chain.component_pkg.GetCompanySid(in_component_id));
	END IF;
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM purchase pur
	  JOIN ( --Get the full tree of purchases
		SELECT app_sid, component_id
		  FROM chain.purchased_component
		 START WITH component_id = in_component_id
	   CONNECT BY NOCYCLE PRIOR component_id = previous_purch_component_id OR PRIOR previous_purch_component_id = component_id
	  ) pc ON pur.app_sid = pc.app_sid AND pur.component_id = pc.component_id
	 WHERE pur.app_sid = security_pkg.GetApp
	   AND pur.purchase_id = in_purchase_id;
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot find purchase '||in_purchase_id||' on purchased component '||in_component_id||' or one of its revisions.');
	END IF;
		
	DELETE FROM purchase_tag
	 WHERE app_sid = security_pkg.GetApp
	   AND purchase_id IN (
		SELECT purchase_id
		  FROM purchase
		 WHERE app_sid = security_pkg.GetApp
		   AND purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		   AND purchase_id = in_purchase_id
	   );
	   
	DELETE FROM purchase
	 WHERE app_sid = security_pkg.GetApp
	   AND purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
	   AND purchase_id = in_purchase_id;
END;

PROCEDURE SearchPurchases (
	in_component_id		IN	purchase.component_id%TYPE,
	in_start			IN	NUMBER,
	in_count			IN	NUMBER,
	out_total			OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) AS
BEGIN
    IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied searching for purchases for purchased component '||in_component_id||'. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
    END IF;
    
    IF NOT capability_pkg.CheckCapability(chain.component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on purchases for purchased component '||in_component_id||' belonging to company with sid '||chain.component_pkg.GetCompanySid(in_component_id));
    END IF;
	
	SELECT COUNT(*)
	  INTO out_total
	  FROM purchase pur
	  JOIN ( --Get the full tree of purchases
		SELECT app_sid, component_id
		  FROM chain.purchased_component
		 START WITH component_id = in_component_id
	   CONNECT BY NOCYCLE PRIOR component_id = previous_purch_component_id OR PRIOR previous_purch_component_id = component_id
	  ) pc ON pur.app_sid = pc.app_sid AND pur.component_id = pc.component_id
	 WHERE pur.app_sid = security_pkg.GetApp
	   AND pur.purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY');
	
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT inner1.*, rownum rn FROM (
				SELECT pur.purchase_id, pur.component_id, pur.start_date, pur.end_date, NVL(ch.description, 'General') as channel_description,
				        ch.purchase_channel_id, pur.invoice_number, pur.purchase_order, pur.note, pur.amount,
				        pur.amount_unit_id, u.description as amount_unit_description
				  FROM purchase pur
				  JOIN ( --Get the full tree of purchases
					SELECT app_sid, component_id
					  FROM chain.purchased_component
					 START WITH component_id = in_component_id
				   CONNECT BY NOCYCLE PRIOR component_id = previous_purch_component_id OR PRIOR previous_purch_component_id = component_id
				  ) pc ON pur.app_sid = pc.app_sid AND pur.component_id = pc.component_id
				  JOIN amount_unit u ON pur.amount_unit_id = u.amount_unit_id
				  LEFT JOIN purchase_channel ch ON pur.purchase_channel_id = ch.purchase_channel_id AND pur.purchaser_company_sid = ch.company_sid AND pur.app_sid = ch.app_sid
				 WHERE pur.app_sid = security_pkg.GetApp
				   AND pur.purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
				 ORDER BY pur.start_date DESC
				) inner1
			 WHERE rownum-1 < in_start + in_count
			)
		 WHERE rn-1 >= in_start;
END;

FUNCTION GetPurchaseId(
	in_component_id			component.component_id%TYPE,
	in_purchase_order		IN	purchase.purchase_order%TYPE
)RETURN NUMBER
AS
	v_purchase_id		purchase.purchase_id%TYPE;
BEGIN

	BEGIN
		SELECT pur.purchase_id
		  INTO v_purchase_id
		  FROM purchase pur
		 WHERE pur.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND pur.purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		   AND pur.component_id = in_component_id
		   AND NVL(in_purchase_order, 1) = NVL(pur.purchase_order, 1)
		   AND end_date IS NULL; --only single invoice purchases
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			v_purchase_id := -1;
	END;	 
	RETURN v_purchase_id;
END;

PROCEDURE INTERNAL_GetPurchase (
	in_component_code		IN	component.component_code%TYPE,
	in_purchase_order		IN	purchase.purchase_order%TYPE,
	in_start_date			IN	purchase.start_date%TYPE,
	in_end_date				IN	purchase.end_date%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
) AS
	v_component_id			component.component_id%TYPE;
BEGIN


	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN	
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading purchases. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
    END IF;
	
	BEGIN
	SELECT component_id
	  INTO v_component_id
	  FROM v$purchased_component
	 WHERE app_sid = security_pkg.GetApp
	   AND deleted = 0
	   AND company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
	   AND component_code = in_component_code; --TODO: case insensitive compare?
    EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			NULL;
	END;
	
    IF NOT capability_pkg.CheckCapability(chain.component_pkg.GetCompanySid(v_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on purchases for component'||v_component_id||' belonging to company with sid '||chain.component_pkg.GetCompanySid(v_component_id));
    END IF;
	
	OPEN out_cur FOR
		SELECT pur.purchase_id, pur.component_id, pur.start_date, pur.end_date, NVL(ch.description, 'General') as channel_description,
				ch.purchase_channel_id, pur.invoice_number, pur.purchase_order, pur.note, pur.amount,
				pur.amount_unit_id, u.description as amount_unit_description
		  FROM purchase pur
		  JOIN amount_unit u ON pur.amount_unit_id = u.amount_unit_id
		  LEFT JOIN purchase_channel ch ON pur.purchase_channel_id = ch.purchase_channel_id AND pur.purchaser_company_sid = ch.company_sid AND pur.app_sid = ch.app_sid
		 WHERE pur.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND pur.purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		   AND pur.component_id = v_component_id
		   AND (in_purchase_order IS NULL OR (pur.purchase_order = NVL(in_purchase_order, pur.purchase_order)))
		   AND (in_start_date IS NULL OR (pur.start_date = NVL(in_start_date, pur.start_date)))
		   AND (in_end_date IS NULL);
		   -- we never match date range purchases - as is valid to have multiple with same dates, for same product quite distinct
END;

PROCEDURE GetPurchase (
	in_component_code		IN	component.component_code%TYPE,
	in_start_date			IN	purchase.start_date%TYPE,
	in_end_date				IN	purchase.end_date%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
) AS
BEGIN
	INTERNAL_GetPurchase(in_component_code, null, in_start_date, in_end_date, out_cur);
END;

PROCEDURE GetPurchase (
	in_component_code		IN	component.component_code%TYPE,
	in_purchase_order		IN	purchase.purchase_order%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
) AS
BEGIN
	INTERNAL_GetPurchase(in_component_code, in_purchase_order, null, null, out_cur);
END;

PROCEDURE DownloadPurchases (
	in_component_id		IN	purchase.component_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied searching for purchases for purchased component '||in_component_id||'. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top level company');
	END IF;
	
	IF NOT capability_pkg.CheckCapability(chain.component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on purchases for purchased component'||in_component_id||' belonging to company with sid '||chain.component_pkg.GetCompanySid(in_component_id));
	END IF;
	
	
	OPEN out_cur FOR
		SELECT com.description as product_name, com.component_code as code, pur.start_date, pur.end_date, pur.amount, u.description as unit,
				NVL(ch.description, 'General') as channel, pur.invoice_number, pur.purchase_order, pur.note
		  FROM purchase pur
		  JOIN amount_unit u ON pur.amount_unit_id = u.amount_unit_id
		  LEFT JOIN chain.v$purchased_component com ON pur.component_id = com.component_id AND pur.app_sid = com.app_sid
		  LEFT JOIN purchase_channel ch ON pur.purchase_channel_id = ch.purchase_channel_id AND pur.purchaser_company_sid = ch.company_sid AND pur.app_sid = ch.app_sid
		 WHERE pur.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND pur.purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		   AND pur.component_id = in_component_id
		 ORDER BY pur.start_date DESC;
END;

-- TO DO - this is a temporary procedure to "finish" adding purchases
-- This will be redundant when / if we need to move to a "timeline" model
-- but I need this for demo / reports / at the moment
PROCEDURE SetPurchaseLock (
	in_component_id			component.component_id%TYPE,
	in_purchases_locked		purchased_component.purchases_locked%TYPE
) AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied editing purchasess for product '||in_component_id||'. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top level company');
	END IF;
	
	UPDATE purchased_component SET purchases_locked = in_purchases_locked WHERE component_id = in_component_id AND app_sid = SYS_CONTEXT('SECURITY','APP');

END;

FUNCTION AreUnitsMixedForProd	(
	in_component_id			component.component_id%TYPE
) RETURN NUMBER
AS
	v_is_mismatched NUMBER;
BEGIN
	 SELECT COUNT(DISTINCT unit_type)  
	   INTO v_is_mismatched
	   FROM purchase p
	   JOIN amount_unit au ON p.amount_unit_id = au.amount_unit_id AND p.app_sid = au.app_sid
	  WHERE p.component_id = in_component_id;
	  
	IF v_is_mismatched <=1 THEN 
		RETURN 0;
	ELSE
		RETURN 1;
	END IF;
END;

--moved from company_pkg
PROCEDURE GetSupplierNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_show_all_components		NUMBER(1, 0) DEFAULT CASE WHEN helper_pkg.ShowAllComponents = 1 OR company_user_pkg.IsCompanyAdmin = 1 OR helper_pkg.IsChainAdmin THEN 1 ELSE 0 END;
	v_company_sids				security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	-- Show all suppliers we have bought from - whether fully registered or not
	
	--using CheckPermission as an SQL function might cause a DML error - check permission in a loop instead
	--alternative: call explicitly FillUserGroups 
	FOR r IN (  
	   SELECT DISTINCT supplier_company_sid company_sid, supplier_name name, q.questionnaire_id
		 FROM v$purchased_component pc
		 LEFT JOIN questionnaire q ON pc.supplier_product_id = q.component_id
		WHERE pc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  AND pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  AND supplier_company_sid IS NOT NULL
		  AND pc.deleted = 0
		  AND supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  AND (q.questionnaire_id IS NOT NULL OR v_show_all_components = 1 OR pc.created_by_sid = SYS_CONTEXT('SECURITY', 'SID'))
		UNION
		--TODO: we could unify this to a single query
	   SELECT DISTINCT uninvited_supplier_sid company_sid, uninvited_name name, NULL questionnaire_id
		 FROM v$purchased_component pc
		WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  AND uninvited_supplier_sid IS NOT NULL
		  AND pc.deleted = 0
		  AND uninvited_supplier_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	  )
	LOOP
		IF r.questionnaire_id IS NULL OR questionnaire_security_pkg.CheckPermission(r.questionnaire_id, chain_pkg.QUESTIONNAIRE_VIEW) THEN
			v_company_sids.EXTEND;
			v_company_sids(v_company_sids.COUNT) := r.company_sid;
		END IF;
	END LOOP; 
	
	OPEN out_cur FOR 
		SELECT DISTINCT c.company_sid, c.name 
		  FROM TABLE(v_company_sids) t
		  JOIN chain.company c ON t.column_value = c.company_sid		 
		 ORDER BY LOWER(c.name) ASC;
	
END;


END purchased_component_pkg;
/
