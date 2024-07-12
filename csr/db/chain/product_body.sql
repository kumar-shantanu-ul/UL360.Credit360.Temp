CREATE OR REPLACE PACKAGE BODY CHAIN.product_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/
FUNCTION CheckCapability (
	in_product_id			IN  product.product_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_component_id			component.component_id%TYPE;
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT root_component_id
		  INTO v_component_id
		  FROM v$product
		 WHERE product_id = in_product_id
		   AND rownum = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	v_company_sid := NVL(component_pkg.GetCompanySid(v_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	
	RETURN capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, in_permission_set);
END;

PROCEDURE CheckCapability (
	in_product_id			IN  product.product_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
	v_component_id			component.component_id%TYPE;
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckCapability(in_product_id, in_permission_set)  THEN
		
		BEGIN
			SELECT root_component_id
			  INTO v_component_id
			  FROM v$product
			 WHERE product_id = in_product_id
			   AND rownum = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
		
		v_company_sid := NVL(component_pkg.GetCompanySid(v_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		
		IF in_permission_set = security_pkg.PERMISSION_WRITE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to products for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_READ THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_DELETE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to products for company with sid '||v_company_sid);
		
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied (perm_set:'||in_permission_set||') to products for company with sid '||v_company_sid);
		
		END IF;
	END IF;
END;

PROCEDURE CollectToCursor (
	in_product_ids			IN  T_NUMERIC_TABLE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT	x.product_id, x.supplier_root_component_id, x.validated_root_component_id, x.active, x.code1, x.code2, x.code3, x.notes,
				x.need_review, x.description, x.company_sid, x.created_by_sid, x.created_dtm, status,
				x.published, x.last_published_dtm, x.last_published_by_user_sid, x.validation_status_id, x.validation_status_description,
				can_start_edit, can_start_validation, min_published_per_product_id, first_unpublished_revision_num
		  FROM (
			SELECT p.product_id, p.supplier_root_component_id, p.validated_root_component_id, p.active, p.code1, p.code2, p.code3, p.notes,
				p.need_review, p.description, p.company_sid, p.created_by_sid, p.created_dtm,
				CASE WHEN published=1 THEN 'Closed' ELSE 'Open' END status,
				p.published, p.last_published_dtm, p.last_published_by_user_sid, p.validation_status_id, p.validation_status_description,
				CASE
					WHEN p.validation_status_id IN (chain_pkg.NOT_YET_VALIDATED, chain_pkg.VALIDATED, chain_pkg.VALIDATION_NEEDS_REVIEW) THEN 1
					ELSE 0
				END can_start_edit,
				CASE
					WHEN p.validation_status_id IN (chain_pkg.NOT_YET_VALIDATED, chain_pkg.VALIDATED, chain_pkg.VALIDATION_NEEDS_REVIEW) THEN 1
					ELSE 0
				END can_start_validation,
				MIN (p.published) OVER (PARTITION BY product_id) min_published_per_product_id,
				FIRST_VALUE (p.revision_num) OVER (PARTITION BY product_id ORDER BY published, revision_num) first_unpublished_revision_num,
				ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY revision_num DESC) rn
			  FROM v$product_all_revisions p
			  JOIN TABLE(in_product_ids) i ON p.product_id = i.item
			 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 ORDER BY i.pos
		 )x
		 WHERE x.rn = 1;
END;

/**********************************************************************************
	PRODUCT CALLS
**********************************************************************************/

PROCEDURE Internal_CheckUniqueProductSKU(
	in_product_id			IN  product.product_id%TYPE,
	in_code1				IN  chain_pkg.T_COMPONENT_CODE
)
AS
	v_count					NUMBER;
BEGIN
	--count of the not marked as deleted existing products with the same SKU (code1)
	SELECT COUNT(*)
	  INTO v_count  
      FROM v$product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND product_id != NVL(in_product_id, 0)
	   AND lower(code1) = lower(in_code1)	   
	   AND deleted = 0;
	
	IF v_count > 0 THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A product with the same SKU code exists already');
	END IF;
END;

FUNCTION GetLastRevisionPseudoRootCmpId(
	in_product_id		product.product_id%TYPE
) RETURN product_revision.supplier_root_component_id%TYPE
AS
	v_supplier_root_component_id	product_revision.supplier_root_component_id%TYPE;
BEGIN
	SELECT supplier_root_component_id
	  INTO v_supplier_root_component_id
	  FROM v$product_last_revision
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id = in_product_id;
	
	RETURN v_supplier_root_component_id;
END;

FUNCTION SaveProduct (
	in_product_id			IN  product.product_id%TYPE,
    in_description			IN  component.description%TYPE,
    in_code1				IN  chain_pkg.T_COMPONENT_CODE,
    in_code2				IN  chain_pkg.T_COMPONENT_CODE,
    in_code3				IN  chain_pkg.T_COMPONENT_CODE,
    in_notes				IN  product_revision.notes%TYPE,
	in_user_sid				security.security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
) RETURN NUMBER
AS
	v_product_id			product.product_id%TYPE DEFAULT CASE WHEN NVL(in_product_id, 0) > 0 THEN in_product_id ELSE NULL END;
	v_pct					product_code_type%ROWTYPE;
	v_revision_num	 		product_revision.revision_num%TYPE;
	v_rev_start_date		product_revision.revision_start_dtm%TYPE;
	v_supplier_root_component_id	product_revision.supplier_root_component_id%TYPE;	
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
		
	-- this will do in the place of a NOT NULL on the column (not all components require a code)
	IF in_code1 IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'A product cannot have NULL component_code (code1)');
	END IF;	
		
	-- we select this into a variable to be sure that the entry exists, an insert based on select would fail silently
	SELECT *
	  INTO v_pct
	  FROM product_code_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	-- Do these on save only, rather than forcing a table constraint, so that the mandatoryness can be changed by the user without constraint errors
	IF v_pct.code2_mandatory=1 AND in_code2 IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'A product cannot have NULL code2 when product_code_type has code2_mandatory set');
	END IF;
	IF v_pct.code3_mandatory=1 AND in_code3 IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'A product cannot have NULL code3 when product_code_type has code2_mandatory set');
	END IF;
	
	IF v_product_id IS NOT NULL THEN		
		--get the last revision for this product
		SELECT revision_num, supplier_root_component_id, company_sid
		  INTO v_revision_num, v_supplier_root_component_id, v_company_sid
		  FROM chain.v$product
		 WHERE app_sid = security_pkg.GetApp
		   AND product_id = in_product_id;
		
		IF v_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
			RAISE_APPLICATION_ERROR(-20001, 'Product with ID:'|| v_product_id ||' can only be edited by company with sid:' || v_company_sid);
		END IF;
		
		v_supplier_root_component_id := component_pkg.SaveComponent(
			in_component_id	 	=> v_supplier_root_component_id, 
			in_type_id		 	=> chain_pkg.PRODUCT_COMPONENT, 
			in_description		=> in_description, 
			in_component_code	=> in_code1
		);
		
		UPDATE product_revision pr
		   SET pr.code2 = in_code2,
			   pr.code3 = in_code3,
			   pr.notes = in_notes
		 WHERE pr.app_sid = security_pkg.GetApp
		   AND pr.product_id = v_product_id
		   AND pr.revision_num = v_revision_num;
	ELSE
		v_supplier_root_component_id := component_pkg.SaveComponent(
			in_component_id	 	=> -1, 
			in_type_id		 	=> chain_pkg.PRODUCT_COMPONENT, 
			in_description		=> in_description, 
			in_component_code	=> in_code1,
			in_user_sid			=> in_user_sid
		);
		
		SELECT product_id_seq.NEXTVAL
		  INTO v_product_id
		  FROM dual;
		  
		v_rev_start_date := chain_link_pkg.GetDefaultRevisionStartDate;
		 
		INSERT INTO product(product_id)	VALUES (v_product_id);
		
		INSERT INTO product_revision(product_id, supplier_root_component_id, code2, code3, notes, revision_num, revision_start_dtm, revision_created_by_sid)
			VALUES(v_product_id, v_supplier_root_component_id, in_code2, in_code3, in_notes, 1, v_rev_start_date, in_user_sid);
		
		chain_link_pkg.AddProduct(v_product_id);
	END IF;
	
	-- check if the SKU is unique per company for products, not transaction safe
	Internal_CheckUniqueProductSKU(v_product_id, in_code1); 
	
	RETURN v_product_id;
END;

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
)
AS
	v_supplier_root_component_id		component.component_id%TYPE;
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	FOR r IN (
		SELECT supplier_root_component_id, validated_root_component_id
		  FROM product_revision
		 WHERE product_id = in_product_id
	) LOOP
		IF r.validated_root_component_id IS NOT NULL THEN
			component_pkg.DeleteComponent(r.validated_root_component_id);
		END IF;
		
		component_pkg.DeleteComponent(r.supplier_root_component_id);
	END LOOP;
END;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
) 
AS
	v_count_mapped			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count_mapped
	  FROM v$purchased_component pc
	  JOIN v$product p ON pc.supplier_product_id = p.product_id
	 WHERE pc.app_sid = security_pkg.GetApp
	   AND pc.deleted = chain_pkg.NOT_DELETED
	   AND p.root_component_id = in_component_id
	   AND pc.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	IF v_count_mapped>0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not delete component with id: '||in_component_id||'. Component is mapped to purchased components of another company');
	END IF;
END;

PROCEDURE GetValidationStatuses(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT validation_status_id, description
		  FROM validation_status;
END;

PROCEDURE PublishProduct (
	in_product_id		IN product.product_id%TYPE,
	in_revision_no		IN product_revision.revision_num%TYPE DEFAULT NULL
)
AS
	v_component_id		component.component_id%TYPE;
	v_validation_status_id		product_revision.validation_status_id%TYPE;
	v_revision_no		product_revision.revision_num%TYPE;
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	IF in_revision_no IS NOT NULL THEN
		v_revision_no := in_revision_no;
	ELSE
		SELECT MAX(revision_num)
		  INTO v_revision_no
		  FROM product_revision
		 WHERE app_sid = security_pkg.GetApp
		   AND product_id = in_product_id;
	END IF;
	
	SELECT validation_status_id
	  INTO v_validation_status_id
	  FROM product_revision
	 WHERE app_sid = security.security_pkg.GetApp
	   AND product_id = in_product_id
	   AND revision_num = v_revision_no;
	
	IF v_validation_status_id <> chain_pkg.INITIAL_VALIDATION_STATUS THEN
		RAISE_APPLICATION_ERROR(-20001, 'Couldn''t publish product with id '||in_product_id||' as it is not in the initial status.');
	END IF;
	
	UPDATE product_revision pr
	   SET pr.published = 1,
	       pr.last_published_by_user_sid = security_pkg.GetSid,
	       pr.last_published_dtm = SYSDATE,
		   pr.validation_status_id = NVL2(pr.validated_root_component_id, chain_pkg.VALIDATION_NEEDS_REVIEW, chain_pkg.NOT_YET_VALIDATED)
	 WHERE pr.app_sid = security_pkg.GetApp
	   AND pr.product_id = in_product_id
	   AND pr.revision_num = v_revision_no
 RETURNING supplier_root_component_id
	  INTO v_component_id;
	
	IF NOT HasMappedUnpublishedProducts(component_pkg.GetCompanySid(v_component_id)) THEN
		message_pkg.CompleteMessageIfExists (
			in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
			in_to_company_sid	  	 	=> component_pkg.GetCompanySid(v_component_id)
		);
	END IF;
END;

PROCEDURE EditProduct (
	in_product_id		   IN product.product_id%TYPE,
	in_revision_no			IN	product_revision.revision_num%TYPE DEFAULT NULL
)
AS
	v_component_id		component.component_id%TYPE;
	v_validation_status_id	product_revision.validation_status_id%TYPE;
	v_revision_no		product_revision.revision_num%TYPE;
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	IF in_revision_no IS NOT NULL THEN
		v_revision_no := in_revision_no;
	ELSE
		SELECT MAX(revision_num)
		  INTO v_revision_no
		  FROM product_revision
		 WHERE app_sid = security_pkg.GetApp
		   AND product_id = in_product_id;
	END IF;
	
	SELECT validation_status_id
	  INTO v_validation_status_id
	  FROM product_revision
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id = in_product_id
	   AND revision_num = v_revision_no;
	
	IF v_validation_status_id NOT IN (chain_pkg.NOT_YET_VALIDATED, chain_pkg.VALIDATED, chain_pkg.VALIDATION_NEEDS_REVIEW) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot edit product with id '||in_product_id||' as it is not in the correct validation status.');
	END IF;
	
	UPDATE product_revision pr
	   SET pr.published = 0,
		   pr.validation_status_id = chain_pkg.INITIAL_VALIDATION_STATUS
	 WHERE pr.app_sid = security.security_pkg.GetApp
	   AND pr.product_id = in_product_id
	   AND pr.revision_num = v_revision_no
 RETURNING supplier_root_component_id
	  INTO v_component_id;
	
	IF HasMappedUnpublishedProducts(component_pkg.GetCompanySid(v_component_id)) THEN
		message_pkg.TriggerMessage (
			in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
			in_to_company_sid	  	 	=> component_pkg.GetCompanySid(v_component_id)
		);
	END IF;
END;


PROCEDURE GetProduct (
	in_product_id			IN  product.product_id%TYPE,
	in_revision_no			IN	product_revision.revision_num%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_revision_no			product_revision.revision_num%TYPE;
BEGIN
	IF in_revision_no IS NOT NULL THEN
		v_revision_no := in_revision_no;
	ELSE
		SELECT MAX(revision_num)
		  INTO v_revision_no
		  FROM product_revision
		 WHERE app_sid = security_pkg.GetApp
		   AND product_id = in_product_id;
	END IF;
	-- if the supply chain is transparent for this company and the logged on company is in the supply chain for this product / component 
	IF NOT (component_pkg.CanSeeComponentAsChainTrnsprnt(in_product_id)) THEN
		CheckCapability(in_product_id, security_pkg.PERMISSION_READ);
	END IF;
	
	OPEN out_cur FOR
		SELECT p.product_id, p.supplier_root_component_id, p.validated_root_component_id, p.active, p.code1, p.code2, p.code3, p.notes,
				p.need_review, p.description, p.company_sid, p.created_by_sid, p.created_dtm,
				CASE WHEN published=1 THEN 'Closed' ELSE 'Open' END status,
				p.published, p.last_published_dtm, p.last_published_by_user_sid, p.validation_status_id, p.validation_status_description, 
				CASE
					WHEN p.validation_status_id IN (chain_pkg.NOT_YET_VALIDATED, chain_pkg.VALIDATED, chain_pkg.VALIDATION_NEEDS_REVIEW) THEN 1
					ELSE 0
				END can_start_edit,
				CASE
					WHEN p.validation_status_id IN (chain_pkg.NOT_YET_VALIDATED, chain_pkg.VALIDATED, chain_pkg.VALIDATION_NEEDS_REVIEW)  THEN 1
					ELSE 0
				END can_start_validation, p.revision_num, p.revision_start_dtm, p.revision_end_dtm
		  FROM v$product_all_revisions p
		 WHERE p.app_sid = security_pkg.GetApp
		   AND p.product_id = in_product_id
		   AND p.deleted = chain_pkg.NOT_DELETED
		   AND p.revision_num = v_revision_no;
END;

PROCEDURE GetProductRevisions (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT product_id, description, supplier_root_component_id, published, revision_num, revision_start_dtm, revision_end_dtm
		  FROM v$product_all_revisions
		 WHERE app_sid = security_pkg.GetApp
		   AND product_id = in_product_id
		 ORDER BY revision_num;
END;

PROCEDURE GetProducts (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||in_company_sid);
	END IF;	
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
		SELECT product_id
		  FROM v$product
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND deleted = chain_pkg.NOT_DELETED
		 ORDER BY LOWER(description), LOWER(code1)
		);
	
	CollectToCursor(v_product_ids, out_cur);
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
)
AS
	v_top_component_ids		T_NUMERIC_TABLE;
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM TT_PRODUCT_COMPONENT_TREE
	 WHERE top_component_id = in_top_component_id;
	
	-- if we've already got entries, get out
	IF v_count > 0 THEN
		RETURN;
	END IF;
	
	SELECT T_NUMERIC_ROW(in_top_component_id, NULL)
	  BULK COLLECT INTO v_top_component_ids
	  FROM DUAL;
	
	RecordTreeSnapshot(v_top_component_ids);
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
)
AS
BEGIN
	component_pkg.RecordTreeSnapshot(in_top_component_ids);
	
	INSERT INTO TT_PRODUCT_COMPONENT_TREE (top_component_id, top_product_id)
	SELECT DISTINCT t.item, p.product_id
	  FROM TABLE(in_top_component_ids) t
	  JOIN v$product_last_revision p ON p.validated_root_component_id = t.item OR p.supplier_root_component_id = t.item
	 WHERE item NOT IN (
			SELECT top_component_id
			  FROM TT_PRODUCT_COMPONENT_TREE
	 );
END;

-- this is required for component implementation
PROCEDURE GetComponent (
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetProduct(in_component_id, NULL, out_cur);
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
)
AS
BEGIN
	RecordTreeSnapshot(in_top_component_id);
	
	OPEN out_cur FOR
		SELECT p.product_id, p.supplier_root_component_id, p.validated_root_component_id, p.active, p.code1, p.code2, p.code3, p.notes,
				p.need_review, p.description, p.company_sid, p.created_by_sid, p.created_dtm,
				CASE WHEN p.published = 1 THEN 'Closed' ELSE 'Open' END status,
				p.published, p.last_published_dtm, p.last_published_by_user_sid, in_top_component_id comp_id
		  FROM v$product_all_revisions p
		  JOIN TT_COMPONENT_TREE ct ON p.validated_root_component_id = ct.child_component_id OR p.supplier_root_component_id = ct.child_component_id
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ct.top_component_id = in_top_component_id
		   AND in_type_id = chain_pkg.PRODUCT_COMPONENT
		   AND p.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position;
END;


PROCEDURE SearchProductsSold (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_only_show_empty_codes	IN  NUMBER,
	in_only_show_unpublished	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_top_component_ids			T_NUMERIC_TABLE;
	v_product_ids				T_NUMERIC_TABLE;
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_order_by					VARCHAR2(200) DEFAULT 'LOWER(t.'||in_sort_by||') '||in_sort_dir;
	v_total_count				NUMBER(10);
	v_record_called				BOOLEAN DEFAULT FALSE;
	v_pct						product_code_type%ROWTYPE;
BEGIN

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	---------------------------------------------------------------------------------------
	-- VALIDATE ORDERING DATA
	
	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN ('description', 'code1', 'code2', 'code3', 'status') THEN -- add as needed
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by col "'||in_sort_by||'".');
	END IF;	
	
	IF LOWER(in_sort_by) = 'status' THEN
		-- clear the order by as the only status that we have right now is 'Open'
		v_order_by := '';
	/* ELSIF LOWER(in_sort_by) = 'customer' THEN  -- Not used
		-- remap the order by
		v_order_by := 'LOWER(t.value) '||in_sort_dir; */
	END IF;
	
	-- always sub order by product description (unless ordering by description)
	IF LOWER(in_sort_by) <> 'description' THEN
		v_order_by	:= v_order_by || ', LOWER(t.description) '||in_sort_dir;
	END IF;
	
	-- Get the product code types ready for filtering on empty codes
	SELECT *
	  INTO v_pct
	  FROM product_code_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	---------------------------------------------------------------------------------------
	-- COLLECT PRODCUT IDS BASED ON INPUT
	
	-- first we'll add all product that match our search and product flags
	DELETE FROM TT_PRODUCT_RESULT_HELPER;
	INSERT INTO TT_PRODUCT_RESULT_HELPER (product_id, description, code1, code2, code3)
	SELECT p.product_id, p.description, p.code1, p.code2, p.code3
	  FROM v$product p
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND p.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   -- don't show deleted unless it's been asked for
	   AND (p.deleted = chain_pkg.NOT_DELETED OR in_show_deleted = 1)
	   -- show all products unless we want to only show needs review ones
	   AND ((p.need_review = chain_pkg.ACTIVE AND in_only_show_need_review = 1) OR in_only_show_need_review = 0)
	   AND ((p.published = 0 AND in_only_show_unpublished = 1) OR in_only_show_unpublished = 0)
	   AND (((p.code2 IS NULL AND v_pct.code_label2 IS NOT NULL) OR (p.code3 IS NULL AND v_pct.code_label3 IS NOT NULL)) OR in_only_show_empty_codes = 0)
	   AND (   LOWER(p.description) LIKE v_search
			OR LOWER(p.code1) LIKE v_search
			OR LOWER(p.code2) LIKE v_search
			OR LOWER(p.code3) LIKE v_search
		   );

	-- if we're looking at a specific purchaser company, remove any products that we don't supply to them
	IF in_purchaser_company_sid IS NOT NULL THEN
	
		DELETE FROM TT_PRODUCT_RESULT_HELPER 
		 WHERE product_id NOT IN (
		 	SELECT supplier_product_id
		 	  FROM v$purchased_component
		 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND company_sid = in_purchaser_company_sid
		 	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND supplier_product_id IS NOT NULL );-- we are trying to find who we sell this too which we can only do if this is mapped
		 
	END IF;
	
	-- if we're looking at a specific supplier company, then we need to drill down the component tree and find all of our purchased components
	IF in_supplier_company_sid IS NOT NULL THEN
		
		SELECT T_NUMERIC_ROW(p.root_component_id, rownum)
	  	  BULK COLLECT INTO v_top_component_ids
	  	  FROM TT_PRODUCT_RESULT_HELPER t
		  JOIN v$product p ON t.product_id = p.product_id;
		
		RecordTreeSnapshot(v_top_component_ids);
		v_record_called := TRUE;
		
		DELETE FROM TT_PRODUCT_RESULT_HELPER
		 WHERE product_id NOT IN (
		 	SELECT pt.top_product_id
		 	  FROM TT_COMPONENT_TREE ct
			  JOIN TT_PRODUCT_COMPONENT_TREE pt ON ct.top_component_id = pt.top_component_id
			  JOIN v$purchased_component pc ON pc.component_id = ct.child_component_id
			  JOIN TT_PRODUCT_RESULT_HELPER i ON pt.top_product_id = i.product_id
		 	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND pc.supplier_company_sid = in_supplier_company_sid
		 	   AND pc.deleted = chain_pkg.NOT_DELETED
		 );
		 
	END IF;
	
	---------------------------------------------------------------------------------------
	-- APPLY THE ORDERING
	DELETE FROM TT_ID;
	
	EXECUTE IMMEDIATE ''||
		'INSERT INTO TT_ID (id, position)'||
		'	SELECT product_id, rownum'||
		'	  FROM('||
		'		SELECT product_id '||
		'	  	  FROM TT_PRODUCT_RESULT_HELPER t'|| 
		'	 	 ORDER BY '||v_order_by||
		'	 )';
 
		---------------------------------------------------------------------------------------
	-- APPLY PAGING
	
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE FROM TT_ID
	 WHERE position <= NVL(in_start, 0)
	    OR position > NVL2(in_page_size, in_start + in_page_size, v_total_count);
		
	
	
	---------------------------------------------------------------------------------------
	-- COLLECT SEARCH RESULTS
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
	
	OPEN out_purchaser_cur FOR
		SELECT DISTINCT pc.supplier_product_id product_id, c.company_sid, c.name
		  FROM v$purchased_component pc
		  JOIN company c ON pc.app_sid = c.app_sid AND pc.company_sid = c.company_sid
		  JOIN TT_ID i ON pc.supplier_product_id = i.id
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.deleted = chain_pkg.NOT_DELETED
		   AND c.deleted = 0
		   AND c.pending = 0
	 	 ORDER BY LOWER(c.name);
	
	
	IF NOT v_record_called THEN
		SELECT T_NUMERIC_ROW(p.root_component_id, rownum)
	  	  BULK COLLECT INTO v_top_component_ids
	  	  FROM TT_ID t
		  JOIN v$product p ON t.id = p.product_id;

		RecordTreeSnapshot(v_top_component_ids);
	END IF;
	
	OPEN out_supplier_cur FOR
		SELECT *
		  FROM (
			SELECT i.id product_id, c.company_sid, c.name
			  FROM TT_COMPONENT_TREE ct
			  JOIN TT_PRODUCT_COMPONENT_TREE pt ON ct.top_component_id = pt.top_component_id
			  JOIN TT_ID i ON pt.top_product_id = i.id
			  JOIN v$purchased_component pc ON pc.component_id = ct.child_component_id
			  JOIN company c ON pc.app_sid = c.app_sid AND pc.supplier_company_sid = c.company_sid
			 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND pc.deleted = chain_pkg.NOT_DELETED
			   AND c.deleted = chain_pkg.NOT_DELETED
			UNION
			SELECT i.id product_id, us.uninvited_supplier_sid, us.name
			  FROM TT_COMPONENT_TREE ct
			  JOIN TT_PRODUCT_COMPONENT_TREE pt ON ct.top_component_id = pt.top_component_id
			  JOIN TT_ID i ON pt.top_product_id = i.id
			  JOIN v$purchased_component pc ON pc.component_id = ct.child_component_id
			  JOIN uninvited_supplier us ON pc.app_sid = us.app_sid AND pc.uninvited_supplier_sid = us.uninvited_supplier_sid
			 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND pc.deleted = chain_pkg.NOT_DELETED
			)
	 	 ORDER BY LOWER(name);
		 
	SELECT T_NUMERIC_ROW(id, position)
	  BULK COLLECT INTO v_product_ids
	  FROM TT_ID;
	
	CollectToCursor(v_product_ids, out_product_cur);
END;

PROCEDURE GetRecentProducts (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
			SELECT product_id
			  FROM v$product
			 WHERE created_by_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND created_dtm > SYSDATE - 7 -- let's give them a week as the row limit will take care of too many
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND deleted = 0
			 ORDER BY created_dtm DESC
			)
	 WHERE rownum <= 3;
	
	CollectToCursor(v_product_ids, out_cur);
END;


PROCEDURE GetProductCodes (
	in_company_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	IF NOT ((company_pkg.CanSeeCompanyAsChainTrnsprnt(in_company_sid)) OR (capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)))  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product code types for company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT code_label1, code_label2, code_label3, code2_mandatory, code3_mandatory
		  FROM product_code_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductCodes (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_code_label1					IN  product_code_type.code_label1%TYPE,
	in_code_label2					IN  product_code_type.code_label2%TYPE,
	in_code_label3					IN  product_code_type.code_label3%TYPE,
	in_code2_mandatory				IN  product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory				IN 	product_code_type.code3_mandatory%TYPE,
	out_products_with_empty_codes	OUT NUMBER,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_pct					product_code_type%ROWTYPE;
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;
	
	SELECT *
	  INTO v_pct
	  FROM product_code_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	-- If a field has been made mandatory, count the number of products that will be affected
	IF (v_pct.code2_mandatory=0 AND in_code2_mandatory=1) OR (v_pct.code3_mandatory=0 AND in_code3_mandatory=1) THEN
		SELECT COUNT(*)
		  INTO out_products_with_empty_codes
		  FROM v$product p
		  JOIN product_code_type pct ON p.app_sid = pct.app_sid AND p.company_sid = pct.company_sid
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.company_sid =in_company_sid
		   AND ((pct.code2_mandatory=0 AND in_code2_mandatory=1 AND p.code2 IS NULL)
			OR ( pct.code3_mandatory=0 AND in_code3_mandatory=1 AND p.code3 IS NULL));
	ELSE
		out_products_with_empty_codes := 0;
	END IF;
	
	-- If a code label has been removed, remove the value of that code for all products in that company
	IF v_pct.code_label2 IS NOT NULL AND in_code_label2 IS NULL THEN
		UPDATE product_revision pr
		   SET pr.code2 = NULL
		  WHERE pr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND EXISTS (
			SELECT 1
			  FROM component c
			 WHERE c.app_sid = pr.app_sid
			   AND c.component_id = pr.supplier_root_component_id
			   AND c.company_sid = in_company_sid
		   )
		   AND pr.code2 IS NOT NULL
		   AND pr.revision_num = (
				SELECT MAX(revision_num)
				  FROM product_revision pr2
				 WHERE pr2.app_sid = pr.app_sid
				   AND pr2.product_id = pr.product_id
			   ); 
	END IF;
	IF v_pct.code_label3 IS NOT NULL AND in_code_label3 IS NULL THEN
		UPDATE product_revision pr
		   SET pr.code3 = NULL
		  WHERE pr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND EXISTS (
			SELECT 1
			  FROM component c
			 WHERE c.app_sid = pr.app_sid
			   AND c.component_id = pr.supplier_root_component_id
			   AND c.company_sid = in_company_sid
		   )
		   AND pr.code3 IS NOT NULL
		   AND pr.revision_num = (
				SELECT MAX(revision_num)
				  FROM product_revision pr2
				 WHERE pr2.app_sid = pr.app_sid
				   AND pr2.product_id = pr.product_id
			   ); 
	END IF;
	
	UPDATE product_code_type
	   SET code_label1 = TRIM(in_code_label1),
		   code_label2 = TRIM(in_code_label2),
		   code_label3 = TRIM(in_code_label3),
		   code2_mandatory = CASE WHEN in_code_label2 IS NULL THEN 0 ELSE in_code2_mandatory END,
		   code3_mandatory = CASE WHEN in_code_label3 IS NULL THEN 0 ELSE in_code3_mandatory END
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	GetNonEmptyProductCodes(in_company_sid, out_cur);
END;

PROCEDURE GetNonEmptyProductCodes (
	in_company_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT COUNT(CASE WHEN (code2 IS NOT NULL AND pct.code_label2 IS NOT NULL) THEN p.product_id ELSE NULL END) code2_count,
				COUNT(CASE WHEN (code3 IS NOT NULL AND pct.code_label3 IS NOT NULL) THEN p.product_id ELSE NULL END) code3_count
		  FROM v$product p
		  JOIN product_code_type pct ON p.app_sid = pct.app_sid AND p.company_sid = pct.company_sid
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.company_sid = in_company_sid
		   AND (code2 IS NOT NULL OR code3 IS NOT NULL)
		   AND (pct.code_label2 IS NOT NULL OR pct.code_label2 IS NOT NULL);
END;

PROCEDURE SetProductCodeDefaults (
	in_company_sid			IN  company.company_sid%TYPE
)
AS 
BEGIN
	-- we'll let this blow up if it already exists because I'm not sure what the correct response is if this is called twice
	INSERT INTO product_code_type 
	(company_sid) 
	VALUES (in_company_sid);
END;


PROCEDURE GetMappingApprovalRequired (
	in_company_sid					IN  company.company_sid%TYPE,
	out_mapping_approval_required	OUT	product_code_type.mapping_approval_required%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product codes for company with sid '||in_company_sid);
	END IF;

	SELECT mapping_approval_required
	  INTO out_mapping_approval_required
	  FROM product_code_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetMappingApprovalRequired (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	product_code_type.mapping_approval_required%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;

	UPDATE product_code_type
	   SET mapping_approval_required = in_mapping_approval_required
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductActive (
	in_product_id			IN  product.product_id%TYPE,
    in_active				IN  product_revision.active%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);

	UPDATE product_revision pr
	   SET pr.active = in_active
	 WHERE pr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pr.product_id = in_product_id
	   AND pr.revision_num = (
				SELECT MAX(revision_num)
				  FROM product_revision pr2
				 WHERE pr2.app_sid = security_pkg.GetApp
				   AND pr2.product_id = in_product_id
			   );
END;


PROCEDURE SetProductNeedsReview (
	in_product_id			IN  product.product_id%TYPE,
    in_need_review			IN  product_revision.need_review%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	UPDATE product_revision pr
	   SET pr.need_review = in_need_review
	 WHERE pr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pr.product_id = in_product_id
	   AND pr.revision_num = (
				SELECT MAX(revision_num)
				  FROM product_revision pr2
				 WHERE pr2.app_sid = security_pkg.GetApp
				   AND pr2.product_id = in_product_id
			   );
END;

FUNCTION HasMappedUnpublishedProducts (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$product_all_revisions p
	  JOIN v$purchased_component pc ON p.product_id = pc.supplier_product_id AND p.app_sid = pc.app_sid
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND p.company_sid = in_company_sid
	   AND p.published = 0
	   AND p.deleted = 0
	   AND pc.deleted = 0;
	
	RETURN v_count > 0;
END;

/**********************************************************************************
	COPY PRODUCT
**********************************************************************************/
/*** PRIVATE ***/

/* CopyDocuments: Copies all entries under the component_document table for in_from_component_id to in_to_component_id (creates new SOs for them) */
PROCEDURE CopyComponentDocuments(
	in_from_component_id			  		IN component.component_id%TYPE,
	in_to_component_id						IN component.component_id%TYPE
)
AS
	v_from_company_sid 					security.security_pkg.T_SID_ID;
	v_to_company_sid 						security.security_pkg.T_SID_ID;

BEGIN

	SELECT company_sid 
	  INTO v_from_company_sid
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_from_component_id; 
	   
	SELECT company_sid 
	  INTO v_to_company_sid 
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_to_component_id; 

--copy over any documents for top component
--copy each individual file over to the new company (otherwise we can't access it since the links will point to the old company and there will be a context mismatch)
FOR r IN (
	SELECT *
	   FROM component_document 
	WHERE component_id = in_from_component_id 
		 AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		DECLARE
			v_new_file_sid security.security_pkg.T_SID_ID;
			v_parent_sid security.security_pkg.T_SID_ID;
		BEGIN
			--get parent sid ('Uploads')
			SELECT parent_sid_id 
				 INTO v_parent_sid
			   FROM security.securable_object
			WHERE sid_id = r.file_upload_sid;
			  
			--create new so for file copy
			security.SecurableObject_pkg.CreateSO(SYS_CONTEXT('SECURITY', 'ACT'), v_parent_sid, class_pkg.GetClassID('ChainFileUpload'), NULL, v_new_file_sid);
			  
			--copy file upload
		   INSERT INTO file_upload (app_sid, file_upload_sid, company_sid, download_permission_id, filename, mime_type, data, sha1, last_modified_dtm, lang, last_modified_by_sid) 
					SELECT app_sid, v_new_file_sid file_upload_sid, v_to_company_sid company_sid, download_permission_id, filename, mime_type, data, sha1, last_modified_dtm, lang, last_modified_by_sid
					    FROM file_upload
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND file_upload_sid = r.file_upload_sid;
			  
			--copy component_document
		   INSERT INTO  component_document (app_sid, component_id, file_upload_sid, key)			   
					SELECT app_sid, in_to_component_id component_id, v_new_file_sid file_upload_sid, key
						FROM component_document
					 WHERE component_id = in_from_component_id
						   AND file_upload_sid = r.file_upload_sid
						   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		END;
END LOOP;
END;

-- creates new component using some of the basic data from the provided component (this creates the component for the company currently set in context)
FUNCTION CopyCreateComponentBase(
	in_component_id			  					IN component.component_id%TYPE,
	in_from_company_sid 						IN security.security_pkg.T_SID_ID
) RETURN component.component_id%TYPE
AS
	v_type_id				  						chain_pkg.T_COMPONENT_TYPE;
	v_description			  					component.description%TYPE;
	v_component_code		  			component.component_code%TYPE;
	v_component_notes		  			component.component_notes%TYPE;
BEGIN
	SELECT component_type_id, description, component_code, component_notes 
	  INTO v_type_id, v_description, v_component_code, v_component_notes
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id
	   AND company_sid = in_from_company_sid;

	RETURN component_pkg.SaveComponent ( --company sid is the current context company
		in_component_id	=> -1, --create new 
		in_type_id	=> v_type_id,
		in_description	=> v_description,
		in_component_code	=> v_component_code,
		in_component_notes	=> v_component_notes
	);
END;

PROCEDURE SetContextCompany(
	in_company_sid 						IN security.security_pkg.T_SID_ID,
	out_context_company_sid			OUT security.security_pkg.T_SID_ID
)
AS
BEGIN
	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NULL THEN
		IF company_pkg.TrySetCompany(in_company_sid) = 0 THEN 
			RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Unable to set company ' || in_company_sid || ' in context.');
		END IF;
	ELSIF company_pkg.GetCompany <> in_company_sid THEN
		-- save existing context company so it can be set back once copying is done
		out_context_company_sid :=  SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		--set in_to_company in context; needed for creating new components	
		IF company_pkg.TrySetCompany(in_company_sid) = 0 THEN 
			RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Unable to set company ' || in_company_sid || ' in context.');
		END IF;
	END IF;
END;

PROCEDURE ReSetContextCompany(
	in_context_company_sid			IN security.security_pkg.T_SID_ID
)
AS
BEGIN
	IF  in_context_company_sid IS NOT NULL AND company_pkg.GetCompany <> in_context_company_sid THEN
		IF company_pkg.TrySetCompany(in_context_company_sid) = 0 THEN 
			RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Unable to set company ' || in_context_company_sid || ' in context.');
		END IF;
	END IF;
END;

PROCEDURE CopyComponent (
	in_component_id			  					IN component.component_id%TYPE,
	in_from_company_sid 						IN security.security_pkg.T_SID_ID,
	in_to_company_sid							IN security.security_pkg.T_SID_ID, --if this is the same as in_from_company, simply make a copy within the same company
	in_container_component_id					IN component.component_id%TYPE DEFAULT NULL,
	in_new_container_component_id				IN component.component_id%TYPE DEFAULT NULL,
	in_for_validation							IN BOOLEAN,
	out_new_component_id						OUT component.component_id%TYPE
)
AS
	v_new_child_comp_id				component.component_id%TYPE;
	v_count_purchased_component		NUMBER;
	v_context_company_sid 			security.security_pkg.T_SID_ID DEFAULT NULL;
BEGIN

	SetContextCompany(in_to_company_sid, v_context_company_sid);

	SELECT COUNT(*) 
	  INTO v_count_purchased_component 
	  FROM purchased_component pc
	  JOIN component c ON pc.app_sid = c.app_sid AND pc.component_id = c.component_id
	 WHERE c.company_sid = in_from_company_sid
	   AND c.component_id = in_component_id
	   AND pc.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	out_new_component_id := CopyCreateComponentBase(in_component_id, in_from_company_sid);
	
	IF v_count_purchased_component > 0 THEN --this is a purchased component
		IF in_for_validation THEN
			INSERT INTO validated_purchased_component(component_id, mapped_purchased_component_id)
			VALUES (out_new_component_id, in_component_id);
			
			UPDATE component
			   SET component_type_id = chain_pkg.VALIDATED_PURCHASED_COMPONENT
			 WHERE app_sid = security_pkg.GetApp
			   AND component_id = out_new_component_id;
		ELSE
			INSERT INTO purchased_component (component_id, previous_purch_component_id, company_sid, supplier_company_sid, component_type_id, component_supplier_type_id, acceptance_status_id,
												uninvited_supplier_sid, supplier_product_id, mapped_dtm, mapped_by_user_sid, purchases_locked)
			SELECT out_new_component_id, in_component_id, in_to_company_sid, supplier_company_sid, component_type_id, component_supplier_type_id, acceptance_status_id,
					uninvited_supplier_sid, supplier_product_id, mapped_dtm, mapped_by_user_sid, purchases_locked
			  FROM purchased_component
			 WHERE app_sid = security_pkg.GetApp
			   AND component_id = in_component_id;
		END IF;
	END IF;
	
	-- if in_container_component_id is not null this is not a "top level" component so we DO need to copy component relations for it
	IF in_container_component_id IS NOT NULL THEN
		UPDATE chain.component c
		   SET (parent_component_id, parent_component_type_id, position, amount_child_per_parent, amount_unit_id) = (
				SELECT in_new_container_component_id, parent_component_type_id, position, amount_child_per_parent, amount_unit_id 
				  FROM component c2
				 WHERE c2.parent_component_id = in_container_component_id
				   AND component_id = in_component_id
				   AND company_sid = in_from_company_sid
			   )
		 WHERE app_sid = security_pkg.GetApp
		   AND component_id = out_new_component_id;
	END IF;

	CopyComponentDocuments(in_component_id, out_new_component_id);

	--call any client specific copy logic we might have (like wood components for RFA)
	chain_link_pkg.CopyComponent(in_component_id, out_new_component_id, in_from_company_sid, in_to_company_sid, in_container_component_id, in_new_container_component_id);

	--recursive call to copy any child components
	FOR r IN (
	   SELECT component_id
		 FROM component
		WHERE app_sid = security_pkg.GetApp
		  AND parent_component_id = in_component_id
		  AND company_sid = in_from_company_sid
	) LOOP
		 CopyComponent(r.component_id, in_from_company_sid, in_to_company_sid, in_component_id, out_new_component_id, in_for_validation, v_new_child_comp_id);
	END LOOP;
	
	--set original company back in context if different
	ReSetContextCompany(v_context_company_sid);

END;

--Copy product's component for validation
PROCEDURE CopyProdCompForValidation (
	in_product_id			IN product.product_id%TYPE,
	in_revision_no			IN product_revision.revision_num%TYPE,
	in_force_copy			IN NUMBER,
	out_new_component_id	OUT component.component_id%TYPE
)
AS
	v_component_id				component.component_id%TYPE;
	v_validated_component_id	component.component_id%TYPE;
	v_company_sid				security.security_pkg.T_SID_ID;
	v_validation_status_id			product_revision.validation_status_id%TYPE;
	v_revision_no				product_revision.revision_num%TYPE;
BEGIN
	IF in_revision_no IS NOT NULL THEN
		v_revision_no := in_revision_no;
	ELSE
		SELECT MAX(revision_num)
		  INTO v_revision_no
		  FROM product_revision
		 WHERE app_sid = security_pkg.GetApp
		   AND product_id = in_product_id;
	END IF;
	
	SELECT validation_status_id
	  INTO v_validation_status_id
	  FROM product_revision
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id = in_product_id
	   AND revision_num = v_revision_no;
	
	IF in_force_copy = 0 AND v_validation_status_id NOT IN (chain_pkg.NOT_YET_VALIDATED, chain_pkg.VALIDATED, chain_pkg.VALIDATION_NEEDS_REVIEW) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Couldn''t start validation for product '||in_product_id||', revision '||v_revision_no||' as it is not in the correct status.');
	END IF;
	
	SELECT supplier_root_component_id, company_sid, validated_root_component_id
	  INTO v_component_id, v_company_sid, v_validated_component_id
	  FROM v$product_all_revisions
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id = in_product_id
	   AND revision_num = v_revision_no;
	
	IF v_validated_component_id IS NOT NULL AND in_force_copy = 0 THEN
		out_new_component_id := v_validated_component_id;
	ELSE
		CopyComponent(v_component_id, v_company_sid, v_company_sid, NULL, NULL, TRUE, out_new_component_id);
	END IF;
	
	UPDATE product_revision pr
	   SET pr.validated_root_component_id = out_new_component_id,
		   pr.validation_status_id = chain_pkg.VALIDATION_IN_PROGRESS
	 WHERE pr.app_sid = security_pkg.GetApp
	   AND pr.product_id = in_product_id
	   AND pr.revision_num = v_revision_no;
END;

PROCEDURE FinishValidation (
	in_product_id		   IN product.product_id%TYPE,
	in_revision_no			IN product_revision.revision_num%TYPE,
	out_validation_status_id	OUT product_revision.validation_status_id%TYPE
)
AS
	v_validation_status_id		product_revision.validation_status_id%TYPE;
	v_revision_no		product_revision.revision_num%TYPE;
BEGIN
	IF in_revision_no IS NOT NULL THEN
		v_revision_no := in_revision_no;
	ELSE
		SELECT MAX(revision_num)
		  INTO v_revision_no
		  FROM product_revision
		 WHERE app_sid = security_pkg.GetApp
		   AND product_id = in_product_id;
	END IF;
	
	SELECT validation_status_id
	  INTO v_validation_status_id
	  FROM product_revision
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id = in_product_id
	   AND revision_num = v_revision_no;
	
	IF v_validation_status_id <> chain_pkg.VALIDATION_IN_PROGRESS THEN
		RAISE_APPLICATION_ERROR(-20001, 'Couldn''t finish validation for product '||in_product_id||', revision '||v_revision_no||' as it is not in the correct status.');
	END IF;
	
	UPDATE product_revision pr
	   SET pr.validation_status_id = chain_pkg.VALIDATED
	 WHERE pr.app_sid = security_pkg.GetApp
	   AND pr.product_id = in_product_id
	   AND pr.revision_num = v_revision_no
	RETURNING validation_status_id
	  INTO out_validation_status_id;
END;

PROCEDURE CreateNewProductRevision (
	in_product_id			IN product.product_id%TYPE
)
AS
	v_created_by_sid		product_revision.revision_created_by_sid%TYPE := security_pkg.GetSid;
	v_start_dtm				product_revision.revision_start_dtm%TYPE := SYSDATE; --this is both the end of the previous revision and the start of the new revision
	v_company_sid			security.security_pkg.T_SID_ID;
	v_new_revision_num		product_revision.revision_num%TYPE;
	v_old_pseudo_root		product_revision.supplier_root_component_id%TYPE;
	v_old_validated_root	product_revision.validated_root_component_id%TYPE;
	v_new_pseudo_root		product_revision.supplier_root_component_id%TYPE;
	v_new_validated_root	product_revision.validated_root_component_id%TYPE;
BEGIN
	SELECT revision_num + 1, supplier_root_component_id, validated_root_component_id, company_sid
	  INTO v_new_revision_num, v_old_pseudo_root, v_old_validated_root, v_company_sid
	  FROM v$product
	 WHERE app_sid = security_pkg.getApp
	   AND product_id = in_product_id;
	
	UPDATE product_revision
	   SET revision_end_dtm = v_start_dtm
	 WHERE app_sid = security_pkg.getApp
	   AND product_id = in_product_id
	   AND revision_num = v_new_revision_num - 1;
	
	CopyComponent(v_old_pseudo_root, v_company_sid, v_company_sid, NULL, NULL, FALSE, v_new_pseudo_root);
	IF v_old_validated_root IS NOT NULL THEN
		CopyComponent(v_old_validated_root, v_company_sid, v_company_sid, NULL, NULL, FALSE, v_new_validated_root);
	END IF;
	
	INSERT INTO product_revision 
			(app_sid, product_id, supplier_root_component_id, active, code2, code3, need_review, notes, published,
			last_published_dtm, last_published_by_user_sid, validated_root_component_id, validation_status_id,
			previous_end_dtm, previous_rev_number, revision_start_dtm, revision_end_dtm, revision_num, revision_created_by_sid)
	SELECT app_sid, product_id, v_new_pseudo_root, active, code2, code3, need_review, notes, 0,
			last_published_dtm, last_published_by_user_sid, v_new_validated_root, chain_pkg.INITIAL_VALIDATION_STATUS,
			revision_end_dtm, revision_num, v_start_dtm, NULL, v_new_revision_num, v_created_by_sid
	  FROM product_revision
	 WHERE app_sid = security_pkg.getApp
	   AND product_id = in_product_id
	   AND revision_num = v_new_revision_num - 1;

	chain_link_pkg.CreateNewProductRevision(in_product_id);
END;

--
-- Product Type procedures
--
PROCEDURE GetProductTypes (
	in_parent_product_type_id		IN  product_type.parent_product_type_id%TYPE DEFAULT NULL,
	in_fetch_depth					IN  NUMBER DEFAULT NULL,
	out_product_type_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_product_tag_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
	OPEN out_product_type_cur FOR
		SELECT pt.product_type_id, pt.parent_product_type_id, pt.label, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, 
		       REPLACE(SYS_CONNECT_BY_PATH(pt.label, ''), '', ' / ') path, pt.lookup_key
		  FROM product_type pt
		 WHERE level <= NVL(in_fetch_depth, level)
		 START WITH ((in_parent_product_type_id IS NULL AND pt.parent_product_type_id IS NULL) OR
				(in_parent_product_type_id IS NOT NULL AND pt.parent_product_type_id = in_parent_product_type_id))
		 CONNECT BY PRIOR pt.product_type_id = pt.parent_product_type_id
		ORDER SIBLINGS BY LOWER(pt.label);
		
	
	OPEN out_product_tag_cur FOR
		SELECT ptt.product_type_id, t.tag_id, t.tag, t.explanation, t.lookup_key
		  FROM product_type_tag ptt
		  JOIN (
			SELECT pt.product_type_id
			  FROM product_type pt
			 WHERE level <= NVL(in_fetch_depth, level)
			 START WITH ((in_parent_product_type_id IS NULL AND pt.parent_product_type_id IS NULL) OR
					(in_parent_product_type_id IS NOT NULL AND pt.parent_product_type_id = in_parent_product_type_id))
			 CONNECT BY PRIOR pt.product_type_id = pt.parent_product_type_id
		  ) fpt ON ptt.product_type_id = fpt.product_type_id
		  JOIN csr.v$tag t ON ptt.tag_id = t.tag_id;
END;

PROCEDURE GetProductTypeList (
	in_parent_product_type_id		IN	product_type.parent_product_type_id%TYPE,
	in_search_phrase				IN	VARCHAR2 DEFAULT NULL,
	in_fetch_depth					IN	NUMBER DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
	OPEN out_cur FOR
		SELECT t1.product_type_id, t1.parent_product_type_id, t1.label, t1.lookup_key, t1.lvl, 
		       t1.is_leaf, SUBSTR(t1.path, 4) path, 1 is_match
		  FROM (
			SELECT rownum rn, pt.product_type_id, pt.parent_product_type_id, pt.label, pt.lookup_key, 
			       level lvl, CONNECT_BY_ISLEAF is_leaf, REPLACE(SYS_CONNECT_BY_PATH(pt.label, ''), '', ' / ') path
			  FROM product_type pt
			 WHERE level <= NVL(in_fetch_depth, level)
				START WITH ((in_parent_product_type_id IS NULL AND pt.parent_product_type_id IS NULL) OR
					(in_parent_product_type_id IS NOT NULL AND pt.parent_product_type_id = in_parent_product_type_id))
				CONNECT BY PRIOR pt.product_type_id = pt.parent_product_type_id
			 ORDER SIBLINGS BY LOWER(pt.label)
		 ) t1
		 WHERE (in_search_phrase IS NULL OR LOWER(t1.label) LIKE '%' || LOWER(in_search_phrase) || '%')
		   AND (in_fetch_depth IS NULL OR t1.lvl <= in_fetch_depth)
		 ORDER BY t1.rn;
END;

PROCEDURE SetProductType (
	in_product_type_id				IN  product_type.product_type_id%TYPE DEFAULT NULL,
	in_parent_product_type_id		IN  product_type.parent_product_type_id%TYPE DEFAULT NULL,
	in_label						IN  product_type.label%TYPE,
	in_lookup_key					IN  product_type.lookup_key%TYPE DEFAULT NULL,
	in_tag_ids						IN  helper_pkg.T_NUMBER_ARRAY,
	out_product_type_id				OUT product_type.product_type_id%TYPE
)
AS
	v_tag_ids						T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_tag_ids);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify product types.');
	END IF;
	
	IF in_product_type_id IS NULL THEN		
		BEGIN
			SELECT product_type_id
			  INTO out_product_type_id
			  FROM product_type
			 WHERE (lookup_key = in_lookup_key) --either get by lookup key or label+parent match
			    OR (label = in_label
			   AND ((in_parent_product_type_id IS NULL AND parent_product_type_id IS NULL)
				OR (in_parent_product_type_id IS NOT NULL AND parent_product_type_id = in_parent_product_type_id)));
		EXCEPTION
			WHEN no_data_found THEN
				INSERT INTO product_type (product_type_id, parent_product_type_id, label, lookup_key)
				 VALUES (product_type_id_seq.NEXTVAL, in_parent_product_type_id, in_label, in_lookup_key)
			  RETURNING product_type_id INTO out_product_type_id;
		END;
	ELSE 	 
		out_product_type_id := in_product_type_id;
	END IF;
	
	UPDATE product_type
	   SET parent_product_type_id = in_parent_product_type_id,
		   label = in_label,
		   lookup_key = in_lookup_key
	 WHERE product_type_id = out_product_type_id;
	
	-- resync tags, not dropping existing ones
	DELETE FROM product_type_tag
		  WHERE product_type_id = out_product_type_id
			AND tag_id NOT IN (
			SELECT item
			  FROM TABLE(v_tag_ids)
			);
			
	INSERT INTO product_type_tag (product_type_id, tag_id)
		 SELECT out_product_type_id, item
		   FROM TABLE(v_tag_ids)
		  WHERE item NOT IN (
			SELECT tag_id
			  FROM product_type_tag
			 WHERE product_type_id = out_product_type_id
		  );
END;

PROCEDURE DeleteOldProductTypes (
	in_product_type_ids_to_keep		IN  helper_pkg.T_NUMBER_ARRAY
)
AS
	v_ids						T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_product_type_ids_to_keep);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify product types.');
	END IF;
	
	DELETE FROM product_metric_product_type
	      WHERE app_sid = security_pkg.GetApp
		    AND product_type_id NOT IN (
			SELECT item
			  FROM TABLE(v_ids)
		  );
						 
	DELETE FROM company_product_type
	      WHERE app_sid = security_pkg.GetApp
		    AND product_type_id NOT IN (
			SELECT item
			  FROM TABLE(v_ids)
		  );
		  
	DELETE FROM product_type_tag
	      WHERE app_sid = security_pkg.GetApp
		    AND product_type_id NOT IN (
			SELECT item
			  FROM TABLE(v_ids)
		  );
		  
	DELETE FROM product_type
	      WHERE app_sid = security_pkg.GetApp
		    AND product_type_id NOT IN (
			SELECT item
			  FROM TABLE(v_ids)
		  );
END;

PROCEDURE GetCompanyProductTypes (
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),	
	out_product_type_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_product_tag_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product types for company with sid '||in_company_sid);
	END IF;	
	
	OPEN out_product_type_cur FOR
		-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
		SELECT cpt.company_sid, pt.product_type_id, pt.parent_product_type_id, pt.label, pt.lookup_key, (
			 SELECT REPLACE(LTRIM(sys_connect_by_path(label,''),''), '', ' / ')
				 FROM chain.product_type
        WHERE product_type_id = pt.product_type_id
				 START WITH parent_product_type_id is null
			CONNECT BY PRIOR product_type_id = parent_product_type_id
			) path
		  FROM chain.company_product_type cpt
		  JOIN chain.product_type pt ON cpt.product_type_id = pt.product_type_id
		 WHERE cpt.company_sid = in_company_sid;
	
	OPEN out_product_tag_cur FOR
		SELECT ptt.product_type_id, t.tag_id, t.tag, t.explanation, t.lookup_key
		  FROM company_product_type cpt
		  JOIN product_type_tag ptt ON cpt.product_type_id = ptt.product_type_id
		  JOIN csr.v$tag t ON ptt.tag_id = t.tag_id
		 WHERE cpt.company_sid = in_company_sid;
END;

PROCEDURE SetCompanyProductTypes (
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),	
	in_product_type_ids				IN  helper_pkg.T_NUMBER_ARRAY
)
AS
	v_product_type_ids				T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_product_type_ids);
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product types for company with sid '||in_company_sid);
	END IF;	
	
	DELETE FROM company_product_type
		  WHERE company_sid = in_company_sid
			AND product_type_id NOT IN (
			SELECT item
			  FROM TABLE(v_product_type_ids)
			);
			
	INSERT INTO company_product_type (company_sid, product_type_id)
		 SELECT in_company_sid, item
		   FROM TABLE(v_product_type_ids)
		  WHERE item NOT IN (
			SELECT product_type_id
			  FROM company_product_type
			 WHERE company_sid = in_company_sid
		  );
END;

PROCEDURE AddCompanyProductType (
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),	
	in_product_type_id				IN  product_type.product_type_id%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product types for company with sid '||in_company_sid);
	END IF;	
	
	BEGIN
		INSERT INTO company_product_type (company_sid, product_type_id)
			 VALUES (in_company_sid, in_product_type_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;

PROCEDURE RemoveCompanyProductType (
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),	
	in_product_type_id				IN  product_type.product_type_id%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product types for company with sid '||in_company_sid);
	END IF;	
	
	DELETE FROM company_product_type
	      WHERE company_sid = in_company_sid
		    AND product_type_id = in_product_type_id;
END;

PROCEDURE FilterCompaniesByProdTypeTags (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	   
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, t.tag_id, t.tag
		  FROM csr.v$tag t
		  JOIN csr.tag_group_member tgm ON t.tag_id = tgm.tag_id
		  JOIN csr.tag_group tg ON tgm.tag_group_id = tg.tag_group_id
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = t.tag_id
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(cpt.company_sid, fv.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM company_product_type cpt
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cpt.company_sid = t.object_id
	  JOIN product_type_tag ptt ON cpt.product_type_id = ptt.product_type_id
	  JOIN chain.v$filter_value fv ON ptt.tag_id = fv.num_value
	 WHERE fv.filter_id = in_filter_id 
	   AND fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCompaniesByProductType (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, pt.product_type_id, pt.label
		  FROM product_type pt
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = pt.product_type_id
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cpt.company_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM company_product_type cpt
	  JOIN TABLE(in_ids) t ON cpt.company_sid = t.object_id
	  JOIN (
		SELECT pt.product_type_id
		  FROM product_type pt
			START WITH pt.product_type_id IN (
				SELECT ff.num_value
				  FROM chain.v$filter_value ff 
				 WHERE ff.filter_id = in_filter_id
				   AND ff.filter_field_id = in_filter_field_id
			)
			CONNECT BY PRIOR pt.product_type_id = pt.parent_product_type_id
		) pt ON cpt.product_type_id = pt.product_type_id;


END;

PROCEDURE SupplySummary (
	out_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_customers			NUMBER;
	v_suppliers 		NUMBER;
	v_products_bought	NUMBER;
	v_products_sold		NUMBER;
BEGIN
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.COMPANY, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid ' || SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	SELECT COUNT(*) INTO v_suppliers
	  FROM v$supplier_relationship sr, chain.company c
	 WHERE sr.app_sid = c.app_sid
	   AND sr.supplier_company_sid = c.company_sid
	   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sr.deleted = 0
	   AND c.deleted = 0
	   AND c.pending = 0;

	SELECT COUNT(*) INTO v_customers 
	  FROM v$supplier_relationship sr, chain.company c
	 WHERE sr.app_sid = c.app_sid
	   AND sr.purchaser_company_sid = c.company_sid
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sr.deleted = 0
	   AND c.deleted = 0
	   AND c.pending = 0;

	SELECT COUNT(*) INTO v_products_sold 
	  FROM v$product
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND deleted = 0;

	SELECT COUNT(*) INTO v_products_bought
	  FROM v$purchased_component
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND deleted = 0;

	OPEN out_cur FOR
		SELECT
			v_suppliers supplier_count,
			v_customers customer_count,
			v_products_sold products_sold,
			v_products_bought products_bought
		FROM dual;

END;

END product_pkg;
/
