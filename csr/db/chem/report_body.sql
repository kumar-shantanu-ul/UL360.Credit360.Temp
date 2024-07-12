CREATE OR REPLACE PACKAGE BODY chem.report_pkg AS

PROCEDURE GetMissingDestinations(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetMissingDestinations') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		-- report showing which substances have been recorded, but no destination
		-- data entered. This could happen if an updated AC2M file is uploaded and
		-- adds CAS codes to a substance that previously didn't have CAS codes (AC2M
		-- data can be a little flaky)
		SELECT ref, substance, region_sid, location, start_dtm, mass_value, cas_code
		  FROM (
			SELECT spcd.substance_process_use_id, s.ref, s.description substance, 
				spu.region_sid, r.description location, spu.start_dtm,  spu.mass_value, sc.cas_code
			  FROM chem.substance_process_use spu
			  JOIN chem.substance_cas sc ON spu.substance_Id = sc.substance_id AND spu.app_sid = sc.app_sid
			  JOIN csr.v$region r on spu.region_sid = r.region_sid AND spu.app_sid = r.app_sid
			  JOIN chem.substance s ON spu.substance_id = s.substance_id AND spu.app_sid = s.app_sid
			  LEFT JOIN chem.substance_process_cas_dest spcd 
				ON spu.substance_process_use_id = spcd.substance_process_use_id 
			   AND sc.cas_code = spcd.cas_code AND sc.substance_id = spcd.substance_id
			   AND spu.app_sid = spcd.app_sid AND sc.app_sid = spcd.app_sid
		 )
		 WHERE substance_process_use_id IS NULL;
		   
END;

PROCEDURE GetCasCodes(
	in_unconfirmed	IN	number,
	out_list_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetCasCodes') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_list_cur FOR
		SELECT	cas_code, name, is_voc "Is VOC?",
			CASE 
				WHEN unconfirmed = 1 THEN 'Unconfirmed'
				ELSE 'Confirmed'
			END "Unconfirmed"
		  FROM	cas
		 WHERE	unconfirmed = in_unconfirmed;
END;

PROCEDURE GetCasRestrictions(
	out_list_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetCasRestrictions') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_list_cur FOR
		SELECT	c.cas_code, c.name, c.category, remarks, source, clp_table_3_1, clp_table_3_2,
				REPLACE(csr.region_pkg.INTERNAL_GetRegionPathString(root_region_sid),'Regions / Main / Philips / ', '') region,
				start_dtm, end_dtm
		  FROM	cas_restricted cr
		  JOIN	cas c ON c.cas_code = cr.cas_code;
END;

PROCEDURE GetWaiverStatus(
	in_required_only	IN	NUMBER,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetWaiverStatus') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_list_cur FOR	
		SELECT	s.ref "12NC or Internal Code", s.description "Substance",
				REPLACE(csr.region_pkg.INTERNAL_GetRegionPathString(sr.region_sid),'Regions / Main / Philips / ', '') path,
				ws.description "Status"
		  FROM	substance_region sr
		  JOIN	substance s ON s.substance_id = sr.substance_id
		  JOIN	waiver_status ws ON sr.waiver_status_id = ws.waiver_status_id
		 WHERE	(in_required_only <> 1) OR (in_required_only = 1 AND sr.waiver_status_id NOT IN (0,3));
END;

PROCEDURE GetMSDS(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_msds_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_msds_cur FOR
		SELECT filename, data, mime_type
		  FROM substance_file
		 WHERE substance_id = in_substance_id;
END;

PROCEDURE GetMSDSUploads(
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetMSDSUploads') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_list_cur FOR	
		SELECT sf.uploaded_dtm "Date uploaded", cu.full_name "User name", filename, s.description "Substance", m.name manufacturer,
			REPLACE(csr.region_pkg.INTERNAL_GetRegionPathString(s.region_sid),'Regions / Main / Philips / ', '') "Site"
		  FROM substance_file sf
			JOIN csr.csr_user cu ON sf.uploaded_user_sid = cu.csr_user_sid
			JOIN substance s ON sf.substance_id = s.substance_id
			JOIN manufacturer m ON s.manufacturer_id = m.manufacturer_id;
END;

PROCEDURE GetUngroupedCASCodes(
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetUngroupedCASCodes') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_list_cur FOR	
		SELECT cas_code, name
		  FROM cas
		 WHERE cas_code IN ( 
			SELECT cas_code
			  FROM substance_cas
			 MINUS
			SELECT cas_code
			  FROM cas_group_member
		 );
END;

PROCEDURE GetRawOutputs(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetRawOutputs') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_list_cur FOR	
		SELECT cas_group_label, 
			REPLACE(csr.region_pkg.INTERNAL_GetRegionPathString(o.region_sid),'Regions / Main / Philips / ', '') "Site",
				r.lookup_key "Site code",
			start_dtm, end_dtm,
			ROUND(SUM(air_mass_value), 10) air_mass_value,
			ROUND(SUM(water_mass_value), 10) water_mass_value
		  FROM V$OUTPUTS o
			JOIN csr.region r ON o.region_sid = r.region_sid
		 WHERE end_dtm > in_start_dtm AND start_dtm < in_end_dtm
		GROUP BY cas_group_label, cas_group_id, r.lookup_key, o.region_sid, start_dtm, end_dtm
		ORDER BY "Site", cas_group_label, start_dtm;
END;


PROCEDURE SubstCompCheckReport(
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.SubstCompCheckReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_list_cur FOR
		SELECT s.substance_id, s.description, s.ref, y.pct
		  FROM (
			SELECT * FROM (
				SELECT substance_Id, SUM(pct_composition) pct FROM substance_cas GROUP BY substance_Id
			) WHERE pct > 1
		) y
		JOIN substance s ON y.substance_Id = s.substance_Id;
END;


PROCEDURE CasGroupsReport(
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.CasGroupsReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_list_cur FOR
		SELECT label, cc.cas_code, cc.name
		  FROM cas_group cg
			JOIN cas_group_member cgm ON cg.cas_group_id = cgm.cas_group_id
			JOIN cas cc ON cgm.cas_code = cc.cas_Code
		 ORDER BY label, cas_code;
END;

PROCEDURE GetFullSheetReport(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetFullSheetReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_list_cur FOR
		SELECT REPLACE(csr.region_pkg.INTERNAL_GetRegionPathString(spu.region_sid),'Regions / Main / Philips / ', '') "Site",
			   r.lookup_Key "Site ref",
			   spu.start_dtm "Start date", spu.end_dtm "End date", 
			   CASE WHEN sla.last_action_id IN (3,6,9) THEN 'Validated' ELSE null END "Status",
			   CASE WHEN sla.last_action_id IN (3,6,9) THEN sla.last_action_dtm ELSE null END "Validated on",
			   s.ref "Reference",
			   sr.local_ref "Local site code",
			   spu.mass_value "Consumption (kg)", 
			   s.description "Substance", 
			   CASE WHEN (SELECT count(*) FROM substance_cas csc JOIN cas_restricted cr ON csc.cas_code = cr.cas_code WHERE csc.substance_id = s.substance_id) > 0 THEN 'Yes' ELSE 'No' END AS Reportable,
			   CASE WHEN EXISTS (
				SELECT null
				  FROM substance_cas sc
				  JOIN cas c on c.cas_code = sc.cas_code
				 WHERE sc.substance_id = spu.substance_id and c.category = '1a'
				) THEN 'Required' ELSE 'Not Required' END  "Waiver status", 
			   CASE WHEN sr.first_used_dtm = spu.start_dtm THEN 'Yes' ELSE 'No' END "Newly added",
			   CASE WHEN spu.changed_since_prev_period = 1 THEN 'Yes' ELSE 'No' END "Changed",
			   m.name "Manufacturer", srp.label "Application area", u.description "Usage",
			   spu.note "Note", 
			   NVL(spcd.to_air_pct, 0) "% to air", 
			   NVL(spcd.to_product_pct, 0) "% to product", 
			   NVL(spcd.to_waste_pct, 0) "% to waste", 
			   NVL(spcd.to_water_pct, 0) "% to water", 
			   NVL(spcd.remaining_pct, 1 - NVL(spcd.to_air_pct, 0) - NVL(spcd.to_water_pct, 0) - NVL(spcd.to_waste_pct, 0) - NVL(spcd.to_product_pct, 0)) "% remaining", 
			   spcd.remaining_dest "Destination for remaining",
			   sc.cas_code "CAS Code", 
			   c.name "Chemical name", 
			   c.category "Category",
			   CASE WHEN c.is_voc = 1 THEN 'Yes' ELSE 'No' END "Is VOC?",
			   sc.pct_composition "% composition"
		  FROM substance_process_use spu
		  JOIN csr.sheet_with_last_action sla 
		    ON spu.root_delegation_sid = sla.delegation_sid 
		   AND spu.start_dtm = sla.start_dtm 
		   AND spu.end_dtm = sla.end_dtm 
		   AND spu.app_sid = sla.app_sid
		  LEFT JOIN substance_cas sc 
		    ON spu.substance_id = sc.substance_id 
		    AND spu.app_sid = sc.app_sid
		  LEFT JOIN cas c  
		    ON sc.cas_code = c.cas_code
		  LEFT JOIN substance_process_cas_dest spcd
		    ON spu.substance_process_use_id = spcd.substance_process_use_id
		   AND spu.substance_id = spcd.substance_id
		   AND spu.app_sid = spcd.app_sid
		   AND c.cas_code = spcd.cas_code
		  LEFT JOIN substance_region_process srp
			ON spu.app_sid = srp.app_sid
           AND spu.substance_id = srp.substance_id
           AND spu.process_id = srp.process_id	
		  JOIN substance_region sr 
		    ON spu.substance_id = sr.substance_id 
		   AND spu.region_sid = sr.region_sid 
		   AND spu.app_sid = sr.app_sid
		  JOIN csr.v$region r ON sr.region_sid = r.region_sid AND sr.app_sid = r.app_sid
		  JOIN substance s 
		    ON spu.substance_id = s.substance_id 
		   AND spu.app_sid = s.app_sid
		  LEFT JOIN manufacturer m
		    ON s.manufacturer_id = m.manufacturer_id AND s.app_sid = m.app_sid
		  LEFT JOIN usage u ON srp.usage_Id = u.usage_Id AND srp.app_sid = u.app_sid
		 WHERE spu.end_dtm > in_start_dtm AND spu.start_dtm < in_end_dtm
		ORDER BY r.lookup_key, spu.start_dtm, s.description, spcd.cas_code;
END;

PROCEDURE GetFullReport(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetFullReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_list_cur FOR
		SELECT cas_group_label, o.substance_ref, 
			o.local_ref "Local site code",
			o.substance_description, o.cas_code, 
		   o.category "Category",
		   CASE WHEN o.is_voc = 1 THEN 'Yes' ELSE 'No' END "Is VOC?",
			o.name,
			REPLACE(csr.region_pkg.INTERNAL_GetRegionPathString(o.region_sid),'Regions  Main  Philips  ', '') "Site",
				r.lookup_key "Site code",
			o.start_dtm, o.end_dtm,
			cas_weight,
			NVL(o.to_air_pct, 0) to_air_pct,
			NVL(o.to_water_pct, 0) to_water_pct,
			NVL(o.to_waste_pct, 0) to_waste_pct,
			NVL(o.to_product_pct, 0) to_product_pct,
			NVL(o.remaining_pct, 1 - NVL(o.to_air_pct, 0) - NVL(o.to_water_pct, 0) - NVL(o.to_waste_pct, 0) - NVL(o.to_product_pct, 0)) remaining_pct,
			ROUND(air_mass_value, 10) air_mass_value,
			ROUND(water_mass_value, 10) water_mass_value,
			CASE
				WHEN status.sheet_action_id = 3 THEN 'Validated'
				WHEN status.sheet_action_id = 6 THEN 'Validated'
				WHEN status.sheet_action_id = 9 THEN 'Validated'
				ELSE 'Invalid'
			END status,
			CASE
				WHEN status.sheet_action_id = 3 THEN status.action_dtm
				WHEN status.sheet_action_id = 6 THEN status.action_dtm
				WHEN status.sheet_action_id = 9 THEN status.action_dtm
				ELSE null
			END validated
		  FROM V$OUTPUTS o
		  JOIN csr.region r ON o.region_sid = r.region_sid
		  JOIN csr.sheet s ON s.delegation_sid = o.root_delegation_sid AND s.start_dtm = o.start_dtm AND s.end_dtm = o.end_dtm
		  JOIN csr.sheet_history status ON status.sheet_history_id = s.last_sheet_history_id
		 WHERE o.end_dtm > in_start_dtm AND o.start_dtm < in_end_dtm
		ORDER BY "Site", substance_ref, cas_group_label, o.start_dtm;
END;

PROCEDURE GetSubstances(
	out_list_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetSubstances') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_list_cur FOR
		SELECT ref "12NC or Internal Code", s.description "Substance", c.description Classification, m.name Manufacturer
		  FROM substance s
		  JOIN classification c ON c.classification_id = s.classification_id
		  JOIN manufacturer m ON m.manufacturer_id = s.manufacturer_id;
END;

PROCEDURE GetSubstancesReport(
	out_list_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetSubstancesReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_list_cur FOR
		SELECT s.ref "12NC or Internal Code", CASE WHEN s.is_central = 1 THEN 'Yes' ELSE 'No' END "Is 12NC", 
				c.description "Classification", s.description "Substance", m.name "Manufacturer",
				cas.name "CAS name", cas.cas_code "Code", sc.pct_composition "% composition"
		  FROM substance s
		  LEFT JOIN manufacturer m ON s.manufacturer_id = m.manufacturer_id AND s.app_sid = m.app_sid
		  LEFT JOIN classification c ON s.classification_id = c.classification_id AND s.app_sid = c.app_sid
		  LEFT JOIN substance_cas sc ON s.substance_id = sc.substance_id AND s.app_sid = sc.app_sid
		  LEFT JOIN cas ON sc.cas_code = cas.cas_code
		  ORDER BY s.ref, sc.cas_code, sc.pct_composition;
END;


PROCEDURE GetAuditReport(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_list_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.sqlreport_pkg.CheckAccess('chem.report_pkg.GetAuditReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_list_cur FOR
 		SELECT cas_group_label, o.substance_ref, o.substance_description, o.cas_code, o.name, 
			REPLACE(csr.region_pkg.INTERNAL_GetRegionPathString(o.region_sid),'Regions  Main  Philips  ', '') "Site",
				r.lookup_key "Site code",
			o.start_dtm, o.end_dtm,
			cas_weight,
			to_air_pct,
			to_water_pct,
			to_waste_pct,
			to_product_pct,
			remaining_pct,
			ROUND(air_mass_value, 10) air_mass_value,
			ROUND(water_mass_value, 10) water_mass_value,
			o.mass_value "Consumption (kg)",
			CASE
				WHEN status.sheet_action_id = 3 THEN 'Validated'
				WHEN status.sheet_action_id = 6 THEN 'Validated'
				WHEN status.sheet_action_id = 9 THEN 'Validated'
				ELSE NULL
			END status,
			CASE
				WHEN status.sheet_action_id = 3 THEN status.action_dtm
				WHEN status.sheet_action_id = 6 THEN status.action_dtm
				WHEN status.sheet_action_id = 9 THEN status.action_dtm
				ELSE NULL
			END validated,
			o.changed_dtm "Changed on",
			u.full_name || ' (' || u.user_name || ')' "Changed by",
			o.retired_dtm "Removed",
			history.description "History"
		  FROM V$AUDIT_LOG o
		  JOIN csr.region r ON o.region_sid = r.region_sid
		  JOIN csr.sheet s ON s.delegation_sid = o.root_delegation_sid AND s.start_dtm = o.start_dtm AND s.end_dtm = o.end_dtm
		  JOIN csr.sheet_history status ON status.sheet_history_id = s.last_sheet_history_id
		  JOIN (
			SELECT sa.sheet_id, REPLACE(REPLACE(csr.stragg(REPLACE(sa.description || ': ' || TO_CHAR(sa.action_dtm, 'dd/MM/yyyy HH24:mi:ss'), ',','#')), ',',' -> '),'#', ',') description
			  FROM csr.sheet si
			  JOIN (
				SELECT sheet_id, max(shi.action_dtm) action_dtm, sai.description, sai.sheet_action_id
				  FROM csr.sheet_history shi
				  JOIN csr.sheet_action sai ON sai.sheet_action_id = shi.sheet_action_id
				 GROUP BY sheet_id, sai.sheet_action_id, sai.description
			) sa ON sa.sheet_id = si.sheet_id
			 GROUP BY sa.sheet_id
			) history ON history.sheet_id = s.sheet_id
		  JOIN csr.csr_user u ON u.csr_user_sid = o.changed_by
		 WHERE o.end_dtm > in_start_dtm AND o.start_dtm < in_end_dtm
		ORDER BY "Site", substance_ref, cas_group_label, o.start_dtm;
END;

END;
/
