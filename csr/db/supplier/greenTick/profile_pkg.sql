create or replace package supplier.profile_pkg
IS

PROCEDURE GetProductProfile (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_profile			OUT	security_pkg.T_OUTPUT_CUR,
	out_biodiv			OUT	security_pkg.T_OUTPUT_CUR,
	out_source			OUT	security_pkg.T_OUTPUT_CUR,
	out_transport		OUT	security_pkg.T_OUTPUT_CUR,
	out_scores			OUT	security_pkg.T_OUTPUT_CUR,
	out_socamp			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductProfileData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBiodiversityChartData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSourceChartData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTransportToBootsData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id			IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHazChemData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEndangeredData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPalmData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAccredNoteData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_product_id		IN	all_product.product_id%TYPE,
	in_revision_id		IN product_revision.revision_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CopyProfilesFromRevision(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN all_product.product_id%TYPE,
	in_from_rev						IN product_revision.revision_id%TYPE
);

END profile_pkg;
/
