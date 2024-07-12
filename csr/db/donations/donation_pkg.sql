CREATE OR REPLACE PACKAGE DONATIONS.donation_Pkg
IS

TYPE T_DECIMAL_ARRAY      IS TABLE OF NUMBER(24,10) 				  INDEX BY PLS_INTEGER;
TYPE T_CUSTOM_VALUES      IS TABLE OF donation.custom_1%TYPE         INDEX BY PLS_INTEGER;
TYPE T_BUDGET_NAMES       IS TABLE OF budget.description%TYPE        INDEX BY PLS_INTEGER;

FUNCTION CanUpdate(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE
) RETURN BOOLEAN;

-- 
-- PROCEDURE: CreateDONATION 
--
PROCEDURE CreateDonation (
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_recipient_sid			IN	security_pkg.T_SID_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_budget_id			  	IN	donation.budget_id%TYPE,
	in_region_sid			  	IN	security_pkg.T_SID_ID,
	in_activity						IN	donation.activity%TYPE,
	in_donated_dtm				IN	donation.donated_dtm%TYPE,
	in_end_dtm					IN	donation.end_dtm%TYPE,
	in_donation_status_sid	IN	donation.donation_status_sid%TYPE,
	in_paid_dtm						IN	donation.paid_dtm%TYPE,
	in_payment_ref				IN	donation.payment_ref%TYPE,
	in_notes							IN	donation.notes%TYPE,
	in_allocated_from_donation_id	IN	donation.allocated_from_donation_id%TYPE,
	in_extra_values_xml		IN	donation.extra_values_xml%TYPE,
	in_document_sids				IN	security_pkg.T_SID_IDS,
	in_letter_text			IN	donation.letter_body_text%TYPE,
	in_contact_name					IN	donation.contact_name%TYPE,
	in_custom_values				IN  T_CUSTOM_VALUES,
	out_donation_id				OUT donation.donation_id%TYPE
);

-- 
-- PROCEDURE: AmendDONATION 
--
PROCEDURE AmendDonation (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_donation_id			IN	donation.donation_id%TYPE,
	in_recipient_sid		IN	security_pkg.T_SID_ID,
	in_scheme_sid				IN	security_pkg.T_SID_ID,
	in_budget_id			 	IN	donation.budget_id%TYPE,
	in_region_sid			  IN	security_pkg.T_SID_ID,
	in_activity					IN	donation.activity%TYPE,
	in_donated_dtm			IN	donation.donated_dtm%TYPE,
	in_end_dtm					IN	donation.end_dtm%TYPE,
	in_donation_status_sid	IN	donation.donation_status_sid%TYPE,
	in_paid_dtm						IN	donation.paid_dtm%TYPE,
	in_payment_ref				IN	donation.payment_ref%TYPE,
	in_notes							IN	donation.notes%TYPE,
	in_allocated_from_donation_id	IN	donation.allocated_from_donation_id%TYPE,
	in_extra_values_xml		IN	donation.extra_values_xml%TYPE,
	in_document_sids				IN	security_pkg.T_SID_IDS,
	in_letter_text			IN	donation.letter_body_text%TYPE,
	in_contact_name					IN	donation.contact_name%TYPE,
	in_custom_values				IN  T_CUSTOM_VALUES
);

-- 
-- PROCEDURE: DeleteDONATION 
--
PROCEDURE DeleteDonation (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_donation_id	IN donation.donation_Id%TYPE
);


FUNCTION ConcatTagIds(
	in_donation_id	IN	donation.donation_id%TYPE
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatTagIds, WNDS, WNPS);


FUNCTION ConcatTags(
	in_donation_id	IN	donation.donation_id%TYPE,
	in_max_length		IN 	INTEGER  DEFAULT 10
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatTags, WNDS, WNPS);

FUNCTION ConcatRecipientTagIds(
	in_recipient_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatRecipientTagIds, WNDS, WNPS);

FUNCTION ConcatRecipientTags(
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	in_max_length		IN 	INTEGER DEFAULT 10
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatRecipientTags, WNDS, WNPS);

FUNCTION ConcatRegionTagIds(
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatRegionTagIds, WNDS, WNPS);

FUNCTION ConcatRegionTags(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_max_length		IN 	INTEGER DEFAULT 10
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatRegionTags, WNDS, WNPS);

PROCEDURE GetDonationsForStatuses(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_status_sids		IN  security_pkg.T_SID_IDS,	
	out_cur				OUT security_Pkg.T_OUTPUT_CUR,
	out_docs			OUT	security_Pkg.T_OUTPUT_CUR,
	out_tags			OUT	security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetDonationsForRecipient(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_recipient_sid	IN  security_pkg.T_SID_ID,
	out_cur				OUT security_Pkg.T_OUTPUT_CUR,
	out_docs			OUT	security_Pkg.T_OUTPUT_CUR,
	out_tags			OUT	security_Pkg.T_OUTPUT_CUR
);
PROCEDURE GetDonation(
    in_act_id			IN  security_pkg.T_ACT_ID,
	in_donation_id		IN  donation.donation_id%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur       OUT Security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDonationsForApp(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_app_sid			IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur		OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetDonationsForScheme(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_scheme_sid		IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur       OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetDonationsForBudget(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_budget_id		IN  budget.budget_id%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur       OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetDonationsForRecipient2(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_recipient_sid	IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur		OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetDonationsCountForRecipient(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_recipient_sid    IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetDonationsListForRecipient(
    in_act_id					IN  security_pkg.T_ACT_ID,
	in_recipient_sid	        IN  security_pkg.T_SID_ID,
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetDonationsForTag(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_tag_id			IN  tag.tag_id%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur		OUT Security_Pkg.T_OUTPUT_CUR
);


PROCEDURE ClearTagsFromFilterCondition;

PROCEDURE AddTagsToFilterCondition(
	 in_tag_group_sid	IN	security_pkg.T_SID_ID,
	 in_tag_ids 		IN	security_pkg.T_SID_IDS
);

PROCEDURE AddRecTagsToFilterCondition(
	 in_tag_group_sid	IN	security_pkg.T_SID_ID,
	 in_tag_ids 		IN	security_pkg.T_SID_IDS
);

PROCEDURE AddRegionTagsToFilterCondition(
	 in_tag_group_id	IN	security_pkg.T_SID_ID,
	 in_tag_ids 		IN	security_pkg.T_SID_IDS
);


PROCEDURE GetFilteredList(
	 in_act_id				   IN  security_pkg.T_ACT_ID,
	 in_app_sid				   IN  security_pkg.T_SID_ID,
	 in_recipient_name		   IN  recipient.org_name%TYPE,
	 in_recipient_sid		   IN  security_pkg.T_SID_ID,
	 in_scheme_ids             IN  security_pkg.T_SID_IDS,
	 in_donation_status_sids   IN  security_pkg.T_SID_IDS,
	 in_budget_names           IN  donation_pkg.T_BUDGET_NAMES,
	 in_region_group_ids	   IN  security_pkg.T_SID_IDS,
	 in_region_sid             IN  security_pkg.T_SID_ID,
	 in_include_children       IN  NUMBER,
	 in_funding_commitment_ids IN  security_pkg.T_SID_IDS,
	 in_start_dtm              IN  donation.entered_dtm%TYPE,
	 in_end_dtm                IN  donation.entered_dtm%TYPE,
	 in_donated_start_dtm      IN  donation.donated_dtm%TYPE,
	 in_donated_end_dtm        IN  donation.donated_dtm%TYPE,
	 in_search_term            IN  varchar2,
	 in_start_row			   IN  NUMBER,		    -- 1 based (not 0)
	 in_page_size			   IN  NUMBER,		
	 in_sort_by			   IN  security_pkg.T_VARCHAR2_ARRAY,
	 in_sort_dir			   IN  security_pkg.T_VARCHAR2_ARRAY,	
	 out_cur				   OUT security_pkg.T_OUTPUT_CUR 
);

PROCEDURE GetDonationDetails(
	 in_act_id				   IN  security_pkg.T_ACT_ID,
	 in_app_sid				   IN  security_pkg.T_SID_ID,
	 in_donation_id		       IN  security_pkg.T_SID_ID,
	 out_cur				   OUT security_pkg.T_OUTPUT_CUR,
	 out_doc_cur    		   OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE SetRecipientContactName(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE,
  in_recipient_sid   IN donation.recipient_sid%TYPE,
	in_contact_name		IN	donation.contact_name%TYPE
);


PROCEDURE SetLetterText(
	in_act				IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE,
	in_text				IN	donation.letter_body_text%TYPE
);

PROCEDURE GetLetterText(
	in_act				IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE AuditInfoXmlChanges(
	in_act					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_object_sid		    IN	security_pkg.T_SID_ID,
	in_info_xml_fields		IN	XMLTYPE,
	in_old_info_xml			IN	XMLTYPE,
	in_new_info_xml			IN	XMLTYPE,
	in_sub_object_id		IN  donation.donation_id%TYPE
);


PROCEDURE GetAuditLogForDonation(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_object_sid		    IN	security_pkg.T_SID_ID,
	in_sub_object_id		IN	donation.donation_id%TYPE,
	in_order_by			    IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

-- no security -- called only by import tool
PROCEDURE UNSEC_ImportDonation(
	in_donation_Id		IN	donation.donation_id%TYPE,
	in_entered_by_sid	IN	donation.entered_by_sid%TYPE
);

PROCEDURE UpdateDonationDoc(
	in_donation_id		IN	donation.donation_id%TYPE,
	in_document_sid 	IN	donation_doc.document_sid%TYPE,
	in_filename			IN 	csr.file_upload.filename%TYPE,
	in_description		IN	donation_doc.description%TYPE
);

PROCEDURE GetDonationDocs(
	in_document_sid		IN donation_doc.document_sid%TYPE,
	out_doc_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_description_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllFiles(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE IsV2Enabled(
	out_is_version_2_enabled		OUT	customer_filter_flag.is_version_2_enabled%TYPE
);

PROCEDURE GetCountries(
	out_cur							OUT	SYS_REFCURSOR
);

END donation_Pkg;

/
