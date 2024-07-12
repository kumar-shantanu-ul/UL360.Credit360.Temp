CREATE OR REPLACE PACKAGE ct.advice_pkg AS

PROCEDURE AddEIOGroupAdvice(
	in_eio_group_id 					IN eio_group.eio_group_id%TYPE,
	in_advice							IN advice.advice%TYPE,
	out_advice_id						OUT advice.advice_id%TYPE
);

PROCEDURE AddEIOAdvice(
	in_eio_id 							IN eio.eio_id%TYPE,
	in_advice							IN advice.advice%TYPE,
	out_advice_id						OUT advice.advice_id%TYPE
);

PROCEDURE AddScope3CatAdvice(
	in_scope_category_id				IN scope_3_category.scope_category_id%TYPE,
	in_advice_key						IN scope_3_advice.advice_key%TYPE,
	in_advice							IN advice.advice%TYPE,
	out_advice_id						OUT advice.advice_id%TYPE
);

PROCEDURE AddAdviceURL(
	in_advice_id						IN advice_url.advice_id%TYPE,
	in_url_pos_id						IN advice_url.url_pos_id%TYPE,
	in_text								IN advice_url.text%TYPE,
	in_url								IN advice_url.url%TYPE
);

PROCEDURE GetCompanyEioAdvice(
	in_company_sid						IN  security_pkg.T_SID_ID,
	in_breakdown_ids					IN  security_pkg.T_SID_IDS,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEioAdvice(
	in_eio_id 							IN  eio.eio_id%TYPE,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEioAdvice(
	in_eio_ids 							IN  security_pkg.T_SID_IDS,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyScopeCategoryAdvice(
	in_company_sid						IN  security_pkg.T_SID_ID,
	in_breakdown_ids					IN  security_pkg.T_SID_IDS,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR, 
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetScopeCategoryAdvice(
	in_scope_category_id				IN  scope_3_category.scope_category_id%TYPE,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetScopeCategoryAdvice(
	in_scope_category_ids				IN  security_pkg.T_SID_IDS,
	out_advice_cur 						OUT security_pkg.T_OUTPUT_CUR,
	out_urls_cur 						OUT security_pkg.T_OUTPUT_CUR
);


END advice_pkg;
/
