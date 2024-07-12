create or replace package body supplier.gt_transport_pkg
IS

PROCEDURE GetTransportCompound(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,	
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_answers						OUT security_pkg.T_OUTPUT_CUR,
	out_sold_in						OUT security_pkg.T_OUTPUT_CUR,
	out_made_in						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetTransportAnswers(in_act_id, in_product_id, in_revision_id, out_answers);
	GetCountriesSoldIn(in_act_id, in_product_id, in_revision_id, out_sold_in);
	GetCountriesMadeIn(in_act_id, in_product_id, in_revision_id, out_made_in);
END;


PROCEDURE SetTransportAnswers (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,	
  	in_princont						IN gt_transport_answers.prod_in_cont_pct%TYPE,
  	in_prbtcont						IN gt_transport_answers.prod_btwn_cont_pct%TYPE,
  	in_pruncont						IN gt_transport_answers.prod_cont_un_pct%TYPE,
  	in_pkincont						IN gt_transport_answers.pack_in_cont_pct%TYPE,
  	in_pkbtcont						IN gt_transport_answers.pack_btwn_cont_pct%TYPE,
  	in_pkuncont						IN gt_transport_answers.pack_cont_un_pct%TYPE,
	in_data_quality_type_id      IN gt_product_answers.data_quality_type_id%TYPE
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
BEGIN
	
    SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	FOR r IN (
		SELECT 
			   pr.product_id, pr.revision_id, 
			   	prod_in_cont_pct, 
				prod_btwn_cont_pct,
				prod_cont_un_pct, 
				pack_in_cont_pct, 
				pack_btwn_cont_pct,
				pack_cont_un_pct
		FROM gt_transport_answers ta, product_revision pr
            WHERE pr.product_id=ta.product_id (+)
            AND pr.revision_id = ta.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
	) 
	LOOP
		-- actually only ever going to be single row as product id and revision id are PK
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_RAW_MAT, null, 'Product - materials obtained within continent %', r.prod_in_cont_pct, in_princont);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_RAW_MAT, null, 'Product - materials travelling between continents %', r.prod_btwn_cont_pct, in_prbtcont);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_RAW_MAT, null, 'Product - materials from unknown continent %', r.prod_cont_un_pct, in_pruncont);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_RAW_MAT, null, 'Packaging - materials obtained within continent %', r.pack_in_cont_pct, in_pkincont);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_RAW_MAT, null, 'Packaging - materials travelling between continents %', r.pack_btwn_cont_pct, in_pkbtcont);
		score_log_pkg.LogNumValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_RAW_MAT, null, 'Packaging - materials from unknown continent %', r.pack_cont_un_pct, in_pkuncont);
		
	END LOOP;
	
	BEGIN
		INSERT INTO gt_transport_answers
			(product_id, revision_id, prod_in_cont_pct, prod_btwn_cont_pct, prod_cont_un_pct,
				pack_in_cont_pct, pack_btwn_cont_pct, pack_cont_un_pct, data_quality_type_id)
		  VALUES (in_product_id, v_max_revision_id, in_princont, in_prbtcont, in_pruncont, 
		  			in_pkincont, in_pkbtcont, in_pkuncont, in_data_quality_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE gt_transport_answers
			   SET prod_in_cont_pct = in_princont,
			   	   prod_btwn_cont_pct = in_prbtcont,
			   	   prod_cont_un_pct = in_pruncont,
			   	   pack_in_cont_pct = in_pkincont,
			   	   pack_btwn_cont_pct = in_pkbtcont,
			   	   pack_cont_un_pct = in_pkuncont,
				   data_quality_type_id = in_data_quality_type_id
			 WHERE product_id = in_product_id
			 AND revision_id = v_max_revision_id;
	END;
	
	model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);
	
END;

PROCEDURE GetTransportAnswers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_has_ingredients			NUMBER(1) := 1;
	v_has_packaging				NUMBER(1) := 1;
BEGIN

	IF product_info_pkg.GetProductClassId(in_act_id, in_product_id, in_revision_id) = model_pd_pkg.PROD_CLASS_PARENT_PACK THEN 
		v_has_ingredients := 0;
	END IF;
	
	IF product_info_pkg.IsSubProduct(in_act_id, in_product_id, in_revision_id) = 1 THEN 
		v_has_packaging := 0;
	END IF;

	OPEN out_cur FOR
	   SELECT p.product_id, 
			NVL(prod_in_cont_pct,-1) prod_in_cont_pct, 
			NVL(prod_btwn_cont_pct,-1) prod_btwn_cont_pct,
			NVL(prod_cont_un_pct,-1) prod_cont_un_pct,
			NVL(pack_in_cont_pct,-1) pack_in_cont_pct, 
			NVL(pack_btwn_cont_pct, -1) pack_btwn_cont_pct, 
			NVL(pack_cont_un_pct,-1) pack_cont_un_pct,
			v_has_ingredients has_ingredients,
			v_has_packaging has_packaging,
			data_quality_type_id, 
			DECODE(pq.questionnaire_status_id, questionnaire_pkg.QUESTIONNAIRE_CLOSED, pq.last_saved_by, null) last_saved_by
		FROM product p, gt_transport_answers ta, product_questionnaire pq
	   WHERE p.product_id = ta.product_id(+) 
	     AND p.product_id = in_product_id
		 AND p.product_id = pq.product_id
		 AND pq.questionnaire_id = model_pd_pkg.QUESTION_GT_TRANSPORT
	     AND ((ta.revision_id IS NULL) OR (ta.revision_id = in_revision_id));
END;

PROCEDURE SetCountriesSoldIn (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,	
  	in_country_codes				IN T_COUNTRY_CODES
)
AS
	v_max_revision_id				product_revision.revision_id%TYPE;
	v_old_sold_in_list				VARCHAR(2048);
	v_new_sold_in_list				VARCHAR(2048);
BEGIN

	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	SELECT NVL(csr.stragg(country), 'None selected') INTO v_old_sold_in_list FROM (
            SELECT si.country 
            	FROM (SELECT c.country, si.product_id, si.revision_id FROM gt_country_sold_in si, country c WHERE c.country_code = si.country_code) si, 
				product_revision pr
            WHERE pr.product_id=si.PRODUCT_ID (+)
            AND pr.REVISION_ID = si.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(si.country)
	);
	
	DELETE FROM gt_country_sold_in
	 WHERE product_id = in_product_id
	 AND revision_id = v_max_revision_id;

	-- Check for "empty array"
	IF in_country_codes.COUNT = 1 AND in_country_codes(1) IS NULL THEN
		score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Countries sold in', v_old_sold_in_list, v_new_sold_in_list);
		model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);	
		RETURN;
	END IF;

	FOR i IN in_country_codes.FIRST .. in_country_codes.LAST
	LOOP
		INSERT INTO gt_country_sold_in
		  (product_id, revision_id, country_code)
		 VALUES (in_product_id, v_max_revision_id, in_country_codes(i));
	END LOOP;
	
	SELECT NVL(csr.stragg(country), 'None selected') INTO v_new_sold_in_list FROM (
            SELECT si.country 
            	FROM (SELECT c.country, si.product_id, si.revision_id FROM gt_country_sold_in si, country c WHERE c.country_code = si.country_code) si, 
				product_revision pr
            WHERE pr.product_id=si.PRODUCT_ID (+)
            AND pr.REVISION_ID = si.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(si.country)
	);
	
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_NON_SCORING, null, 'Countries sold in', v_old_sold_in_list, v_new_sold_in_list);
	
	model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);
END;

PROCEDURE GetCountriesSoldIn(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.country_code, c.country country_name, 
			DECODE(s.country_code, NULL, 0, 1) sold_in
	      FROM gt_country_sold_in s, country c
	     WHERE s.country_code(+) = c.country_code
	       AND product_id(+) = in_product_id
		 	AND ((s.revision_id IS NULL) OR (s.revision_id = in_revision_id))
            and c.country_code <> 'UK'
	      	ORDER BY sold_in DESC, c.country ASC;
END;

PROCEDURE SetCountriesMadeIn (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,	
	in_country_codes				IN T_COUNTRY_CODES,
  	in_ttypes						IN T_TRANSPORT_TYPES,
  	in_int_flags					IN T_MADE_INTERNALLY_FLAGS,
  	in_pcts							IN T_PERCENTAGES
)
AS
	v_ttype							gt_transport_type.gt_transport_type_id%TYPE;
	v_max_revision_id				product_revision.revision_id%TYPE;
	v_old_made_in_list				VARCHAR(2048);
	v_new_made_in_list				VARCHAR(2048);
BEGIN

	SELECT MAX(revision_id) INTO v_max_revision_id FROM product_revision WHERE product_id = in_product_id;
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_old_made_in_list FROM (
            SELECT mi.description 
            	FROM (SELECT c.country||', '||tt.description||DECODE(mi.pct, -1, '', ', '||mi.pct||'%') description , mi.product_id, mi.revision_id FROM gt_country_made_in mi, gt_transport_type tt, country c WHERE c.country_code = mi.country_code AND mi.gt_transport_type_id = tt.gt_transport_type_id) mi, 
				product_revision pr
            WHERE pr.product_id=mi.PRODUCT_ID (+)
            AND pr.REVISION_ID = mi.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(mi.description)
	);
	
	DELETE FROM gt_country_made_in
	 WHERE product_id = in_product_id
	 AND revision_id = v_max_revision_id;
	
	-- Check for "empty array"
	IF in_country_codes.COUNT = 1 AND in_country_codes(1) IS NULL THEN
		score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_TO_BOOTS, null, 'Countries made in', v_old_made_in_list, v_new_made_in_list);
		model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);	
		RETURN;
	END IF;
	 
	FOR i IN in_country_codes.FIRST .. in_country_codes.LAST
	LOOP
		v_ttype := in_ttypes(i);
		IF in_int_flags(i) != 0 THEN
			v_ttype := 0; -- ALWAYS special "Onsite" type if made internally
		END IF;
		
		INSERT INTO gt_country_made_in
			(product_id, revision_id, country_code, gt_transport_type_id, made_internally, pct)
		  VALUES (in_product_id, v_max_revision_id, in_country_codes(i), v_ttype, in_int_flags(i), in_pcts(i));
	END LOOP;
	
	SELECT NVL(csr.stragg(description), 'None selected') INTO v_new_made_in_list FROM (
            SELECT mi.description 
            	FROM (SELECT c.country||', '||tt.description||DECODE(mi.pct, -1, '', ', '||mi.pct||'%') description , mi.product_id, mi.revision_id FROM gt_country_made_in mi, gt_transport_type tt, country c WHERE c.country_code = mi.country_code AND mi.gt_transport_type_id = tt.gt_transport_type_id) mi, 
				product_revision pr
            WHERE pr.product_id=mi.PRODUCT_ID (+)
            AND pr.REVISION_ID = mi.revision_id(+)
			AND pr.product_id = in_product_id
			AND pr.revision_id = v_max_revision_id
			ORDER BY LOWER(mi.description)
	);
	
	score_log_pkg.LogValChange(in_act_id, in_product_id, score_log_pkg.ID_SCORE_TRANS_TO_BOOTS, null, 'Countries made in', v_old_made_in_list, v_new_made_in_list);
	
	model_pkg.CalcProductScores(in_act_id, in_product_id, v_max_revision_id);	

END;

PROCEDURE GetCountriesMadeIn(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id				IN product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT m.product_id, m.country_code, m.gt_transport_type_id, m.made_internally, m.pct,
			c.country country_name, t.description transport_type_name
		  FROM gt_country_made_in m, country c, gt_transport_type t
		 WHERE m.product_id = in_product_id
		   AND c.country_code = m.country_code
		   AND t.gt_transport_type_id = m.gt_transport_type_id
		 	AND ((m.revision_id IS NULL) OR (m.revision_id = in_revision_id))
		   	ORDER BY c.country;
END;

PROCEDURE GetCountries(
	in_act_id					IN	security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT country_code, country country_name
		  FROM country
		  	ORDER BY country;
END;

PROCEDURE GetTransportTypes(
	in_act_id					IN	security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT gt_transport_type_id, description, pos
		  FROM gt_transport_type
		 WHERE gt_transport_type_id > 0
		 	ORDER BY pos;
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
BEGIN
		
	DELETE FROM gt_country_made_in
		WHERE product_id = in_to_product_id
		AND revision_id =  in_to_rev;
		
	DELETE FROM gt_transport_answers
		WHERE product_id = in_to_product_id
		AND revision_id =  in_to_rev;
	
	INSERT INTO gt_transport_answers (
	   product_id, revision_id, prod_in_cont_pct, 
	   prod_btwn_cont_pct, prod_cont_un_pct, pack_in_cont_pct, 
	   pack_btwn_cont_pct, pack_cont_un_pct, data_quality_type_id) 
	SELECT 
		in_to_product_id, in_to_rev, prod_in_cont_pct, 
	   prod_btwn_cont_pct, prod_cont_un_pct, pack_in_cont_pct, 
	   pack_btwn_cont_pct, pack_cont_un_pct, data_quality_type_id
	FROM gt_transport_answers
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;
		
	INSERT INTO gt_country_made_in (
	   product_id, country_code, gt_transport_type_id, 
	   revision_id, made_internally, pct) 
	SELECT 
		in_to_product_id, country_code, gt_transport_type_id, 
		in_to_rev, made_internally, pct
	FROM gt_country_made_in
		WHERE product_id = in_from_product_id
		AND revision_id =  in_from_rev;
	
END;

END gt_transport_pkg;
/
