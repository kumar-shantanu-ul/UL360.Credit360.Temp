create or replace package supplier.gt_transport_pkg
IS

TYPE T_COUNTRY_CODES IS TABLE OF country.country_code%TYPE INDEX BY PLS_INTEGER;
TYPE T_TRANSPORT_TYPES IS TABLE OF gt_transport_type.gt_transport_type_id%TYPE INDEX BY PLS_INTEGER;
TYPE T_MADE_INTERNALLY_FLAGS IS TABLE OF gt_country_made_in.made_internally%TYPE INDEX BY PLS_INTEGER;
TYPE T_PERCENTAGES IS TABLE OF gt_country_made_in.pct%TYPE INDEX BY PLS_INTEGER;


PROCEDURE GetTransportCompound(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,	
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_answers						OUT security_pkg.T_OUTPUT_CUR,
	out_sold_in						OUT security_pkg.T_OUTPUT_CUR,
	out_made_in						OUT security_pkg.T_OUTPUT_CUR
);


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
);

PROCEDURE GetTransportAnswers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCountriesSoldIn (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,	
  	in_country_codes				IN T_COUNTRY_CODES
);

PROCEDURE GetCountriesSoldIn(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCountriesMadeIn (
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,	
	in_country_codes				IN T_COUNTRY_CODES,
  	in_ttypes						IN T_TRANSPORT_TYPES,
  	in_int_flags					IN T_MADE_INTERNALLY_FLAGS,
  	in_pcts							IN T_PERCENTAGES
);

PROCEDURE GetCountriesMadeIn(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id				IN	all_product.product_id%TYPE,
	in_revision_id					IN product_revision.revision_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCountries(
	in_act_id					IN	security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTransportTypes(
	in_act_id					IN	security_pkg.T_ACT_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE IncrementRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE
);

PROCEDURE CopyAnswers(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_product_id				IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE,
	in_to_product_id				IN all_product.product_id%TYPE,
	in_to_rev						IN product_revision.revision_id%TYPE
);

END gt_transport_pkg;
/
