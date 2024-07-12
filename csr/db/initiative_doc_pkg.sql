CREATE OR REPLACE PACKAGE CSR.initiative_doc_pkg
IS

PROCEDURE GetDocFolders(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDocsForInitiative(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE InsertDocFromCache(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_folder_name			IN	project_doc_folder.name%TYPE,
	out_doc_id				OUT	doc.doc_id%TYPE
);

PROCEDURE DeleteAbsentDocs(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_doc_ids				IN	security_pkg.T_SID_IDS
);

END initiative_doc_pkg;
/
