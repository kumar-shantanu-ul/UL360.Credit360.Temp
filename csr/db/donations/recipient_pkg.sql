CREATE OR REPLACE PACKAGE  DONATIONS.recipient_Pkg
IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);


PROCEDURE CreateRecipient(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_PKG.T_SID_ID,
	in_parent_sid				IN 	security_PKG.T_SID_ID,
	in_org_name		  			IN	recipient.org_name%TYPE,
	in_contact_name		  		IN	recipient.contact_name%TYPE,
	in_address_1				IN	recipient.address_1%TYPE,
	in_address_2				IN	recipient.address_2%TYPE,
	in_address_3				IN	recipient.address_3%TYPE,
	in_address_4				IN	recipient.address_4%TYPE,
	in_town		  				IN	recipient.town%TYPE,
	in_state					IN	recipient.state%TYPE,
	in_postcode				 	IN	recipient.postcode%TYPE,
	in_country_code				IN	postcode.country.country%TYPE,
	in_phone					IN	recipient.phone%TYPE,
	in_phone_alt				IN	recipient.phone_alt%TYPE,
	in_fax						IN	recipient.fax%TYPE,
	in_email					IN	recipient.email%TYPE,
	in_ref						IN	recipient.ref%TYPE,
	in_account_num				IN	recipient.account_num%TYPE,
	in_bank_name				IN	recipient.bank_name%TYPE,
	in_sort_code				IN	recipient.sort_code%TYPE,
	in_tax_id					IN	recipient.tax_id%TYPE,
	out_recipient_sid  			OUT security_PKG.T_SID_ID
);

PROCEDURE AmendRecipient (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_recipient_sid			IN	security_PKG.T_SID_ID,
	in_parent_sid				IN 	security_PKG.T_SID_ID,
	in_org_name					IN	recipient.org_name%TYPE,
	in_contact_name				IN	recipient.contact_name%TYPE,
	in_address_1				IN	recipient.address_1%TYPE,
	in_address_2	 			IN	recipient.address_2%TYPE,
	in_address_3	 			IN	recipient.address_3%TYPE,
	in_address_4	 			IN	recipient.address_4%TYPE,
	in_town						IN	recipient.town%TYPE,
	in_state		  			IN	recipient.state%TYPE,
	in_postcode	  				IN	recipient.postcode%TYPE,
	in_country_code				IN	postcode.country.country%TYPE,
	in_phone		  			IN	recipient.phone%TYPE,
	in_phone_alt				IN	recipient.phone_alt%TYPE,
	in_fax		 				IN	recipient.fax%TYPE,
	in_email					IN	recipient.email%TYPE,
	in_ref						IN	recipient.ref%TYPE,	
	in_account_num				IN	recipient.account_num%TYPE,
	in_bank_name				IN	recipient.bank_name%TYPE,
	in_sort_code				IN	recipient.sort_code%TYPE,
	in_tax_id					IN	recipient.tax_id%TYPE
);


FUNCTION GetOrgName(
	in_recipient_sid		IN security_pkg.T_SID_ID
) RETURN recipient.org_name%TYPE;
PRAGMA RESTRICT_REFERENCES(GetOrgName, WNDS, WNPS);


FUNCTION GetChildCount(
	in_recipent_sid		IN security_pkg.T_SID_ID
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(GetChildCount, WNDS, WNPS);


FUNCTION ConcatTagIds(
	in_recipient_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatTagIds, WNDS, WNPS);

PROCEDURE Search (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	in_phrase			IN	varchar2,
	in_max				IN	number,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetRecipient(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_recipient_sid	IN  security_pkg.T_SID_ID,
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR
);


PROCEDURE GetRecipientByName(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_org_name					IN  recipient.org_name%TYPE,
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetRecipientsForApp(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_app_sid			IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetChildRecipients(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_parent_sid		IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE AddRecipientRegionGroup(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID
);


PROCEDURE SetPostIt(
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	in_postit_id		IN	csr.postit.postit_id%TYPE,
	out_postit_id		OUT csr.postit.postit_id%TYPE
);

PROCEDURE GetPostIts(
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FindRef(
	in_ref				IN	varchar2,
	in_country_code		IN	postcode.country.country%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FilterRef(
	in_filter			IN	varchar2,
	in_country_code		IN	postcode.country.country%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END recipient_Pkg;
/
