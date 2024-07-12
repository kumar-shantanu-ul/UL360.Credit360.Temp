create or replace package body supplier.part_wood_pkg
IS

FUNCTION GetForestSourceCatCode(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE
) RETURN cert_scheme.verified_fscc%TYPE
AS
	v_forest_source_cat_code cert_scheme.verified_fscc%TYPE;
BEGIN

	-- Probably too trivial for sec check
    SELECT DECODE(t.means_verified + c.means_verified, 2, verified_fscc, non_verified_fscc) 
	  INTO v_forest_source_cat_code
	  FROM wood_part_wood w
      JOIN country c ON LOWER(W.country_code) = LOWER(c.country_code)
      JOIN tree_species t ON LOWER(w.species_code) = LOWER(t.species_code)
	  JOIN cert_scheme cs ON cs.cert_scheme_id = w.cert_scheme_id
	 WHERE product_part_id = in_part_id;
	
	RETURN v_forest_source_cat_code;
END;

PROCEDURE GetForestSourceCatCode(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_cert_scheme_id		IN cert_scheme.cert_scheme_id%TYPE,
	in_country_code			IN wood_part_wood.country_code%TYPE,
	in_species_code			IN wood_part_wood.species_code%TYPE, 
	out_fscc_desc			OUT VARCHAR2
) 
AS
	v_country_verified				country.means_verified%TYPE;
	v_species_verified				tree_species.means_verified%TYPE;
BEGIN
	-- code contract assumes cert_scheme_id, species_code, country_code	set		
	IF(in_cert_scheme_id IS NULL) OR (in_cert_scheme_id = -1)  THEN
		out_fscc_desc := '-';
		RETURN;
	END IF;
	
	BEGIN
		SELECT means_verified INTO v_country_verified FROM country WHERE LOWER(country_code) = LOWER(in_country_code);
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN 
		out_fscc_desc := '-';
		RETURN;
	END;
	
	BEGIN
		SELECT means_verified INTO v_species_verified FROM tree_species WHERE LOWER(species_code) = LOWER(in_species_code);
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN 
		out_fscc_desc := '-';
		RETURN;
	END;
		 
    SELECT forest_source_cat_code || ' - ' || name 
	  INTO out_fscc_desc
	  FROM forest_source_cat 
	 WHERE forest_source_cat_code = 
    (	
		SELECT DECODE(v_country_verified + v_species_verified, 2, verified_fscc, non_verified_fscc)
		  FROM cert_scheme c
		 WHERE cert_scheme_id = in_cert_scheme_id
     );
	
END;

PROCEDURE CreatePartWood(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product_part.product_id%TYPE,
	in_parent_part_id		IN product_part.parent_id%TYPE,
	in_species_code			IN wood_part_wood.species_code%TYPE,
	in_country_code			IN wood_part_wood.country_code%TYPE,
	in_region				IN wood_part_wood.region%TYPE,
	in_cert_doc_group_id	IN wood_part_wood.cert_doc_group_id%TYPE,
	in_bleaching_process_id	IN wood_part_wood.bleaching_process_id%TYPE,
	in_wrme_wood_type_id	IN wood_part_wood.wrme_wood_type_id%TYPE,
	in_cert_scheme_id		IN wood_part_wood.cert_scheme_id%TYPE,
	out_product_part_id		OUT product_part.product_part_id%TYPE
)
AS
	v_product_part_id		product_part.product_part_id%TYPE;
	v_part_type_id			product_part.part_type_id%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
	v_parent_desc			wood_part_description.description%TYPE;
	v_product_id 			product.product_id%TYPE;
BEGIN

	-- don't need security check here as CreateProductPart checks everything we need to worry about
	-- this just floats on the top and does the custom bits for WOOD 
	
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = PART_WOOD_CLASS_NAME;

	product_part_pkg.CreateProductPart(in_act_id, v_part_type_id, in_product_id, in_parent_part_id, v_product_part_id);
	
	INSERT INTO wood_part_wood 
		(product_part_id, species_code, country_code, region, cert_doc_group_id, 
			bleaching_process_id, wrme_wood_type_id, cert_scheme_id)
		VALUES (v_product_part_id, in_species_code, in_country_code, in_region, in_cert_doc_group_id, 
			in_bleaching_process_id, in_wrme_wood_type_id, NVL(in_cert_scheme_id, CERT_UNKNOWN));
		
	out_product_part_id := v_product_part_id;

	-- audit

	-- could be multiple products in the future but not supported atm
    SELECT DISTINCT(product_id) product_id 
    	INTO v_product_id
    	FROM product_part
		START WITH product_part_id = v_product_part_id
		CONNECT BY PRIOR parent_id = product_part_id;

	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = v_product_id;
	
	SELECT description INTO v_parent_desc FROM wood_part_description wpd WHERE product_part_id = in_parent_part_id;
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, v_app_sid, 'Added wood type ({0}) to {1}', in_species_code, v_parent_desc, NULL, v_product_id);	
	
END;

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
	v_part_type_id			product_part.part_type_id%TYPE;
	v_product_id 			product.product_id%TYPE;
	v_old_doc_group_id			wood_part_wood.cert_doc_group_id%TYPE;
	v_new_doc_group_id			wood_part_wood.cert_doc_group_id%TYPE;
BEGIN

	-- don't need security check here as CreateProductPart checks everything we need to worry about
	-- this just floats on the top and does the custom bits for WOOD 
	
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = PART_WOOD_CLASS_NAME;

	product_part_pkg.CreateProductPart(in_act_id, v_part_type_id, in_to_product_id, in_new_parent_part_id, v_new_product_part_id);
	
	-- copy documents
	document_pkg.CreateDocumentGroup(in_act_id, v_new_doc_group_id);
	BEGIN
		SELECT cert_doc_group_id
		  INTO v_old_doc_group_id 
	 	  FROM wood_part_wood WHERE product_part_id = in_from_part_id;
	  
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_doc_group_id, v_new_doc_group_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
	
	INSERT INTO wood_part_wood 
		(product_part_id, species_code, country_code, region, cert_doc_group_id, 
			bleaching_process_id, wrme_wood_type_id, cert_scheme_id)
	SELECT 
		v_new_product_part_id, species_code, country_code, region, v_new_doc_group_id, 
			bleaching_process_id, wrme_wood_type_id, cert_scheme_id
	FROM wood_part_wood
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


PROCEDURE UpdatePartWood(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE,
	in_species_code			IN wood_part_wood.species_code%TYPE,
	in_country_code			IN wood_part_wood.country_code%TYPE,
	in_region				IN wood_part_wood.region%TYPE,
	in_cert_doc_group_id	IN wood_part_wood.cert_doc_group_id%TYPE,
	in_bleaching_process_id	IN wood_part_wood.bleaching_process_id%TYPE,
	in_wrme_wood_type_id	IN wood_part_wood.wrme_wood_type_id%TYPE,
	in_cert_scheme_id		IN wood_part_wood.cert_scheme_id%TYPE
)
AS
	CURSOR c_old IS 
		SELECT wpw.region, c.country, ts.common_name, bp.name bleaching_process, cs.name cert_scheme_name, wwt.description wrme_description 
		FROM wood_part_wood wpw, country c, tree_species ts, bleaching_process bp, cert_scheme cs, wrme_wood_type wwt
		WHERE wpw.country_code = c.country_code
		  AND wpw.species_code = ts.species_code
		  AND wpw.bleaching_process_id = bp.bleaching_process_id
		  AND wpw.cert_scheme_id = cs.cert_scheme_id
		  AND wpw.wrme_wood_type_id = wwt.wrme_wood_type_id
		  AND wpw.product_part_id = in_part_id;
	r_old c_old%ROWTYPE;
	
	CURSOR c_new IS 
		SELECT wpw.region, c.country, ts.common_name, bp.name bleaching_process, cs.name cert_scheme_name, wwt.description wrme_description 
		FROM wood_part_wood wpw, country c, tree_species ts, bleaching_process bp, cert_scheme cs, wrme_wood_type wwt
		WHERE wpw.country_code = c.country_code
		  AND wpw.species_code = ts.species_code
		  AND wpw.bleaching_process_id = bp.bleaching_process_id
		  AND wpw.cert_scheme_id = cs.cert_scheme_id
		  AND wpw.wrme_wood_type_id = wwt.wrme_wood_type_id
		  AND wpw.product_part_id = in_part_id;
	r_new c_new%ROWTYPE;
	
	v_app_sid 			security_pkg.T_SID_ID;
	v_parent_desc			wood_part_description.description%TYPE;
	v_product_id 			product.product_id%TYPE;
BEGIN

	-- read some bits about the old part
	OPEN c_old;
	FETCH c_old INTO r_old;
	IF c_old%NOTFOUND THEN
		CLOSE c_old;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The part with id '||in_part_id||' was not found');
	END IF;
	CLOSE c_old;

	-- TODO: security check
	UPDATE wood_part_wood
  	  SET species_code = in_species_code,
	   	  country_code = in_country_code,
	   	  region = in_region,
	   	  cert_doc_group_id = in_cert_doc_group_id,
	   	  bleaching_process_id = in_bleaching_process_id,
	   	  wrme_wood_type_id = in_wrme_wood_type_id,
	   	  cert_scheme_id = NVL(in_cert_scheme_id , CERT_UNKNOWN)
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
		CONNECT BY PRIOR parent_id = in_part_id;
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = v_product_id;
	
    SELECT wpd.description 
    	INTO v_parent_desc
    	FROM wood_part_description wpd, product_part pp
   		WHERE pp.parent_id = wpd.product_part_id 
    	AND pp.product_part_id = in_part_id;
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood type: ' || v_parent_desc || ': Species', r_old.common_name, r_new.common_name, v_product_id);	
				
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood type: ' || v_parent_desc || ': Country', r_old.country, r_new.country, v_product_id);	
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood type: ' || v_parent_desc || ': Region', r_old.region, r_new.region, v_product_id);	
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood type: ' || v_parent_desc || ': Bleaching process', r_old.bleaching_process, r_new.bleaching_process, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood type: ' || v_parent_desc || ': Certification scheme', r_old.cert_scheme_name, r_new.cert_scheme_name, v_product_id);

	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Wood type: ' || v_parent_desc || ': WRME Type', r_old.wrme_description, r_new.wrme_description, v_product_id);	

END;

-- Deletes parts and child parts
-- Actually deleted from the relevent tables. 
PROCEDURE DeletePart(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_part_id		IN product_part.product_part_id%TYPE
)
AS
	v_parent_desc			wood_part_description.description%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
	v_species_code			wood_part_wood.species_code%TYPE;
	v_product_id 			product.product_id%TYPE;
BEGIN	
	
	-- could be multiple products in the future but not supported atm
    SELECT DISTINCT(product_id) 
    	INTO v_product_id 
    	FROM product_part
		START WITH product_part_id = in_product_part_id
		CONNECT BY PRIOR parent_id = product_part_id;
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = v_product_id;
	
    SELECT wpd.description 
    	INTO v_parent_desc
    	FROM wood_part_description wpd, product_part pp
   		WHERE pp.parent_id = wpd.product_part_id 
    	AND pp.product_part_id = in_product_part_id;
    	
    SELECT species_code INTO v_species_code FROM wood_part_wood WHERE product_part_id = in_product_part_id;
	
	DELETE FROM wood_part_wood 
	 WHERE product_part_id IN (
         SELECT product_part_id
               FROM all_product p, product_part pp
              WHERE p.product_id = pp.product_id
         START WITH product_part_id = in_product_part_id
         CONNECT BY PRIOR product_part_id = parent_id
	);
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, v_app_sid, 'Deleted wood type {0} from {1}', v_species_code, v_parent_desc, NULL, v_product_id);	

END;


PROCEDURE GetGenusList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT genus
		  FROM tree_species
		  	ORDER BY genus ASC;
END;


PROCEDURE GetSpeciesList(
	in_genus				IN	tree_species.genus%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN
	OPEN out_cur FOR
		SELECT species_code, genus, species, common_name
		  FROM tree_species
		 WHERE LOWER(genus) = LOWER(in_genus)
		  	ORDER BY species ASC;
END;

PROCEDURE GetCommonNameList(
	in_genus				IN	tree_species.genus%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN
	IF in_genus IS NULL THEN
		OPEN out_cur FOR
			SELECT species_code, genus, species, common_name
			  FROM tree_species
			  	ORDER BY common_name ASC;
	ELSE
		OPEN out_cur FOR
			SELECT species_code, genus, species, common_name
			  FROM tree_species
			 WHERE LOWER(genus) = LOWER(in_genus)
			  	ORDER BY species ASC;
	END IF;
END;

PROCEDURE GetCertSchemeList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cert_scheme_id, name, description
		  FROM cert_scheme 
		 WHERE allow_user_select = 1 
			ORDER BY (name);
END;

PROCEDURE GetBleachingProcList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT bleaching_process_id, name, description
		  FROM bleaching_process
		 	ORDER BY name;
END;

PROCEDURE GetWrmeWoodTypeList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT wrme_wood_type_id, description, factor_per_metric_ton, explanation
		  FROM wrme_wood_type
			ORDER BY description;
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
		SELECT MIN(end_dtm) INTO out_min_date FROM product_part pp, part_type pt, wood_part_wood wpw, document_group dg, document_group_member dgm, document d
			WHERE pp.part_type_id = pt.part_type_id
			  AND wpw.product_part_id = pp.product_part_id
			  AND wpw.cert_doc_group_id = dg.document_group_id
			  AND dg.document_group_id = dgm.document_group_id
			  AND dgm.document_id = d.document_id
			  AND pt.class_name = PART_WOOD_CLASS_NAME
			  AND pp.product_id = in_product_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_min_date  := NULL;
	END;

END;

END part_wood_pkg;
/


