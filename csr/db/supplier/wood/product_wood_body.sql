create or replace package body supplier.product_wood_pkg
IS

PROCEDURE GetProductAnswers(
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

	/*
	OPEN out_cur FOR
		SELECT w.product_id, w.declaration_made, w.declaration_made_by_sid, u.full_name declaration_made_by_name
		  FROM wood_product_answers w, csr.csr_user u
		 WHERE product_id = in_product_id
		   AND u.csr_user_sid = w.declaration_made_by_sid;
	*/
END;

PROCEDURE GetWoodTypes(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: security check?
	OPEN out_cur FOR
		SELECT p.product_part_id, w.species_code, ts.genus species_genus, ts.species species_species, 
			ts.common_name species_common_name, w.country_code, c.country country_name, 
			w.region, w.cert_doc_group_id, w.bleaching_process_id, bp.name bleaching_process_name, 
			fs.forest_source_cat_code, fs.name forest_source_cat_name, 
			w.wrme_wood_type_id, wrme.description wrme_wood_type_name, 
			w.cert_scheme_id, cs.name cert_scheme_name
		  FROM product_part p, wood_part_wood w, forest_source_cat fs, bleaching_process bp, 
		  		tree_species ts, country c, wrme_wood_type wrme, cert_scheme cs
		 WHERE p.parent_id = in_part_id
		   AND p.part_type_id = 2 --<< Hard code this value for now
		   AND w.product_part_id = p.product_part_id
		   AND bp.bleaching_process_id = w.bleaching_process_id
		   AND ts.species_code = w.species_code
		   AND c.country_code = w.country_code
		   AND wrme.wrme_wood_type_id = w.wrme_wood_type_id
		   AND cs.cert_scheme_id = w.cert_scheme_id
		   AND fs.forest_source_cat_code = part_wood_pkg.GetForestSourceCatCode(in_act_id, w.product_part_id);
END;


PROCEDURE SetProductAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN product.product_id%TYPE
)
AS
	v_count		NUMBER(10);
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	/*
	SELECT COUNT(0)
	  INTO v_count
	  FROM wood_product_answers
	 WHERE product_id = in_product_id;
	 
	IF v_count = 0 THEN
		INSERT INTO wood_product_answers
			(product_id, --...)
			VALUES (in_product_id, --...);
	ELSE
		UPDATE wood_product_answers
		   SET --...
		 WHERE product_id = in_product_id;
	END IF;
	*/
END;

-- this is named consistently across all GT and sustainability packages and is the entry point for copying the answers for a questionnaire
PROCEDURE CopyAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_product_id				IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE, -- not used yet
	in_to_product_id				IN all_product.product_id%TYPE,
	in_to_rev						IN product_revision.revision_id%TYPE -- not used yet
)
AS
	v_new_product_part_id			product_part.product_part_id%TYPE;
BEGIN
	
	-- no actual product level wood answers to copy

	
	-- get parent parts from "to" product and delete if any
 	FOR prt IN (
		SELECT product_part_id, parent_id, package FROM product_part pp, part_type pt
		 WHERE pp.part_type_id = pt.part_type_id
		   AND parent_id IS NULL
           AND class_name IN (part_wood_pkg.PART_WOOD_CLASS_NAME, part_description_pkg.PART_DESCRIPTION_CLASS_NAME)
		   AND product_id = in_to_product_id
		   ORDER BY product_part_id ASC
	)
	LOOP
		    product_part_pkg.DeleteProductPart(in_act_id, prt.product_part_id);
	END LOOP;
	
	-- get parent parts from "from" priduct and copy 
	FOR prt IN (
		SELECT product_part_id, parent_id, package FROM product_part pp, part_type pt
		 WHERE pp.part_type_id = pt.part_type_id
		   AND parent_id IS NULL
           AND class_name IN (part_wood_pkg.PART_WOOD_CLASS_NAME, part_description_pkg.PART_DESCRIPTION_CLASS_NAME)
		   AND product_id = in_from_product_id
		   ORDER BY product_part_id ASC
	)
	LOOP
		    EXECUTE IMMEDIATE 'begin '||prt.package||'.CopyPart(:1,:2,:3,:4,:5);end;'
				USING in_act_id, prt.product_part_id, in_to_product_id, prt.parent_id, OUT v_new_product_part_id;
	END LOOP;
	
END;

PROCEDURE GetDocumentList(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_doc_group_id			IN document_group.document_group_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: security check?
	OPEN out_cur FOR
		SELECT d.document_id, d.title, d.description, d.file_name, d.mime_type, d.start_dtm, d.end_dtm
		  FROM document d, document_group_member gm
		 WHERE d.document_id = gm.document_id
		   AND gm.document_group_id = in_doc_group_id;
END;

PROCEDURE GetDocumentData(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_doc_id				IN document.document_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: security check?
	OPEN out_cur FOR
		SELECT document_id, title, description, file_name, mime_type, start_dtm, end_dtm, data
		  FROM document
		 WHERE document_id = in_doc_id;
END;

END product_wood_pkg;
/
