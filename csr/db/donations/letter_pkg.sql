CREATE OR REPLACE PACKAGE DONATIONS.letter_pkg
IS

PROCEDURE GetTemplateList(
	in_act					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSelectedTemplate(
	in_act					IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTemplate(
	in_act					IN	security_pkg.T_ACT_ID,
	in_template_id			IN	letter_template.letter_template_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE NewTemplateFromCache(
	in_act					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_template_id			OUT	letter_template.letter_template_id%TYPE
);

PROCEDURE AssocTemplateWithRegionGroup(
	in_act					IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_template_id			IN	letter_template.letter_template_id%TYPE
);


PROCEDURE DeleteTemplate(
	in_act					IN	security_pkg.T_ACT_ID,
	in_template_id			IN	letter_template.letter_template_id%TYPE
);



-- If the region group supplied has no body text then the default body text will be returned
-- Region group can be null, in which case the default body text is returned
PROCEDURE GetBodyTextForRegionGroup(
	in_act					IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_status_sid			IN	donation_status.donation_status_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBodyText(
	in_act					IN	security_pkg.T_ACT_ID,
	in_body_text_id			IN	letter_body_text.letter_body_text_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE SetBodyText(
	in_act					IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_status_sid			IN	donation_status.donation_status_sid%TYPE,
	in_text	    			IN	letter_body_text.body_text%TYPE,
	in_active               IN  donation_status.letter_active%TYPE DEFAULT 1,
	out_body_text_id		OUT	letter_body_text.letter_body_text_id%TYPE
);


PROCEDURE DeleteBodyText(
	in_act					IN	security_pkg.T_ACT_ID,
	in_body_text_id			IN	letter_body_text.letter_body_text_id%TYPE
);

PROCEDURE DeleteBodyTextForRegionGroup(
	in_act					IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_status_sid			IN	donation_status.donation_status_sid%TYPE
);


PROCEDURE GetStatusToActiveMapping(
	in_act					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

END letter_pkg;
/