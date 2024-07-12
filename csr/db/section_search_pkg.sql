CREATE OR REPLACE PACKAGE CSR.section_search_pkg
IS

SEARCH_RESULT_SECTION		CONSTANT NUMBER := 1;
SEARCH_RESULT_DOCUMENT		CONSTANT NUMBER := 2;
SEARCH_RESULT_ATTACHMENT	CONSTANT NUMBER := 3;

SEARCH_ROOT_SECTION			CONSTANT NUMBER := 1;
SEARCH_ROOT_DOC_LIB			CONSTANT NUMBER := 2;

SEARCH_WEIGHTING_TITLE	CONSTANT NUMBER := 4;
SEARCH_WEIGHTING_BODY	CONSTANT NUMBER := 1;

SEARCH_INSTR_SCORE		CONSTANT NUMBER := 5;

SNIPPET_ON_BODY			CONSTANT NUMBER := 1;
SNIPPET_ON_DESC			CONSTANT NUMBER := 2;
SNIPPET_NONE			CONSTANT NUMBER := 3;

/* FUNCTIONS */
FUNCTION GetSectionSnippet(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_section_sid		IN security_pkg.T_SID_ID,
	in_version_number	IN section_version.version_number%TYPE,
	in_text_query		IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION GetDocDataSnippet(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_doc_data			IN security_pkg.T_SID_ID,
	in_text_query		IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION GetDocDescSnippet(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_doc_id			IN doc_version.doc_id%TYPE,
	in_version			IN doc_version.version%TYPE,
	in_text_query		IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION GetMarkupTitle(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_section_sid		IN security_pkg.T_SID_ID,
	in_version_number	IN section_version.version_number%TYPE,
	in_text_query		IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION GetMarkupBody(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_section_sid		IN security_pkg.T_SID_ID,
	in_version_number	IN section_version.version_number%TYPE,
	in_text_query		IN VARCHAR2)
RETURN CLOB;

FUNCTION InstrCount(
	in_text		IN VARCHAR2,
	in_contains	IN VARCHAR2
)
RETURN NUMBER;

/* PROCEDURES */
PROCEDURE SearchSections(
	in_contains_text		IN	VARCHAR2,
	in_like_text			IN VARCHAR2,
	in_include_answers		IN	NUMBER,
	in_include_attachments	IN	NUMBER,
	in_include_documents	IN	NUMBER,
	in_module_ids			IN	security_pkg.T_SID_IDS,
	in_tag_ids				IN	security_pkg.T_SID_IDS,
	in_editor_ids			IN	security_pkg.T_SID_IDS,
	in_last_modified_dtm	IN	SECTION_VERSION.changed_dtm%TYPE,
	in_last_modified_dir	IN	NUMBER,
	in_created_dtm			IN	SECTION_VERSION.changed_dtm%TYPE,
	in_created_dir			IN	NUMBER,
	in_filter_mime			IN	NUMBER,
	in_min_rownum			IN NUMBER	DEFAULT 1,
	in_max_rownum			IN NUMBER	DEFAULT 50,
	out_result_count		OUT NUMBER,
	out_search_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchDocumentLib(
	in_contains_text		IN	VARCHAR2,
	in_like_text			IN VARCHAR2,
	in_editor_ids			IN	security_pkg.T_SID_IDS,
	in_last_modified_dtm	IN	SECTION_VERSION.changed_dtm%TYPE,
	in_last_modified_dir	IN	NUMBER,
	in_created_dtm			IN	SECTION_VERSION.changed_dtm%TYPE,
	in_created_dir			IN	NUMBER,
	in_filter_mime			IN	NUMBER,
	in_min_rownum			IN NUMBER	DEFAULT 1,
	in_max_rownum			IN NUMBER	DEFAULT 50,
	out_result_count		OUT NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSectionMarkUp(
	in_section_sid			IN security_pkg.T_SID_ID,
	in_highlight			IN VARCHAR2,
	out_section_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_attachment_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_content_docs_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_plugins_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_paths_cur 			OUT security_pkg.T_OUTPUT_CUR
);

END section_search_pkg;
/
