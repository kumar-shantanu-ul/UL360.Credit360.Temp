CREATE OR REPLACE PACKAGE CHAIN.company_tag_pkg
IS

PROCEDURE GetTagGroup (
	in_tag_group_id			IN  chain.company_tag_group.tag_group_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroups (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetTagGroup (
	in_tag_group_id			IN  chain.company_tag_group.tag_group_id%TYPE,
	in_applies_to_component	IN  chain.company_tag_group.applies_to_component%TYPE,
	in_applies_to_purchase	IN  chain.company_tag_group.applies_to_purchase%TYPE
);

PROCEDURE GetCompanyTags (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END company_tag_pkg;
/
