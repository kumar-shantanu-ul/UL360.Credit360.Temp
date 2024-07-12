CREATE OR REPLACE PACKAGE CSR.section_pkg
IS

-- errors
--ERR_TAG_IN_USE			CONSTANT NUMBER := -20501;
--TAG_IN_USE EXCEPTION;
--PRAGMA EXCEPTION_INIT(TAG_IN_USE, -20501);

/* The section is not checked out by anyone and an
   opration requiring a check out was requested */
ERR_NOT_CHECKED_OUT			CONSTANT NUMBER := -20501;
NOT_CHECKED_OUT				EXCEPTION;
PRAGMA EXCEPTION_INIT(NOT_CHECKED_OUT, -20501);

/* The section is checked out by another user and an operation requiring
   the current user has the section checked out was requested */
ERR_CHECKED_OUT_OTHERUSER	CONSTANT NUMBER := -20502;
CHECKED_OUT_OTHERUSER		EXCEPTION;
PRAGMA EXCEPTION_INIT(CHECKED_OUT_OTHERUSER, -20502);

/* An invalid version of the section was requested */
ERR_INVALID_VERSION			CONSTANT NUMBER := -20503;
INVALID_VERSION				EXCEPTION;
PRAGMA EXCEPTION_INIT(INVALID_VERSION, -20503);

/* The section was not found */
ERR_SECTION_NOT_FOUND		CONSTANT NUMBER := -20506;
SECTION_NOT_FOUND			EXCEPTION;
PRAGMA EXCEPTION_INIT(SECTION_NOT_FOUND, -20506);

/*	Oracle text exception works in 11g but not 10g
	see GetDocDataSnippet */
-- ORACLE_TEXT_ERROR EXCEPTION;
-- PRAGMA EXCEPTION_INIT(ORACLE_TEXT_ERROR, -20000);

-- Bespoke permissions in csr_data_pkg

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
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE TrashObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_section_sid		IN security_pkg.T_SID_ID
);

FUNCTION HasCapabilityAccess(
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_capability_id			IN	flow_capability.flow_capability_id%TYPE,
	in_permission				IN	NUMBER
) RETURN BOOLEAN;

FUNCTION SQL_HasEditFactCapability(
	in_section_sid				IN	security_pkg.T_SID_ID
) RETURN BINARY_INTEGER;

FUNCTION SQL_HasClearFactCapability(
	in_section_sid				IN	security_pkg.T_SID_ID
) RETURN BINARY_INTEGER;

FUNCTION GetFirstRouteStepId(
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE
)	RETURN route_step.route_step_id%TYPE;
PRAGMA RESTRICT_REFERENCES(GetFirstRouteStepId, WNDS, WNPS);

FUNCTION GetLastRouteStepId(
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE
)	RETURN route_step.route_step_id%TYPE;
PRAGMA RESTRICT_REFERENCES(GetFirstRouteStepId, WNDS, WNPS);

/**
 * Get the next version number for the specified section
 *
 * We use a sequential version number so that it makes sense to humans
 * (as opposed to an Oracle sequence)
 *
 * @param in_section_sid	The SID of the section
 */
FUNCTION GetNextVersionNumber(
	in_section_sid		IN	security_pkg.T_SID_ID
) RETURN section_version.version_number%TYPE;
PRAGMA RESTRICT_REFERENCES(GetNextVersionNumber, WNDS, WNPS);

/**
 * Get the SID of the user who has this section checked out
 *
 * Returns NULL is no user has the section checked out
 *
 * @param in_section_sid	The SID of the section
 */
FUNCTION GetCheckedOutToSID(
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(GetCheckedOutToSID, WNDS, WNPS);

/**
 * Get the details of the user who has this section checked out
 *
 * @param in_act_id			Access token
 * @param in_section_sid	The SID of the section
 * @param out_cur			A rowset containing the user details
 */
PROCEDURE GetCheckedOutTo(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Get the very latest verison number for the given section
 *
 * Returns the very latest version number, including the
 * checked out version if the section is already checked out
 *
 * @param in_section_sid	The SID of the section
 */
FUNCTION GetLatestVersion(
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN section_version.VERSION_NUMBER%TYPE;
PRAGMA RESTRICT_REFERENCES(GetLatestVersion, WNDS, WNPS);

/**
 * Get the version number of the latest checked in version
 *
 * Returns the version number of the last
 * checked in version of the given section
 *
 * @param in_section_sid	The SID of the section
 */
FUNCTION GetLatestCheckedInVersion(
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN section_version.VERSION_NUMBER%TYPE;
PRAGMA RESTRICT_REFERENCES(GetLatestCheckedInVersion, WNDS, WNPS);

/**
 * Get the version number of the latest approved version
 *
 * Returns the version number of the last
 * approved version of the specified section
 *
 * @param in_section_sid	The SID of the section
 */
FUNCTION GetLatestApprovedVersion(
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN section_version.VERSION_NUMBER%TYPE;
PRAGMA RESTRICT_REFERENCES(GetLatestApprovedVersion, WNDS, WNPS);

/**
 * Get the module name for section sid
 *
 * Returns the module name
 *
 * @param in_section_sid	The SID of the section
 */
FUNCTION GetModuleName(
	in_section_sid			IN	Security_Pkg.T_SID_ID
) RETURN section_module.LABEL%TYPE;
PRAGMA RESTRICT_REFERENCES(GetModuleName, WNDS, WNPS);

FUNCTION GetLatestVisibleVersion(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN section_version.VERSION_NUMBER%TYPE;
PRAGMA RESTRICT_REFERENCES(GetLatestVisibleVersion, WNDS, WNPS);

FUNCTION GetPathFromSectionSID(
    in_act_id			IN	Security_Pkg.T_ACT_ID,
	in_sid_id 			IN	Security_Pkg.T_SID_ID,
	in_join_with		IN	VARCHAR2 DEFAULT ' / ',
	in_ignore_last_lvl	IN	NUMBER DEFAULT 0
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetPathFromSectionSID, WNDS, WNPS);

FUNCTION GetSectionTagPath(
	in_section_tag_id	IN	section_tag.section_tag_id%TYPE,
	in_join_with		IN	VARCHAR2 DEFAULT ' / '
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetSectionTagPath, WNDS, WNPS);

FUNCTION GetNextSectionPosition(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_section_sid	IN	security_pkg.T_SID_ID
) RETURN section.section_position%TYPE;
PRAGMA RESTRICT_REFERENCES(GetNextSectionPosition, WNDS, WNPS);

FUNCTION SecurableObjectChildCount(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_sid_id		IN	security_pkg.T_SID_ID
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(SecurableObjectChildCount, WNDS, WNPS);

PROCEDURE FixSectionPositionData(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_section_sid	IN	security_pkg.T_SID_ID
);

/**
 * Validate the given version number for the specified section
 *
 * Simply returns if the version number is valid, raises an exception
 * if the version number does not exist for the given section
 *
 * @param in_section_sid	The SID of the section
 * @param in_version		The the version number to validate
 */
PROCEDURE ValidateVersion(
	in_section_sid			IN security_pkg.T_SID_ID,
	in_version				IN section_version.VERSION_NUMBER%TYPE
);


/**
 * Create a new section
 *
 * Creates a new section object under the specified parent
 * or at the section root if in_paretn_sid_id is NULL.
 * Adds the newly created section object to itself (it's a
 * group too) granting its members access to it and it's children.
 * Inserts the required data that backs the securable object.
 *
 * @param in_act_id			Access token
 * @param in_app_sid	CSR root SID for given application
 * @param in_parent_sid_id	Parent section SID
 * @param in_title			Title of the section
 * @param in_body			Body text for the section (NULLABLE)
 * @param out_sid_id		Returned SID of the new section object
 */
PROCEDURE CreateSectionWithPerms(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_access_perms			IN	security_pkg.T_PERMISSION,
	in_parent_sid_id		IN	security_pkg.T_SID_ID,
	in_title				IN	section_version.title%TYPE,
	in_title_only			IN	section.title_only%TYPE,
	in_body					IN	section_version.body%TYPE,
	in_help_text			IN	section.help_text%TYPE,
	in_ref					IN	section.ref%TYPE,
	in_further_info_url		IN	section.further_info_url%TYPE,
	in_plugin				IN  section.plugin%TYPE,
	in_auto_checkout		IN	NUMBER,
	out_sid_id				OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateSection(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid_id		IN	security_pkg.T_SID_ID,
	in_title				IN	section_version.title%TYPE,
	in_title_only			IN	section.title_only%TYPE,
	in_body					IN	section_version.body%TYPE,
	in_auto_checkout		IN	NUMBER,
	out_sid_id				OUT	security_pkg.T_SID_ID
);


PROCEDURE CopySection(
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid		IN 	security_pkg.T_SID_ID,
	in_title			IN	section_version.title%TYPE,
	out_section_sid		OUT	security_pkg.T_SID_ID
);

/**
 * Save content while editing
 *
 * Saves the passed content back to the latest checked out version,
 * the current user must be the user that has the section checked out
 * otherwise an ERR_NOT_CHECKED_OUT or ERR_CHECKED_OUT_OTHERUSER
 * exception will be raised.
 *
 * @param in_act_id			Access token
 * @param in_section_sid	SID of the section to be modified
 * @param in_title			Title of the section
 * @param in_plugin			Plugin to use for section NULL means just text
 * @param in_body			Body text for the section
 */
PROCEDURE SaveContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_title				IN	section_version.title%TYPE,
	in_title_only			IN	section.title_only%TYPE,
	in_plugin				IN	section.plugin%TYPE,
	in_body					IN	section_version.body%TYPE,
	in_gen_attach_disabled	IN	section.disable_general_attachments%TYPE DEFAULT 0
);

/**
 * Get content of the section with all the data necessary
 * for the previous section panel.
 *
 * @param in_section_sid	SID of the previous section
 *
*/
PROCEDURE GetLatestContentFull(
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_section_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_section_tag_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_content_docs_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_attachment_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_plugins_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_comments_cur		OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Get the latest content for a section
 *
 * Gets the very latest version of the content, however, if the current
 * user has the section checked out then the latest saved content will be
 * retrieved if the section is not checked out or the current user is
 * not the user that has the section checked out then the latest
 * checked in version of the content will be retrieved.
 *
 * @param in_act_id			Access token
 * @param in_section_sid	SID of the section to be modified
 * @param out_title			TReturned title of the section
 * @param out_body			Returned body text for the section
 */
PROCEDURE GetLatestContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Get the latest CHECKED IN content for a section
 *
 * @param in_act_id			Access token
 * @param in_section_sid	SID of the section to be modified
 * @param out_title			TReturned title of the section
 * @param out_body			Returned body text for the section
 */
PROCEDURE GetLatestCheckedInContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Get the latest APPROVED in content for a section
 *
 * @param in_act_id			Access token
 * @param in_section_sid	SID of the section to be modified
 * @param out_title			TReturned title of the section
 * @param out_body			Returned body text for the section
 */
PROCEDURE GetLatestApprovedContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Get the specific version of then content for a given section
 *
 * The specified verison is validated and an ERR_INVALID_VERSION exception
 * is raised if the specified version does not exist for the given section.
 *
 * @param in_act_id			Access token
 * @param in_section_sid	SID of the section to be modified
 * @param out_title			TReturned title of the section
 * @param out_body			Returned body text for the section
 */
PROCEDURE GetContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_version				IN	section_version.VERSION_NUMBER%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSection(
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Check out a section
 *
 * After checking permissions, the section is checked out to the
 * current user unless another user has the section checked out
 * in which case an ERR_CHECKED_OUT_OTHERUSER exception is raised.
 *
 * @param in_act_id			Access token
 * @param in_section_sid	SID of the section to be checked out
 */
PROCEDURE CheckOut(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID
);

/**
 * Check in a section
 *
 * After validating the current user has the section checked out the
 * version table is updated with the user sid and the dat and time.
 * If the current section is not checked out then an ERR_NOT_CHECKED_OUT
 * exception is reised, if another user has the section checked out then
 * an ERR_CHECKED_OUT_OTHERUSER excpetion is raised. A reason for change
 * comment must be sulllied.
 *
 * @param in_act_id				Access token
 * @param in_section_sid		SID of the section to be checked out
 * @param in_reason_for_change	Comment indicating the reason for the changes
 */
PROCEDURE CheckIn(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_reason_for_change	IN	section_version.REASON_FOR_CHANGE%TYPE
);

/**
 * Cancel changes to a checked out section
 *
 * The current user must have the section checked out otherwise an
 * ERR_NOT_CHECKED_OUT or ERR_CHECKED_OUT_OTHERUSER exception will
 * be raised. The currently edited version will be removed and the
 * section released (no longer checked out). If this is the first
 * version of a section then the securabel object will also be deleted,
 * this will also remove the entry for this section from the section table.
 *
 * @param in_act_id			Access token
 * @param in_section_sid	SID of the section to be checked out
 */
PROCEDURE CancelChanges(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_deleted				OUT	NUMBER
);

PROCEDURE ForceCancelChanges(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_deleted				OUT	NUMBER
);

PROCEDURE internal_CancelChanges(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_deleted				OUT	NUMBER
);

PROCEDURE UndoCheckout(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_deleted				OUT	NUMBER
);

/**
 * Add a comment to a section
 *
 * Adds a comment to a section, in_in_reply_to_id specifiesd
 * the id of the comment this is in reply to but can be NULL.
 *
 * @param in_act_id				Access token
 * @param in_section_sid		SID of the section to be checked out
 * @param in_in_reply_to_id		ID of comment this is in reply to (NULLABLE)
 * @param in_comment_text		Comment text
 */
PROCEDURE AddComment(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_in_reply_to_id		IN	section_comment.IN_REPLY_TO_ID%TYPE,
	in_comment_text			IN	section_comment.COMMENT_TEXT%TYPE
);

PROCEDURE RemoveComment(
	in_section_sid				IN	section.section_sid%TYPE,
	in_section_comment_id		IN	section_comment.section_comment_id%TYPE
);

PROCEDURE RemoveTransitionComment(
	in_section_sid			IN	section.section_sid%TYPE,
	in_trans_comment_id		IN	section_trans_comment.section_trans_comment_id%TYPE
);

/**
 * Close a comment
 *
 * Sets the comment closed flag
 *
 * @param in_act_id					Access token
 * @param in_section_comment_id		ID of the comment to close
 */
PROCEDURE CloseComment(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_comment_id	IN	section_comment.SECTION_COMMENT_ID%TYPE
);

/**
 * Get all comments for specified section
 *
 * Currentyl only returns comments for the section specified
 * there is a note in the body about returning comments for
 * all the specified sections children too?
 *
 * @param in_act_id				Access token
 * @param in_section_sid		ID of the comment to close
 * @param in_in_reply_to_id		Only get comments in preply to specified comment (NULLABLE)
 * @param out_cur				Returned comments
 */
PROCEDURE GetComments(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_in_reply_to_id		IN	section_comment.IN_REPLY_TO_ID%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Get the version log for the specified section
 *
 * Get the version log ordered by descending version number,
 * in_max_records specified how many records at most the retrieve
 * but it can be NULL for all records.
 *
 * @param in_section_sid		ID of the comment to close
 * @param in_max_records		Naximum number of records to fetch (NULLABLE)
 * @param out_cur				Returned comments
 */
PROCEDURE GetVersionLog(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_max_records			IN	INT,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_now					OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Approve the specified version of the section
 *
 * @param in_act_id				Access token
 * @param in_section_sid		ID of the comment to close
 * @param in_version			Version of the changes to approve
 */
PROCEDURE ApproveVersion(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_version				IN	section_version.VERSION_NUMBER%TYPE
);

PROCEDURE ApproveLatestCheckedInVersion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetUserMountPoints(
	in_module_root_sid	IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeNodeChildren(
	in_parent_sid 		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

/**
 * Return a list of information about attachments
 * associted with the given section.
 *
 * @param in_act_id				Access token
 * @param in_section_sid		SID of the section
 * @param out_attachments		Output list of attachment information
 */
PROCEDURE GetAttachmentList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	out_attachments		OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetContentDocList (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	out_content_docs	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetContentDocData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_doc_id			IN	section_content_doc.DOC_ID%TYPE,
	out_content_doc		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateIndicatorAttachment(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_indicator_sid	IN	security_pkg.T_SID_ID,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	in_fact_id			IN	section_fact.fact_id%TYPE,
	in_fact_idx			IN	section_fact_attach.fact_idx%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
);

PROCEDURE CreateDocumentAttachment(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_doc_id					IN	security_pkg.T_SID_ID,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	in_fact_id			IN	section_fact.fact_id%TYPE,
	in_fact_idx			IN	section_fact_attach.fact_idx%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
);

/**
 * Attaches file or chart data from the file cache to the given section
 *
 * @param in_act_id				Access token
 * @param in_section_sid		SID of the section to attach to
 * @param in_dataview_sid		SID of the chart dataview, may be null for files
 * @param in_cache_key			Cache key, specifies where to get the data from
 * @param out_attachment_id		New attachment ID
 */
PROCEDURE CreateAttachmentFromCache(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_dataview_sid		IN	security_pkg.T_SID_ID,
    in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	in_embed        	IN	attachment.embed%TYPE,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	in_fact_id			IN	section_fact.fact_id%TYPE,
	in_fact_idx			IN	section_fact_attach.fact_idx%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
);

/**
 * Attaches file or chart data from the passed data to the given section
 *
 * @param in_act_id				Access token
 * @param in_section_sid		SID of the section to attach to
 * @param in_dataview_sid		SID of the chart dataview, may be null for files
 * @param in_data				The data to store
 * @param out_attachment_id		New attachment ID
 */
PROCEDURE CreateAttachmentFromBlob(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_dataview_sid		IN	security_pkg.T_SID_ID,
	in_filename			IN	attachment.filename%TYPE,
	in_mime_type		IN	attachment.mime_type%TYPE,
	in_view_as_table	IN	attachment.view_as_table%TYPE,
	in_embed        	IN	attachment.embed%TYPE,
    in_data				IN	attachment.data%TYPE,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
);

/**
 * Updates a file or chart attachment with new data fomr the file cache
 *
 * @param in_act_id				Access token
 * @param in_section_sid		SID of the section to attach to
 * @param in_dataview_sid		SID of the chart dataview, may be null for files
 * @param in_data				The data to store
 * @param out_attachment_id		New attachment ID
 */
PROCEDURE UpdateAttachmentFromBlob(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_attachment_id	IN 	attachment.ATTACHMENT_ID%TYPE,
	in_dataview_sid		IN	security_pkg.T_SID_ID,
	in_filename			IN	attachment.filename%TYPE,
	in_mime_type		IN	attachment.mime_type%TYPE,
	in_view_as_table	IN	attachment.view_as_table%TYPE,
    in_data				IN	attachment.data%TYPE,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE
);

PROCEDURE CreateURLAttachment(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_url				IN	attachment.url%TYPE,
	in_name				IN	attachment.filename%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	in_fact_id			IN	section_fact.fact_id%TYPE,
	in_fact_idx			IN	section_fact_attach.fact_idx%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
);

/**
 * Attaches file or chart data from the file cache to the given section
 *
 * @param in_act_id				Access token
 * @param in_section_sid		SID of the section
 * @param in_attachment_id		ID of the attachment
 * @param out_attachment		Output information about the attachment and the attachment data
 */
PROCEDURE GetAttachmentData(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_attachment_id	IN	attachment.ATTACHMENT_ID%TYPE,
	out_attachment		OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Remove an attachment from the specified section
 *
 * @param in_act_id				Access token
 * @param in_section_sid		SID of the section to attach to
 * @param attachment_id			ID of the attachment to remove
 */
PROCEDURE RemoveAttachment(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_attachment_id	IN 	attachment.ATTACHMENT_ID%TYPE
);

PROCEDURE GetDocumentSections(
	in_section_sids		IN	security_pkg.T_SID_IDS,
	out_sections		OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetTagId(
	in_path  IN  VARCHAR2
) RETURN section_tag.section_tag_id%TYPE;

PROCEDURE GetDocumentSections(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_section_tag_id 	IN  section_tag_member.section_tag_id%TYPE,
	out_sections		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDocumentSections(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	out_sections		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRouteUpTree(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_section_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RepositionSection(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_module_root_sid	IN	security_pkg.T_SID_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_new_position		IN	section.section_position%TYPE
);

PROCEDURE GeneratePositionData(
	in_app_sid		IN section.app_sid%TYPE
);

PROCEDURE PositionDataProcessNode(
	in_parent_sid	IN security_pkg.T_SID_ID
);

PROCEDURE GetWholeModule(
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	out_tree_cur			OUT	SYS_REFCURSOR,
	out_attachment_cur		OUT	SYS_REFCURSOR
);

PROCEDURE CheckoutAndUpdateBody(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_body					IN	section_version.body%TYPE,
	in_reason_for_change	IN	section_version.REASON_FOR_CHANGE%TYPE,
	in_section_status_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE AddTagToSection(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_tag_id				IN	security_PKG.T_SID_ID
);

PROCEDURE AddTagToSectionByName(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_tag_name				IN	section_tag.tag%TYPE
);

PROCEDURE RemoveTagFromSection(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_tag_id				IN	security_PKG.T_SID_ID
);

PROCEDURE GetModuleSectionTags(
	in_module_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSectionsTags(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateSectionTag(
	in_tag					IN	csr.section_tag.tag%TYPE,
	in_parent_id			IN	csr.section_tag.parent_id%TYPE,
	out_tag_id				OUT	csr.section_tag.tag%TYPE
);

PROCEDURE DeleteSectionTag(
	in_section_tag_id			IN	csr.section_tag.section_tag_id%TYPE,
	removed_ids_cur				OUT	SYS_REFCURSOR
);

PROCEDURE FilterSurvey(
	in_filter				IN	csr.section_module.label%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FilterCart(
	in_filter				IN	csr.section_module.label%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FilterSectionTag(
	in_filter				IN	csr.section_tag.tag%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FilterStatus(
	in_filter				IN	csr.section_status.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FilterFlowState(
	in_filter				IN	csr.section_status.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ApplyFilter(
	in_contains_text			IN	VARCHAR2,
	in_include_answers			IN	NUMBER,
	in_changed_dtm				IN	SECTION_VERSION.changed_dtm%TYPE,
	in_changed_dir				IN  NUMBER,
	in_flow_state_ids			IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_module_ids				IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_assigned_to_ids			IN	security_pkg.T_SID_IDS,
	in_progress_state_ids		IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_section_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_path_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ApplyFilter(
	in_contains_text			IN	VARCHAR2,
	in_include_answers			IN	NUMBER,
	in_changed_dtm				IN	SECTION_VERSION.changed_dtm%TYPE,
	in_changed_dir				IN  NUMBER,
	in_flow_state_ids			IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_module_ids				IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_assigned_to_ids			IN	security_pkg.T_SID_IDS,
	in_progress_state_ids		IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	out_section_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_path_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ApplyUserViewFilter(
	in_contains_text			IN	VARCHAR2,
	in_include_answers			IN	NUMBER,
	in_module_ids				IN	security_pkg.T_SID_IDS,
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	out_section_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_path_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_transition_cur			OUT security_pkg.T_OUTPUT_CUR --keep last!
);

PROCEDURE GetDashboardData(
	in_flow_state_ids			IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_module_ids				IN	security_pkg.T_SID_IDS,
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_assigned_to_ids			IN	security_pkg.T_SID_IDS,
	in_cart_ids					IN	security_pkg.T_SID_IDS, -- not sids, but will do
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDashboardDetails(
	in_flow_state_ids			IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_module_ids				IN	security_pkg.T_SID_IDS,
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_assigned_to_ids			IN	security_pkg.T_SID_IDS,
	in_cart_ids					IN	security_pkg.T_SID_IDS, -- not sids, but will do
	in_filter_type				IN  NUMBER DEFAULT '0',
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateCart(
	in_name					IN	csr.section_cart.name%TYPE,
	in_section_sids			IN	security_pkg.T_SID_IDS,
	out_id					OUT	security_pkg.T_SID_ID
);

PROCEDURE DeleteCart(
	in_section_cart_id		IN	csr.section_cart.section_cart_id%TYPE
);

PROCEDURE SetCartSections(
	in_section_cart_id		IN	csr.section_cart.section_cart_id%TYPE,
	in_section_sids			IN	security_pkg.T_SID_IDS
);


PROCEDURE SetCartName(
	in_section_cart_id		IN	csr.section_cart.section_cart_id%TYPE,
	in_name					IN	csr.section_cart.name%TYPE
);

/**
 * Returns cursors with sections, routes, section tags, comments
 */
PROCEDURE GetSectionsFull(
	in_section_sids					IN	security_pkg.T_SID_IDS,
	out_section_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_body_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_section_tag_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_attachment_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_content_docs_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_plugins_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_path_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_comment_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSections(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSectionsPaths(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAttachments(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetContentDocs(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetComments(
	in_section_sids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddTransitionComment(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_comment_text			IN	section_trans_comment.COMMENT_TEXT%TYPE
);

PROCEDURE GetTransitionComments(
	in_section_sids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCarts(
	out_carts_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_cart_members_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_sections_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSectionsCarts(
	in_section_sids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFlows(
	out_flow_cur			OUT	SYS_REFCURSOR,
	out_state_cur			OUT	SYS_REFCURSOR,
	out_trans_cur			OUT	SYS_REFCURSOR,
	out_routed_cur			OUT	SYS_REFCURSOR
);

PROCEDURE ProcessStateChangeAlerts(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_vote_direction		IN  NUMBER DEFAULT NULL
);

PROCEDURE SetSectionState(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_flow_state_id		IN	flow_state.flow_state_id%TYPE,
	in_direction			IN	NUMBER
);

PROCEDURE ReleaseCart(
	in_section_sids			IN	security_pkg.T_SID_IDS,
	in_flow_state_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE DeleteRoute(
	in_route_id    IN	route.route_id%TYPE
);

PROCEDURE SetRoute(
	in_section_sid		IN	section.section_sid%TYPE,
	in_flow_state_id	IN	route.flow_state_id%TYPE,
	in_due_dtm			IN  route.due_dtm%TYPE,
	out_route_id		OUT	route.route_id%TYPE
);

PROCEDURE GetRoutes(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_route_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur 	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRoute(
	in_section_sid				IN	security_pkg.T_SID_ID,
	out_route_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur 	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearRouteSteps(
	in_route_id			IN	route.route_id%TYPE,
	in_route_step_ids	IN	security_pkg.T_SID_IDS	-- an array of ids that WON'T be deleted (so we can update them)
);

PROCEDURE InsertStepAfter(
	in_route_id				IN	route.route_id%TYPE,
	in_route_step_id		IN	route_step.route_step_id%TYPE,
	in_work_days_offset		IN	route_step.work_days_offset%TYPE,
	in_user_sids			IN	security_pkg.T_SID_IDS,
	out_route_step_id		OUT	route_step.route_step_id%TYPE
);

PROCEDURE SetRouteStep(
	in_route_id				IN	route.route_id%TYPE,
	in_route_step_id		IN	route_step.route_step_id%TYPE,
	in_work_days_offset		IN	route_step.work_days_offset%TYPE,
	in_user_sids			IN	security_pkg.T_SID_IDS,
	in_pos					IN	NUMBER DEFAULT 0,
	out_route_step_id		OUT	route_step.route_step_id%TYPE
);

PROCEDURE ResetSectionRoute(
	in_section_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_id		IN  route.flow_state_id%TYPE,
	in_comment				IN	section_trans_comment.comment_text%TYPE
);

PROCEDURE INTERNAL_DeleteRouteStep(
	in_route_step_id 		IN  route_step.route_step_id%TYPE
);

PROCEDURE AdvanceSectionState(
	in_section_sid			IN 	security_pkg.T_SID_ID,
	in_comment				IN	section_trans_comment.comment_text%TYPE,
	in_dest_flow_state_id	IN	flow_state.flow_state_id%TYPE,
	in_vote_direction		IN  NUMBER DEFAULT 0,
	in_is_return			IN	NUMBER DEFAULT 0,
	in_is_casting_vote	    IN  NUMBER DEFAULT 0,
	in_send_alert			IN	NUMBER DEFAULT 1,
	out_flow_state_id		OUT	flow_state.flow_state_id%TYPE
);

PROCEDURE AdvanceSectionStep(
	in_section_sid			IN 	security_pkg.T_SID_ID,
	in_comment				IN	section_trans_comment.comment_text%TYPE,
	in_dest_route_step_id	IN	section.current_route_step_id%TYPE,
	in_vote_direction		IN  NUMBER DEFAULT 0,
	in_is_return			IN	NUMBER DEFAULT 0,
	in_is_casting_vote	    IN  NUMBER DEFAULT 0,
	in_send_alert			IN	NUMBER DEFAULT 1,
	out_route_step_id		OUT	section.current_route_step_id%TYPE
);

PROCEDURE Split(
	in_section_sid			IN 	security_pkg.T_SID_ID,
	in_titles				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveSplit(
	in_section_sid			IN 	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ApplyRoute(
	in_route_id				IN	ROUTE.ROUTE_ID%TYPE,
	in_dst_section_sid		IN	SECTION.SECTION_SID%TYPE,
	in_dst_flow_state_id	IN	ROUTE.FLOW_STATE_ID%TYPE
);

PROCEDURE GetFlowSummary(
	in_parent_section_sid			IN security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlertData(
    out_cur    OUT  SYS_REFCURSOR
);

PROCEDURE MarkSectionAlertsProcessed (
    in_section_alert_ids    IN    security_pkg.T_SID_IDS
);

PROCEDURE GetReminderAlertData(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RecordReminderSent(
	in_csr_user_sid					security_pkg.T_SID_ID,
	in_route_step_id				security_pkg.T_SID_ID
);

PROCEDURE GetOverdueAlertData(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RecordOverdueSent(
	in_csr_user_sid					security_pkg.T_SID_ID,
	in_route_step_id				security_pkg.T_SID_ID
);

PROCEDURE GetDeclinedAlertData(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RecordDeclinedSent(
	in_csr_user_sid					security_pkg.T_SID_ID,
	in_route_step_id				security_pkg.T_SID_ID
);

PROCEDURE PromoteAttach(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_attachment_id		   	IN	attachment.ATTACHMENT_ID%TYPE
);

PROCEDURE MoveToDocLib(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_folder_sid			IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE,
	in_desc						IN	VARCHAR2
);

PROCEDURE CheckoutDoc(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE
);

PROCEDURE GetEmailInfo(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RevertDocCheckout(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE
);

PROCEDURE RemoveContentDoc(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE
);

FUNCTION GetFormPathFromName(
	in_form_name			VARCHAR2
) RETURN VARCHAR2;

PROCEDURE GetFormPlugins(
	in_section_sids		IN	security_pkg.T_SID_IDS,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomerForms(
	in_act_Id			IN	security_pkg.T_ACT_ID,
	in_app_sid  		IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE AddFormToSection(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN security_pkg.T_SID_ID,
	in_form_name			IN VARCHAR2,
	out_attachment_id		OUT	attachment.ATTACHMENT_ID%TYPE
);

PROCEDURE AddDocWait(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE,
	in_csr_user_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveDocWait(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE,
	in_csr_user_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE GetRouteExportData(
	in_section_sids					IN	security_pkg.T_SID_IDS,
	out_module_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_section_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_flow_state_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur			OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetStateChangeAlertId(
	in_vote_direction	IN  NUMBER DEFAULT NULL,
	in_route_step_id	IN 	NUMBER DEFAULT NULL
) RETURN NUMBER;

PROCEDURE GetSingleAlertData (
	in_section_sid  		IN	security_pkg.T_SID_ID,
	in_route_step_id 		IN	security_pkg.T_SID_ID,
	in_flow_state_id  		IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE SetPreviousSectionByRef(
	in_section_sid		IN	section.section_sid%TYPE,
	in_previous_ref		IN	section.ref%TYPE
);

PROCEDURE GetSectionRoutedFlowState(
	in_flow_state_id				IN section_routed_flow_state.flow_state_id%TYPE,
	out_section_flow_cur			OUT SYS_REFCURSOR,
	out_routed_state_cur			OUT SYS_REFCURSOR
);

PROCEDURE SetSectionRoutedFlowState(
	in_flow_state_id				IN section_routed_flow_state.flow_state_id%TYPE,
	in_is_section_routed 			IN NUMBER,
	in_is_split_ques_flow_state		IN section_flow.split_question_flow_state_id%TYPE,
	in_reject_from_state_id			IN flow_state_transition.from_state_id%TYPE,
	in_reject_to_state_id			IN flow_state_transition.to_state_id%TYPE
);

PROCEDURE SetSplitQuestionFlowState(
	in_flow_sid						IN flow.flow_sid%TYPE,
	in_split_ques_flow_state_id		IN section_flow.split_question_flow_state_id%TYPE,
	in_is_split_ques_flow_state		IN NUMBER DEFAULT 0
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetFlowAlerts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Get embedded indicator value
 *
 * @param in_act_id						Access token
 * @param in_section_sid				SID of the section to be modified
 * @param in_fact_id					Indicator look up key/robecosam fact id
 * @param in_region_sid					Region sid
 * @param in_start_dtm					Start date
 * @param in_end_dtm					End date
 * @param in_idx						Index
 */
PROCEDURE GetContentVal(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_idx							IN	section_val.idx%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Save embedded indicator value
 */
PROCEDURE SaveContentVal(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_idx							IN	section_val.idx%TYPE,
	in_start_dtm					IN	section_val.start_dtm%TYPE,
	in_end_dtm						IN	section_val.end_dtm%TYPE,
	in_val_number					IN	section_val.val_number%TYPE,
	in_note							IN	section_val.note%TYPE,
	in_entry_type					IN	section_val.entry_type%TYPE,
	in_period_set_id				IN	section_val.period_set_id%TYPE,
	in_period_interval_id			IN	section_val.period_interval_id%TYPE
);

/**
 * Save embedded indicator value without modifying dates.
 */
PROCEDURE SaveContentValueNoDates(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_idx							IN	section_val.idx%TYPE,
	in_val_number					IN	section_val.val_number%TYPE,
	in_note							IN	section_val.note%TYPE,
	in_entry_type					IN	section_val.entry_type%TYPE
);

/**
 * Get section fact
 *
 * @param in_act_id						Access token
 * @param in_section_sid				SID of the section to be modified
 * @param in_fact_id					Indicator look up key/robecosam fact id
 */
PROCEDURE GetSectionFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Get section facts
 *
 * @param in_act_id						Access token
 * @param in_section_sid				SID of the section to be modified
 */
PROCEDURE GetSectionFacts(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Disable section facts
 *
 * @param in_act_id						Access token
 * @param in_section_sid				SID of the section to be modified
 */
PROCEDURE DisableSectionFacts(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID
);

FUNCTION SaveSectionFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_data_type					IN	section_fact.data_type%TYPE,
	in_max_length					IN	section_fact.max_length%TYPE,
	in_map_to_ind_sid				IN	section_fact.map_to_ind_sid%TYPE DEFAULT NULL,
	in_map_to_region_sid			IN	section_fact.map_to_region_sid%TYPE DEFAULT NULL,
	in_measure_conversion			IN	section_fact.std_measure_conversion_id%TYPE DEFAULT NULL
)RETURN section_fact.fact_id%TYPE;

/**
 * Save section fact
 *
 * @param in_act_id						Access token
 * @param in_section_sid				SID of the section to be modified
 * @param in_fact_id					robecosam fact id
 * @param in_map_to_ind_sid				ind_sid to map to, optional
 * @param in_map_to_region_sid			region_sid to map to, optional
 * @param in_measure_conversion			standard measure conversion to apply, optional
 */
PROCEDURE SaveSectionFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_data_type					IN	section_fact.data_type%TYPE,
	in_max_length					IN	section_fact.max_length%TYPE,
	in_map_to_ind_sid				IN	section_fact.map_to_ind_sid%TYPE DEFAULT NULL,
	in_map_to_region_sid			IN	section_fact.map_to_region_sid%TYPE DEFAULT NULL,
	in_measure_conversion			IN	section_fact.std_measure_conversion_id%TYPE DEFAULT NULL
);

PROCEDURE DeleteFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE
);

PROCEDURE ClearFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE
);

/**
 * Get module and section facts
 *
 * @param in_act_id						Access token
 * @param in_section_sid				SID of the section to be modified
 */
PROCEDURE GetSectionContext(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	module_out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	facts_out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	fact_values_out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	fact_attch_out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Get section facts
 *
 * @param in_act_id						Access token
 * @param in_section_sid				SID of the section to be modified
 */
PROCEDURE GetSectionFactValues(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	fact_values_out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	fact_attch_out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE UNSECURE_UpdateContent( --Used by array bind in copy module
	in_section_sid		IN	section.section_sid%TYPE,
	in_body				IN	section_version.body%TYPE
);


PROCEDURE UpdateMetaData(
	in_attachment_id	IN	attachment.ATTACHMENT_ID%TYPE,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_page				IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE
);

PROCEDURE GetModuleSectionFacts(
	in_module_root_sid	IN section_module.module_root_sid%TYPE,
	in_section_sid		IN	section.section_sid%TYPE DEFAULT NULL,
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Return a list of information about attachments
 * associated with the given module
 *
 * @param in_act_id				Access token
 * @param in_module_root_sid	SID of the module
 * @param out_attachments		Output list of attachment information
 */
PROCEDURE GetModuleAttachmentList(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	out_attachments			OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Get list of fact values associated with the given module
 *
 * @param in_act_id						Access token
 * @param in_module_root_sid			SID of the module
 * @param out_cur						output list of fact values
 */
PROCEDURE GetModuleVal(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_module_root_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Get list of periods associated with values of given module
 *
 * @param in_act_id						Access token
 * @param in_module_root_sid			SID of the module
 * @param out_cur						output list of periods
 */
PROCEDURE GetModulePeriod(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_module_root_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetModuleValFull(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_module_root_sid				IN	security_pkg.T_SID_ID,
	out_period_context_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_module_val_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_module_attachment_cur		OUT	security_pkg.T_OUTPUT_CUR
);

END section_pkg;
/
