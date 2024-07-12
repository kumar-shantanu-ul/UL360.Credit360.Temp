CREATE OR REPLACE PACKAGE SUPPLIER.document_pkg
IS

TYPE T_DOCUMENT_IDS        IS TABLE OF document.document_id%TYPE INDEX BY PLS_INTEGER;

PROCEDURE CreateDocumentGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	out_group_id			OUT	document_group.document_group_id%TYPE
);

PROCEDURE CopyDocumentsToFilecache(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_id			IN	document.document_id%TYPE,
	out_cache_key			OUT aspen2.filecache.cache_key%TYPE
);

PROCEDURE CopyDocumentsToNewGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_source_group_id		IN	document_group.document_group_id%TYPE,
	in_dest_group_id		IN  document_group.document_group_id%TYPE
);

PROCEDURE CreateDocument(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_group_id				IN	document_group.document_group_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_title				IN	document.title%TYPE,
	in_description			IN	document.description%TYPE,
	in_file_name			IN	document.file_name%TYPE,
	in_mime_type			IN	document.mime_type%TYPE,
	in_start_dtm			IN	document.start_dtm%TYPE,
	in_end_dtm				IN	document.end_dtm%TYPE,
	out_document_id			OUT	document.document_id%TYPE
);

PROCEDURE UpdateDocument(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_id			IN	document.document_id%TYPE,
	in_group_id				IN	document_group.document_group_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_title				IN	document.title%TYPE,
	in_description			IN	document.description%TYPE,
	in_file_name			IN	document.file_name%TYPE,
	in_mime_type			IN	document.mime_type%TYPE,
	in_start_dtm			IN	document.start_dtm%TYPE,
	in_end_dtm				IN	document.end_dtm%TYPE
);

PROCEDURE DeleteDocumentGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_group_id	IN	document.document_id%TYPE
);

PROCEDURE DeleteDocument(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_id			IN	document.document_id%TYPE
);

PROCEDURE DeleteAbsentDocs(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_group_id				IN document_group.document_group_id%TYPE,
	in_doc_ids				IN T_DOCUMENT_IDS
);

PROCEDURE GetDocument(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_id			IN	document.document_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDocumentList(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_doc_group_id			IN document_group.document_group_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDocumentData(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_doc_id				IN document.document_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

END document_pkg;
/