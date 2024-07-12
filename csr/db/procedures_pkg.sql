CREATE OR REPLACE PACKAGE CSR.procedures_pkg IS

TYPE T_CACHE_KEYS IS TABLE OF aspen2.filecache.cache_key%TYPE INDEX BY PLS_INTEGER;

PROCEDURE GetDocsForRegion (
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetDocsForRegion (
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_doc_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE GetFilesForRegion (
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetFilesForRegion (
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_file_ids		IN	security_pkg.T_SID_IDS,
	in_cache_keys	IN	T_CACHE_KEYS
);

END procedures_pkg;
/
