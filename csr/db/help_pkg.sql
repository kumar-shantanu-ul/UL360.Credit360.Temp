CREATE OR REPLACE PACKAGE CSR.help_pkg
IS

/* The specified language is invalid */
ERR_INVALID_LANG			CONSTANT NUMBER := -20601;
INVALID_LANG				EXCEPTION;
PRAGMA EXCEPTION_INIT(INVALID_LANG, -20601);

/* The specified topic content could not be found */
ERR_TOPIC_TEXT_NOT_FOUND	CONSTANT NUMBER := -20602;
TOPIC_TEXT_NOT_FOUND		EXCEPTION;
PRAGMA EXCEPTION_INIT(TOPIC_TEXT_NOT_FOUND, -20602);

/* The specified lookup name could not be found */
ERR_INVALID_LOOKUP_NAME		CONSTANT NUMBER := -20603;
INVALID_LOOKUP_NAME			EXCEPTION;
PRAGMA EXCEPTION_INIT(INVALID_LOOKUP_NAME, -20603);

/* Edit in specified language was denied */
ERR_EDIT_LANGUAGE_DENIED	CONSTANT NUMBER := -20604;
EDIT_LANGUAGE_DENIED		EXCEPTION;
PRAGMA EXCEPTION_INIT(INVALID_LOOKUP_NAME, -20604);

/* The lookup name already exists */
ERR_DUPLICATE_LOOKUP_NAME	CONSTANT NUMBER := -20605;
DUPLICATE_LOOKUP_NAME		EXCEPTION;
PRAGMA EXCEPTION_INIT(DUPLICATE_LOOKUP_NAME, -20605);

--
-- Useful helper functions
--

FUNCTION GetNextHelpTopicPos(
	in_parent_id		IN help_topic.help_topic_id%TYPE
) RETURN help_topic.pos%TYPE;
PRAGMA RESTRICT_REFERENCES(GetNextHelpTopicPos, WNDS, WNPS);


FUNCTION ResolveLangIdForTopic(
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_topic_id			IN help_topic.help_topic_id%TYPE
) RETURN help_lang.help_lang_id%TYPE;
PRAGMA RESTRICT_REFERENCES(ResolveLangIdForTopic, WNDS, WNPS);


FUNCTION SecurableObjectChildCount(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_sid_id		IN	security_pkg.T_SID_ID
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(SecurableObjectChildCount, WNDS, WNPS);

FUNCTION GetDefaultLangId(
	in_app_sid		IN security_pkg.T_SID_ID
) RETURN help_lang.help_lang_id%TYPE;
PRAGMA RESTRICT_REFERENCES(GetDefaultLangId, WNDS, WNPS);

PROCEDURE CheckEditAccessRights(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE
);

PROCEDURE ValidateLanguageIdForCustomer (
	in_act				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_lang_id			OUT help_lang.help_lang_id%TYPE
);

--
-- Securable object callbacks
--

PROCEDURE CreateObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_class_id			IN security_pkg.T_CLASS_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_new_name			IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

--
-- Language
--

PROCEDURE AddLanguage(
	in_act 				IN security_pkg.T_ACT_ID,
	in_base_id			IN help_lang.base_lang_id%TYPE,
	in_label			IN help_lang.label%TYPE,
	out_lang_id			OUT	help_lang.help_lang_id%TYPE
);

PROCEDURE GetDefaultLanguage(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	out_lang_id			OUT	help_lang.help_lang_id%TYPE
);

PROCEDURE GetLanguages(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

--
-- Topic
--

PROCEDURE AddTopic_Deprecate(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_parent_id		IN security_pkg.T_SID_ID,
	in_lookup_name		IN help_topic.lookup_name%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddTopic(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_parent_id		IN security_pkg.T_SID_ID,
	in_lookup_name		IN help_topic.lookup_name%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveTopic(
	in_act 				IN security_pkg.T_ACT_ID,
	in_topic_id			IN security_pkg.T_SID_ID
);

PROCEDURE RemoveTopicContent(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE
);

PROCEDURE SetLookupName(
	in_act 				IN security_pkg.T_ACT_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lookup_name		IN help_topic.lookup_name%TYPE,
	out_actual_name		OUT help_topic.lookup_name%TYPE
);

PROCEDURE SetTopicContent(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_title			IN help_topic_text.title%TYPE,
	in_body				IN help_topic_text.body%TYPE
);

PROCEDURE GetTopicContent(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTopicIdFromLookup(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lookup_name		IN help_topic.lookup_name%TYPE,
	out_topic_id		OUT	help_topic.help_topic_id%TYPE
);

--
-- File (attachment)
--

PROCEDURE AddHelpFileReference(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_file_id			IN help_file.help_file_id%TYPE
);

PROCEDURE RemoveHelpFileReference(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_file_id			IN help_file.help_file_id%TYPE
);

PROCEDURE CreateHelpFileFromCache(		  
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_topic_id			IN	security_pkg.T_SID_ID,
	in_lang_id			IN	help_lang.help_lang_id%TYPE,
    in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	out_file_id			OUT	help_file.help_file_id%TYPE
);

PROCEDURE GetHelpFileReferences(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHelpFileData(		  
	in_act				IN security_pkg.T_ACT_ID,
	in_file_id			IN help_file.help_file_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

--
-- Navigation
--

PROCEDURE GetBreadcrumbTrail(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_topic_id			IN help_topic.help_topic_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetTreeNodeChildren(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_parent_id 		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetPathDownTopics(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_start_id 		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);


PROCEDURE ExportHelp(
	out_cur_lang		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_topics		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_topic_files	OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_topic_text	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ImportLanguage(
	in_base_lang_Id		IN	help_lang.base_Lang_id%TYPE,
	in_label			IN	help_lang.label%TYPE,
	in_short_name		IN	help_Lang.short_name%TYPE,
	out_help_lang_id	OUT	help_lang.help_lang_id%TYPE
);

PROCEDURE ImportTopic(
	in_parent_id		IN	security_pkg.T_SID_ID,
	in_lookup_name		IN	help_topic.lookup_name%TYPE,
	in_pos				IN	help_topic.pos%TYPE,
	in_hits				IN	help_topic.hits%TYPE,
	in_votes			IN	help_topic.votes%TYPE,
	in_score			IN	help_topic.score%TYPE,
	out_topic_Id		OUT	security_pkg.T_SID_ID
);

PROCEDURE ImportFile(
	in_hash				IN	help_file.data_hash%TYPE,
	in_last_updated_dtm	IN	help_file.last_updated_dtm%TYPE,
	in_mime_type		IN	help_file.mime_type%TYPE,
	in_label			IN	help_file.label%TYPE,
	out_file_Id			OUT	help_file.help_file_id%TYPE,
	out_data			OUT	help_file.data%TYPE
);

PROCEDURE ImportTopicFileLink(
	in_help_topic_id	IN	help_topic_file.help_topic_id%TYPE, 
	in_help_Lang_id 	IN  help_topic_file.help_Lang_id%TYPE,
	in_help_file_id		IN	help_topic_file.help_file_id%TYPE
);


PROCEDURE ImportText(
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_Lang_id 	IN  help_topic_text.help_Lang_id%TYPE,
	in_title			IN	help_topic_text.title%TYPE,
	in_last_updated_dtm	IN	help_topic_text.last_updated_dtm%TYPE,
	out_body			OUT	help_topic_text.body%TYPE
);

PROCEDURE GetHelpTopic(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_topic_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_file_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHelpTopicWithTrail(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_topic_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_file_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_trail_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchTopicTitle(
	in_topic_title		IN	VARCHAR2,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchTopicText(
	in_topic_text		IN	VARCHAR2,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPath(
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_path			OUT	VARCHAR
);

PROCEDURE GetIdPath(
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	out_path			OUT	VARCHAR
);

PROCEDURE GetItemsUsingImage(
	in_image_id			IN  help_image.image_id%TYPE,
	out_cur				OUT SYS_REFCURSOR			
);

PROCEDURE AttachFile(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	in_filename			IN 	file_upload.filename%TYPE,
	in_mime_type		IN	file_upload.mime_type%type,
	in_data				IN	file_upload.data%TYPE,
	out_help_file_id	OUT	security_pkg.T_SID_ID
);

PROCEDURE DownloadFile(
	in_act 				IN security_pkg.T_ACT_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_help_file_id		IN	security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE RemoveFile(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	in_help_file_id		IN	security_pkg.T_SID_ID
);

PROCEDURE CopyTopic(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE
);

PROCEDURE ValidateTopicId(
	in_topic_id			IN security_pkg.T_SID_ID,
	out_topic_id		OUT security_pkg.T_SID_ID
);

PROCEDURE GetTopicChildren(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,	
	in_parent_id 		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE SetTopicImage(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_image_ids		IN security_pkg.T_SID_IDS
);

PROCEDURE SetTopicParent(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_parent_id		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE
);

PROCEDURE GetTopicPath(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	out_cur				OUT VARCHAR2
);

END help_pkg;
/
