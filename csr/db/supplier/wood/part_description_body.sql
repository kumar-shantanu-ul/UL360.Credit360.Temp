create or replace package body supplier.part_description_pkg
IS

PROCEDURE CreatePartDescription(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN product_part.product_id%TYPE, -- in proctice won't be - but could be null in future
	in_parent_part_id				IN product_part.parent_id%TYPE,
	in_description	 				IN wood_part_description.description%TYPE,
	in_number_in_product 			IN wood_part_description.number_in_product%TYPE,
	in_weight 						IN wood_part_description.weight%TYPE,
	in_weight_unit_id 				IN wood_part_description.weight_unit_id%TYPE,
	in_pct_post_recycled	   		IN wood_part_description.post_recycled_pct%TYPE,
	in_pct_pre_recycled 			IN wood_part_description.pre_recycled_pct%TYPE,
	in_post_recycled_doc_group_id 	IN wood_part_description.post_recycled_doc_group_id%TYPE,
	in_pre_recycled_doc_group_id	IN wood_part_description.pre_recycled_doc_group_id%TYPE,
	in_post_cert_scheme_id	   		IN wood_part_description.post_cert_scheme_id%TYPE,
	in_pre_cert_scheme_id 			IN wood_part_description.pre_cert_scheme_id%TYPE,
	in_post_recycled_country_code	IN wood_part_description.post_recycled_country_code%TYPE,
	in_pre_recycled_country_code 	IN wood_part_description.pre_recycled_country_code%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
)
AS
	v_product_part_id				product_part.product_part_id%TYPE;
	v_part_type_id					product_part.part_type_id%TYPE;
	v_app_sid 					security_pkg.T_SID_ID;
BEGIN

	-- don't need security check here as CreateProductPart checks everything we need to worry about
	-- this just floats on the top and does the custom bits for WOOD 
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = PART_DESCRIPTION_CLASS_NAME;

	product_part_pkg.CreateProductPart(in_act_id, v_part_type_id, in_product_id, in_parent_part_id, v_product_part_id);
	
	-- If pre/post cert scheme id is NULL then use an id of 1 (unknown)
	-- If pre/post country code is NULL then use an id of 1 (unknown)
	
	INSERT INTO wood_part_description
		(product_part_id, description, number_in_product, weight, weight_unit_id, post_recycled_pct, pre_recycled_pct, 
			post_recycled_doc_group_id, pre_recycled_doc_group_id, post_cert_scheme_id, pre_cert_scheme_id, post_recycled_country_code, pre_recycled_country_code) 
		VALUES (v_product_part_id, in_description, in_number_in_product, in_weight, in_weight_unit_id, in_pct_post_recycled, 
			in_pct_pre_recycled, in_post_recycled_doc_group_id, in_pre_recycled_doc_group_id, NVL(in_post_cert_scheme_id, CERT_UNKNOWN), NVL(in_pre_cert_scheme_id, CERT_UNKNOWN), NVL(in_post_recycled_country_code, COUNTRY_CODE_UNSPECIFIED), NVL(in_pre_recycled_country_code, COUNTRY_CODE_UNSPECIFIED));

	out_product_part_id := v_product_part_id;
	
	-- audit log 
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, v_app_sid, 'Added wooden part {0}', in_description, NULL, NULL, in_product_id);	

END;

-- copies own children as well
PROCEDURE CopyPart(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_part_id					IN product_part.product_part_id%TYPE, 
	in_to_product_id				IN product_part.product_id%TYPE, 
	in_new_parent_part_id			IN product_part.parent_id%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
)
AS
	v_new_product_part_id			product_part.product_part_id%TYPE;
	v_new_child_product_part_id		product_part.product_part_id%TYPE;
	v_part_type_id					product_part.part_type_id%TYPE;
	v_old_post_doc_group_id			wood_part_description.post_recycled_doc_group_id%TYPE;
	v_old_pre_doc_group_id			wood_part_description.pre_recycled_doc_group_id%TYPE;
	v_new_post_doc_group_id			wood_part_description.post_recycled_doc_group_id%TYPE;
	v_new_pre_doc_group_id			wood_part_description.pre_recycled_doc_group_id%TYPE;
BEGIN
	
		-- don't need security check here as CreateProductPart checks everything we need to worry about
	-- this just floats on the top and does the custom bits for WOOD 
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = PART_DESCRIPTION_CLASS_NAME;

	product_part_pkg.CreateProductPart(in_act_id, v_part_type_id, in_to_product_id, in_new_parent_part_id, v_new_product_part_id);
	
	-- copy documents
	document_pkg.CreateDocumentGroup(in_act_id, v_new_post_doc_group_id);
	BEGIN
		SELECT post_recycled_doc_group_id 
		  INTO v_old_post_doc_group_id 
		  FROM wood_part_description WHERE product_part_id = in_from_part_id;
		  
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_post_doc_group_id, v_new_post_doc_group_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
	
	document_pkg.CreateDocumentGroup(in_act_id, v_new_pre_doc_group_id);
	BEGIN	
		SELECT pre_recycled_doc_group_id 
		  INTO v_old_pre_doc_group_id 
		  FROM wood_part_description WHERE product_part_id = in_from_part_id;
		
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_pre_doc_group_id, v_new_pre_doc_group_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;


	INSERT INTO wood_part_description
		(product_part_id, description, number_in_product, weight, weight_unit_id, post_recycled_pct, pre_recycled_pct, 
			post_recycled_doc_group_id, pre_recycled_doc_group_id, post_cert_scheme_id, pre_cert_scheme_id, post_recycled_country_code, pre_recycled_country_code) 
	SELECT 
		v_new_product_part_id, description, number_in_product, weight, weight_unit_id, post_recycled_pct, pre_recycled_pct, 
			v_new_post_doc_group_id, v_new_pre_doc_group_id, post_cert_scheme_id, pre_cert_scheme_id, post_recycled_country_code, pre_recycled_country_code
	FROM wood_part_description 
	WHERE product_part_id = in_from_part_id;
	
	-- now copies children 
	FOR child IN (
		SELECT product_part_id, package FROM product_part pp, part_type pt
		 WHERE pp.part_type_id = pt.part_type_id
		   AND parent_id = in_from_part_id
		   ORDER BY product_part_id ASC
	)
	LOOP
		    EXECUTE IMMEDIATE 'begin '||child.package||'.CopyPart(:1,:2,:3,:4,:5);end;'
				USING in_act_id, child.product_part_id, in_to_product_id, v_new_product_part_id, OUT v_new_child_product_part_id;
	END LOOP;
	
	out_product_part_id := v_new_product_part_id;
	
END;


PROCEDURE UpdatePartDescription(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_part_id						IN product_part.product_part_id%TYPE,
	in_description	 				IN wood_part_description.description%TYPE,
	in_number_in_product 			IN wood_part_description.number_in_product%TYPE,
	in_weight 						IN wood_part_description.weight%TYPE,
	in_weight_unit_id 				IN wood_part_description.weight_unit_id%TYPE,
	in_post_recycled_pct	   		IN wood_part_description.post_recycled_pct%TYPE,
	in_pre_recycled_pct 			IN wood_part_description.pre_recycled_pct%TYPE,
	in_post_recycled_doc_group_id 	IN wood_part_description.post_recycled_doc_group_id%TYPE,
	in_pre_recycled_doc_group_id	IN wood_part_description.pre_recycled_doc_group_id%TYPE,
	in_post_cert_scheme_id	   		IN wood_part_description.post_cert_scheme_id%TYPE,
	in_pre_cert_scheme_id 			IN wood_part_description.pre_cert_scheme_id%TYPE,
	in_post_recycled_country_code	IN wood_part_description.post_recycled_country_code%TYPE,
	in_pre_recycled_country_code 	IN wood_part_description.pre_recycled_country_code%TYPE
)
AS
	-- need a couple of nested loops because of the double join
	CURSOR c_old IS 
		SELECT b.*, u.name unit_name, cs.name pre_cert_scheme_name, c.country pre_recycled_country FROM (
		    SELECT a.*, cs.name post_cert_scheme_name, c.country post_recycled_country FROM (
		        SELECT    product_part_id, wpd.description, number_in_product, weight, weight_unit_id, post_recycled_pct, pre_recycled_pct, 
		                  post_cert_scheme_id, pre_cert_scheme_id, post_recycled_country_code, pre_recycled_country_code
		             FROM wood_part_description wpd
		    ) a, cert_scheme cs, country c
		    WHERE cs.cert_scheme_id = a.post_cert_scheme_id
		      AND c.COUNTRY_CODE = a.post_recycled_country_code
		) b, cert_scheme cs, country c, unit u
		    WHERE cs.cert_scheme_id = b.pre_cert_scheme_id
		      AND c.country_code = b.pre_recycled_country_code
		      AND b.weight_unit_id = u.unit_id 
		      AND product_part_id = in_part_id;
	r_old c_old%ROWTYPE;
	
	-- need a couple of nested loops because of the double join
	CURSOR c_new IS 
		SELECT b.*, u.name unit_name, cs.name pre_cert_scheme_name, c.country pre_recycled_country FROM (
		    SELECT a.*, cs.name post_cert_scheme_name, c.country post_recycled_country FROM (
		        SELECT    product_part_id, wpd.description, number_in_product, weight, weight_unit_id, post_recycled_pct, pre_recycled_pct, 
		                  post_cert_scheme_id, pre_cert_scheme_id, post_recycled_country_code, pre_recycled_country_code
		             FROM wood_part_description wpd
		    ) a, cert_scheme cs, country c
		    WHERE cs.cert_scheme_id = a.post_cert_scheme_id
		      AND c.COUNTRY_CODE = a.post_recycled_country_code
		) b, cert_scheme cs, country c, unit u
		    WHERE cs.cert_scheme_id = b.pre_cert_scheme_id
		      AND c.country_code = b.pre_recycled_country_code
		      AND b.weight_unit_id = u.unit_id 
		      AND product_part_id = in_part_id;
	r_new c_new%ROWTYPE;

	v_app_sid 					security_pkg.T_SID_ID;
	v_product_id 					product.product_id%TYPE;
BEGIN

	IF NOT product_part_pkg.IsPartAccessAllowed(in_act_id, in_part_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to part with id '||in_part_id);
	END IF;

	-- read some bits about the old part
	OPEN c_old;
	FETCH c_old INTO r_old;
	IF c_old%NOTFOUND THEN
		CLOSE c_old;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The part with id '||in_part_id||' was not found');
	END IF;
	CLOSE c_old;

	-- TODO: security check
	UPDATE wood_part_description
	   SET description = in_description,
	   	   number_in_product = in_number_in_product,
	   	   weight = in_weight,
	   	   weight_unit_id = in_weight_unit_id,
	   	   post_recycled_pct = in_post_recycled_pct,
	   	   pre_recycled_pct = in_pre_recycled_pct,
	   	   post_recycled_doc_group_id = in_post_recycled_doc_group_id,
	   	   pre_recycled_doc_group_id = in_pre_recycled_doc_group_id,
	   	   post_cert_scheme_id = NVL(in_post_cert_scheme_id, CERT_UNKNOWN),
	   	   pre_cert_scheme_id = NVL(in_pre_cert_scheme_id, CERT_UNKNOWN),
	   	   post_recycled_country_code = NVL(in_post_recycled_country_code, COUNTRY_CODE_UNSPECIFIED),
	   	   pre_recycled_country_code = NVL(in_pre_recycled_country_code, COUNTRY_CODE_UNSPECIFIED)
	 WHERE product_part_id = in_part_id;
	 
	-- read some bits about the new part
	OPEN c_new;
	FETCH c_new INTO r_new;
	IF c_new%NOTFOUND THEN
		CLOSE c_new;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The part with id '||in_part_id||' was not found');
	END IF;
	CLOSE c_new;
	 
	-- could be multiple products in the future but not supported atm
    SELECT DISTINCT(product_id) 
    	INTO v_product_id
    	FROM product_part
		START WITH product_part_id = in_part_id
		CONNECT BY PRIOR parent_id = product_part_id;
	 
	-- Audit changes
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = v_product_id;
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood part: ' || in_description || ': Part description', r_old.description, r_new.description, v_product_id);	
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood part: ' || in_description || ': Number in product', r_old.number_in_product, r_new.number_in_product, v_product_id);	
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood part: ' || in_description || ': Weight', r_old.weight || r_old.unit_name, r_new.weight || r_new.unit_name, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood part: ' || in_description || ': Post recycled %', r_old.post_recycled_pct, r_new.post_recycled_pct, v_product_id);
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood part: ' || in_description || ': Pre recycled %', r_old.pre_recycled_pct, r_new.pre_recycled_pct, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood part: ' || in_description || ': Post recycled scheme', r_old.post_cert_scheme_name, r_new.post_cert_scheme_name, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood part: ' || in_description || ': Pre recycled scheme', r_old.pre_cert_scheme_name, r_new.pre_cert_scheme_name, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood part: ' || in_description || ': Post recycled country', r_old.post_recycled_country, r_new.post_recycled_country, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood part: ' || in_description || ': Pre recycled country', r_old.pre_recycled_country, r_new.pre_recycled_country, v_product_id);
	 
END;

-- Deletes parts and child parts
-- Actually deleted from the relevent tables. 
PROCEDURE DeletePart(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_part_id		IN product_part.product_part_id%TYPE
)
AS
	v_desc					wood_part_description.description%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
	v_product_id 			product.product_id%TYPE;
BEGIN

	SELECT description INTO v_desc FROM wood_part_description WHERE product_part_id = in_product_part_id;
	
	-- could be multiple products in the future but not supported atm
    SELECT DISTINCT(product_id) 
    	INTO v_product_id
    	FROM product_part
		START WITH product_part_id = in_product_part_id
		CONNECT BY PRIOR parent_id = product_part_id;
	
	-- audit log 
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = v_product_id;
	
	DELETE FROM wood_part_description 
	 WHERE product_part_id IN (
         SELECT product_part_id
               FROM all_product p, product_part pp
              WHERE p.product_id = pp.product_id
         START WITH product_part_id = in_product_part_id
         CONNECT BY PRIOR product_part_id = parent_id
	);
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, v_app_sid, 'Deleted wooden part {0}', v_desc, NULL, NULL, v_product_id);	
	
END;

PROCEDURE GetCertSchemeList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.cert_scheme_id, c.name, c.description
		  FROM cert_scheme c
		   	ORDER BY (c.name);
END;

PROCEDURE GetCertSchemeList(
	in_forest_source_cat	IN	forest_source_cat.forest_source_cat_code%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.cert_scheme_id, c.name, c.description
		  FROM cert_scheme c, recyc_fscc_cs_map m
		 WHERE LOWER(m.forest_source_cat_code) = LOWER(in_forest_source_cat)
		   AND c.cert_scheme_id = m.cert_scheme_id
		   	ORDER BY (c.name);
END;

-- Helper function in all part type spoecific packages to return min
-- doc date for any groups attatched to parts of this type for a product. 
-- If no doc groups for a type return NULL date
PROCEDURE GetMinDateForType (
	in_product_id			IN product.product_id%TYPE,
	out_min_date			OUT DATE -- don't use function as don't think you can use EXECUTE IMMEDIATE
)
AS
BEGIN

	BEGIN
		SELECT MIN(end_dtm) INTO out_min_date FROM product_part pp, part_type pt, wood_part_description wpd, document_group dg, document_group_member dgm, document d
		WHERE pp.part_type_id = pt.part_type_id
		  AND wpd.product_part_id = pp.product_part_id
		  AND (wpd.PRE_RECYCLED_DOC_GROUP_ID = dg.document_group_id OR wpd.POST_RECYCLED_DOC_GROUP_ID= dg.document_group_id)
		  AND dg.DOCUMENT_GROUP_ID = dgm.DOCUMENT_GROUP_ID
		  AND dgm.DOCUMENT_ID = d.DOCUMENT_ID
		  AND pt.class_name = PART_DESCRIPTION_CLASS_NAME
		  AND pp.product_id = in_product_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_min_date  := NULL;
	END;

END;

PROCEDURE GetProductParts(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check for read access
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT p.product_part_id, w.description, w.description description_with_code, w.number_in_product, w.weight, w.weight_unit_id, u.name weight_unit_name, 
			w.post_recycled_pct, w.pre_recycled_pct, 
			w.post_recycled_doc_group_id, w.pre_recycled_doc_group_id,
			w.post_cert_scheme_id, (SELECT name FROM cert_scheme WHERE cert_scheme_id = w.post_cert_scheme_id) post_cert_scheme_name,
			w.pre_cert_scheme_id, (SELECT name FROM cert_scheme WHERE cert_scheme_id = w.pre_cert_scheme_id) pre_cert_scheme_name,
			w.post_recycled_country_code, (SELECT country FROM country WHERE country_code = w.post_recycled_country_code) post_recycled_country_name,
			w.pre_recycled_country_code, (SELECT country FROM country WHERE country_code = w.pre_recycled_country_code) pre_recycled_country_name
		  FROM product_part p, wood_part_description w, unit u
		 WHERE p.product_id = in_product_id
		   AND p.parent_id IS NULL
		   AND p.part_type_id = 1 --<< Hard code this value for now
		   AND w.product_part_id = p.product_part_id
		   AND u.unit_id = w.weight_unit_id;
END;

END part_description_pkg;
/


