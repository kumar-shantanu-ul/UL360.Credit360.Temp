CREATE OR REPLACE PACKAGE BODY SUPPLIER.product_pkg
IS

	-- to add / remove a product from a company you need write access on the supplier company
	-- to delete a product you need write access on the supplier company (deletion is setting a flag only)
	-- to activate / deactivate a product you need write access on the supplier company
	-- to update a product you need write access on the supplier company
	-- to view a product you need read access on the supplier company
	-- to enter question data for a product you need write access to the supplier company
	-- to view question data for a product you need read access to the supplier company

-- Create a new product on the system
-- TO DO need to set following tags
--		sale type (tag?)
--		merchant_type (tag?)
PROCEDURE CreateProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_company_sid IN security_pkg.T_SID_ID,
	in_active				IN product.active%TYPE,
	out_product_id			OUT product.product_id%TYPE
)
AS
	v_product_id			product.product_id%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	
	-- logged on user
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_supplier_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT product_id_seq.nextval INTO v_product_id FROM DUAL;

	-- create the product
	INSERT INTO product (product_id, app_sid, product_code, description, supplier_company_sid, active, deleted)
		VALUES (v_product_id, in_app_sid, in_product_code, in_description, in_supplier_company_sid, in_active, PRODUCT_NOT_DELETED);
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_CREATED, in_app_sid, in_app_sid, 
		'Product created. Name: {0} Code: {1}', 
		in_description, in_product_code, NULL, v_product_id);
		
	-- insert the product questionnaire group status for this app / product
	INSERT INTO product_questionnaire_group (product_id, group_id, group_status_id) 
		SELECT v_product_id, group_id, DATA_BEING_ENTERED 
		FROM questionnaire_group 
		WHERE app_sid = in_app_sid;
		
	security.user_pkg.GetSID(in_act_id, v_user_sid);

	INSERT INTO product_revision 
		(product_id, revision_id, description, created_by_sid, created_dtm) 
	VALUES 
		(v_product_id, 1, 'Starting product', v_user_sid, sysdate);

	out_product_id := v_product_id;
	
END;

PROCEDURE CopyProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_product_id			OUT product.product_id%TYPE
)
AS
	v_app_sid				product.app_sid%TYPE;
	v_new_product_id		product.product_id%TYPE;
	v_product_code			product.product_code%TYPE;
	v_description			product.description%TYPE;
	v_new_description		product.description%TYPE;
	v_supplier_company_sid	security_pkg.T_SID_ID;
	v_cnt_name_match		NUMBER;
	v_idx					NUMBER;
	v_tag					tag.tag_id%TYPE;
BEGIN
	
	-- all non null fields so safe
	SELECT app_sid, description, supplier_company_sid INTO v_app_sid, v_description, v_supplier_company_sid FROM product WHERE product_id = in_product_id;
	
	-- check write access on parent company
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_supplier_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- sales type is used to generate a default product code
	v_tag := GetSaleType(in_product_id);
	v_product_code := GetProdCodeFromTag(v_tag);

	v_idx := 1;
	v_cnt_name_match := 1;
	
	WHILE ((v_cnt_name_match > 0) AND (v_idx<100))
	LOOP
		v_new_description := 'Copy of ' || v_description || ' ('||v_idx||')';
		SELECT COUNT(*) INTO v_cnt_name_match FROM product WHERE lower(description) = lower(v_new_description);
		v_idx := v_idx + 1;
	END LOOP;
	
	CreateProduct(in_act_id, v_app_sid, v_product_code, v_new_description, v_supplier_company_sid, PRODUCT_ACTIVE, v_new_product_id);
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_CREATED, v_app_sid, v_app_sid, 
		'Product id {0} created as copy of product. Name: {1}', 
		v_new_product_id, v_description, null, v_new_product_id);
		
	-- copy tags for merchant type and sales type
	INSERT INTO product_tag 
		(product_id, tag_id, note, num)
	SELECT v_new_product_id, pt.tag_id, pt.note, pt.num 
	 FROM product_tag pt, tag_group_member tgm, tag_group tg 
	WHERE pt.tag_id = tgm.tag_id
	  AND tgm.tag_group_sid = tg.tag_group_sid 
	  AND tg.name in ('sale_type', 'merchant_type')
	  AND product_id = in_product_id;


	  
	CopyQAssToNewProd(in_act_id, in_product_id, v_new_product_id);

	-- questionnaire loop
	FOR r IN (
         SELECT package_name 
           FROM all_product_questionnaire pql, questionnaire q
          WHERE pql.questionnaire_id = q.questionnaire_id 
            AND product_id = in_product_id
            AND package_name IS NOT null
            --AND package_name NOT IN ('natural_product_pkg') -- temp
	)
	LOOP
		questionnaire_pkg.CopyQsToNewProd(in_act_id, in_product_id, v_new_product_id, r.package_name);
	END LOOP;

	out_product_id := v_new_product_id;
	
END;

-- TO DO - this is currently an internal function only called from CopyProduct
-- ASSUMPTIONS - it currently assumes that the prdoct being copied to (id=in_new_product_id) is a new product
-- wouldn't be hard to change it to check and clear stuff up for the 'copy to' product, but no need for this currently and have to focus on what's needed 
PROCEDURE CopyQAssToNewProd(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_old_product_id			IN product.product_id%TYPE,
	in_new_product_id			IN product.product_id%TYPE
)
AS
	v_supplier_company_sid	security_pkg.T_SID_ID;
BEGIN
		-- all non null fields so safe
	SELECT supplier_company_sid INTO v_supplier_company_sid FROM product WHERE product_id = in_new_product_id;
	
	-- check write access on parent company of new prod
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_supplier_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- copy product questionnaire links - just a straight copy except questionnaires are reopened
	INSERT INTO all_product_questionnaire 
        (product_id, questionnaire_id, questionnaire_status_id, used, due_date) 
        SELECT in_new_product_id, questionnaire_id, questionnaire_pkg.QUESTIONNAIRE_OPEN, 
            used, due_date
          FROM SUPPLIER.all_product_questionnaire
	     WHERE product_id = in_old_product_id;
	
	-- copy approvers and providers
	INSERT INTO product_questionnaire_approver 
        (product_id, questionnaire_id, approver_sid)  
        SELECT in_new_product_id, questionnaire_id, approver_sid
          FROM supplier.product_questionnaire_approver
         WHERE product_id = in_old_product_id;
	
	INSERT INTO product_questionnaire_provider 
        (product_id, questionnaire_id, provider_sid)  
        SELECT in_new_product_id, questionnaire_id, provider_sid
          FROM supplier.product_questionnaire_provider
         WHERE product_id = in_old_product_id;
	 
	-- copy tags for product category (control questionnaire assignment)_
	INSERT INTO product_tag 
		(product_id, tag_id, note, num)
        SELECT in_new_product_id, pt.tag_id, pt.note, pt.num 
          FROM product_tag pt, tag_group_member tgm, tag_group tg 
         WHERE pt.tag_id = tgm.tag_id
           AND tgm.tag_group_sid = tg.tag_group_sid 
           AND tg.name in ('product_category')
           AND product_id = in_old_product_id;
		   
	-- copy the gt product user entries - this only copies where they existed so won't do anything for non GT
	INSERT INTO gt_product_user (app_sid, product_id, user_sid, company_sid, started)
		SELECT app_sid, in_new_product_id, user_sid, company_sid, 0 FROM gt_product_user WHERE product_id = in_old_product_id;
	
END;




PROCEDURE DeleteMultipleProducts(
	in_act_id				IN security_pkg.T_ACT_ID,	
	in_product_ids			IN T_PRODUCT_IDS,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_id 			product.product_id%TYPE;
BEGIN

	IF in_product_ids.COUNT = 1 AND in_product_ids(1) IS NULL THEN
		-- do nothing 
		OPEN out_cur FOR
			SELECT product_id, description, deleted
			  FROM TEMP_PRODUCT;
	END IF;
	
	FOR i IN in_product_ids.FIRST .. in_product_ids.LAST
	LOOP
        v_product_id := in_product_ids(i);
        DeleteProduct(in_act_id, v_product_id);
        -- catch errors from DeleteProduct - not applicable at the moment
	END LOOP;

	-- leave this mechanism in here. I think we may need to trap some delete errors and warn later
	OPEN out_cur for 
		SELECT DISTINCT product_id, description FROM TEMP_PRODUCT;
END;

-- Set a deleted flag against the product - don't actually remove the product
PROCEDURE DeleteProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE
)
AS
	v_app_sid 			security_pkg.T_SID_ID;
BEGIN

	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;

	UPDATE product 
	   SET deleted = PRODUCT_DELETED
	 WHERE product_id = in_product_id;
	
	-- Need this as products are not secured objects. We only check access is allowed to the supplier company		
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The product with id '|| in_product_id ||'  was not found');
	END IF;
	
	-- TODO: don't think there's much as we're not really deleting the product
	-- Ignore associated parts - they stay in place
	-- Ignore associated question answers - they stay in place

	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_DP_DELETED, v_app_sid, v_app_sid, 
		'Product deleted.', 
		NULL, NULL, NULL, in_product_id);


END;


-- Update all product details 
PROCEDURE UpdateProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_company_sid IN security_pkg.T_SID_ID,
	in_active				IN product.active%TYPE
)
AS
	CURSOR c IS 
		SELECT  app_sid, product_code, description, supplier_company_sid, 
            CASE active WHEN 1 THEN 'Yes' ELSE 'No' END active
		  FROM all_product 
		 WHERE product_id = in_product_id;
	r c%ROWTYPE;
	v_active	VARCHAR2(10);
BEGIN

	-- logged on user
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_supplier_company_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- read some bits about the old product
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		CLOSE c;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The product with id '||in_product_id||'  was not found');
	END IF;
	CLOSE c;

	UPDATE product 
	   SET product_code = in_product_code,
			description = in_description,
			supplier_company_sid = in_supplier_company_sid,
			active = in_active
	 WHERE product_id = in_product_id;
	
	-- Audit changes
	audit_pkg.AuditValueChange(in_act_id,csr.csr_data_pkg.AUDIT_TYPE_PROD_UPDATED, r.app_sid, r.app_sid,
		'Product Code', r.product_code, in_product_code, in_product_id);
	audit_pkg.AuditValueChange(in_act_id,csr.csr_data_pkg.AUDIT_TYPE_PROD_UPDATED, r.app_sid, r.app_sid,
		'Product Description', r.description, in_description, in_product_id);
	audit_pkg.AuditValueChange(in_act_id,csr.csr_data_pkg.AUDIT_TYPE_PROD_UPDATED, r.app_sid, r.app_sid,
		'Supplier Company',
		company_pkg.GetNameFromSid(in_act_id, r.supplier_company_sid) || '(' || r.supplier_company_sid || ')', 
		company_pkg.GetNameFromSid(in_act_id, in_supplier_company_sid) || '(' || in_supplier_company_sid || ')', in_product_id);
	SELECT CASE in_active WHEN 1 THEN 'Yes' ELSE 'No' END active INTO v_active FROM dual;
	audit_pkg.AuditValueChange(in_act_id,csr.csr_data_pkg.AUDIT_TYPE_PROD_UPDATED, r.app_sid, r.app_sid,
		'Product Active', r.active, v_active, in_product_id);

END;

-- for use by the data sync update function
PROCEDURE UpdateProductDescription(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_new_description		IN product.description%TYPE
)
AS
	CURSOR c IS 
		SELECT  app_sid, description
		  FROM all_product 
		 WHERE product_id = in_product_id;
	r c%ROWTYPE;
BEGIN

	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- read some bits about the old user
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		CLOSE c;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The product with id '||in_product_id||'  was not found');
	END IF;
	CLOSE c;

	UPDATE product 
	   SET description = in_new_description
	 WHERE product_id = in_product_id;
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_UPDATED, r.app_sid, r.app_sid,
		'Product Description', r.description, in_new_description);

END;

-- TODO: have this take an array instead of a single tag id. 
-- It's not a major issue ATM as we only use single-select tags.
PROCEDURE SetProductTag(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_tag_id				IN tag.tag_id%TYPE
)
AS
	v_company_sid			security_pkg.T_SID_ID;
	v_tag_group_sid			security_pkg.T_SID_ID;
	v_multi_select			tag_group.multi_select%TYPE;
	v_tag_group_description	tag_group.description%TYPE;
	v_tag_explanation		tag.explanation%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
	v_old_tag_ids			tag_pkg.T_TAG_IDS;
	v_index					NUMBER;
BEGIN
	
	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
	
	-- Get the tag group sid and the multi select mode
	SELECT g.tag_group_sid, g.multi_select, g.description, t.explanation
	  INTO v_tag_group_sid, v_multi_select, v_tag_group_description, v_tag_explanation
	  FROM tag_group g, tag_group_member m, tag t
	 WHERE g.tag_group_sid = m.tag_group_sid
	   AND m.tag_id = t.tag_id
	   AND m.tag_id = in_tag_id
	   AND g.app_sid = v_app_sid;
	   
	   
	-- need to do audit logging here as may be deleteing old tags before inserting new tags
	v_index := 1;
	
	FOR r IN (
		SELECT tag_id FROM product_tag
		 WHERE tag_id IN (
		 	SELECT tag_id
		 	  FROM tag_group_member
		 	 WHERE tag_group_sid = v_tag_group_sid
		 )
		 AND product_id = in_product_id
	)
	LOOP
		v_old_tag_ids(v_index) := r.tag_id;
		v_index := v_index + 1;
	END LOOP;
	
	audit_pkg.AuditTagChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_TAG_CHANGED, v_app_sid, v_app_sid, v_tag_group_description,
		v_old_tag_ids, in_tag_id, 1 - v_multi_select, in_product_id);

	-- now deal with the multiselect case
	IF v_multi_select = 0 THEN
		-- If not multi-select then clear down existing 
		-- tags for thisproduct, from this tag group
		DELETE FROM product_tag
		 WHERE tag_id IN (
		 	SELECT tag_id
		 	  FROM tag_group_member
		 	 WHERE tag_group_sid = v_tag_group_sid
		 )
		 AND product_id = in_product_id;
	END IF;
	
	-- Upsert the tag_id into the join table
	BEGIN
		INSERT INTO product_tag
			(product_id, tag_id)
		 VALUES(in_product_id, in_tag_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- Handle this as we may already have this 
			-- product/tag association in multi-select mode
			NULL;
	END;
	
END;

PROCEDURE SetProductTags(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_id			IN product.product_id%TYPE,
	in_tag_group_name		IN tag_group.name%TYPE,
	in_tag_ids				IN tag_pkg.T_TAG_IDS,
	in_tag_numbers			IN T_TAG_NUMBERS,
	in_tag_notes			IN T_TAG_NOTES
)
AS
	v_company_sid			security_pkg.T_SID_ID;
	v_tag_group_sid			security_pkg.T_SID_ID;
	v_tag_group_description	tag_group.description%TYPE;
	v_tag_explanation		tag.explanation%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
	v_old_tag_ids			tag_pkg.T_TAG_IDS;
	v_index					NUMBER;
	v_number				product_tag.num%TYPE;
	v_note					product_tag.note%TYPE;
BEGIN
	-- Check for NULL array
	IF in_tag_ids IS NULL OR (in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL) THEN
		RAISE_APPLICATION_ERROR(ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
		
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
			SELECT tag_id FROM product_tag
			 WHERE product_id = in_product_id
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
		
		audit_pkg.AuditTagChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_TAG_CHANGED, v_app_sid, v_app_sid, v_tag_group_description,
			v_old_tag_ids, in_tag_ids, 1, in_product_id);
			
		DELETE FROM product_tag
		 WHERE product_id = in_product_id
		   AND tag_id IN (
	   		SELECT tag_id
	   		  FROM tag_group_member
	   		 WHERE tag_group_sid = v_tag_group_sid
	   		);
	ELSE
	
		-- need to do audit logging here as deleteing old tags before inserting new tags
		FOR r IN (
			SELECT tag_id FROM product_tag WHERE product_id = in_product_id
		)
		LOOP
			v_old_tag_ids(v_index) := r.tag_id;
			v_index := v_index + 1;
		END LOOP;
		
		audit_pkg.AuditTagChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_TAG_CHANGED, v_app_sid, v_app_sid, v_tag_group_description,
			v_old_tag_ids, in_tag_ids, 1, in_product_id);
	
		DELETE FROM product_tag
		 WHERE product_id = in_product_id;
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
	
		INSERT INTO product_tag
			(product_id, tag_id, num, note)
		VALUES
			(in_product_id, in_tag_ids(t), v_number, v_note);
			
	END LOOP;

END;

PROCEDURE SetProductTags(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_id			IN product.product_id%TYPE,
	in_tag_group_name		IN tag_group.name%TYPE,
	in_tag_ids				IN tag_pkg.T_TAG_IDS
)
AS
	v_numbers		T_TAG_NUMBERS;
	v_notes			T_TAG_NOTES;
BEGIN
	SetProductTags(in_act_id, in_app_sid, in_product_id, 
		in_tag_group_name, in_tag_ids, v_numbers, v_notes);
	
END;

PROCEDURE SearchProductCount(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_name		IN company.name%TYPE,
	in_product_type_tag_id	IN product_tag.tag_id%TYPE,
	in_sale_type_tag_id		IN product_tag.tag_id%TYPE,
	in_active				IN product.active%TYPE,
	in_end_user_name		IN VARCHAR2,
	in_cert_expiry_months	IN NUMBER,
	out_count				OUT	NUMBER
)
IS
	v_product_code			VARCHAR2(1024) DEFAULT '%' || TRIM(LOWER(in_product_code)) || '%';
	v_description			VARCHAR2(1024) DEFAULT '%' || TRIM(LOWER(in_description)) || '%';
	v_supplier_name			VARCHAR2(1024) DEFAULT '%' || TRIM(LOWER(in_supplier_name)) || '%';
	v_end_user_name			VARCHAR2(1024) DEFAULT '%' || TRIM(LOWER(in_end_user_name)) || '%';
	v_companies_sid 		security_pkg.T_SID_ID;
	v_is_admin				NUMBER(1) := 0;
	v_user_company_sid		security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID;
BEGIN

	-- Check read permission on companies folder in security
	-- Products are not secured objects so effectively we are saying if you're allowed to read  companies you're allowed to read their products
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');
	
	-- if not an admin only return the products for user company
	IF security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_WRITE) THEN
		v_is_admin := 1; -- admins get everything
		v_user_company_sid := -1;
	ELSE
		user_pkg.GetSID(in_act_id, v_user_sid);
		SELECT NVL(company_sid,-1) INTO v_user_company_sid FROM company_user WHERE app_sid = in_app_sid AND csr_user_sid = v_user_sid;
		
	    -- check user has read permission on company
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_user_company_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
		END IF;
	END IF;
	   
 	SELECT COUNT(*) INTO out_count FROM (
   	SELECT DISTINCT p.product_id FROM (
	 	SELECT DISTINCT p.product_id
	 		FROM product p, product_tag pt, company c
		   WHERE p.product_id = pt.product_id(+) 
			 AND p.supplier_company_sid = c.company_sid 
			 AND p.app_sid = in_app_sid 
			 AND (in_product_code IS NULL OR LOWER(p.product_code) LIKE v_product_code) 
			 AND (in_description IS NULL OR LOWER(p.description) LIKE v_description) 
			 AND (in_supplier_name IS NULL OR LOWER(c.name) LIKE v_supplier_name) 
			 AND (in_product_type_tag_id IS NULL OR p.product_id IN (SELECT product_id FROM product_tag WHERE tag_id = in_product_type_tag_id)) 
			 AND (in_sale_type_tag_id IS NULL OR p.product_id IN (SELECT product_id FROM product_tag WHERE tag_id = in_sale_type_tag_id)) 
			 AND ((v_is_admin=1) OR (p.supplier_company_sid=NVL(v_user_company_sid,-1)))
			 AND p.active = NVL(in_active, p.active) 
			 --AND (in_review_months IS NULL OR status_changed_dtm IS NULL OR p.status_changed_dtm < sysdate - (in_review_months * 30)) 
			 --AND p.product_status_id = NVL(in_product_status_id, p.product_status_id)
	) p, 
	(
			  SELECT pq.product_id, u.csr_user_sid, u.user_name, u.friendly_name, u.full_name
			  FROM product_questionnaire pq, product_questionnaire_provider pqp, csr.csr_user u
			  WHERE pq.product_id = pqp.product_id
			  AND pq.questionnaire_id = pqp.questionnaire_id
			  AND pqp.provider_sid = u.csr_user_sid
	) prv,
	(
			  SELECT pq.product_id, u.csr_user_sid, u.user_name, u.friendly_name, u.full_name
			  FROM product_questionnaire pq, product_questionnaire_approver pqa, csr.csr_user u
			  WHERE pq.product_id = pqa.product_id
			  AND pq.questionnaire_id = pqa.questionnaire_id
			  AND pqa.approver_sid = u.csr_user_sid
	) app
	WHERE p.product_id = prv.product_id(+)
	AND  p.product_id = app.product_id(+)
		AND (((in_end_user_name IS NULL OR LOWER(prv.user_name) LIKE v_end_user_name) OR (in_end_user_name IS NULL OR LOWER(prv.full_name) LIKE v_end_user_name) OR (in_end_user_name IS NULL OR LOWER(prv.friendly_name) LIKE v_end_user_name)) 
		OR ((in_end_user_name IS NULL OR LOWER(app.user_name) LIKE v_end_user_name) OR (in_end_user_name IS NULL OR LOWER(app.full_name) LIKE v_end_user_name) OR (in_end_user_name IS NULL OR LOWER(app.friendly_name) LIKE v_end_user_name)))
		AND (in_cert_expiry_months IS NULL OR product_pkg.GetMinCertExpiryDate(p.product_id) < sysdate + (in_cert_expiry_months * 30))
	);
	   
END;


-- used from Admin search page 
PROCEDURE SearchProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	in_description			IN product.description%TYPE,
	in_supplier_name		IN company.name%TYPE,
	in_product_type_tag_id	IN product_tag.tag_id%TYPE,
	in_sale_type_tag_id		IN product_tag.tag_id%TYPE,
	in_active				IN product.active%TYPE,
	in_end_user_name		IN VARCHAR2,
	in_cert_expiry_months	IN NUMBER,	
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_product_code			VARCHAR2(1024) DEFAULT '%' || TRIM(LOWER(in_product_code)) || '%';
	v_description			VARCHAR2(1024) DEFAULT '%' || TRIM(LOWER(in_description)) || '%';
	v_supplier_name			VARCHAR2(1024) DEFAULT '%' || TRIM(LOWER(in_supplier_name)) || '%';
	v_end_user_name			VARCHAR2(1024) DEFAULT '%' || TRIM(LOWER(in_end_user_name)) || '%';
	v_companies_sid 		security_pkg.T_SID_ID;
	v_SQL					VARCHAR2(32000);
	v_is_admin				NUMBER(1) := 0;
	v_user_company_sid		security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID;
BEGIN

	-- Check read permission on companies folder in security
	-- Products are not secured objects so effectively we are saying if you're allowed to read  companies you're allowed to read their products
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');
	
	-- if not an admin only return the products for user company
	IF security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_WRITE) THEN
		v_is_admin := 1; -- admins get everything
		v_user_company_sid := -1;
	ELSE
		user_pkg.GetSID(in_act_id, v_user_sid);
		SELECT NVL(company_sid,-1) INTO v_user_company_sid FROM company_user WHERE app_sid = in_app_sid AND csr_user_sid = v_user_sid;
		
	    -- check user has read permission on company
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_user_company_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
		END IF;
	END IF;

	IF LOWER(in_order_by) NOT IN ('product_id', 'description', 'productcode', 'active', 'companyname', 
		'sale_type_tag_id', 'merchant_type_tag_id', 'category') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_by not in the allowed list');
	END IF;
	IF LOWER(in_order_direction) NOT IN ('asc', 'desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_direction not asc or desc');
	END IF;
	
	v_SQL := v_SQL || 		'  (SELECT * FROM ';
	v_SQL := v_SQL || 		'  ( ';
	v_SQL := v_SQL || 		'	 SELECT rownum rn, product_id, description, productcode, active, companyname, sale_type_tag_id, merchant_type_tag_id, category FROM   ';
	v_SQL := v_SQL || 		'	 (   ';
	v_SQL := v_SQL || 		'		SELECT DISTINCT p.product_id, description, productcode, active, companyname, sale_type_tag_id, merchant_type_tag_id, category FROM ';
	v_SQL := v_SQL || 		'		( ';
	v_SQL := v_SQL || 		'				SELECT DISTINCT p.product_id, p.description, p.product_code productcode, p.active, c.name companyname, ';
	v_SQL := v_SQL || 		'				product_pkg.GetSaleType(p.product_id) sale_type_tag_id, ';
	v_SQL := v_SQL || 		'				product_pkg.GetMerchantType(p.product_id) merchant_type_tag_id, '; 
	v_SQL := v_SQL || 		'				product_pkg.GetMerchantTypeDescription(p.product_id) category ';
	v_SQL := v_SQL || 		'				FROM product p, product_tag pt, company c ';
	v_SQL := v_SQL || 		'				  WHERE p.product_id = pt.product_id(+) '; 
	v_SQL := v_SQL || 		'					 AND p.supplier_company_sid = c.company_sid ';
	v_SQL := v_SQL || 		'					 AND p.app_sid = :in_app_sid  ';
	v_SQL := v_SQL || 		'					 AND (:in_product_code IS NULL OR LOWER(p.product_code) LIKE :v_product_code)  ';  
	v_SQL := v_SQL || 		'					 AND (:in_description IS NULL OR LOWER(p.description) LIKE :v_description)  ';
	v_SQL := v_SQL || 		'					 AND (:in_supplier_name IS NULL OR LOWER(c.name) LIKE :v_supplier_name)  ';
	v_SQL := v_SQL || 		'					 AND (:in_product_type_tag_id IS NULL OR p.product_id IN (SELECT product_id FROM product_tag WHERE tag_id = :in_product_type_tag_id))  ';
	v_SQL := v_SQL || 		'					 AND (:in_sale_type_tag_id IS NULL OR p.product_id IN (SELECT product_id FROM product_tag WHERE tag_id = :in_sale_type_tag_id))  ';
	v_SQL := v_SQL || 		'					 AND ((:v_is_admin=1) OR (p.supplier_company_sid=NVL(:v_user_company_sid,-1)))  ';	
	v_SQL := v_SQL || 		'					 AND p.active = NVL(:in_active, p.active)  ';

	v_SQL := v_SQL || 		'	   ) p,  ';
	v_SQL := v_SQL || 		'		( ';
	v_SQL := v_SQL || 		'				  SELECT pq.product_id, u.csr_user_sid, u.user_name, u.friendly_name, u.full_name ';
	v_SQL := v_SQL || 		'				  FROM product_questionnaire pq, product_questionnaire_provider pqp, csr.csr_user u ';
	v_SQL := v_SQL || 		'				  WHERE pq.product_id = pqp.product_id  ';
	v_SQL := v_SQL || 		'				  AND pq.questionnaire_id = pqp.questionnaire_id ';
	v_SQL := v_SQL || 		'				  AND pqp.provider_sid = u.csr_user_sid ';
	v_SQL := v_SQL || 		'		) prv, ';
	v_SQL := v_SQL || 		'		( ';
	v_SQL := v_SQL || 		'				  SELECT pq.product_id, u.csr_user_sid, u.user_name, u.friendly_name, u.full_name ';
	v_SQL := v_SQL || 		'				  FROM product_questionnaire pq, product_questionnaire_approver pqa, csr.csr_user u ';
	v_SQL := v_SQL || 		'				  WHERE pq.product_id = pqa.product_id  ';
	v_SQL := v_SQL || 		'				  AND pq.questionnaire_id = pqa.questionnaire_id ';
	v_SQL := v_SQL || 		'				  AND pqa.approver_sid = u.csr_user_sid ';
	v_SQL := v_SQL || 		'		) app ';
	v_SQL := v_SQL || 		'				WHERE p.product_id = prv.product_id(+) ';
	v_SQL := v_SQL || 		'				AND  p.product_id = app.product_id(+) ';
	v_SQL := v_SQL || 		'			   AND (((:in_end_user_name IS NULL OR LOWER(prv.user_name) LIKE :v_end_user_name) OR (:in_end_user_name IS NULL OR LOWER(prv.full_name) LIKE :v_end_user_name) OR (:in_end_user_name IS NULL OR LOWER(prv.friendly_name) LIKE :v_end_user_name)) ';
	v_SQL := v_SQL || 		'			   OR ((:in_end_user_name IS NULL OR LOWER(app.user_name) LIKE :v_end_user_name) OR (:in_end_user_name IS NULL OR LOWER(app.full_name) LIKE :v_end_user_name) OR (:in_end_user_name IS NULL OR LOWER(app.friendly_name) LIKE :v_end_user_name))) ';
	v_SQL := v_SQL || 		'			   AND (:in_cert_expiry_months IS NULL OR product_pkg.GetMinCertExpiryDate(p.product_id) < sysdate + (:in_cert_expiry_months * 30)) ';
	v_SQL := v_SQL || 		'	 	ORDER BY LOWER(' || in_order_by || ') ' || in_order_direction;
	v_SQL := v_SQL || 		'	 ) ';
	v_SQL := v_SQL || 		'	 WHERE rownum <= NVL(:in_end, rownum) ';
	v_SQL := v_SQL || 		'  ) WHERE rn > NVL(:in_start, 0) ) ';
	
	OPEN out_cur FOR v_SQL
		USING in_app_sid, in_product_code, v_product_code, in_description, v_description, in_supplier_name, v_supplier_name, in_product_type_tag_id, 
			in_product_type_tag_id, in_sale_type_tag_id, in_sale_type_tag_id, v_is_admin, v_user_company_sid, in_active,  
			in_end_user_name, v_end_user_name, in_end_user_name, v_end_user_name, in_end_user_name, v_end_user_name, 
			in_end_user_name, v_end_user_name, in_end_user_name, v_end_user_name, in_end_user_name, v_end_user_name,
			in_cert_expiry_months, in_cert_expiry_months, (in_start + in_page_size), in_start; 
			
END;


-- used for product edit screen
PROCEDURE SearchProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_search				IN product.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_search				VARCHAR2(1024) DEFAULT '%' || TRIM(LOWER(in_search)) || '%';
	v_companies_sid 		security_pkg.T_SID_ID;
BEGIN

	-- Check read permission on companies folder in security
	-- Products are not secured objects so effectively we are saying if you're allowed to read  companies you're allowed to read their products
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- The following will only work where the tags sale_type and 
	-- merchant_type are single-select, whch they are at the moment.
	OPEN out_cur FOR
	   	SELECT product_id, description, product_code, active, 
				supplier_company_sid, 
			max(DECODE (tag_group_name, 'sale_type', tag_id, NULL)) sale_type_tag_id,
			max(DECODE (tag_group_name, 'merchant_type', tag_id, NULL)) merchant_type_tag_id
		 FROM
		(
			SELECT p.product_id, p.description, p.product_code, p.active, 
				p.supplier_company_sid, t.tag_id, tg.name tag_group_name
			  FROM product p, product_tag pt, tag t, tag_group_member tgm, tag_group tg
			 WHERE p.app_sid = in_app_sid 
		   	   AND (in_search IS NULL OR LOWER(p.description) LIKE v_search) 
			   AND p.product_id = pt.product_id
			   AND pt.tag_id = t.tag_id
			   AND tgm.tag_id = t.tag_id
			   AND tgm.tag_group_sid = tg.tag_group_sid
			   	ORDER BY LOWER(p.description) ASC
		)
		   GROUP BY product_id, description, product_code, active,
				supplier_company_sid;
END;


PROCEDURE SearchProductCode(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_search				IN product.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_search				VARCHAR2(1024) DEFAULT '%' || LOWER(in_search) || '%';
	v_companies_sid 		security_pkg.T_SID_ID;
BEGIN

	-- Check read permission on companies folder in security
	-- Products are not secured objects so effectively we are saying if you're allowed to read  companies you're allowed to read their products
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT product_id, description, product_code, active, 
				supplier_company_sid,
			max(DECODE (tag_group_name, 'sale_type', tag_id, NULL)) sale_type_tag_id,
			max(DECODE (tag_group_name, 'merchant_type', tag_id, NULL)) merchant_type_tag_id
		 FROM
		(
			SELECT p.product_id, p.description, p.product_code, p.active, 
				p.supplier_company_sid, t.tag_id, tg.name tag_group_name
			  FROM product p, product_tag pt, tag t, tag_group_member tgm, tag_group tg
			 WHERE p.app_sid = in_app_sid 
		   	   AND (in_search IS NULL OR LOWER(p.product_code) LIKE v_search) 
			   AND p.product_id = pt.product_id
			   AND pt.tag_id = t.tag_id
			   AND tgm.tag_id = t.tag_id
			   AND tgm.tag_group_sid = tg.tag_group_sid
			   	ORDER BY p.product_code ASC
		)
			GROUP BY product_id, description, product_code, active, 
				supplier_company_sid;
END;

-- used for product edit screen
PROCEDURE GetProductsByDesc(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_desc			IN product.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_companies_sid 		security_pkg.T_SID_ID;
BEGIN

	-- Check read permission on companies folder in security
	-- Products are not secured objects so effectively we are saying if you're allowed to read  companies you're allowed to read their products
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- The following will only work where the tags sale_type and 
	-- merchant_type are single-select, which they are at the moment.
	OPEN out_cur FOR
	   	SELECT product_id, description, product_code, active, supplier_company_sid,
				max(DECODE (tag_group_name, 'sale_type', tag_id, NULL)) sale_type_tag_id,
				max(DECODE (tag_group_name, 'merchant_type', tag_id, NULL)) merchant_type_tag_id
		 FROM
		(
			SELECT p.product_id, p.description, p.product_code, p.active, 
				p.supplier_company_sid, t.tag_id, tg.name tag_group_name
			  FROM product p, product_tag pt, tag t, tag_group_member tgm, tag_group tg
			 WHERE p.app_sid = in_app_sid 
		   	   AND (in_product_desc IS NULL OR LOWER(p.description) = TRIM(LOWER(in_product_desc))) 
			   AND p.product_id = pt.product_id
			   AND pt.tag_id = t.tag_id
			   AND tgm.tag_id = t.tag_id
			   AND tgm.tag_group_sid = tg.tag_group_sid
			   	ORDER BY LOWER(p.description) ASC
		)
		   GROUP BY product_id, description, product_code, active,
				supplier_company_sid;
END;


-- used for product edit screen
PROCEDURE GetProductsByCode(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_companies_sid 		security_pkg.T_SID_ID;
BEGIN

	-- Check read permission on companies folder in security
	-- Products are not secured objects so effectively we are saying if you're allowed to read  companies you're allowed to read their products
	v_companies_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/Companies');

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_companies_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
	   	SELECT product_id, description, product_code, active, supplier_company_sid,
				max(DECODE (tag_group_name, 'sale_type', tag_id, NULL)) sale_type_tag_id,
				max(DECODE (tag_group_name, 'merchant_type', tag_id, NULL)) merchant_type_tag_id
		 FROM
		(
			SELECT p.product_id, p.description, p.product_code, p.active, 
				p.supplier_company_sid, t.tag_id, tg.name tag_group_name
			  FROM product p, product_tag pt, tag t, tag_group_member tgm, tag_group tg
			 WHERE p.app_sid = in_app_sid 
		   	   AND (in_product_code IS NULL OR LOWER(p.product_code) = LOWER(in_product_code)) 
			   AND p.product_id = pt.product_id
			   AND pt.tag_id = t.tag_id
			   AND tgm.tag_id = t.tag_id
			   AND tgm.tag_group_sid = tg.tag_group_sid
			   	ORDER BY p.product_code ASC
		)
		   GROUP BY product_id, description, product_code, active,
				supplier_company_sid;
END;

PROCEDURE GetProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
	   	SELECT p.product_id, p.description, p.product_code, p.active, 
	   		p.supplier_company_sid,
			max(DECODE (tag_group_name, 'sale_type', tag_id, NULL)) sale_type_tag_id,
			max(DECODE (tag_group_name, 'merchant_type', tag_id, NULL)) merchant_type_tag_id
		 FROM 
		(
			SELECT p.product_id, p.description, p.product_code, p.active, 
				p.supplier_company_sid, 
				t.tag_id, tg.name tag_group_name
			  FROM product p, product_tag pt, tag t, tag_group_member tgm, tag_group tg
			 WHERE p.product_id = in_product_id
			   AND p.product_id = pt.product_id
			   AND pt.tag_id = t.tag_id
			   AND tgm.tag_id = t.tag_id
			   AND tgm.tag_group_sid = tg.tag_group_sid	
		)p 
		GROUP BY product_id, description, product_code, active, 
				supplier_company_sid;

END;


PROCEDURE GetAllProduct(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
	   	SELECT p.product_id, p.description, p.product_code, p.active, 
		  		p.supplier_company_sid, 
				  max(DECODE (tag_group_name, 'sale_type', tag_id, NULL)) sale_type_tag_id,
				  max(DECODE (tag_group_name, 'merchant_type', tag_id, NULL)) merchant_type_tag_id
		   FROM 
		  (
				  SELECT p.product_id, p.description, p.product_code, p.active,
						  p.supplier_company_sid,  
						  t.tag_id, tg.name tag_group_name
				FROM all_product p, product_tag pt, tag t, tag_group_member tgm, tag_group tg
			   WHERE p.product_id = in_product_id
				 AND p.product_id = pt.product_id
				 AND pt.tag_id = t.tag_id
				 AND tgm.tag_id = t.tag_id
				 AND tgm.tag_group_sid = tg.tag_group_sid	
		  )p 
		  GROUP BY product_id, description, product_code, active, 
						  supplier_company_sid;
END;

-- Only gets product with work to do on them - or approved products for up to 14 days 
PROCEDURE GetSmpWkflwProdUserProv(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_group_id				IN questionnaire_group.group_id%TYPE,
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_SQL					VARCHAR2(2048);
BEGIN
	IF LOWER(in_order_by) NOT IN ('product_id', 'productcode', 'description', 'status', 'overdue') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_by not in the allowed list');
	END IF;
	IF LOWER(in_order_direction) NOT IN ('asc', 'desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_direction not asc or desc');
	END IF;

	--select all products that have a questionairre assigned to current user to fill in 

v_SQL := v_SQL || 		'	 SELECT * FROM  ';
v_SQL := v_SQL || 		'	 ( 	 ';
v_SQL := v_SQL || 		'		 SELECT rownum rn, total_count, product_id, productcode, description, status, overdue  ';
v_SQL := v_SQL || 		'		 FROM	';
v_SQL := v_SQL || 		'		 (	';
v_SQL := v_SQL || 		'			SELECT COUNT(*) OVER () total_count, x.* FROM   ';
v_SQL := v_SQL || 		'			(  ';
v_SQL := v_SQL || 		'				SELECT DISTINCT  ';
v_SQL := v_SQL || 		'					p.product_id, p.product_code productcode, p.description, '; 
				-- MIN status as all should be the same for simple workflow 
v_SQL := v_SQL || 		'					MIN(group_status_id) status,  ';
v_SQL := v_SQL || 		'					CASE WHEN ((MIN(pq.due_date) < sysdate - 1) AND (MIN(group_status_id) IN (:data_entry_group_status_id, :reopenend_group_status_id))) THEN 1 ELSE 0 END overdue   '; -- only work to do as provider if open for data entry or reopened
v_SQL := v_SQL || 		'				FROM product p, product_questionnaire pq, product_questionnaire_provider pqp, questionnaire_group_membership qgm, product_questionnaire_group pqg  ';
v_SQL := v_SQL || 		'				WHERE p.product_id = pq.product_id  ';
v_SQL := v_SQL || 		'				AND pq.questionnaire_id = pqp.questionnaire_id  ';
v_SQL := v_SQL || 		'				AND pq.product_id = pqp.product_id  ';
v_SQL := v_SQL || 		'				AND pqp.questionnaire_id = qgm.questionnaire_id  ';
v_SQL := v_SQL || 		'				AND p.product_id = pqg.product_id  ';
v_SQL := v_SQL || 		'				AND pqg.group_id = :in_group_id ';
v_SQL := v_SQL || 		'				AND qgm.group_id = :in_group_id  ';
v_SQL := v_SQL || 		'			   AND pqp.provider_sid = :in_user_sid ';
 v_SQL := v_SQL || 		'			   AND active = 1  ';
			-- Show if I'm not approving or the state is data being entered / reviewed 
v_SQL := v_SQL || 		'				AND (  ';
v_SQL := v_SQL || 		'						(pqp.provider_sid NOT IN   ';
v_SQL := v_SQL || 		'							(  ';
v_SQL := v_SQL || 		'								SELECT approver_sid FROM product_questionnaire_approver pqa  ';
v_SQL := v_SQL || 		'								WHERE pqa.PRODUCT_ID = pq.product_id   ';
v_SQL := v_SQL || 		'								AND pqa.questionnaire_id = pq.questionnaire_id  ';
v_SQL := v_SQL || 		'							)  ';
v_SQL := v_SQL || 		'					)   ';
v_SQL := v_SQL || 		'					OR   ';
v_SQL := v_SQL || 		'					 (group_status_id IN (:DATA_BEING_ENTERED,:DATA_BEING_REVIEWED))  ';
v_SQL := v_SQL || 		'					)		  ';
			-- The product will not show after being approved 
v_SQL := v_SQL || 		'				AND group_status_id <> :DATA_APPROVED  '; 
v_SQL := v_SQL || 		'				GROUP BY p.product_id, p.product_code, p.description  ';
v_SQL := v_SQL || 		'			) x  ';
v_SQL := v_SQL || 		'			ORDER BY LOWER(' || in_order_by || ') ' || in_order_direction;
v_SQL := v_SQL || 		'		 )	';
v_SQL := v_SQL || 		'		 WHERE rownum <= :end_rec ';
v_SQL := v_SQL || 		'	) WHERE rn > :start_rec ';
	
	

   OPEN out_cur FOR v_SQL
		USING DATA_BEING_ENTERED, DATA_BEING_REVIEWED, in_group_id, in_group_id, in_user_sid, DATA_BEING_ENTERED, DATA_BEING_REVIEWED, DATA_APPROVED,
		in_start+in_page_size, in_start;
	
END;

PROCEDURE GetSmpWkflwProdUserApprv(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_group_id				IN questionnaire_group.group_id%TYPE,
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_SQL					VARCHAR2(2048);
BEGIN
--select all products that have a questionairre assigned to current user to fill in 
	IF LOWER(in_order_by) NOT IN ('product_id', 'description', 'productcode', 'status', 'overdue') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_by not in the allowed list');
	END IF;
	IF LOWER(in_order_direction) NOT IN ('asc', 'desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_direction not asc or desc');
	END IF;

				
	v_SQL := v_SQL || 		'	 SELECT * FROM  ';
	v_SQL := v_SQL || 		'	 ( 	 ';
	v_SQL := v_SQL || 		'		 SELECT rownum rn, total_count, product_id, productcode, description, status, overdue  ';
	v_SQL := v_SQL || 		'		 FROM	';
	v_SQL := v_SQL || 		'		 (	';
	v_SQL := v_SQL || 		'			SELECT COUNT(*) OVER () total_count, x.* FROM   ';
	v_SQL := v_SQL || 		'			(  ';
	v_SQL := v_SQL || 		'				SELECT DISTINCT  ';
	v_SQL := v_SQL || 		'					p.product_id, p.product_code productcode, p.description, '; 
					-- MIN status as all should be the same for simple workflow 
	v_SQL := v_SQL || 		'					MIN(group_status_id) status,  ';
	v_SQL := v_SQL || 		'					CASE WHEN ((MIN(pq.due_date) < sysdate - 1) AND (MIN(group_status_id) IN (:submitted_group_status_id))) THEN 1 ELSE 0 END overdue   '; -- only work to do as approver if submitted
	v_SQL := v_SQL || 		'				FROM product p, product_questionnaire pq, product_questionnaire_approver pqa, questionnaire_group_membership qgm, product_questionnaire_group pqg  ';
	v_SQL := v_SQL || 		'				WHERE p.product_id = pq.product_id  ';
	v_SQL := v_SQL || 		'				AND pq.questionnaire_id = pqa.questionnaire_id  ';
	v_SQL := v_SQL || 		'				AND pq.product_id = pqa.product_id  ';
	v_SQL := v_SQL || 		'				AND pqa.questionnaire_id = qgm.questionnaire_id  ';
	v_SQL := v_SQL || 		'				AND p.product_id = pqg.product_id  ';
	v_SQL := v_SQL || 		'				AND pqg.group_id = :in_group_id ';
	v_SQL := v_SQL || 		'				AND qgm.group_id = :in_group_id  ';
	v_SQL := v_SQL || 		'			   AND pqa.approver_sid = :in_user_sid ';
	 v_SQL := v_SQL || 		'			   AND active = 1  ';
				-- Show if I'm not approving or the state is data being entered / reviewed 
	v_SQL := v_SQL || 		'				AND (  ';
	v_SQL := v_SQL || 		'						(pqa.approver_sid NOT IN   ';
	v_SQL := v_SQL || 		'							(  ';
	v_SQL := v_SQL || 		'								SELECT provider_sid FROM product_questionnaire_provider pqp  ';
	v_SQL := v_SQL || 		'								WHERE pqp.PRODUCT_ID = pq.product_id   ';
	v_SQL := v_SQL || 		'								AND pqp.questionnaire_id = pq.questionnaire_id  ';
	v_SQL := v_SQL || 		'							)  ';
	v_SQL := v_SQL || 		'					)   ';
	v_SQL := v_SQL || 		'					OR   ';
	v_SQL := v_SQL || 		'					 (group_status_id IN (:DATA_SUBMITTED,:DATA_APPROVED))  ';
	v_SQL := v_SQL || 		'					)		  ';
				-- The product will not show after being approved 
	v_SQL := v_SQL || 		'				AND group_status_id <> :DATA_APPROVED  '; 
	v_SQL := v_SQL || 		'				GROUP BY p.product_id, p.product_code, p.description  ';
	v_SQL := v_SQL || 		'			) x  ';
	v_SQL := v_SQL || 		'			ORDER BY LOWER(' || in_order_by || ') ' || in_order_direction;
	v_SQL := v_SQL || 		'		 )	';
	v_SQL := v_SQL || 		'		 WHERE rownum <= :end_rec ';
	v_SQL := v_SQL || 		'	) WHERE rn > :start_rec ';
	
	
	OPEN out_cur FOR v_SQL
		USING DATA_SUBMITTED, in_group_id, in_group_id, in_user_sid, DATA_SUBMITTED, DATA_APPROVED, DATA_APPROVED,
			in_start+in_page_size, in_start;
	
END;


-- OPEN WORKFLOW
-- Open Workflow - gets all products a user has links to whatever the status
PROCEDURE GetOpenWkflwProdUserLink(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_group_id				IN questionnaire_group.group_id%TYPE,
	in_order_by				IN VARCHAR2,
	in_order_direction		IN VARCHAR2,
	in_start				IN NUMBER,
	in_page_size			IN NUMBER,
	in_approving			IN NUMBER,
	in_complete				IN NUMBER,
	in_from_dtm				IN DATE, 
	in_to_dtm				IN DATE, 
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
	v_SQL					VARCHAR2(8192);
BEGIN
	IF LOWER(in_order_by) NOT IN ('product_id', 'description', 'productcode', 'status', 'overdue') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_by not in the allowed list');
	END IF;
	IF LOWER(in_order_direction) NOT IN ('asc', 'desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_order_direction not asc or desc');
	END IF;

	
v_SQL := v_SQL || 		'	 SELECT * FROM  ';
v_SQL := v_SQL || 		'	 ( 	 ';
v_SQL := v_SQL || 		'		 SELECT rownum rn, total_count, product_id, productcode, description, group_status_id groupstatusid, duePI, dueP, dueF, dueT, dueS, duePD, dueFD,   ';
v_SQL := v_SQL || 		'			statusPI, statusP, statusF, statusT, statusS, statusPD, statusFD, started, overdue  ';
v_SQL := v_SQL || 		'		 FROM	';
v_SQL := v_SQL || 		'		 (	';
v_SQL := v_SQL || 		'			SELECT COUNT(*) OVER () total_count, tbl.product_id, productcode, description, group_status_id, duePI, dueP, dueF, dueT, dueS, duePD, dueFD,   ';
v_SQL := v_SQL || 		'				statusPI, statusP, statusF, statusT, statusS, statusPD, statusFD, started, MAX(overdue) overdue, is_complete FROM   ';
v_SQL := v_SQL || 		'			(  ';
v_SQL := v_SQL || 		'				SELECT product_id, productcode, description, statusPI, statusP, statusF, statusT, statusS, statusPD, statusFD, ';
v_SQL := v_SQL || 		'						duePI, dueP, dueF, dueT, dueS, duePD, dueFD, started, overdue, is_complete ';
v_SQL := v_SQL || 		'				  FROM ';
v_SQL := v_SQL || 		'				  ( ';
v_SQL := v_SQL || 		'					SELECT p.product_id, p.product_code productcode, p.description,';
v_SQL := v_SQL || 		'						statusPI, statusP, statusF, statusT, statusS, statusPD, statusFD,   ';
v_SQL := v_SQL || 		'						duePI, dueP, dueF, dueT, dueS, duePD, dueFD, started,  ';
v_SQL := v_SQL || 		'						CASE WHEN ((MIN(pq.due_date) < sysdate - 1) AND (min(group_status_id)!=:approved_group_status_id)) THEN 1 ELSE 0 END overdue, '; -- if the product is approved then can't be overdue
v_SQL := v_SQL || 		'						MIN(DECODE(pq.questionnaire_status_id, :open_status_id, 0, 1)) is_complete, ';
v_SQL := v_SQL || 		'						MIN(pq.last_saved_dtm) last_saved_dtm ';
v_SQL := v_SQL || 		'					FROM  ';
v_SQL := v_SQL || 		'						product p, product_questionnaire pq, product_questionnaire_approver pqa, questionnaire_group_membership qgm, product_questionnaire_group pqg, gt_product_user gpu,  ';
v_SQL := v_SQL || 		'						(SELECT pq.product_id,';
v_SQL := v_SQL || 		'						         nvl(sum(decode(pq.questionnaire_id, 8,pq.questionnaire_status_id)),0) statusPI,';
v_SQL := v_SQL || 		'						         nvl(sum(decode(pq.questionnaire_id, 9,pq.questionnaire_status_id)),0) statusP ,';
v_SQL := v_SQL || 		'						         nvl(sum(decode(pq.questionnaire_id,10,pq.questionnaire_status_id)),0) statusF ,';
v_SQL := v_SQL || 		'						         nvl(sum(decode(pq.questionnaire_id,11,pq.questionnaire_status_id)),0) statusT ,';
v_SQL := v_SQL || 		'						         nvl(sum(decode(pq.questionnaire_id,12,pq.questionnaire_status_id)),0) statusS ,';
v_SQL := v_SQL || 		'						         nvl(sum(decode(pq.questionnaire_id,13,pq.questionnaire_status_id)),0) statusPD,';
v_SQL := v_SQL || 		'						         nvl(sum(decode(pq.questionnaire_id,14,pq.questionnaire_status_id)),0) statusFD,';
v_SQL := v_SQL || 		'						         max(decode(pq.questionnaire_id, 8,pq.due_date)) duePI,';
v_SQL := v_SQL || 		'						         max(decode(pq.questionnaire_id, 9,pq.due_date)) dueP ,';
v_SQL := v_SQL || 		'						         max(decode(pq.questionnaire_id,10,pq.due_date)) dueF ,';
v_SQL := v_SQL || 		'						         max(decode(pq.questionnaire_id,11,pq.due_date)) dueT ,';
v_SQL := v_SQL || 		'						         max(decode(pq.questionnaire_id,12,pq.due_date)) dueS ,';
v_SQL := v_SQL || 		'						         max(decode(pq.questionnaire_id,13,pq.due_date)) duePD,';
v_SQL := v_SQL || 		'						         max(decode(pq.questionnaire_id,14,pq.due_date)) dueFD';
v_SQL := v_SQL || 		'						    FROM product_questionnaire pq';
v_SQL := v_SQL || 		'						    JOIN product p ON pq.product_id=p.product_id';
v_SQL := v_SQL || 		'						    JOIN product_questionnaire_approver pqa ON pq.questionnaire_id=pqa.questionnaire_id AND pq.product_id=pqa.product_id';
v_SQL := v_SQL || 		'						   WHERE pqa.approver_sid = :in_user_sid ';
v_SQL := v_SQL || 		'						   GROUP BY pq.product_id';
v_SQL := v_SQL || 		'						   ORDER BY pq.product_id) T';
v_SQL := v_SQL || 		'					WHERE p.product_id = pq.product_id ';
v_SQL := v_SQL || 		'					AND pq.questionnaire_id = pqa.questionnaire_id ';
v_SQL := v_SQL || 		'					AND pq.product_id = pqa.product_id ';
v_SQL := v_SQL || 		'					AND pq.product_id = T.product_id ';
v_SQL := v_SQL || 		'					AND pqa.questionnaire_id = qgm.questionnaire_id ';
v_SQL := v_SQL || 		'					AND p.product_id = pqg.product_id ';
v_SQL := v_SQL || 		'					AND pqg.group_id = :in_group_id ';
v_SQL := v_SQL || 		'					AND qgm.group_id = :in_group_id ';
v_SQL := v_SQL || 		'					AND pqa.approver_sid = :in_user_sid ';
v_SQL := v_SQL || 		'					AND gpu.user_sid = pqa.approver_sid';
v_SQL := v_SQL || 		'					AND pq.product_id = gpu.product_id';
v_SQL := v_SQL || 		'					AND active = 1 ';
v_SQL := v_SQL || 		'					GROUP BY p.product_id, p.product_code, p.description, statusPI, statusP, statusF, statusT, statusS, statusPD, statusFD,';   
v_SQL := v_SQL || 		'							duePI, dueP, dueF, dueT, dueS, duePD, dueFD, started';
v_SQL := v_SQL || 		'				) ';
v_SQL := v_SQL || 		'				WHERE (:in_complete = 0) OR ((is_complete = 1) AND ((last_saved_dtm >= NVL(:in_from_dtm, last_saved_dtm)) AND (last_saved_dtm <= NVL(:in_to_dtm, last_saved_dtm)))) ';

v_SQL := v_SQL || 		'				UNION		';
v_SQL := v_SQL || 		'				SELECT DISTINCT p.product_id, p.product_code productcode, p.description, ';
v_SQL := v_SQL || 		'					statusPI, statusP, statusF, statusT, statusS, statusPD, statusFD,   ';
v_SQL := v_SQL || 		'					duePI, dueP, dueF, dueT, dueS, duePD, dueFD, started, CASE WHEN (MIN(decode(pq.questionnaire_status_id, :open_status_id, pq.due_date, null)) < sysdate - 1) THEN 1 ELSE 0 END overdue, ';
v_SQL := v_SQL || 		'					MIN(DECODE(pq.questionnaire_status_id, :open_status_id, 0, 1)) is_complete ';
v_SQL := v_SQL || 		'				FROM  ';
v_SQL := v_SQL || 		'					product p, product_questionnaire pq, product_questionnaire_provider pqp, questionnaire_group_membership qgm, product_questionnaire_group pqg, gt_product_user gpu,  ';
v_SQL := v_SQL || 		'					(SELECT pq.product_id,';
v_SQL := v_SQL || 		'					         nvl(sum(decode(pq.questionnaire_id, 8,pq.questionnaire_status_id)),0) statusPI,';
v_SQL := v_SQL || 		'					         nvl(sum(decode(pq.questionnaire_id, 9,pq.questionnaire_status_id)),0) statusP ,';
v_SQL := v_SQL || 		'					         nvl(sum(decode(pq.questionnaire_id,10,pq.questionnaire_status_id)),0) statusF ,';
v_SQL := v_SQL || 		'					         nvl(sum(decode(pq.questionnaire_id,11,pq.questionnaire_status_id)),0) statusT ,';
v_SQL := v_SQL || 		'					         nvl(sum(decode(pq.questionnaire_id,12,pq.questionnaire_status_id)),0) statusS ,';
v_SQL := v_SQL || 		'					         nvl(sum(decode(pq.questionnaire_id,13,pq.questionnaire_status_id)),0) statusPD,';
v_SQL := v_SQL || 		'					         nvl(sum(decode(pq.questionnaire_id,14,pq.questionnaire_status_id)),0) statusFD,';
v_SQL := v_SQL || 		'					         max(decode(pq.questionnaire_id, 8,pq.due_date)) duePI,';
v_SQL := v_SQL || 		'					         max(decode(pq.questionnaire_id, 9,pq.due_date)) dueP ,';
v_SQL := v_SQL || 		'					         max(decode(pq.questionnaire_id,10,pq.due_date)) dueF ,';
v_SQL := v_SQL || 		'					         max(decode(pq.questionnaire_id,11,pq.due_date)) dueT ,';
v_SQL := v_SQL || 		'					         max(decode(pq.questionnaire_id,12,pq.due_date)) dueS ,';
v_SQL := v_SQL || 		'					         max(decode(pq.questionnaire_id,13,pq.due_date)) duePD,';
v_SQL := v_SQL || 		'					         max(decode(pq.questionnaire_id,14,pq.due_date)) dueFD';
v_SQL := v_SQL || 		'					    FROM product_questionnaire pq'; 
v_SQL := v_SQL || 		'					    JOIN product p ON pq.product_id=p.product_id';
v_SQL := v_SQL || 		'					    JOIN product_questionnaire_provider pqp ON pq.questionnaire_id=pqp.questionnaire_id AND pq.product_id=pqp.product_id';
v_SQL := v_SQL || 		'					   WHERE pqp.provider_sid = :in_user_sid ';
v_SQL := v_SQL || 		'					     AND :in_approving = 0 ';
v_SQL := v_SQL || 		'					   GROUP BY pq.product_id';
v_SQL := v_SQL || 		'					   ORDER BY pq.product_id) T';
v_SQL := v_SQL || 		'				WHERE p.product_id = pq.product_id ';
v_SQL := v_SQL || 		'				AND pq.questionnaire_id = pqp.questionnaire_id ';
v_SQL := v_SQL || 		'				AND pq.product_id = pqp.product_id ';
v_SQL := v_SQL || 		'				AND pq.product_id = T.product_id ';
v_SQL := v_SQL || 		'				AND pqp.questionnaire_id = qgm.questionnaire_id ';
v_SQL := v_SQL || 		'				AND p.product_id = pqg.product_id ';
v_SQL := v_SQL || 		'				AND pqg.group_id = :in_group_id ';
v_SQL := v_SQL || 		'				AND qgm.group_id = :in_group_id ';
v_SQL := v_SQL || 		'				AND pqp.provider_sid = :in_user_sid ';
v_SQL := v_SQL || 		'				AND gpu.user_sid = pqp.provider_sid';
v_SQL := v_SQL || 		'				AND pq.product_id = gpu.product_id';
v_SQL := v_SQL || 		'				AND active = 1 ';
v_SQL := v_SQL || 		'				AND (pq.questionnaire_status_id = :open_status_id OR NVL(pqg.status_changed_dtm, sysdate) > (sysdate - 14)) ';-- consider open or closed with in 2 weeks for providers
v_SQL := v_SQL || 		'				GROUP BY p.product_id, p.product_code, p.description, statusPI, statusP, statusF, statusT, statusS, statusPD, statusFD, duePI, dueP, dueF, dueT, dueS, duePD, dueFD, started ';   
v_SQL := v_SQL || 		'			) tbl JOIN product_questionnaire_group pqg ON tbl.product_id = pqg.product_id  ';
v_SQL := v_SQL || 		'		 	WHERE pqg.group_id  = :in_group_id ';
v_SQL := v_SQL || 		'			  AND ((:in_complete = 0) OR (is_complete = 1)) ';
v_SQL := v_SQL || 		'			GROUP BY tbl.product_id, productcode, description, group_status_id, statusPI, statusP, statusF, statusT, statusS, statusPD, statusFD,';   
v_SQL := v_SQL || 		'				duePI, dueP, dueF, dueT, dueS, duePD, dueFD, started, is_complete';
v_SQL := v_SQL || 		'			ORDER BY LOWER(' || in_order_by || ') ' || in_order_direction;
v_SQL := v_SQL || 		'		 )	';
v_SQL := v_SQL || 		'		 WHERE rownum <= :end_rec ';
v_SQL := v_SQL || 		'	)  ';
v_SQL := v_SQL || 		' WHERE rn > :start_rec ';


OPEN out_cur FOR v_SQL
	USING product_pkg.DATA_APPROVED, questionnaire_pkg.QUESTIONNAIRE_OPEN, in_user_sid, in_group_id, in_group_id, in_user_sid, in_complete, in_from_dtm, in_to_dtm, questionnaire_pkg.QUESTIONNAIRE_OPEN, questionnaire_pkg.QUESTIONNAIRE_OPEN, in_user_sid, 
		in_approving, in_group_id, in_group_id, in_user_sid, questionnaire_pkg.QUESTIONNAIRE_OPEN, in_group_id, in_complete, in_start+in_page_size, in_start;
 
END;

/*
PROCEDURE GetOpenWkflwProdUserLinkCnt(
	in_user_sid					IN security_pkg.T_SID_ID,
	in_app_sid					IN security_pkg.T_SID_ID,
	in_group_id					IN questionnaire_group.group_id%TYPE,
	out_count					OUT	NUMBER
)
AS
BEGIN

   SELECT COUNT(DISTINCT (product_id))  
   INTO out_count
   FROM
   (
	   SELECT p.product_id
	   FROM 
			product p, product_questionnaire pq, product_questionnaire_approver pqa, questionnaire_group_membership qgm, product_questionnaire_group pqg --pq = used only 
		WHERE p.product_id = pq.product_id
		AND pq.questionnaire_id = pqa.questionnaire_id
		AND pq.product_id = pqa.product_id
		AND pqa.questionnaire_id = qgm.questionnaire_id
		AND p.product_id = pqg.product_id
		AND pqg.group_id = in_group_id
		AND qgm.group_id = in_group_id
		AND pqa.approver_sid = in_user_sid
		AND active = 1
	   UNION
		SELECT p.product_id
		FROM 
			product p, product_questionnaire pq, product_questionnaire_provider pqp, questionnaire_group_membership qgm, product_questionnaire_group pqg --pq = used only 
		WHERE p.product_id = pq.product_id
		AND pq.questionnaire_id = pqp.questionnaire_id
		AND pq.product_id = pqp.product_id
		AND pqp.questionnaire_id = qgm.questionnaire_id
		AND p.product_id = pqg.product_id
		AND pqg.group_id = in_group_id
		AND qgm.group_id = in_group_id
		AND pqp.provider_sid = in_user_sid
		AND active = 1
		AND pq.questionnaire_status_id = questionnaire_pkg.QUESTIONNAIRE_OPEN -- consider open only for providers
	 );
		  
END;
*/

-- for a particular product and user return a list of all questionnaires ids, whether the questionnaire is used, and whether the user is linked to it as provider or approver. 
PROCEDURE GetAllowUserQLinks(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_product_id		IN user_report_settings.period_id%TYPE,
	out_cur 			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_user_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','SID');
	v_admin_approver_override	NUMBER(1) := 0;
	v_same_company				NUMBER(10) := 0;
BEGIN
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- Check write permission on companies folder in security - as this means approver or admin
	IF security_pkg.IsAccessAllowedSID(in_act_id, securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Supplier/Companies'), security_pkg.PERMISSION_WRITE) THEN
		v_admin_approver_override := 1;
	END IF;
	
	-- is the current user from the same company as the product - if so they are allowed full access to GT questionnaires - even if not linked
	  SELECT COUNT(*) 
		INTO v_same_company
		FROM company_user cu
		JOIN product p ON cu.app_sid = p.app_sid AND cu.company_sid = p.supplier_company_sid
	   WHERE cu.app_sid = v_app_sid
		 AND cu.csr_user_sid =  v_user_sid
		 AND p.product_id = in_product_id;
	
	IF v_same_company > 0 THEN 
		v_same_company := 1;		 
	END IF;

	
	OPEN out_cur FOR
	SELECT 	class_name, friendly_name, q.questionnaire_id, aa.used, pq.questionnaire_status_id,
			MAX(is_user_linked) is_user_linked, DECODE(MAX(allow_access), 1, 1, DECODE(q.workflow_type_id, questionnaire_pkg.Q_WORKFLOW_OPEN, v_same_company, 0)) allow_access FROM
	v$questionnaire q, all_product_questionnaire pq,
	(
			SELECT pql.questionnaire_id, used, NVL2(provider_sid, 1, 0) is_user_linked, NVL2(provider_sid, 1, v_admin_approver_override) allow_access FROM all_product_questionnaire pql, (SELECT * FROM product_questionnaire_provider WHERE provider_sid = v_user_sid) pqp
			WHERE pql.product_id = pqp.product_id(+)
			AND pql.questionnaire_id = pqp.questionnaire_id(+)
			AND pql.product_id = in_product_id
		UNION
			SELECT pql.questionnaire_id, used, NVL2(approver_sid, 1, 0) is_user_linked, NVL2(approver_sid, 1, v_admin_approver_override) allow_access FROM all_product_questionnaire pql, (SELECT * FROM product_questionnaire_approver WHERE approver_sid = v_user_sid) pqa 
			WHERE pql.product_id = pqa.product_id(+)
			AND pql.questionnaire_id = pqa.questionnaire_id(+)
			AND pql.product_id = in_product_id
	) aa
	WHERE q.questionnaire_id = aa.questionnaire_id
	  AND q.questionnaire_id = pq.questionnaire_id
	  AND pq.product_id = in_product_id
	  AND pq.used = 1
	GROUP BY q.class_name, q.friendly_name, q.questionnaire_id, q.workflow_type_id, aa.used, pq.questionnaire_status_id;
		
END;
	
PROCEDURE GetSalesVolumesForProduct(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_product_id		IN user_report_settings.period_id%TYPE,
	out_cur 			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF in_product_id > 0 THEN
	-- existing product
		OPEN out_cur FOR
			SELECT cpp.period_id, cpp.name period_name, NVL(psv.volume, 0) volume, 
			NVL(psv.value, 0) value, cpp.from_dtm, cpp.to_dtm 
			FROM (
				SELECT product_id, p.description, pr.period_id, pr.name, pr.from_dtm, pr.to_dtm 
				  FROM product p, customer_period cp, period pr
				 WHERE cp.app_sid = in_app_sid
				   AND p.app_sid = cp.app_sid
				   AND pr.period_id = cp.period_id
			) cpp, product_sales_volume psv
			WHERE cpp.product_id = psv.product_id(+)
				AND cpp.period_id = psv.period_id(+)
				AND cpp.product_id = in_product_id
			ORDER BY cpp.from_dtm, cpp.to_dtm;
	ELSE
	-- return empty set of values for a new product
		OPEN out_cur FOR
			SELECT pr.period_id, pr.name period_name, pr.from_dtm, pr.to_dtm,
				0 volume, 0 value
			 FROM  customer_period cp, period pr
			WHERE cp.app_sid = in_app_sid
			  AND cp.app_sid = cp.app_sid
			  AND pr.period_id = cp.period_id;
	END IF;
END;

-- This procedure does presume that the volume and value arrays are of the same dimension
PROCEDURE SetSalesVolumesForProduct(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_product_id		IN product_sales_volume.product_id%TYPE,
	in_period_ids		IN T_PERIODS,
	in_values			IN T_PRODUCT_VALUES,
	in_volumes			IN T_PRODUCT_SALES_VOLUMES
)
AS
BEGIN
	FOR i IN in_volumes.FIRST .. in_volumes.LAST
	LOOP
		BEGIN
			product_pkg.SetSalesVolumeForProduct(in_act_id, in_product_id, in_period_ids(i), in_values(i), in_volumes(i));		
		END;
	END LOOP;
END;

PROCEDURE SetSalesVolumeForProduct(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_product_code		IN product.product_code%TYPE,
	in_period_id		IN product_sales_volume.period_id%TYPE,
	in_value			IN product_sales_volume.value%TYPE,
	in_volume			IN product_sales_volume.volume%TYPE
)
AS
	v_product_id		product_sales_volume.product_id%TYPE;
BEGIN
	SELECT product_id
	  INTO v_product_id
	  FROM product
	 WHERE app_sid = in_app_sid
	   AND product_code = in_product_code;
	   
	-- Security check 
	IF NOT IsProductAccessAllowed(in_act_id, v_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to product with id '||v_product_id);
	END IF;
	
	-- Set the sales volume
	SetSalesVolumeForProduct(in_act_id, v_product_id, in_period_id, in_value, in_volume);
END;

PROCEDURE SetSalesVolumeForProduct(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_product_id		IN product_sales_volume.product_id%TYPE,
	in_period_id		IN product_sales_volume.period_id%TYPE,
	in_value			IN product_sales_volume.value%TYPE,
	in_volume			IN product_sales_volume.volume%TYPE
)
AS
	v_period_name		period.name%TYPE;
	v_app_sid 		security_pkg.T_SID_ID;
	v_volume			NUMBER;
	v_value				NUMBER;
BEGIN
	
	SELECT name INTO v_period_name FROM period WHERE period_id = in_period_id;
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
	
	IF in_value + in_volume = 0 THEN
		-- if the volume and values are zero then delete volume record	
		DELETE FROM product_sales_volume 
			WHERE product_id = in_product_id
			  AND period_id = in_period_id;
			  
		IF SQL%ROWCOUNT > 0 THEN
			audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_VOL_CHANGED, v_app_sid, v_app_sid, 
				'Product volume cleared for {0}', v_period_name, NULL, NULL, in_product_id);
		END IF;
			  		
	ELSE
		-- upsert 
		BEGIN
			INSERT INTO product_sales_volume (product_id, period_id, value, volume)
				VALUES (in_product_id, in_period_id, in_value, in_volume);
				
			audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_VOL_CHANGED, v_app_sid, v_app_sid, 
				'Product volume set for {0}- Volume:{1} Value:{2}', v_period_name, in_volume, in_value, in_product_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
			BEGIN
				SELECT volume, value
				  INTO v_volume, v_value
				  FROM product_sales_volume
				 WHERE product_id = in_product_id
				   AND period_id = in_period_id;
				 
				UPDATE product_sales_volume 
				   SET 
				   value = in_value,
				   volume = in_volume
				 WHERE product_id = in_product_id
				 AND period_id = in_period_id;
				 
			  audit_pkg.AuditValueChange(in_act_id,csr.csr_data_pkg.AUDIT_TYPE_PROD_VOL_CHANGED, v_app_sid, v_app_sid,
				'Product volume', v_volume, in_volume);
			  audit_pkg.AuditValueChange(in_act_id,csr.csr_data_pkg.AUDIT_TYPE_PROD_VOL_CHANGED, v_app_sid, v_app_sid,
				'Product value', v_value, in_value);
			END;
		END;		
	END IF;
					
END;


FUNCTION GetSaleType(
	in_product_id			IN 	product.product_id%TYPE
) RETURN NUMBER
IS
	v_tag_id				tag.tag_id%TYPE;
BEGIN
	BEGIN
		SELECT pt.tag_id
		  INTO v_tag_id
		  FROM product_tag pt, tag_group tg, tag_group_member tm, product p
		 WHERE pt.product_id = in_product_id
		   AND pt.tag_id = tm.tag_id
		   AND p.product_id = pt.product_id
		   AND tm.tag_group_sid = tg.tag_group_sid
		   AND tg.app_sid = p.app_sid
		   AND tg.name = 'sale_type';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_tag_id := NULL;
	END;
	
	RETURN v_tag_id;
END;

FUNCTION GetMerchantType(
	in_product_id			IN 	product.product_id%TYPE
) RETURN NUMBER
IS
	v_tag_id				tag.tag_id%TYPE;
BEGIN
	BEGIN
		SELECT pt.tag_id
		  INTO v_tag_id
		  FROM product_tag pt, tag_group tg, tag_group_member tm
		 WHERE pt.product_id = in_product_id
		   AND pt.tag_id = tm.tag_id
		   AND tm.tag_group_sid = tg.tag_group_sid
		   AND tg.name = 'merchant_type';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_tag_id := NULL;
	END;
	
	RETURN v_tag_id;
END;

FUNCTION GetMerchantTypeDescription(
	in_product_id			IN 	product.product_id%TYPE
) RETURN VARCHAR2
IS
	v_explanation			tag.explanation%TYPE;
BEGIN
	BEGIN
		SELECT t.explanation
		  INTO v_explanation
		  FROM tag t, product_tag pt, tag_group tg, tag_group_member tm
		 WHERE pt.product_id = in_product_id
		   AND t.tag_id = pt.tag_id
		   AND pt.tag_id = tm.tag_id
		   AND tm.tag_group_sid = tg.tag_group_sid
		   AND tg.name = 'merchant_type';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_explanation := NULL;
	END;
	
	RETURN v_explanation;
END;

PROCEDURE GetProductTags(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_tag_group_name		IN tag_group.name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	IF in_tag_group_name IS NULL THEN
		OPEN out_cur FOR
			SELECT tag_id, note, num
			  FROM product_tag
			 WHERE product_id = in_product_id;
	ELSE
		OPEN out_cur FOR
			SELECT pt.tag_id, pt.note, pt.num
			  FROM product_tag pt, tag_group_member tgm, tag_group tg
			 WHERE tg.name = in_tag_group_name
			   AND tgm.tag_group_sid = tg.tag_group_sid
			   AND pt.tag_id = tgm.tag_id
			   AND pt.product_id = in_product_id
			   	ORDER BY tgm.pos ASC;
	END IF;
	
END;

FUNCTION IsProductAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_product_id			IN 	product.product_id%TYPE,
	in_perms				IN 	security_pkg.T_PERMISSION
) RETURN BOOLEAN
IS
	v_company_sid	security_pkg.T_SID_ID;
BEGIN
	-- Get the company sid to check against
	BEGIN
		SELECT supplier_company_sid
		  INTO v_company_sid
		  FROM product
		 WHERE product_id = in_product_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Product not found');
	END;
	-- Retuern the check result form security
	RETURN security_pkg.IsAccessAllowedSID(in_act_id, v_company_sid, in_perms);
END;

PROCEDURE IsProductAccessAllowedWrite(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_allow				OUT NUMBER
)
AS 
BEGIN
	out_allow := 0;
	IF IsProductAccessAllowed(in_act_id,in_product_id, security_pkg.PERMISSION_WRITE) THEN 
		out_allow := 1;
	END IF;
END;

PROCEDURE GetProdGroupStatus(
	in_product_id			IN product.product_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	OPEN out_cur FOR
		SELECT group_status_id FROM product_questionnaire_group
		 WHERE product_id = in_product_id
		   AND group_id = in_group_id;
	
END;

PROCEDURE GetProdGroupStatusFromQClass(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_id			IN product.product_id%TYPE,
	in_class				IN questionnaire.class_name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_group_id				product_questionnaire_group.group_id%TYPE;
BEGIN
	SELECT DISTINCT qg.group_id 
	  INTO v_group_id
	  FROM questionnaire q, questionnaire_group_membership qgm, questionnaire_group qg
	 WHERE q.questionnaire_id = qgm.questionnaire_id
	   AND qgm.group_id = qg.group_id 
	   AND qg.app_sid = in_app_sid
	   AND class_name = in_class;
	
	GetProdGroupStatus(in_product_id, v_group_id, out_cur);
	
END;

PROCEDURE SetProductGroupStatus(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_status_id			IN product_questionnaire_group.group_status_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE
)
AS
	dummy					security_pkg.T_OUTPUT_CUR;
BEGIN
	SetProductGroupStatus(in_act_id, in_product_id, in_group_id, in_status_id, dummy);
END;

PROCEDURE SetProductGroupStatus(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE,
	in_status_id			IN product_questionnaire_group.group_status_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_old_status_id				group_status.group_status_id%TYPE;
	v_old_status_desc			group_status.description%TYPE;
	v_new_status_desc			group_status.description%TYPE;
	v_group_name				questionnaire_group.name%TYPE;
	v_declaration_user_sid		security_pkg.T_SID_ID;
	v_full_name					csr.csr_user.full_name%TYPE;
	v_user_sid					security_pkg.T_SID_ID;
	v_user_is_approver 			NUMBER;
	v_app_sid 					security_pkg.T_SID_ID;
BEGIN
	
	
	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT pqg.group_status_id, gs.description, qg.app_sid, qg.name
	  INTO v_old_status_id, v_old_status_desc, v_app_sid, v_group_name
	  FROM questionnaire_group qg, product_questionnaire_group pqg, group_status gs 
	 WHERE qg.group_id = pqg.group_id
	   AND pqg.group_status_id = gs.group_status_id
	   AND product_id = in_product_id
	   AND qg.group_id = in_group_id;

	SELECT description INTO v_new_status_desc FROM group_status gs WHERE gs.group_status_id = in_status_id;
	
	IF v_old_status_id != in_status_id THEN
		UPDATE product_questionnaire_group
		   SET group_status_id = in_status_id,
		   	   status_changed_dtm = SYSDATE
		 WHERE product_id = in_product_id
		   AND group_id = in_group_id;
		 
		-- Audit changes
		audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_STATE_CHANGED, v_app_sid, v_app_sid,
			'Product group ('||'v_group_desc'||') status', v_old_status_desc, v_new_status_desc, in_product_id);
		
		-- Set the declaration sid/status
		CASE in_status_id
			WHEN DATA_SUBMITTED THEN
				-- Submitted implies declaration made by current user
				user_pkg.GetSID(in_act_id, v_declaration_user_sid);
				UPDATE product_questionnaire_group
				   SET declaration_made_by_sid = v_declaration_user_sid
				 WHERE product_id = in_product_id
				   AND group_id = in_group_id;
				 
			WHEN DATA_BEING_ENTERED THEN
				-- Data being entered, any previous declaration invalid
				UPDATE product_questionnaire_group
				   SET declaration_made_by_sid = null
				 WHERE product_id = in_product_id
				   AND group_id = in_group_id;
				 
			ELSE
				-- In other cases just get the user sid of the current declaration
				SELECT declaration_made_by_sid
				  INTO v_declaration_user_sid
				  FROM product_questionnaire_group
				 WHERE product_id = in_product_id
				 AND group_id = in_group_id;
		END CASE;
		
		user_pkg.GetSID(in_act_id, v_user_sid);
		
		SELECT COUNT(*) INTO v_user_is_approver FROM (
			SELECT MAX(approver_sid) mx, MIN(approver_sid) mn 
			  FROM product_questionnaire pq, product_questionnaire_approver pqa, questionnaire_group_membership qgm
			 WHERE pq.product_id = in_product_id
			   AND qgm.group_id = in_group_id
			   AND pq.product_id = pqa.product_id
			   AND pq.questionnaire_id = pqa.questionnaire_id
			   AND qgm.questionnaire_id = pqa.questionnaire_id
		)
		WHERE mn = mx AND mn = v_user_sid; 
		
		-- if we are setting to data entry or for review set all Q's open
		-- if we are submitting set the Q's to open - unless the submitting user is the data approver - in which case presumably they are OK with the data
		IF ((in_status_id = DATA_BEING_ENTERED) 
				OR 	(in_status_id = DATA_BEING_REVIEWED)
				OR 	((in_status_id = DATA_SUBMITTED) AND (v_user_is_approver = 0))) 
		THEN
			questionnaire_pkg.SetQuestStatusesForProdGroup(in_act_id, in_product_id, in_group_id, questionnaire_pkg.QUESTIONNAIRE_OPEN);
		END IF;
		
		IF in_status_id = DATA_APPROVED THEN
			questionnaire_pkg.SetQuestStatusesForProdGroup(in_act_id, in_product_id, in_group_id, questionnaire_pkg.QUESTIONNAIRE_CLOSED);
		END IF;
		
	ELSE
		-- Status unchanged, get the sid of the current delcaration
		SELECT declaration_made_by_sid
		  INTO v_declaration_user_sid
		  FROM product_questionnaire_group
		 WHERE product_id = in_product_id
		 AND group_id = in_group_id;
	END IF;
	
	-- Try to get the declaration user name
	v_full_name := NULL;
	BEGIN
		SELECT full_name
		  INTO v_full_name
		  FROM csr.csr_user
		 WHERE csr_user_sid = v_declaration_user_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- Ignore
	END;
	
	OPEN out_cur FOR
		SELECT in_status_id product_group_status, v_declaration_user_sid declaration_user_sid, v_full_name full_name
		  FROM DUAL;
	
END;

PROCEDURE GetProductGroupQuestStatuses(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	in_group_id				IN product_questionnaire_group.group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT q.class_name, pq.questionnaire_status_id
		  FROM questionnaire q, product_questionnaire pq, questionnaire_group_membership qgm
		 WHERE pq.questionnaire_id = q.questionnaire_id
   		   AND q.questionnaire_id = qgm.questionnaire_id
			AND q.active = 1
			AND pq.product_id = in_product_id
			AND qgm.group_id = in_group_id;
END;

/*unlike GetProductsUserApproving/GetProductsUserProviding - this isn't concerned with 
 what work needs doing - this is just "get me the products with this user as provider" */ 
PROCEDURE GetProductsUserIsProviderFor(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_user_sid				IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.product_id, p.product_code, p.description, p.supplier_company_sid, p.active, p.deleted, p.app_sid,
		       pq.questionnaire_id, pq.questionnaire_status_id, pq.due_date, pq.last_saved_by_sid, pq.last_saved_by, pq.last_saved_dtm,
		       pqp.provider_sid
		  FROM product p, product_questionnaire pq, product_questionnaire_provider pqp
		 WHERE p.product_id = pq.product_id 
		   AND pq.questionnaire_id = pqp.questionnaire_id
		   AND pq.product_id = pqp.product_id
		   AND pqp.provider_sid = in_user_sid;
END;

/*unlike GetProductsUserApproving/GetProductsUserProviding - this isn't concerned with 
 what work needs doing - this is just "get me the products with this user as approver" */ 
PROCEDURE GetProductsUserIsApproverFor(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_user_sid				IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.product_id, p.product_code, p.description, p.supplier_company_sid, p.active, p.deleted, p.app_sid,
		       pq.questionnaire_id, pq.questionnaire_status_id, pq.due_date, pq.last_saved_by_sid, pq.last_saved_by, pq.last_saved_dtm,
		       pqa.approver_sid
		  FROM product p, product_questionnaire pq, product_questionnaire_approver pqa
		 WHERE p.product_id = pq.product_id
		   AND pq.questionnaire_id = pqa.questionnaire_id
		   AND pq.product_id = pqa.product_id
		   AND pqa.approver_sid = in_user_sid;
END;

PROCEDURE GetProductsUserIsLinkedTo(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_user_sid				IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.product_id, p.product_code, p.description, p.supplier_company_sid, p.active, p.deleted, p.app_sid,
		       pq.questionnaire_id, pq.questionnaire_status_id, pq.due_date, pq.last_saved_by_sid, pq.last_saved_by, pq.last_saved_dtm,
		       pqp.provider_sid,
		       pqa.approver_sid
		  FROM product p, product_questionnaire pq, product_questionnaire_provider pqp, product_questionnaire_approver pqa
		 WHERE p.product_id = pq.product_id 
		   AND pq.questionnaire_id = pqp.questionnaire_id(+)
		   AND pq.questionnaire_id = pqa.questionnaire_id(+)
		   AND pq.product_id = pqp.product_id(+)
		   AND pq.product_id = pqa.product_id(+)
		   AND (pqp.provider_sid = in_user_sid OR pqa.approver_sid = in_user_sid);
END;

FUNCTION GetMinCertExpiryDate (
	in_product_id			IN product.product_id%TYPE
)RETURN DATE
AS
	v_type_min_date			DATE;
	v_all_min_date 			DATE;
BEGIN

	-- get all the distinct part types linked to the product and loop through 
	FOR r IN (
		SELECT DISTINCT pt.PACKAGE FROM product_part pp, part_type pt 
			WHERE pp.part_type_id = pt.part_type_id 
			  AND pp.product_id = in_product_id
	)
	LOOP
		v_type_min_date := NULL;
		-- get min date for all parts of a certain type using xxx_pkg.GetMinCertExpiryDate for part
		IF r.package IS NOT NULL THEN
			EXECUTE IMMEDIATE 'begin '||r.package||'.GetMinDateForType(:1,:2);end;'
				USING in_product_id, OUT v_type_min_date;
		END IF;
			
		-- update date if it's not null and less than current min or current min is null 
		IF (v_type_min_date IS NOT NULL) AND ((v_all_min_date IS NULL) OR (v_all_min_date > v_type_min_date)) THEN
			v_all_min_date := v_type_min_date;
		END IF;
	END LOOP;
	
	-- return date
	RETURN v_all_min_date;

END;

FUNCTION ProductExists(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE
) RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	SELECT COUNT(0)
	  INTO v_count
	  FROM product
	 WHERE app_sid = in_app_sid
	   AND product_code = in_product_code;
	RETURN v_count;
END;

FUNCTION GetProdCodeFromTag(
	in_tag_id				IN tag.tag_id%TYPE
) RETURN VARCHAR2
AS
	v_stem					VARCHAR2(32);
	v_count					NUMBER;
	v_product_code			VARCHAR2(256);					
BEGIN
	
	BEGIN
		SELECT stem INTO v_stem 
			FROM product_code_stem pcs, product_code_stem_tag pcst 
			WHERE pcs.product_code_stem_id = pcst.product_code_stem_id
			AND pcst.tag_id = in_tag_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_stem := '';
	END;

	LOOP
		SELECT v_stem || TO_CHAR(product_code_seq.nextval) INTO v_product_code FROM DUAL;
		
		SELECT COUNT(*) INTO v_count 
			FROM ALL_PRODUCT -- don't make work for ourselves if we ever have to undelete
			WHERE lower(product_code) = lower(v_product_code);  
		
		EXIT WHEN v_count = 0;
	END LOOP;
	
	RETURN  v_product_code;
	
END;

PROCEDURE GetAllProviderUsers(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_app_sid						IN security_pkg.T_SID_ID,
	in_product_id						IN product.product_id%TYPE,
	in_used_only						IN all_product_questionnaire.used%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	OPEN out_cur FOR
		SELECT qg.group_id, qg.questionnaire_id, qg.friendly_name questionnaire_name, pq.product_id, pq.questionnaire_status_id, pq.used, pq.due_date, pq.provider_sid,
			   cu.company_sid, c.name company_name, u.csr_user_sid, u.full_name, u.email
		FROM csr.csr_user u, company_user cu, company c,
			(
				SELECT qgm.group_id, qgm.questionnaire_id, q.friendly_name
				FROM questionnaire_group qg, questionnaire_group_membership qgm, questionnaire q
				WHERE qg.group_id = qgm.GROUP_ID
				AND qgm.questionnaire_id = q.questionnaire_id
				AND qg.app_sid = in_app_sid
			) qg,
			(
				SELECT pql.product_id, pql.questionnaire_id, pql.questionnaire_status_id, pql.used, pql.due_date, pqp.provider_sid
				FROM all_product_questionnaire pql, product_questionnaire_provider pqp	
				WHERE pql.product_id = pqp.product_id
				AND ((in_used_only=0) OR (in_used_only IS NULL) OR (pql.used = 1))
				AND pql.questionnaire_id = pqp.questionnaire_id
				AND pql.product_id = in_product_id
			) pq
		WHERE pq.questionnaire_id = qg.questionnaire_id
		AND pq.provider_sid = u.csr_user_sid
		AND pq.provider_sid = cu.csr_user_sid
		AND cu.company_sid = c.company_sid;

END;

PROCEDURE GetProvidersForQuestionnaire(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE,
	in_questionnaire_id		IN questionnaire.questionnaire_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	OPEN out_cur FOR
		SELECT pq.product_id, pq.questionnaire_id, pq.questionnaire_status_id, pqp.provider_sid
		FROM product_questionnaire pq, product_questionnaire_provider pqp, csr.csr_user cu
			WHERE pq.product_id = pqp.product_id  
			AND pq.questionnaire_id = pqp.questionnaire_id 
			AND pqp.provider_sid = cu.csr_user_sid
			AND pq.product_id = in_product_id 
   	  		AND pq.questionnaire_id = in_questionnaire_id;

END;

-- Clear existing links and set new links passed in
PROCEDURE SetQuestionnaireProviderLinks(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE,
	in_questionnaire_id		IN questionnaire.questionnaire_id%TYPE,
	in_user_sids					IN security_pkg.T_SID_IDS,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid					security_pkg.T_SID_ID;
	t_user_sids						security.T_SID_TABLE;
BEGIN

	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	t_user_sids := security_pkg.SidArrayToTable(in_user_sids);
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;

	/*IF in_user_sids.COUNT = 1 AND in_user_sids(1) IS NULL THEN
		RETURN;
	END IF;*/
	
	-- delete users no longer linked 
	-- could do this in one if not for audit calls - but not a big deal
	FOR r IN 
		(SELECT provider_sid FROM product_questionnaire_provider pqp
			WHERE product_id = in_product_id 
			AND questionnaire_id = in_questionnaire_id
			AND provider_sid NOT IN (SELECT column_value FROM TABLE(t_user_sids))
		 )
	LOOP
		BEGIN

			DELETE FROM product_questionnaire_provider 
				WHERE product_id = in_product_id	
					AND questionnaire_id = in_questionnaire_id
					AND provider_sid = r.provider_sid; -- products are never shared across applications so this is safe
					
			DELETE FROM gt_product_user
				  WHERE product_id = in_product_id
				    AND user_sid = r.provider_sid
					AND NOT EXISTS (SELECT product_id 
									  FROM product_questionnaire_approver 
									 WHERE product_id = in_product_id 
									   AND approver_sid = r.provider_sid
									UNION 
									SELECT product_id 
									  FROM product_questionnaire_provider 
									 WHERE product_id = in_product_id 
									   AND provider_sid = r.provider_sid);
			-- Audit deletion
			audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_DP_CHANGED, v_app_sid, v_app_sid, 
				'Data provider deleted. Name: {0} ({1})  Questionnaire: {2}', 
				csr.csr_user_pkg.GetUserNameFromSid(in_act_id, r.provider_sid), r.provider_sid, in_questionnaire_id, in_product_id);
		
		END;
	END LOOP;
		  
	-- add users 
	FOR r IN 
		(SELECT column_value user_sid FROM TABLE(t_user_sids) 
			WHERE column_value NOT IN (
	 			SELECT provider_sid FROM product_questionnaire_provider 
   			WHERE product_id = in_product_id 
	 		AND questionnaire_id = in_questionnaire_id
		  )
		)
	LOOP
		BEGIN
			
			BEGIN
				INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid)  
						VALUES(in_product_id, in_questionnaire_id, r.user_sid);
						
				INSERT INTO gt_product_user (product_id, user_sid)
						VALUES(in_product_id, r.user_sid);
				-- Audit addition
				audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_DP_CHANGED, v_app_sid, v_app_sid, 
					'Data provider added. Name: {0} ({1}) Questionnaire: {2}', 
					csr.csr_user_pkg.GetUserNameFromSid(in_act_id, r.user_sid), r.user_sid, in_questionnaire_id, in_product_id);
				
				EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN	-- do nothing
					NULL;
			END;

		
		END;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT product_id, questionnaire_id, provider_sid
		  FROM product_questionnaire_provider
		 WHERE product_id = in_product_id
		   AND questionnaire_id = in_questionnaire_id;
END;

PROCEDURE GetAllApproverUsers(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_app_sid							IN security_pkg.T_SID_ID,
	in_product_id						IN product.product_id%TYPE,
	in_used_only						IN all_product_questionnaire.used%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	OPEN out_cur FOR
		SELECT qg.group_id, qg.questionnaire_id, qg.friendly_name questionnaire_name, pq.product_id, pq.questionnaire_status_id, pq.used, pq.due_date, pq.approver_sid,
			   cu.company_sid, c.name company_name, u.csr_user_sid, u.full_name, u.email
		FROM csr.csr_user u, company_user cu, company c,
			(
				SELECT qgm.group_id, qgm.questionnaire_id, q.friendly_name
				FROM questionnaire_group qg, questionnaire_group_membership qgm, questionnaire q
				WHERE qg.group_id = qgm.GROUP_ID
				AND qgm.questionnaire_id = q.questionnaire_id
				AND qg.app_sid = in_app_sid
			) qg,
			(
				SELECT pql.product_id, pql.questionnaire_id, pql.questionnaire_status_id, pql.used, pql.due_date, pqp.approver_sid
				FROM all_product_questionnaire pql, product_questionnaire_approver pqp	
				WHERE pql.product_id = pqp.product_id
				AND pql.questionnaire_id = pqp.questionnaire_id
				AND ((in_used_only=0) OR (in_used_only IS NULL) OR (pql.used = 1))
				AND pql.product_id = in_product_id
			) pq
		WHERE pq.questionnaire_id = qg.questionnaire_id
		AND pq.approver_sid = u.csr_user_sid
		AND pq.approver_sid = cu.csr_user_sid
		AND cu.company_sid = c.company_sid;

END;

PROCEDURE GetAllUsers(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_app_sid							IN security_pkg.T_SID_ID,
	in_product_id						IN product.product_id%TYPE,
	in_used_only						IN all_product_questionnaire.used%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	OPEN out_cur FOR
		SELECT pos, group_id, group_name, questionnaire_id, questionnaire_name, user_sid, is_approver,
					   company_sid, company_name, csr_user_sid, full_name, email, workflow_type_id
		FROM
		(
			   SELECT qg.pos, qg.group_id, qg.name group_name, qg.questionnaire_id, qg.friendly_name questionnaire_name, pq.approver_sid user_sid, 1 is_approver,
					   cu.company_sid, c.name company_name, u.csr_user_sid, u.full_name, u.email, qg.workflow_type_id
				FROM csr.csr_user u, company_user cu, company c,
					(
						SELECT qgm.group_id, qgm.questionnaire_id, q.friendly_name, qg.name, qgm.pos, qg.workflow_type_id
						FROM questionnaire_group qg, questionnaire_group_membership qgm, questionnaire q
						WHERE qg.group_id = qgm.GROUP_ID
						AND qgm.questionnaire_id = q.questionnaire_id
						AND qg.app_sid = in_app_sid
					) qg,
					(
						SELECT pql.product_id, pql.questionnaire_id, pql.questionnaire_status_id, pql.used, pql.due_date, pqp.approver_sid
						FROM all_product_questionnaire pql, product_questionnaire_approver pqp	
						WHERE pql.product_id = pqp.product_id
						AND pql.questionnaire_id = pqp.questionnaire_id
						AND ((in_used_only=0) OR (in_used_only IS NULL) OR (pql.used = 1))
						AND pql.product_id = in_product_id
					) pq
				WHERE pq.questionnaire_id = qg.questionnaire_id
				AND pq.approver_sid = u.csr_user_sid
				AND pq.approver_sid = cu.csr_user_sid
				AND cu.company_sid = c.company_sid
				UNION
				SELECT qg.pos, qg.group_id, qg.name group_name, qg.questionnaire_id, qg.friendly_name questionnaire_name, pq.provider_sid user_sid, 0 is_approver,
					   cu.company_sid, c.name company_name, u.csr_user_sid, u.full_name, u.email, qg.workflow_type_id
				FROM csr.csr_user u, company_user cu, company c,
					(
						SELECT qgm.group_id, qgm.questionnaire_id, q.friendly_name, qg.name, qgm.pos, qg.workflow_type_id
						FROM questionnaire_group qg, questionnaire_group_membership qgm, questionnaire q
						WHERE qg.group_id = qgm.GROUP_ID
						AND qgm.questionnaire_id = q.questionnaire_id
						AND qg.app_sid = in_app_sid
					) qg,
					(
						SELECT pql.product_id, pql.questionnaire_id, pql.questionnaire_status_id, pql.used, pql.due_date, pqp.provider_sid
						FROM all_product_questionnaire pql, product_questionnaire_provider pqp	
						WHERE pql.product_id = pqp.product_id
						AND pql.questionnaire_id = pqp.questionnaire_id
						AND ((in_used_only=0) OR (in_used_only IS NULL) OR (pql.used = 1))
						AND pql.product_id = in_product_id
					) pq
				WHERE pq.questionnaire_id = qg.questionnaire_id
				AND pq.provider_sid = u.csr_user_sid
				AND pq.provider_sid = cu.csr_user_sid
				AND cu.company_sid = c.company_sid
		) 
		ORDER BY group_id asc, pos, is_approver asc, lower(full_name);

END;

PROCEDURE GetApproversForQuestionnaire(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE,
	in_questionnaire_id				IN questionnaire.questionnaire_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	OPEN out_cur FOR
		SELECT pq.product_id, pq.questionnaire_id, pq.questionnaire_status_id, pqa.approver_sid
		FROM product_questionnaire pq, product_questionnaire_approver pqa, csr.csr_user cu
			WHERE pq.product_id = pqa.product_id  
			AND pq.questionnaire_id = pqa.questionnaire_id 
			AND pqa.approver_sid = cu.csr_user_sid
			AND pq.product_id = in_product_id 
   	  AND pq.questionnaire_id = in_questionnaire_id;

END;


PROCEDURE GetApproversForGrpQuestionn(
	in_product_id						IN product.product_id%TYPE,
	in_group_id							IN questionnaire_group.group_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN

	IF NOT IsProductAccessAllowed(v_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	OPEN out_cur FOR
		SELECT csr_user_sid,full_name,email 
		  FROM csr.csr_user
		 WHERE csr_user_sid in (
						SELECT DISTINCT approver_sid 
						  FROM product_questionnaire_approver pqa, questionnaire_group_membership qgm  
                         WHERE qgm.questionnaire_id = pqa.questionnaire_id
                           AND pqa.PRODUCT_ID = in_product_id
                           AND qgm.group_id = in_group_id
						   );

END;


PROCEDURE GetProvidersForGrpQuestionn(
	in_product_id						IN product.product_id%TYPE,
	in_group_id							IN questionnaire_group.group_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN

	IF NOT IsProductAccessAllowed(v_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	OPEN out_cur FOR
		SELECT csr_user_sid,full_name,email 
		  FROM csr.csr_user
		 WHERE csr_user_sid in (
						SELECT DISTINCT provider_sid 
						   FROM product_questionnaire_provider pqa, questionnaire_group_membership qgm  
                          WHERE qgm.questionnaire_id = pqa.questionnaire_id
                            AND pqa.PRODUCT_ID = in_product_id
                            AND qgm.group_id = in_group_id
						   );

END;


-- Clear existing links and set new links passed in
PROCEDURE SetQuestionnaireApproverLinks(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE,
	in_questionnaire_id		IN questionnaire.questionnaire_id%TYPE,
	in_user_sids					IN security_pkg.T_SID_IDS,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid					security_pkg.T_SID_ID;
	t_user_sids						security.T_SID_TABLE;
BEGIN

	IF NOT IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	t_user_sids := security_pkg.SidArrayToTable(in_user_sids);
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;

	/*IF in_user_sids.COUNT = 1 AND in_user_sids(1) IS NULL THEN
		-- no users		
		RETURN;
	END IF;*/
	
	-- delete users no longer linked 
	-- could do this in one if not for audit calls - but not a big deal
	FOR r IN 
		(SELECT approver_sid FROM product_questionnaire_approver pqa
			WHERE product_id = in_product_id 
			AND questionnaire_id = in_questionnaire_id
			AND approver_sid NOT IN (SELECT column_value FROM TABLE(t_user_sids))
		 )
	LOOP
		BEGIN

			DELETE FROM product_questionnaire_approver 
				WHERE product_id = in_product_id	
					AND questionnaire_id = in_questionnaire_id
					AND approver_sid = r.approver_sid; -- products are never shared across applications so this is safe
					
			DELETE FROM gt_product_user
				  WHERE product_id = in_product_id
				    AND user_sid = r.approver_sid
					AND NOT EXISTS (SELECT product_id 
									  FROM product_questionnaire_approver 
									 WHERE product_id = in_product_id 
									   AND approver_sid = r.approver_sid
									UNION 
									SELECT product_id 
									  FROM product_questionnaire_provider 
									 WHERE product_id = in_product_id 
									   AND provider_sid = r.approver_sid);
			-- Audit deletion
			audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_DP_CHANGED, v_app_sid, v_app_sid, 
				'Data approver deleted. Name: {0} ({1})  Questionnaire: {2}', 
				csr.csr_user_pkg.GetUserNameFromSid(in_act_id, r.approver_sid), r.approver_sid, in_questionnaire_id, in_product_id);
		
		END;
	END LOOP;
		  
	-- add users 
	FOR r IN 
		(SELECT column_value user_sid FROM TABLE(t_user_sids) 
			WHERE column_value NOT IN (
	 			SELECT approver_sid FROM product_questionnaire_approver
   			WHERE product_id = in_product_id 
	 		AND questionnaire_id = in_questionnaire_id
		  )
		)
	LOOP
		BEGIN
			
			BEGIN
				INSERT INTO product_questionnaire_approver (product_id, questionnaire_id, approver_sid)  
						VALUES(in_product_id, in_questionnaire_id, r.user_sid);
				
				INSERT INTO gt_product_user (product_id, user_sid)
						VALUES (in_product_id, r.user_sid);
				-- Audit addition
				audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_PROD_DA_CHANGED, v_app_sid, v_app_sid, 
					'Data approver added. Name: {0} ({1}) Questionnaire: {2}', 
					csr.csr_user_pkg.GetUserNameFromSid(in_act_id, r.user_sid), r.user_sid, in_questionnaire_id, in_product_id);
				
				EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN	-- do nothing
					NULL;
			END;

		
		END;
	END LOOP;

	OPEN out_cur FOR
		SELECT product_id, questionnaire_id, approver_sid
		  FROM product_questionnaire_approver
		 WHERE product_id = in_product_id
		   AND questionnaire_id = in_questionnaire_id;

END;

PROCEDURE GetQuestionnairesForProduct(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_app_sid							IN security_pkg.T_SID_ID,
	in_product_id						IN product.product_id%TYPE,
	in_used_only						IN all_product_questionnaire.used%TYPE,
	out_cur 							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Security check??
	OPEN out_cur FOR
	SELECT 	q.questionnaire_id, q.active, q.class_name, q.friendly_name, q.description, qg.group_id, qg.name group_name, qg.workflow_type_id,
			NVL(pql.used, 0) used, NVL(pql.due_date, sysdate+30) due_date, NVL(pql.questionnaire_status_id, -1) questionnaire_status_id, 
			NVL(pql.group_status_id, -1) group_status_id, NVL(pql.declaration_made_by_sid, -1) declaration_made_by_sid, NVL(pql.declaration_made_by_name, 'None set') declaration_made_by_name, colour
	FROM questionnaire q, questionnaire_group_membership qgm, questionnaire_group qg,
		(
			SELECT pql.questionnaire_id, questionnaire_status_id, used, due_date, pqg.group_status_id, pqg.declaration_made_by_sid, c.full_name declaration_made_by_name
			FROM all_product_questionnaire pql, product_questionnaire_group pqg, questionnaire_group_membership qgm, csr.csr_user c
			WHERE pqg.product_id = pql.product_id
			AND pqg.group_id = qgm.group_id
			AND pql.questionnaire_id = qgm.questionnaire_id
			AND pqg.declaration_made_by_sid = c.csr_user_sid(+)
			AND pql.product_id = in_product_id
		) pql 
		WHERE qg.group_id = qgm.group_id
		AND qgm.questionnaire_id = q.questionnaire_id
		AND q.questionnaire_id = pql.questionnaire_id(+)
		AND ((in_used_only=0) OR (in_used_only IS NULL) OR (pql.used = 1))
		AND q.active = 1
		AND qg.app_sid = in_app_sid
	ORDER BY qgm.pos asc, qg.group_id asc, q.friendly_name;
END;

FUNCTION GetMaxProdRevisionId(
	in_product_id			IN 	product.product_id%TYPE
) RETURN NUMBER
IS
	v_max_rev_id				product_revision.revision_id%TYPE;
BEGIN

	SELECT MAX(revision_id) INTO v_max_rev_id FROM product_revision WHERE product_id = in_product_id;
	
	RETURN v_max_rev_id;
END;

FUNCTION GetProdRevisionDescription(
    in_product_id			IN 	product.product_id%TYPE,
    in_revision_id          IN  product_revision.revision_id%TYPE
) RETURN VARCHAR2
IS
	v_rev_description		product_revision.description%TYPE;
BEGIN
	SELECT description INTO v_rev_description FROM product_revision WHERE product_id = in_product_id AND revision_id = in_revision_id;
	RETURN v_rev_description;
END;

FUNCTION GetMaxProdRevisionDescription(
	in_product_id			IN 	product.product_id%TYPE
) RETURN VARCHAR2
IS
	v_max_rev_id				product_revision.revision_id%TYPE;
	v_max_rev_description		product_revision.description%TYPE;
BEGIN
	SELECT MAX(revision_id) INTO v_max_rev_id FROM product_revision WHERE product_id = in_product_id;
	v_max_rev_description := GetProdRevisionDescription(in_product_id, v_max_rev_id);
	RETURN v_max_rev_description;
END;

PROCEDURE GetAllProductsUserProviding(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_used_only			IN all_product_questionnaire.used%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	
	OPEN out_cur FOR
			SELECT 
			p.product_id, product_code, description
			FROM product p 
			WHERE product_id in 
			(
				SELECT distinct pql.product_id
				FROM all_product_questionnaire pql, product_questionnaire_provider pqp	
				WHERE pql.product_id = pqp.product_id
				AND ((in_used_only=0) OR (in_used_only IS NULL) OR (pql.used = 1))
				AND pql.questionnaire_id = pqp.questionnaire_id
				AND pqp.provider_sid = in_user_sid
			) ;

END;

PROCEDURE GetAllProductsUserApproving(
	in_user_sid				IN security_pkg.T_SID_ID,
	in_used_only			IN all_product_questionnaire.used%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	
	OPEN out_cur FOR
			SELECT 
			p.product_id, product_code, description
			FROM product p 
			WHERE product_id in 
			(
				SELECT distinct pql.product_id
				FROM all_product_questionnaire pql, product_questionnaire_approver pqa  
				WHERE pql.product_id = pqa.product_id
				AND ((in_used_only=0) OR (in_used_only IS NULL) OR (pql.used = 1))
				AND pql.questionnaire_id = pqa.questionnaire_id
				AND pqa.approver_sid = in_user_sid
			) ;

END;

PROCEDURE SetStarted(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID,
	in_product_id			IN product.product_id%TYPE,
	in_started				IN GT_PRODUCT_USER.started%TYPE
)
IS
BEGIN
	UPDATE gt_product_user 
	   SET started = in_started 
	 WHERE app_sid = in_app_sid
	   AND product_id = in_product_id
	   AND user_sid = in_user_sid;
END;

FUNCTION StatusIconExportName(
	in_status_id			IN	product_questionnaire.questionnaire_status_id%TYPE
) RETURN VARCHAR2
AS
BEGIN
	RETURN CASE 
		WHEN in_status_id = 1 THEN 'Data being entered' -- RED
		WHEN in_status_id = 2 THEN 'Complete'			-- GREEN
		WHEN in_status_id = 3 THEN 'Data needs review'	-- GREEN/RED
		ELSE ''
	END;
END;

PROCEDURE GetVisibleCompanyProducts(
	in_start				IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_order_by				IN	VARCHAR2,
	in_order_direction		IN	VARCHAR2,
	in_search				IN	VARCHAR2,
	in_overdue_only			IN	NUMBER,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS 
	v_search				VARCHAR2(1024);
	v_user_company_sid		security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID := SYS_CONTEXT('security', 'sid');
BEGIN

	BEGIN
		SELECT NVL(company_sid,-1) INTO v_user_company_sid FROM company_user WHERE app_sid = SYS_CONTEXT('SECURITY','APP') AND csr_user_sid = v_user_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_user_company_sid := -1; -- some aren't a member of a company - handle this (by returning nothing)
	END;
		
	
	-- Escape filter string
	v_search  := utils_pkg.RegexpEscape(in_search);
	
	-- Replace any number of white spaces with \s+
	v_search := REGEXP_REPLACE(v_search, '\s+', '\s+');
	
	OPEN out_cur FOR
		SELECT x.rn, x.total_rows, x.product_id, x.product_code, x.description, x.group_status_id, x.overdue,
			x.status_pi, x.due_pi, x.status_p, x.due_p, x.status_t, x.due_t, x.status_s, x.due_s, x.status_fmf, x.due_fmf, qclass_fmf,
			-- Nicely named columns used in export
			StatusIconExportName(x.status_pi) "Product info",
			x.due_pi "Product info due date", 
			StatusIconExportName(x.status_p) "Packaging",
			x.due_p "Packaging due date", 
			StatusIconExportName(x.status_t) "Transport",
			x.due_t "Transport due date", 
			StatusIconExportName(x.status_s) "Supplier",
			x.due_s "Supplier due date", 
			StatusIconExportName(x.status_fmf) "F/M/F",
			x.due_fmf "F/M/F due date", 
			DECODE(x.overdue, 1, 'Yes', 'No') "Is overdue"
		  FROM (
		  	SELECT ROWNUM rn, x.total_rows, x.product_id, x.product_code, x.description, x.group_status_id, x.overdue,
				-- Stats icon, due date and questionnaire class logic
				CASE WHEN x.group_status_id = 4 AND x.status_pi != 0 THEN 3 ELSE x.status_pi END status_pi, due_pi,
				CASE WHEN x.group_status_id = 4 AND x.status_p != 0 THEN 3 ELSE x.status_p END status_p, due_p,
				CASE WHEN x.group_status_id = 4 AND x.status_t != 0 THEN 3 ELSE x.status_t END status_t, due_t,
				CASE WHEN x.group_status_id = 4 AND x.status_s != 0 THEN 3 ELSE x.status_s END status_s, due_s,
				CASE WHEN x.status_f <> 0 THEN CASE WHEN x.group_status_id = 4 AND x.status_f != 0 THEN 3 ELSE x.status_f END
				     WHEN x.status_pd <> 0 THEN CASE WHEN x.group_status_id = 4 AND x.status_pd != 0 THEN 3 ELSE x.status_pd END
				     WHEN x.status_fd <> 0 THEN CASE WHEN x.group_status_id = 4 AND x.status_fd != 0 THEN 3 ELSE x.status_fd END
				     ELSE 0
				END status_fmf,
				CASE WHEN x.status_f <> 0 THEN due_f
				     WHEN x.status_pd <> 0 THEN due_pd
				     WHEN x.status_fd <> 0 THEN due_fd
				END due_fmf,
				CASE WHEN x.status_f <> 0  THEN 'gtFormulation'
				     WHEN x.status_pd <> 0 THEN 'gtProductDesign'
				     WHEN x.status_fd <> 0 THEN 'gtFood'
				END qclass_fmf
		  	  FROM (
				SELECT COUNT(*) OVER () total_rows, x.*
				  FROM (
					SELECT DISTINCT p.product_id, p.product_code, p.description, pqg.group_status_id,
						-- Overdiue logic
						CASE WHEN (MIN(DECODE(pq.questionnaire_status_id, questionnaire_pkg.QUESTIONNAIRE_OPEN, pq.due_date, null)) < sysdate - 1) THEN 1 ELSE 0 END overdue,
						-- Statuses and due dates
						NVL(MAX(DECODE(pq.questionnaire_id, 8,pq.questionnaire_status_id)),0) status_pi,
					    NVL(MAX(DECODE(pq.questionnaire_id, 9,pq.questionnaire_status_id)),0) status_p,
					    NVL(MAX(DECODE(pq.questionnaire_id,10,pq.questionnaire_status_id)),0) status_f,
					    NVL(MAX(DECODE(pq.questionnaire_id,11,pq.questionnaire_status_id)),0) status_t,
					    NVL(MAX(DECODE(pq.questionnaire_id,12,pq.questionnaire_status_id)),0) status_s,
					    NVL(MAX(DECODE(pq.questionnaire_id,13,pq.questionnaire_status_id)),0) status_pd,
					    NVL(MAX(DECODE(pq.questionnaire_id,14,pq.questionnaire_status_id)),0) status_fd,
					    MAX(DECODE(pq.questionnaire_id, 8,pq.due_date))	 due_pi,
					    MAX(DECODE(pq.questionnaire_id, 9,pq.due_date)) due_p,
					    MAX(DECODE(pq.questionnaire_id,10,pq.due_date)) due_f,
					    MAX(DECODE(pq.questionnaire_id,11,pq.due_date)) due_t,
					    MAX(DECODE(pq.questionnaire_id,12,pq.due_date)) due_s,
					    MAX(DECODE(pq.questionnaire_id,13,pq.due_date)) due_pd,
					    MAX(DECODE(pq.questionnaire_id,14,pq.due_date)) due_fd,	
						-- Ordering logic
						CASE 
							WHEN LOWER(in_order_direction) = 'asc' AND in_order_by = 'productCode' THEN LOWER(p.product_code)
							WHEN LOWER(in_order_direction) = 'asc' AND in_order_by = 'description' THEN LOWER(p.description)
							ELSE NULL
						END ord_asc,
						CASE 
							WHEN LOWER(in_order_direction) = 'desc' AND in_order_by = 'productCode' THEN LOWER(p.product_code)
							WHEN LOWER(in_order_direction) = 'desc' AND in_order_by = 'description' THEN LOWER(p.description)
							ELSE NULL
						END ord_desc
			          FROM gt_product p, company c, product_questionnaire pq, 
			          	product_questionnaire_approver pqa, product_questionnaire_provider pqp,
			          	questionnaire_group_membership qgm, product_questionnaire_group pqg
			         WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			           AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			           AND p.supplier_company_sid = c.company_sid
			           AND pq.product_id = p.product_id
			           AND pqa.product_id = p.product_id
			           AND pqa.questionnaire_id = pq.questionnaire_id
			           AND pqp.product_id = p.product_id
			           AND pqp.questionnaire_id = pq.questionnaire_id
			           AND qgm.questionnaire_id = pq.questionnaire_id
			           AND pqg.product_id = p.product_id
			           AND pqg.group_id = qgm.group_id
					  -- Sepecific user involved
					  AND (
						in_user_sid IS NULL OR 
						in_user_sid = pqa.approver_sid OR 
						in_user_sid = pqp.provider_sid
					  )
			            AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), c.company_sid, security_pkg.PERMISSION_WRITE) = 1 
						AND p.supplier_company_sid = v_user_company_sid
			           	GROUP BY p.product_id, p.product_code, p.description, pqg.group_status_id
				) x 
				-- Search in produt code and description
				WHERE (in_search IS NULL
					OR REGEXP_LIKE(x.product_code, v_search, 'i')
					OR REGEXP_LIKE(x.description, v_search, 'i'))
				  -- Overdue only
				  AND (in_overdue_only = 0 OR overdue = 1)
			    ORDER BY x.ord_asc ASC, x.ord_desc DESC
			) x
		) x
		 WHERE x.rn > NVL(in_start, 0)
		   AND x.rn <= NVL(in_start + in_page_size, x.rn)
		;
END;

PROCEDURE GetGtApproversAndProviders(
	in_product_id			IN	product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT IsProductAccessAllowed(security_pkg.GetACT, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	
	
	OPEN out_cur FOR
		SELECT x.*, DECODE(is_approver, 1, '(A)', '(P)') prefix
		  FROM (
			SELECT u.csr_user_sid, u.full_name, u.email, 0 is_approver
			  FROM csr.csr_user u, product_questionnaire_provider p
			 WHERE u.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND p.product_id = in_product_id
			   AND u.csr_user_sid = p.provider_sid
			UNION
			SELECT csr_user_sid, full_name, email, 1 is_approver
			  FROM csr.csr_user u, product_questionnaire_approver p
			 WHERE u.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND p.product_id = in_product_id
			   AND u.csr_user_sid = p.approver_sid
		) x
		ORDER BY is_approver DESC, full_name ASC;
END;

PROCEDURE GetTags(
	in_group_name					IN	tag_group.name%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t.tag_id, t.tag, t.explanation
		  FROM tag t, tag_group_member m, tag_group g
		 WHERE m.tag_group_sid = g.tag_group_sid
		   AND t.tag_id = m.tag_id
		   AND g.name = in_group_name
		   AND g.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY m.pos ASC;
END;

END product_pkg;
/
