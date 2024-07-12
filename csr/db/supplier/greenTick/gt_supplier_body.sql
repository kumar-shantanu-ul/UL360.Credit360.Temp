create or replace package body supplier.gt_supplier_pkg
IS

PROCEDURE SetSupplierAnswers (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,	
  	in_gt_sus_relation_type_id  	IN gt_supplier_answers.gt_sus_relation_type_id%TYPE,
	in_sf_supplier_approach     	IN gt_supplier_answers.sf_supplier_approach%TYPE,
	in_sf_supplier_assisted     	IN gt_supplier_answers.sf_supplier_assisted%TYPE,
	in_sust_audit_desc          	IN gt_supplier_answers.sust_audit_desc%TYPE,
	in_sust_doc_group_id        	IN gt_supplier_answers.sust_doc_group_id%TYPE,
	in_data_quality_type_id           IN gt_product_answers.data_quality_type_id%TYPE
) 
AS
	v_gt_sus_relation_type_id		gt_supplier_answers.gt_sus_relation_type_id%TYPE;
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	FOR r IN (
		SELECT 
			   gt_sus_relation_type_id
		FROM gt_supplier_answers aa, product_revision pr
            WHERE pr.product_id=aa.product_id (+)
            AND pr.REVISION_ID = aa.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
	) 
	LOOP
		-- actually only ever going to be single row as product id and revision id are PK
		score_log_pkg.LogSimpleTypeValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_SUPP_MANAGEMENT, null, 'Supplier Relationship', r.gt_sus_relation_type_id, in_gt_sus_relation_type_id,
			'gt_sus_relation_type', 'description', 'gt_sus_relation_type_id');
		
	END LOOP;

	-- Map -1 to NULL for IDs
	SELECT DECODE(in_gt_sus_relation_type_id, -1, NULL, in_gt_sus_relation_type_id) INTO v_gt_sus_relation_type_id FROM dual;
	
	-- upsert
	BEGIN
	   	INSERT INTO gt_supplier_answers (		
			product_id, revision_id, gt_sus_relation_type_id, sf_supplier_approach,     
			sf_supplier_assisted, sust_audit_desc, sust_doc_group_id, data_quality_type_id        
	   	) 
		VALUES (
			in_product_id, v_max_revision_id, in_gt_sus_relation_type_id, in_sf_supplier_approach,     
			in_sf_supplier_assisted, in_sust_audit_desc, in_sust_doc_group_id, in_data_quality_type_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_supplier_answers SET 
					gt_sus_relation_type_id 	=	v_gt_sus_relation_type_id, 	
					sf_supplier_approach 		=	in_sf_supplier_approach, 	
					sf_supplier_assisted 		=	in_sf_supplier_assisted, 	
					sust_audit_desc 			=	in_sust_audit_desc, 	
					sust_doc_group_id 			=	sust_doc_group_id,
					data_quality_type_id		= in_data_quality_type_id
			WHERE product_id = in_product_id
			AND revision_id = v_max_revision_id;
	END;
	
	model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);

END;

PROCEDURE GetSupplierAnswers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN  product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act_id, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;

	OPEN out_cur FOR
		SELECT 	NVL(a.revision_id, 1) revision_id, p.description product_name, p.product_id, p.product_code,
				a.gt_sus_relation_type_id, srt.description,
				sf_supplier_approach, sf_supplier_assisted, 
				sust_audit_desc as sust_audit_desc_1, sust_doc_group_id as sust_audit_desc_1_dg, data_quality_type_id, 
				DECODE(pq.questionnaire_status_id, questionnaire_pkg.QUESTIONNAIRE_CLOSED, pq.last_saved_by, null) last_saved_by
		  FROM gt_supplier_answers a, product p, gt_sus_relation_type srt,  product_questionnaire pq
		 WHERE p.product_id = in_product_id
		   AND p.product_id = pq.product_id
		   AND pq.questionnaire_id = model_pd_pkg.QUESTION_GT_SUPPLIER
		   AND a.product_id(+) = p.product_id
		   AND ((a.revision_id IS NULL) OR (a.revision_id = in_revision_id))
		   AND srt.gt_sus_relation_type_id(+) = a.gt_sus_relation_type_id;
END;

PROCEDURE GetSupRelationTypes(
	in_act_id					IN security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: grouping
	OPEN out_cur FOR
		SELECT gt_sus_relation_type_id, description
		  FROM gt_sus_relation_type
		  	ORDER BY pos ASC;
END;

PROCEDURE IncrementRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE
)
AS
BEGIN
	CopyAnswers(in_act_id, in_product_id, in_from_rev, in_product_id, in_from_rev+1);
END;


PROCEDURE CopyAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_product_id				IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE,
	in_to_product_id				IN all_product.product_id%TYPE,
	in_to_rev						IN product_revision.revision_id%TYPE
)
AS
	v_old_doc_group					document_group.document_group_id%TYPE;
	v_new_doc_group					document_group.document_group_id%TYPE;
BEGIN
	
	-- copy the sust doc group
	document_pkg.CreateDocumentGroup(in_act_id, v_new_doc_group);
	BEGIN
		SELECT sust_doc_group_id INTO v_old_doc_group FROM gt_supplier_answers WHERE product_id = in_from_product_id AND revision_id = in_from_rev;
		document_pkg.CopyDocumentsToNewGroup(in_act_id, v_old_doc_group, v_new_doc_group);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- do nothing
			NULL;
	END;
	-- we always want to overwrite so lets just get rid of the row
	DELETE FROM gt_supplier_answers WHERE product_id = in_to_product_id AND revision_id = in_to_rev;

	INSERT INTO gt_supplier_answers (product_id, revision_id, gt_sus_relation_type_id, sf_supplier_approach, sf_supplier_assisted, sust_audit_desc, sust_doc_group_id, data_quality_type_id) 
	SELECT in_to_product_id, in_to_rev, gt_sus_relation_type_id, sf_supplier_approach, sf_supplier_assisted, sust_audit_desc, v_new_doc_group, data_quality_type_id
		FROM gt_supplier_answers
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;

END;



END gt_supplier_pkg;
/
