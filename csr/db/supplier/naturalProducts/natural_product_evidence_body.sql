create or replace package body supplier.natural_product_evidence_pkg
IS

PROCEDURE CreateComponentEvidence(
	in_act							IN	security_pkg.T_ACT_ID,
	in_product_id					IN	product_part.product_id%TYPE,
	in_parent_part_id				IN	product_part.product_part_id%TYPE,
	in_details						IN	np_part_evidence.details%TYPE,
	in_docuemnt_group_id			IN	np_part_evidence.document_group_id%TYPE,
	in_evidence_class_id			IN	np_part_evidence.np_evidence_class_id%TYPE,
	in_evidence_type_id				IN	np_part_evidence.np_evidence_type_id%TYPE,
	out_product_part_id				OUT	product_part.product_part_id%TYPE
)
AS
	v_part_type_id			product_part.part_type_id%TYPE;
BEGIN
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = PART_EVIDENCE_DESCRIPTION_CLS;

	-- Security check done inside CreateProductPart
	product_part_pkg.CreateProductPart(in_act, v_part_type_id, in_product_id, in_parent_part_id, out_product_part_id);
	
	INSERT INTO np_part_evidence
		(product_part_id, details, document_group_id, np_evidence_class_id, np_evidence_type_id)
		VALUES(out_product_part_id, in_details, in_docuemnt_group_id, in_evidence_class_id, in_evidence_type_id);
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
	v_old_doc_group_id				np_part_evidence.document_group_id%TYPE;
	v_new_doc_group_id				np_part_evidence.document_group_id%TYPE;
BEGIN
	
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = PART_EVIDENCE_DESCRIPTION_CLS;

	-- Security check done inside CreateProductPart
	product_part_pkg.CreateProductPart(in_act_id, v_part_type_id, in_to_product_id, in_new_parent_part_id, v_new_product_part_id);
	
	-- copy documents
	document_pkg.CreateDocumentGroup(in_act_id, v_new_doc_group_id);
	BEGIN
		SELECT document_group_id
		  INTO v_old_doc_group_id 
		  FROM np_part_evidence WHERE product_part_id = in_from_part_id;
	  
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_doc_group_id, v_new_doc_group_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
	
	INSERT INTO np_part_evidence
		(product_part_id, details, document_group_id, np_evidence_class_id, np_evidence_type_id)
	 SELECT v_new_product_part_id, details, v_new_doc_group_id, np_evidence_class_id, np_evidence_type_id
	   FROM np_part_evidence
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

PROCEDURE UpdateComponentEvidence(
	in_act							IN	security_pkg.T_ACT_ID,
	in_part_id						IN	product_part.product_part_id%TYPE,
	in_details						IN	np_part_evidence.details%TYPE,
	in_document_group_id			IN	np_part_evidence.document_group_id%TYPE,
	in_evidence_class_id			IN	np_part_evidence.np_evidence_class_id%TYPE,
	in_evidence_type_id				IN	np_part_evidence.np_evidence_type_id%TYPE
)
AS
BEGIN
	IF NOT product_part_pkg.IsPartAccessAllowed(in_act, in_part_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to part with id '||in_part_id);
	END IF;
	
	UPDATE np_part_evidence
	   SET details = in_details,
	   document_group_id = in_document_group_id,
	   np_evidence_class_id = in_evidence_class_id,
	   np_evidence_type_id = in_evidence_type_id
	 WHERE product_part_id = in_part_id;
END;

PROCEDURE DeletePart(
	in_act					IN	security_pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE
)
AS
BEGIN
	DELETE FROM np_part_evidence
	 WHERE product_part_id IN (
         SELECT product_part_id
               FROM all_product p, product_part pp
              WHERE p.product_id = pp.product_id
         START WITH product_part_id = in_part_id
         CONNECT BY PRIOR product_part_id = parent_id
	);
END;

PROCEDURE GetComponentEvidence(
	in_act					IN	security_pkg.T_ACT_ID,
	in_part_id				IN	product_part.product_part_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_part_pkg.IsPartAccessAllowed(in_act, in_part_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading part with id '||in_part_id);
	END IF;
	
	OPEN out_cur FOR
		SELECT p.product_id, p.product_part_id, p.part_type_id, p.parent_id, 
				e.details, e.document_group_id, e.np_evidence_class_id, e.np_evidence_type_id,
				c.name np_evidence_class_name, c.description np_evidence_class_desc,
				t.name np_evidence_type_name, t.description np_evidence_type_desc
		  FROM product_part p, np_part_evidence e, np_evidence_class c, np_evidence_type t
		 WHERE p.parent_id = in_part_id
		   AND e.product_part_id = p.product_part_id
		   AND c.np_evidence_class_id = e.np_evidence_class_id
		   AND t.np_evidence_type_id = e.np_evidence_type_id
		   	ORDER BY t.name;
END;

PROCEDURE GetEvidenceClassList(
	in_act							IN	security_pkg.T_ACT_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT np_evidence_class_id, name, description
		  FROM np_evidence_class
		  	ORDER BY name;
END;


PROCEDURE GetEvidenceTypeList(
	in_act							IN	security_pkg.T_ACT_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT np_evidence_type_id, name, description
		  FROM np_evidence_type
		  	ORDER BY name;
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
		SELECT MIN(end_dtm) INTO out_min_date FROM product_part pp, part_type pt, np_part_evidence nppe, document_group dg, document_group_member dgm, document d
		WHERE pp.part_type_id = pt.part_type_id
		  AND nppe.product_part_id = pp.product_part_id
		  AND nppe.document_group_id = dg.document_group_id
		  AND dg.document_group_id = dgm.document_group_id
		  AND dgm.document_id = d.document_id
		  AND pt.class_name = part_evidence_description_cls
		  AND pp.product_id = in_product_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_min_date  := NULL;
	END;

END;

END natural_product_evidence_pkg;
/
