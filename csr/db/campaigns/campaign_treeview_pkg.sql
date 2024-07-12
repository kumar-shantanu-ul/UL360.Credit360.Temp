CREATE OR REPLACE PACKAGE campaigns.campaign_treeview_pkg AS

PROCEDURE GetCampaignTreeWithDepth(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_fetch_depth		IN  NUMBER,
	in_show_inactive 	IN 	NUMBER,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCampaignTreeTextFiltered(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_show_inactive 	IN 	NUMBER,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCampaignTreeWithSelect(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_select_sid		IN	security.security_pkg.T_SID_ID,
	in_show_inactive 	IN 	NUMBER,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
);

END campaign_treeview_pkg;
/