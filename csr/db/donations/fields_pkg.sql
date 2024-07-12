CREATE OR REPLACE PACKAGE DONATIONS.fields_pkg
IS


FUNCTION GetFieldName(
  in_field_num    IN custom_field.field_num%TYPE
) RETURN VARCHAR2;

PROCEDURE GetFields(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFieldsOrderByLabel(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFieldDetails(
    in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_lookup_key       IN  custom_field.lookup_key%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFieldsByScheme(
    in_act				IN	security_pkg.T_ACT_ID,
    in_app_sid          IN	security_pkg.T_SID_ID,
	in_scheme_sid       IN security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFieldsForSchemeSetup(
    in_act				IN	security_pkg.T_ACT_ID,
    in_app_sid          IN	security_pkg.T_SID_ID,
	in_scheme_sid       IN security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

/*PROCEDURE AssociateFieldsToScheme(
    in_act				IN	security_pkg.T_ACT_ID,
    in_app_sid			IN	security_pkg.T_SID_ID,
	in_scheme_sid       IN security_pkg.T_SID_ID,
	in_field_nums		IN	VARCHAR2
);
*/

PROCEDURE UpdateField(
	in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid			        IN	security_pkg.T_SID_ID,
    in_label                    IN  custom_field.label%TYPE,
    in_field_num                IN  custom_field.field_num%TYPE,
    in_expr                     IN  custom_field.expr%TYPE,
    in_mandatory                IN  custom_field.is_mandatory%TYPE,
    in_note                     IN  custom_field.note%TYPE,
    in_detailed_note            IN  VARCHAR2,
    in_lookup                   IN  custom_field.lookup_key%TYPE,
    in_currency                 IN  custom_field.is_currency%TYPE,
    in_section                  IN  custom_field.section%TYPE,
    in_pos                      IN  custom_field.pos%TYPE
);

PROCEDURE AddField(
    in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid			        IN	security_pkg.T_SID_ID,
    in_label                    IN  custom_field.label%TYPE,
    in_expr                     IN  custom_field.expr%TYPE,
    in_mandatory                IN  custom_field.is_mandatory%TYPE,
    in_note                     IN  custom_field.note%TYPE,
    in_detailed_note            IN  VARCHAR2,
    in_lookup                   IN  custom_field.lookup_key%TYPE,
    in_currency                 IN  custom_field.is_currency%TYPE,
    in_section                  IN  custom_field.section%TYPE,
    in_pos                      IN  custom_field.pos%TYPE,
    out_field_num				OUT	custom_field.field_num%TYPE
);

PROCEDURE DeleteFields(
    in_app_sid			        IN	security_pkg.T_SID_ID,
	-- NOTE: the fieldnums will REMAIN in DB; the others that belongs to same app_sid will be deleted
	in_field_nums_to_leave	    IN	VARCHAR2
);

PROCEDURE GetFieldsDetails(
    in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid                  IN	security_pkg.T_SID_ID,
    out_cur				        OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AssociateFieldWithScheme(
    in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid                  IN	security_pkg.T_SID_ID,
    in_scheme_sid               IN security_pkg.T_SID_ID,
	in_field_num		        IN scheme_field.field_num%TYPE,
	in_show_in_browse           IN scheme_field.show_in_browse%TYPE
);

PROCEDURE UnmapFields(
    in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid                  IN	security_pkg.T_SID_ID,
    in_scheme_sid               IN security_pkg.T_SID_ID,
    in_field_nums		        IN VARCHAR2
);

PROCEDURE GetFieldsSchemeMapping(
    in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid                  IN	security_pkg.T_SID_ID,
    out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetDependencies(
	in_field_num			IN	custom_field.field_num%TYPE,
	in_dependent_field_nums	IN	security_pkg.T_SID_IDS
);

PROCEDURE GetCalcOrder(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
);

END fields_pkg;
/
