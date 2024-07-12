create or replace package supplier.public_data_pkg
IS

PROCEDURE GetProductsByCode(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_app_sid				IN security_pkg.T_SID_ID,
	in_product_code			IN product.product_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductProfile (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN 	product_revision.revision_id%TYPE,
	out_profile			OUT	security_pkg.T_OUTPUT_CUR,
	out_biodiv			OUT	security_pkg.T_OUTPUT_CUR,
	out_source			OUT	security_pkg.T_OUTPUT_CUR,
	out_transport		OUT	security_pkg.T_OUTPUT_CUR,
	out_scores			OUT	security_pkg.T_OUTPUT_CUR,
	out_socamp			OUT security_pkg.T_OUTPUT_CUR
);

END public_data_pkg;
/