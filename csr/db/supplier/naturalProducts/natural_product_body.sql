create or replace package body supplier.natural_product_pkg
IS

PROCEDURE SetProductAnswers(
	in_act					IN	security_pkg.T_ACT_ID,
	in_product_id			IN	np_product_answers.product_id%TYPE,
	in_note					IN	np_product_answers.note%TYPE
)
AS
	v_old_note				np_product_answers.note%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;
	
	BEGIN
		SELECT note INTO v_old_note FROM np_product_answers WHERE product_id = in_product_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		v_old_note := NULL;
	END;	
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;	

	BEGIN
		INSERT INTO np_product_answers
			(product_id, note)
			VALUES (in_product_id, in_note);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE np_product_answers
		   	   SET note = in_note
		 	 WHERE product_id = in_product_id;
	END;
	
	audit_pkg.AuditValueChange(in_act, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Note field', v_old_note, in_note, in_product_id);
	
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
		-- we always want to overwrite so lets just get rid of the row
	DELETE FROM np_product_answers WHERE product_id = in_to_product_id;
	
	INSERT INTO np_product_answers
		(product_id, note)
	SELECT in_to_product_id, note FROM np_product_answers
	WHERE product_id = in_from_product_id;
	
	-- get parent parts from "to" product and delete if any
 	FOR prt IN (
		SELECT product_part_id, parent_id, package FROM product_part pp, part_type pt
		 WHERE pp.part_type_id = pt.part_type_id
		   AND parent_id IS NULL
           AND class_name IN (natural_product_part_pkg.PART_DESCRIPTION_CLS, natural_product_evidence_pkg.PART_EVIDENCE_DESCRIPTION_CLS, natural_product_component_pkg.COMPONENT_DESCRIPTION_CLS)
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
           AND class_name IN (natural_product_part_pkg.PART_DESCRIPTION_CLS, natural_product_evidence_pkg.PART_EVIDENCE_DESCRIPTION_CLS, natural_product_component_pkg.COMPONENT_DESCRIPTION_CLS)
		   AND product_id = in_from_product_id
		   ORDER BY product_part_id ASC
	)
	LOOP
		    EXECUTE IMMEDIATE 'begin '||prt.package||'.CopyPart(:1,:2,:3,:4,:5);end;'
				USING in_act_id, prt.product_part_id, in_to_product_id, prt.parent_id, OUT v_new_product_part_id;
	END LOOP;
	
END;

PROCEDURE GetProductAnswers(
	in_act					IN	security_pkg.T_ACT_ID,
	in_product_id			IN	np_product_answers.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_pkg.IsProductAccessAllowed(in_act, in_product_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading product with id '||in_product_id);
	END IF;

	OPEN out_cur FOR
		SELECT product_id, note
		  FROM np_product_answers
		 WHERE product_id = in_product_id;
END;

---------------------------------------

PROCEDURE GetKingdomList(
	in_act							IN	security_pkg.T_ACT_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT np_kingdom_id, name, description
		  FROM np_kingdom
		  	ORDER BY name;
END;


PROCEDURE GetProductionProcessList(
	in_act							IN	security_pkg.T_ACT_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT np_production_process_id, name, description
		  FROM np_production_process
		  	ORDER BY name;
END;

END natural_product_pkg;
/
