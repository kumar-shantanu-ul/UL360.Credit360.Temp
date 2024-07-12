CREATE OR REPLACE PACKAGE BODY ct.advice_pkg AS

/****************************************************************************
	PRIVATE
****************************************************************************/
PROCEDURE CollectAdvice (
	in_advice_ids				IN  security_pkg.T_SID_IDS,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_advice_ids						security.T_SID_TABLE;
BEGIN
	t_advice_ids := security_pkg.SidArrayToTable(in_advice_ids);
		
	OPEN out_advice_cur FOR
		SELECT advice_id, advice
		  FROM advice 
		 WHERE advice_id IN (SELECT column_value FROM TABLE(t_advice_ids))
		 ORDER BY advice_id;

	OPEN out_urls_cur FOR
		SELECT advice_id, url_pos_id, text, url
		  FROM advice_url
		 WHERE advice_id IN (SELECT column_value FROM TABLE(t_advice_ids))
		 ORDER BY advice_id, url_pos_id;
END;

/****************************************************************************
	PUBLIC
****************************************************************************/

PROCEDURE AddEIOGroupAdvice(
	in_eio_group_id 					IN eio_group.eio_group_id%TYPE,
	in_advice							IN advice.advice%TYPE,
	out_advice_id						OUT advice.advice_id%TYPE
)
AS
BEGIN
	-- TO DO - security check
	DELETE FROM advice_url 
	 WHERE advice_id 
	    IN (SELECT advice_id FROM eio_group_advice WHERE eio_group_id = in_eio_group_id);
		
	DELETE FROM eio_group_advice 
	 WHERE eio_group_id = in_eio_group_id;
		
	--TO DO - hacky - clearup
	DELETE FROM advice WHERE advice_id NOT IN (
		SELECT advice_id FROM eio_group_advice
			UNION
		SELECT advice_id FROM eio_advice
			UNION
		SELECT advice_id FROM scope_3_advice
	);
		
	INSERT INTO advice (advice_id, advice) VALUES (advice_id_seq.nextval, in_advice)
	RETURNING advice_id INTO out_advice_id;

	INSERT INTO eio_group_advice (eio_group_id, advice_id) VALUES (in_eio_group_id, out_advice_id);
	
END;

PROCEDURE AddEIOAdvice(
	in_eio_id 							IN eio.eio_id%TYPE,
	in_advice							IN advice.advice%TYPE,
	out_advice_id						OUT advice.advice_id%TYPE
)
AS
BEGIN
	-- TO DO - security check
	DELETE FROM advice_url 
	 WHERE advice_id 
	    IN (SELECT advice_id FROM eio_advice WHERE eio_id = in_eio_id);
		
	DELETE FROM eio_advice 
	 WHERE eio_id = in_eio_id;
	 
	 --TO DO - hacky - clearup
	DELETE FROM advice WHERE advice_id NOT IN (
		SELECT advice_id FROM eio_group_advice
			UNION
		SELECT advice_id FROM eio_advice
			UNION
		SELECT advice_id FROM scope_3_advice
	);
		
	INSERT INTO advice (advice_id, advice) VALUES (advice_id_seq.nextval, in_advice)
	RETURNING advice_id INTO out_advice_id;

	-- TO DO - tidy this up
	INSERT INTO eio_advice (eio_id, advice_id) VALUES (in_eio_id, out_advice_id);
	
END;

PROCEDURE AddScope3CatAdvice(
	in_scope_category_id				IN scope_3_category.scope_category_id%TYPE,
	in_advice_key						IN scope_3_advice.advice_key%TYPE,
	in_advice							IN advice.advice%TYPE,
	out_advice_id						OUT advice.advice_id%TYPE
)
AS
BEGIN
	-- TO DO - security check
	DELETE FROM advice_url 
	 WHERE advice_id 
	    IN (SELECT advice_id FROM scope_3_advice WHERE advice_key = in_advice_key);
		
	DELETE FROM scope_3_advice 
	 WHERE advice_key = in_advice_key;
	 
	DELETE FROM advice WHERE advice_id NOT IN (
		SELECT advice_id FROM eio_group_advice
			UNION
		SELECT advice_id FROM eio_advice
			UNION
		SELECT advice_id FROM scope_3_advice
	);
		
	INSERT INTO advice (advice_id, advice) VALUES (advice_id_seq.nextval, in_advice)
	RETURNING advice_id INTO out_advice_id;

	-- TO DO - tidy this up
	INSERT INTO scope_3_advice (scope_category_id, advice_key, advice_id) VALUES (in_scope_category_id, in_advice_key, out_advice_id);
	
END;

PROCEDURE AddAdviceURL(
	in_advice_id						IN advice_url.advice_id%TYPE,
	in_url_pos_id						IN advice_url.url_pos_id%TYPE,
	in_text								IN advice_url.text%TYPE,
	in_url								IN advice_url.url%TYPE
)
AS
BEGIN
	-- TO DO - security check
	BEGIN
		INSERT INTO advice_url (advice_id, url_pos_id, text, url) VALUES (in_advice_id, in_url_pos_id, in_text, in_url);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE advice_url
			   SET 	text = in_text, 
					url = in_url
			 WHERE advice_id = in_advice_id
			   AND url_pos_id = in_url_pos_id;
	END;
END;

PROCEDURE GetCompanyEioAdvice(
	in_company_sid						IN  security_pkg.T_SID_ID,
	in_breakdown_ids					IN  security_pkg.T_SID_IDS,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_breakdown_ids						security.T_SID_TABLE;
	v_eio_ids 							security_pkg.T_SID_IDS;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, in_company_sid);
	END IF;
	
	t_breakdown_ids := security_pkg.SidArrayToTable(in_breakdown_ids);
	
	SELECT UNIQUE bre.eio_id
	  BULK COLLECT INTO v_eio_ids
	  FROM breakdown b, breakdown_region_eio bre
	 WHERE b.app_sid = bre.app_sid
	   AND b.company_sid = in_company_sid
	   AND b.breakdown_id IN (SELECT column_value FROM TABLE(t_breakdown_ids))
	   AND b.breakdown_id = bre.breakdown_id;
	
	GetEioAdvice(v_eio_ids, out_advice_cur, out_urls_cur);
END;

PROCEDURE GetEioAdvice(
	in_eio_id 							IN  eio.eio_id%TYPE,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_eio_ids 							security_pkg.T_SID_IDS;
BEGIN
	SELECT in_eio_id BULK COLLECT INTO v_eio_ids FROM DUAL;
	GetEioAdvice(v_eio_ids, out_advice_cur, out_urls_cur);
END;

PROCEDURE GetEioAdvice(
	in_eio_ids 							IN  security_pkg.T_SID_IDS,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_eio_ids							security.T_SID_TABLE;
	v_advice_ids						security_pkg.T_SID_IDS;
BEGIN
	-- check that the user can at least read their own company
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	t_eio_ids := security_pkg.SidArrayToTable(in_eio_ids);
	
	-- collect the advice ids that we're interested in
	SELECT NVL(ea.advice_id, ega.advice_id)
	  BULK COLLECT INTO v_advice_ids
	  FROM eio e, eio_advice ea, eio_group_advice ega
	 WHERE e.eio_id IN (SELECT column_value FROM TABLE(t_eio_ids))
	   AND e.eio_id = ea.eio_id(+)
	   AND e.eio_group_id = ega.eio_group_id;
	
	CollectAdvice(v_advice_ids, out_advice_cur, out_urls_cur);
END;

PROCEDURE GetCompanyScopeCategoryAdvice(
	in_company_sid						IN  security_pkg.T_SID_ID,
	in_breakdown_ids					IN  security_pkg.T_SID_IDS,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_dummy_cur							security_pkg.T_OUTPUT_CUR;
	v_cat_ids 							security_pkg.T_SID_IDS;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, in_company_sid);
	END IF;

	-- this will populate the chart_value table
	hotspot_pkg.GetEmissionByCategory(in_breakdown_ids, 0, 1, 1, null, v_dummy_cur);

	SELECT UNIQUE scope_3_category_id
	  BULK COLLECT INTO v_cat_ids
	  FROM chart_value
	 WHERE val > 0;
		
	GetScopeCategoryAdvice(v_cat_ids, out_advice_cur, out_urls_cur);
END;

PROCEDURE GetScopeCategoryAdvice(
	in_scope_category_id				IN  scope_3_category.scope_category_id%TYPE,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_cat_ids 							security_pkg.T_SID_IDS;
BEGIN
	SELECT in_scope_category_id BULK COLLECT INTO v_cat_ids FROM DUAL;
	GetEioAdvice(v_cat_ids, out_advice_cur, out_urls_cur);

END;

PROCEDURE GetScopeCategoryAdvice(
	in_scope_category_ids				IN  security_pkg.T_SID_IDS,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_cat_ids							security.T_SID_TABLE;
	v_advice_ids						security_pkg.T_SID_IDS;
BEGIN
	-- check that the user can at least read their own company
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	t_cat_ids := security_pkg.SidArrayToTable(in_scope_category_ids);
	
	-- collect the advice ids that we're interested in
	SELECT advice_id
	  BULK COLLECT INTO v_advice_ids
	  FROM scope_3_advice
	 WHERE scope_category_id IN (SELECT column_value FROM TABLE(t_cat_ids));
	
	CollectAdvice(v_advice_ids, out_advice_cur, out_urls_cur);
END;


END  advice_pkg;
/

