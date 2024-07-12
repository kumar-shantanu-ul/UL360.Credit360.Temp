CREATE OR REPLACE PACKAGE BODY CHEM.AUDIT_PKG
AS

PROCEDURE WriteUsageLogEntry(
	in_substance_id		IN	usage_audit_log.substance_id%TYPE,
	in_delegation_sid	IN	usage_audit_log.root_delegation_sid%TYPE,
	in_region_sid		IN	usage_audit_log.region_sid%TYPE,
	in_start_dtm		IN	usage_audit_log.start_dtm%TYPE,
	in_end_dtm			IN	usage_audit_log.end_dtm%TYPE,
	in_description		IN	usage_audit_log.description%TYPE,
	in_param_1			IN	usage_audit_log.param_1%TYPE,
	in_param_2			IN	usage_audit_log.param_2%TYPE
)
AS
	v_root_delegation_sid		usage_audit_log.root_delegation_sid%TYPE;
BEGIN
	IF in_delegation_sid IS NOT NULL THEN
		v_root_delegation_sid := csr.delegation_pkg.GetRootDelegationSid(in_delegation_sid);
	END IF;
	
	INSERT INTO usage_audit_log (usage_audit_log_id, substance_id, region_sid, root_delegation_sid, start_dtm, end_dtm, description, param_1, param_2)
	VALUES (usage_audit_log_id_seq.nextval, in_substance_id, in_region_sid, v_root_delegation_sid, in_start_dtm, in_end_dtm, in_description, in_param_1, in_param_2);
	--RETURNING audit_log_id INTO out_audit_log_id;
END;

PROCEDURE CheckAndWriteUsageLogEntry(
	in_substance_id		IN	usage_audit_log.substance_id%TYPE,
	in_delegation_sid	IN	usage_audit_log.root_delegation_sid%TYPE,
	in_region_sid		IN	usage_audit_log.region_sid%TYPE,
	in_start_dtm		IN	usage_audit_log.start_dtm%TYPE,
	in_end_dtm			IN	usage_audit_log.end_dtm%TYPE,
	in_description		IN	usage_audit_log.description%TYPE,
	in_param_1			IN	usage_audit_log.param_1%TYPE,
	in_param_2			IN	usage_audit_log.param_2%TYPE
)
AS
BEGIN
	IF NVL(in_param_1, -1) <> NVL(in_param_2, -1) THEN
		WriteUsageLogEntry(in_substance_id, in_delegation_sid, in_region_sid, in_start_dtm, in_end_dtm, in_description, in_param_1, in_param_2);
	END IF;
END;

PROCEDURE GetUsageLogEntries(
	in_delegation_sid	IN	usage_audit_log.root_delegation_sid%TYPE,
	in_region_sid		IN	usage_audit_log.region_sid%TYPE,
	in_start_dtm		IN	usage_audit_log.start_dtm%TYPE,
	in_end_dtm			IN	usage_audit_log.end_dtm%TYPE,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_root_delegation_sid		usage_audit_log.root_delegation_sid%TYPE;
BEGIN
	v_root_delegation_sid := csr.delegation_pkg.GetRootDelegationSid(in_delegation_sid);

	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM usage_audit_log
	 WHERE (root_delegation_sid = v_root_delegation_sid)
	   AND (region_sid = in_region_sid)
	   AND (start_dtm = in_start_dtm)
	   AND (end_dtm = in_end_dtm);
	  
	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT a.*, rownum rn
			  FROM (
				SELECT usage_audit_log_id, ual.substance_id, ual.region_sid, root_delegation_sid, start_dtm, end_dtm, ual.description message, s.description, param_1, param_2, changed_by, changed_dtm
				  FROM usage_audit_log ual
				  JOIN substance s ON s.substance_id = ual.substance_id
				 WHERE (root_delegation_sid = v_root_delegation_sid)
				   AND (ual.region_sid = in_region_sid)
				   AND (start_dtm = in_start_dtm)
				   AND (end_dtm = in_end_dtm)
				 ORDER BY changed_dtm DESC
			   ) a
			 WHERE rownum < in_start_row + in_page_size
		   )
		 WHERE rn >= in_start_row;
END;

PROCEDURE WriteSubstanceLogEntry(
	in_substance_id		IN	substance_audit_log.substance_id%TYPE,
	in_description		IN	substance_audit_log.description%TYPE,
	in_param_1			IN	substance_audit_log.param_1%TYPE,
	in_param_2			IN	substance_audit_log.param_2%TYPE
)
AS
BEGIN
	INSERT INTO substance_audit_log (substance_audit_log_id, substance_id, description, param_1, param_2)
	VALUES (sub_audit_log_id_seq.nextval, in_substance_id, in_description, in_param_1, in_param_2);
END;

PROCEDURE CheckAndWriteSubLogEntry(
	in_substance_id		IN	substance_audit_log.substance_id%TYPE,
	in_description		IN	substance_audit_log.description%TYPE,
	in_param_1			IN	substance_audit_log.param_1%TYPE,
	in_param_2			IN	substance_audit_log.param_2%TYPE
)
AS
BEGIN
	IF NVL(in_param_1, -1) <> NVL(in_param_2, -1) THEN
		WriteSubstanceLogEntry(in_substance_id, in_description, in_param_1, in_param_2);
	END IF;
END;

PROCEDURE GetSubLogEntries(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.audit_pkg.GetSubLogEntries') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT s.ref reference,s.description substance, REPLACE(REPLACE(REPLACE(sal.description, '{2}', param_2), '{1}', param_1), '{0}', s.description) description, u.full_name || ' (' || u.user_name || ')' changed_by, changed_dtm changed_on
		  FROM substance_audit_log sal		  
		  JOIN substance s ON s.substance_id = sal.substance_id
		  JOIN csr.csr_user u ON u.csr_user_sid = sal.changed_by
	  ORDER BY changed_dtm desc;
END;

PROCEDURE GetAllUsageLogEntries(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.audit_pkg.GetAllUsageLogEntries') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT s.description substance, r.description site, ual.start_dtm, ual.end_dtm, REPLACE(REPLACE(REPLACE(ual.description, '{2}', param_2), '{1}', param_1), '{0}', s.description) description, u.full_name || ' (' || u.user_name || ')' changed_by, changed_dtm changed_on
		  FROM usage_audit_log ual
		  JOIN substance s ON s.substance_id = ual.substance_id
		  JOIN csr.v$region r on ual.region_sid = r.region_sid
		  JOIN csr.csr_user u ON u.csr_user_sid = ual.changed_by
		  LEFT JOIN csr.delegation d on ual.root_delegation_sid = d.delegation_sid;
END;

END;
/