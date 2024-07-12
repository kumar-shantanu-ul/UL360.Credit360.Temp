CREATE OR REPLACE PACKAGE CSR.postit_Pkg
IS

PROCEDURE GetFile(
	in_postit_file_id	IN	postit_file.postit_file_id%TYPE,
	in_sha1				IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDetails(
	in_postit_id		IN	postit.postit_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FixUpFiles(
	in_postit_id		IN	postit.postit_id%TYPE,
	in_keeper_ids		IN	security_pkg.T_SID_IDS,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeletePostitOrRemoveFromAudit(
	in_postit_id			IN	postit.postit_id%TYPE,
	in_internal_audit_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE Delete(
	in_postit_id		IN	postit.postit_id%TYPE
);

PROCEDURE UNSEC_Save(
	in_postit_id		IN	postit.postit_id%TYPE,
	in_label			IN	postit.label%TYPE,
	in_message			IN	postit.message%TYPE,
	in_secured_via_sid	IN	security_pkg.T_SID_ID,
	out_postit_id		OUT	postit.postit_id%TYPE
);

PROCEDURE Save(
	in_postit_id		IN	postit.postit_id%TYPE,
	in_label			IN	postit.label%TYPE,
	in_message			IN	postit.message%TYPE,
	in_secured_via_sid	IN	security_pkg.T_SID_ID,
	out_postit_id		OUT	postit.postit_id%TYPE
);

END postit_Pkg;
/
