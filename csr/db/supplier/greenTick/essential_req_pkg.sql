create or replace package supplier.essential_req_pkg
IS

PROCEDURE GetProductEssentialReq (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN 	product_revision.revision_id%TYPE,
	out_prod_data		OUT	security_pkg.T_OUTPUT_CUR,
	out_pack_details	OUT	security_pkg.T_OUTPUT_CUR,
	out_assessment		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN 	product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
); 

PROCEDURE GetPackDetails (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN  product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


END essential_req_pkg;
/
