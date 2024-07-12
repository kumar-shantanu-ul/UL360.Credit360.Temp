CREATE OR REPLACE PACKAGE BODY DONATIONS.SCHEME_Pkg
IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_class_id			IN security_pkg.T_CLASS_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_new_name		IN security_pkg.T_SO_NAME
) AS
BEGIN
	update scheme set name = in_new_name where scheme_sid = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
	DELETE FROM donation_tag
		  WHERE donation_id in (select donation_id from donation where scheme_sid = in_sid_id);
	DELETE FROM donation
		  WHERE scheme_sid = in_sid_id;
	DELETE FROM scheme_field
		  WHERE scheme_sid = in_sid_id;
	DELETE FROM budget_constant
		  WHERE budget_id in (SELECT budget_id FROM budget WHERE scheme_sid = in_sid_id);
	DELETE FROM budget
		  WHERE scheme_sid = in_sid_id;
	DELETE FROM SCHEME_TAG_GROUP
		  WHERE scheme_sid = in_sid_id;
	DELETE FROM SCHEME_DONATION_STATUS
		  WHERE scheme_sid = in_sid_id;
	DELETE FROM SCHEME
		  WHERE scheme_sid = in_sid_id;

END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;
--
-- PROCEDURE: CreateSCHEME
--
PROCEDURE CreateScheme (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_PKG.T_SID_ID,
	in_name					IN	SCHEME.name%TYPE,
	in_description	IN	SCHEME.description%TYPE,
	in_active			 	IN	SCHEME.active%TYPE,
	in_extra_fields_xml		IN	SCHEME.extra_fields_xml%TYPE,
	out_scheme_sid		 	OUT security_pkg.T_SID_ID
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	-- get securable object Donations/SCHEMEs
	v_parent_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Donations/Schemes');

	-- check permission
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_parent_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating scheme');
	END IF;

	-- create scheme SO
	SecurableObject_Pkg.CreateSO(in_act_id, v_parent_sid, class_pkg.getClassID('DonationsScheme'), Replace(in_name,'/','\'), out_scheme_sid); --'

	-- update data in table
	INSERT INTO SCHEME
				(scheme_sid, app_sid, name, description, active, extra_fields_xml
				)
		 VALUES (out_scheme_sid, in_app_sid, in_name, in_description, in_active, in_extra_fields_xml
				);
END;

--
-- PROCEDURE: AmendSCHEME
--
PROCEDURE AmendSCHEME (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	in_name				IN	SCHEME.name%TYPE,
	in_description	IN	SCHEME.description%TYPE,
	in_active		 	IN	SCHEME.active%TYPE,
	in_extra_fields_xml	IN	SCHEME.extra_fields_xml%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing scheme with sid '||in_scheme_sid);
	END IF;

	UPDATE SCHEME
		 SET	active = in_active,
					description = in_description,
					extra_fields_xml = in_extra_fields_xml
	 WHERE scheme_sid = in_scheme_sid;

	 -- we update the name here
	 securableobject_pkg.RenameSO(in_act_id, in_scheme_sid, in_name);
END;

PROCEDURE GetScheme(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme with sid '||in_scheme_sid);
	END IF;

	OPEN out_cur FOR
    	SELECT scheme_sid, name, description, active, extra_fields_xml,
	    	track_payments, track_company_giving, track_charity_budget, helper_pkg, track_donation_end_dtm,
			note_hack -- xml block with info about notes to show on edit screen
        	FROM SCHEME
         WHERE scheme_sid = in_scheme_sid;
END;

PROCEDURE GetSchemeFromBudgetId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_budget_id		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_scheme_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT scheme_sid INTO v_scheme_sid
	  FROM budget
	 WHERE budget_id = in_budget_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme with sid '||v_scheme_sid);
	END IF;

	OPEN out_cur FOR
    	SELECT scheme_sid, name, active, extra_fields_xml,
	    	track_payments, track_company_giving, track_charity_budget, helper_pkg, track_donation_end_dtm,
	    	note_hack -- xml block with info about notes to show on edit screen
          FROM SCHEME
         WHERE scheme_sid = v_scheme_sid;
END;


PROCEDURE GetSchemes(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
    	SELECT scheme_sid, name, description, active, extra_fields_xml,
    		security_pkg.SQL_IsAccessAllowedSID(in_act_id, scheme_sid, security_pkg.PERMISSION_WRITE) can_write,
	    	track_payments, track_company_giving, track_charity_budget, helper_pkg, track_donation_end_dtm,
			note_hack -- xml block with info about notes to show on edit screen
        	FROM SCHEME
         WHERE app_sid = in_app_sid
           AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, scheme_sid, security_pkg.PERMISSION_READ) = 1
         ORDER BY name;
END;

PROCEDURE GetCustomFields(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme with sid '||in_scheme_sid);
	END IF;

	OPEN out_cur FOR
		SELECT sf.scheme_sid, sf.field_num, label, expr, is_mandatory, note, lookup_Key, detailed_note, section,
			is_currency, pos
          FROM SCHEME_FIELD sf, CUSTOM_FIELD cf
         WHERE sf.app_sid = cf.app_sid
           AND sf.field_num = cf.field_num
           AND sf.scheme_sid = in_scheme_sid
         ORDER BY pos;
END;

PROCEDURE GetSchemeStatusMatrix(
  out_cur_schemes					OUT security_pkg.T_OUTPUT_CUR,
  out_cur_statuses				OUT security_pkg.T_OUTPUT_CUR,
  out_cur_matrix					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid 				security_pkg.T_SID_ID;
	v_act_id 					security_pkg.T_ACT_ID;
BEGIN
  v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
  v_act_id := SYS_CONTEXT('SECURITY', 'ACT');

  -- schemes cur
	GetSchemes(v_act_id,v_app_sid, out_cur_schemes);

	-- statuses
	status_pkg.GetStatuses(v_act_id,v_app_sid, out_cur_statuses);

	-- matrix
  OPEN out_cur_matrix FOR
		SELECT scheme_sid, donation_status_sid
		  FROM scheme_donation_status
		 WHERE app_sid = v_app_sid;
END;

PROCEDURE SetSchemeStatuses(
    in_scheme_sid							IN	security_pkg.T_SID_ID,
    in_donation_status_sids		IN	security_pkg.T_SID_IDS
)
AS
	t_items				security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_scheme_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to scheme with sid '||in_scheme_sid);
	END IF;

	t_items := security_Pkg.SidArrayToTable(in_donation_status_sids);

	-- delete everything
	DELETE FROM scheme_donation_status
	 WHERE scheme_sid = in_scheme_sid;

	-- map donation statuses
	INSERT INTO scheme_donation_status (scheme_sid, app_sid, donation_status_sid)
	SELECT in_scheme_sid, SYS_CONTEXT('SECURITY', 'APP'), column_value from table(t_items);
END;

FUNCTION GetSchemeSidByName(
	in_act_id			IN	security_pkg.T_ACT_ID,
  in_app_sid	IN	security_pkg.T_SID_ID,
	in_name				IN	scheme.name%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_sid 				security_pkg.T_SID_ID;
BEGIN

	BEGIN
		SELECT scheme_sid INTO v_sid
			FROM scheme
			WHERE lower(name) = TRIM(LOWER(in_name))
			AND app_sid = in_app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find scheme with name ' || in_name);
	END;

	RETURN v_sid;
END;

/**
* Exports values of custom fields of a given parent indicator and scheme.
* @param in_scheme_id		scheme id to export data from
* @param in_custom_values	list of field_num mapped to custom fields. e.g. 1, 2, 3 mean data from CUSTOM_1, CUSTOM_2, CUSTOM_3 columns of donation table
* @param in_ind_sid			csr parent indicator to set to. All child indicators are also set.
* @param in_reason			comment to insert into csr, where the data came from.
**/
PROCEDURE ExportSchemeDataToCSR(
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_custom_values	IN  donation_pkg.T_CUSTOM_VALUES,
	in_reason			IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
)
AS
	TYPE ref_cursor			IS REF CURSOR;
	v_val_id				csr.val.val_id%TYPE;
	v_sql					VARCHAR2(8000);
	c_values				ref_cursor;
	v_region_sid			security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_donated_dtm			donations.donation.donated_dtm%TYPE;
	v_val					csr.val.val_number%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme with sid '||in_scheme_sid);
	END IF;

	v_sql := '
		SELECT *
		  FROM (
			SELECT d.region_sid,
				   i.ind_sid,
				   TRUNC(donated_dtm, ''MM'') donated_dtm,';

	IF in_custom_values.count > 0 THEN
		v_sql := v_sql || '
				   SUM(
				   CASE ';
		FOR i IN 1..in_custom_values.count
		LOOP
			v_sql := v_sql || ' WHEN cf.field_num = ' || in_custom_values(i) || ' THEN d.custom_' || in_custom_values(i)|| CHR(13);
		END LOOP;
		v_sql := v_sql || ' ELSE NULL END) AS val';
	ELSE
		v_sql := v_sql || ' NULL AS val';
	END IF;

	v_sql := v_sql ||
			  ' FROM donations.donation d
		  CROSS JOIN donations.custom_field cf
			    JOIN csr.ind i ON i.lookup_key = cf.lookup_key||''_F''
			   WHERE d.scheme_sid = :in_scheme_sid
			     AND i.ind_sid IN (
					SELECT ind_sid
					  FROM csr.ind
		  CONNECT BY PRIOR ind_sid = parent_sid
				START WITH ind_sid = :in_ind_sid
				   )
		       GROUP BY region_sid, i.ind_sid, TRUNC(donated_dtm, ''MM'')
				)
		 WHERE val = 0';

	OPEN c_values FOR v_sql USING in_scheme_sid, in_ind_sid;
	LOOP
		FETCH c_values INTO v_region_sid, v_ind_sid, v_donated_dtm, v_val;
		EXIT WHEN c_values%NOTFOUND;
		csr.indicator_pkg.SetValueWithReason(
			in_act_id => security_pkg.getAct,
			in_ind_sid => v_ind_sid,
			in_region_sid => v_region_sid,
			in_period_start => v_donated_dtm,
			in_period_end => ADD_MONTHS(v_donated_dtm,1),
			in_val_number => NVL(v_val,NULL),
			in_flags => 0,
			in_reason => in_reason,
			in_note => NULL,
			out_val_id => v_val_id
	);
	END LOOP;
END;

/**
* Exports value of custom field of a given custom field, tag and scheme.
* @param in_scheme_id			scheme id to export data from
* @param in_ind_sid				csr indicator to set to.
* @param in_custom_field_name	name of custom field. e.g. CUSTOM_1, CUSTOM_2, CUSTOM_3 columns of donation table
* @param in_tag_id				tag id.
* @param in_reason				comment to insert into csr, where the data came from.
**/
PROCEDURE ExportSchemeDataWithTagIdToCSR (
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_custom_field_name	IN	VARCHAR2,
	in_tag_id				IN	tag.tag_id%TYPE,
	in_reason				IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module')
AS
	TYPE ref_cursor			IS REF CURSOR;
	v_val_id				csr.val.val_id%TYPE;
	v_sql					VARCHAR2(8000);
	c_values				ref_cursor;
	v_region_sid			security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_donated_dtm			donations.donation.donated_dtm%TYPE;
	v_val					csr.val.val_number%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme with sid '||in_scheme_sid);
	END IF;

	v_sql :=
		'SELECT d.region_sid,
			    TRUNC(donated_dtm, ''MM'') donated_dtm,
			    SUM(' || in_custom_field_name ||') val
		   FROM donations.donation d
		   JOIN donations.donation_tag dt ON d.donation_id = dt.donation_id
		  WHERE d.scheme_sid = :in_scheme_sid
		    AND dt.tag_id = :in_tag_id
		  GROUP BY region_sid, trunc(donated_dtm, ''MM'')';

	OPEN c_values FOR v_sql USING in_scheme_sid, in_tag_id;
	LOOP
		FETCH c_values INTO v_region_sid, v_donated_dtm, v_val;
		EXIT WHEN c_values%NOTFOUND;
		csr.indicator_pkg.SetValueWithReason(
			in_act_id => security_pkg.getAct,
			in_ind_sid => in_ind_sid,
			in_region_sid => v_region_sid,
			in_period_start => v_donated_dtm,
			in_period_end => ADD_MONTHS(v_donated_dtm,1),
			in_val_number => v_val,
			in_flags => 0,
			in_reason => in_reason,
			in_note => NULL,
			out_val_id => v_val_id);
	END LOOP;
END;

/**
* Exports count of donations of a given tag and scheme.
* @param in_scheme_id		scheme id to export data from
* @param in_ind_sid			csr indicator to set to.
* @param in_tag_id			tag id.
* @param in_reason			comment to insert into csr, where the data came from.
**/
PROCEDURE ExportSchemeDataWithTagIdToCSR (
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_tag_id				IN	tag.tag_id%TYPE,
	in_reason				IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module')
AS
	TYPE ref_cursor			IS REF CURSOR;
	v_val_id				csr.val.val_id%TYPE;
	v_sql					VARCHAR2(8000);
	c_values				ref_cursor;
	v_region_sid			security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_donated_dtm			donations.donation.donated_dtm%TYPE;
	v_val					csr.val.val_number%TYPE;
BEGIN
	v_sql :=
		'SELECT d.region_sid,
			     TRUNC(donated_dtm, ''MM'') donated_dtm,
			     COUNT(d.donation_id) AS val
		   FROM donations.donation d
		   JOIN donations.donation_tag dt ON d.donation_id = dt.donation_id
		  WHERE d.scheme_sid = :in_scheme_sid
		    AND dt.tag_id = :in_tag_id
		  GROUP BY region_sid, trunc(donated_dtm, ''MM'')';

	OPEN c_values FOR v_sql USING in_scheme_sid, in_tag_id;
	LOOP
		FETCH c_values INTO v_region_sid, v_donated_dtm, v_val;
		EXIT WHEN c_values%NOTFOUND;
		csr.indicator_pkg.SetValueWithReason(
			in_act_id => security_pkg.getAct,
			in_ind_sid => in_ind_sid,
			in_region_sid => v_region_sid,
			in_period_start => v_donated_dtm,
			in_period_end => ADD_MONTHS(v_donated_dtm,1),
			in_val_number => v_val,
			in_flags => 0,
			in_reason => in_reason,
			in_note => NULL,
			out_val_id => v_val_id);
	END LOOP;
END;

/**
* Exports values of custom fields of all schemes except one.
* @param in_scheme_id		scheme id to exclude
* @param in_custom_values	list of field_num mapped to custom fields. e.g. 1, 2, 3 mean data from CUSTOM_1, CUSTOM_2, CUSTOM_3 columns of donation table
* @param in_reason			comment to insert into csr, where the data came from.
**/
PROCEDURE ExportAllSchemeDataToCSRExcept(
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	in_custom_values	IN  donation_pkg.T_CUSTOM_VALUES,
	in_reason			IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
)
AS
	TYPE ref_cursor			IS REF CURSOR;
	v_val_id				csr.val.val_id%TYPE;
	v_sql					VARCHAR2(8000);
	c_values				ref_cursor;
	v_region_sid			security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_donated_dtm			donations.donation.donated_dtm%TYPE;
	v_val					csr.val.val_number%TYPE;
BEGIN
	v_sql := '
			SELECT d.region_sid,
				   i.ind_sid,
				   TRUNC(donated_dtm, ''MM'') donated_dtm,';

	IF in_custom_values.count > 0 THEN
		v_sql := v_sql || '
				   SUM(
				   CASE ';
		FOR i IN 1..in_custom_values.count
		LOOP
			v_sql := v_sql || ' WHEN cf.field_num = ' || in_custom_values(i) || ' THEN d.custom_' || in_custom_values(i)|| CHR(13);
		END LOOP;
		v_sql := v_sql || ' ELSE NULL END) AS val';
	ELSE
		v_sql := v_sql || ' NULL AS val';
	END IF;

	v_sql := v_sql ||
			  ' FROM donations.donation d
		  CROSS JOIN donations.custom_field cf
			    JOIN csr.ind i ON i.lookup_key = cf.lookup_key
			   WHERE d.scheme_sid != :in_scheme_sid
		       GROUP BY region_sid, i.ind_sid, TRUNC(donated_dtm, ''MM'')';

	OPEN c_values FOR v_sql USING in_scheme_sid;
	LOOP
		FETCH c_values INTO v_region_sid, v_ind_sid, v_donated_dtm, v_val;
		EXIT WHEN c_values%NOTFOUND;
		csr.indicator_pkg.SetValueWithReason(
			in_act_id => security_pkg.getAct,
			in_ind_sid => v_ind_sid,
			in_region_sid => v_region_sid,
			in_period_start => v_donated_dtm,
			in_period_end => ADD_MONTHS(v_donated_dtm,1),
			in_val_number => NVL(v_val,NULL),
			in_flags => 0,
			in_reason => in_reason,
			in_note => NULL,
			out_val_id => v_val_id
		);
	END LOOP;
END;

/**
* Exports values of custom field of all schemes except one for a given custom field name and tag id.
* @param in_scheme_id			scheme id to exclude
* @param in_ind_sid				csr indicator to set to.
* @param in_custom_field_name	name of custom field. e.g. CUSTOM_1, CUSTOM_2, CUSTOM_3 columns of donation table
* @param in_tag_id				tag id.
* @param in_reason				comment to insert into csr, where the data came from.
**/
PROCEDURE AllSchemeDataWithTagIdToCSREx(
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_custom_field_name	IN	VARCHAR2,
	in_tag_id				IN	tag.tag_id%TYPE,
	in_reason				IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module')
AS
	TYPE ref_cursor			IS REF CURSOR;
	v_val_id				csr.val.val_id%TYPE;
	v_sql					VARCHAR2(8000);
	c_values				ref_cursor;
	v_region_sid			security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_donated_dtm			donations.donation.donated_dtm%TYPE;
	v_val					csr.val.val_number%TYPE;
BEGIN
	v_sql :=
		 'SELECT d.region_sid,
			     TRUNC(donated_dtm, ''MM'') donated_dtm,
			     SUM(' || in_custom_field_name || ') val
		    FROM donations.donation d
		    JOIN donations.donation_tag dt ON d.donation_id = dt.donation_id
		   WHERE d.scheme_sid != :in_scheme_sid
		     AND dt.tag_id = :in_tag_id
		   GROUP BY region_sid, trunc(donated_dtm, ''MM'')';

	OPEN c_values FOR v_sql USING in_scheme_sid, in_tag_id;
	LOOP
		FETCH c_values INTO v_region_sid, v_donated_dtm, v_val;
		EXIT WHEN c_values%NOTFOUND;
		csr.indicator_pkg.SetValueWithReason(
			in_act_id => security_pkg.getAct,
			in_ind_sid => in_ind_sid,
			in_region_sid => v_region_sid,
			in_period_start => v_donated_dtm,
			in_period_end => ADD_MONTHS(v_donated_dtm,1),
			in_val_number => v_val,
			in_flags => 0,
			in_reason => in_reason,
			in_note => NULL,
			out_val_id => v_val_id);
	END LOOP;
END;

/**
* Exports values of custom fields of a given parent indicator and scheme where there is no date by using the budget start and end_dtm.
* @param in_scheme_id		scheme id to export data from
* @param in_custom_values	list of field_num mapped to custom fields. e.g. 1, 2, 3 mean data from CUSTOM_1, CUSTOM_2, CUSTOM_3 columns of donation table
* @param in_ind_sid			csr parent indicator to set to. All child indicators are also set.
* @param in_reason			comment to insert into csr, where the data came from.
**/
PROCEDURE ExportSchemeDataToCSRNoDate(
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_custom_values	IN  donation_pkg.T_CUSTOM_VALUES,
	in_reason			IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
)
AS
	TYPE ref_cursor			IS REF CURSOR;
	v_val_id				csr.val.val_id%TYPE;
	v_sql					VARCHAR2(8000);
	c_values				ref_cursor;
	v_region_sid			security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_start_dtm			donations.donation.donated_dtm%TYPE;
  v_end_dtm			donations.donation.donated_dtm%TYPE;
	v_val					csr.val.val_number%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme with sid '||in_scheme_sid);
	END IF;

	v_sql := '
		SELECT *
		  FROM (
			SELECT d.region_sid,
				   i.ind_sid,
				   b.start_dtm, b.end_dtm,';

	IF in_custom_values.count > 0 THEN
		v_sql := v_sql || '
				   SUM(
				   CASE ';
		FOR i IN 1..in_custom_values.count
		LOOP
			v_sql := v_sql || ' WHEN cf.field_num = ' || in_custom_values(i) || ' THEN d.custom_' || in_custom_values(i)|| CHR(13);
		END LOOP;
		v_sql := v_sql || ' ELSE NULL END) AS val';
	ELSE
		v_sql := v_sql || ' NULL AS val';
	END IF;

	v_sql := v_sql ||
			  ' FROM donations.donation d
    CROSS JOIN donations.custom_field cf
			    JOIN csr.ind i ON i.lookup_key = cf.lookup_key||''_F''
          JOIN donations.budget b ON b.budget_id = d.budget_id
			   WHERE d.scheme_sid = :in_scheme_sid
			     AND i.ind_sid IN (
					SELECT ind_sid
					  FROM csr.ind
		  CONNECT BY PRIOR ind_sid = parent_sid
				START WITH ind_sid = :in_ind_sid
				   )
		       GROUP BY region_sid, i.ind_sid, b.start_dtm, b.end_dtm
				)
		 WHERE val = 0';

	OPEN c_values FOR v_sql USING in_scheme_sid, in_ind_sid;
	LOOP
		FETCH c_values INTO v_region_sid, v_ind_sid, v_start_dtm, v_end_dtm, v_val;
		EXIT WHEN c_values%NOTFOUND;
		csr.indicator_pkg.SetValueWithReason(
			in_act_id => security_pkg.getAct,
			in_ind_sid => v_ind_sid,
			in_region_sid => v_region_sid,
			in_period_start => v_start_dtm,
			in_period_end => v_end_dtm,
			in_val_number => NVL(v_val,NULL),
			in_flags => 0,
			in_reason => in_reason,
			in_note => NULL,
			out_val_id => v_val_id
	);
	END LOOP;
END;




/**
* Exports value of custom field of a given custom field, tag and scheme where no donation date is provided using the budget start and end date instead
* @param in_scheme_id			scheme id to export data from
* @param in_ind_sid				csr indicator to set to.
* @param in_custom_field_name	name of custom field. e.g. CUSTOM_1, CUSTOM_2, CUSTOM_3 columns of donation table
* @param in_tag_id				tag id.
* @param in_reason				comment to insert into csr, where the data came from.
**/
PROCEDURE ExportDataWithTagToCSRNoDate (
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_custom_field_name	IN	VARCHAR2,
	in_tag_id				IN	tag.tag_id%TYPE,
	in_reason				IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module')
AS
	TYPE ref_cursor			IS REF CURSOR;
	v_val_id				csr.val.val_id%TYPE;
	v_sql					VARCHAR2(8000);
	c_values				ref_cursor;
	v_region_sid			security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_start_dtm			donations.donation.donated_dtm%TYPE;
	v_end_dtm			donations.donation.donated_dtm%TYPE;
  v_val					csr.val.val_number%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_scheme_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme with sid '||in_scheme_sid);
	END IF;

	v_sql :=
  	'  SELECT d.region_sid, b.start_dtm, b.end_dtm,
          SUM(' || in_custom_field_name ||') val
         FROM donations.donation d
         JOIN donations.donation_tag dt ON d.donation_id = dt.donation_id
         JOIN budget b ON d.budget_id = b.budget_id
        GROUP BY d.region_sid, b.start_dtm, b.end_dtm';

	OPEN c_values FOR v_sql USING in_scheme_sid, in_tag_id;
	LOOP
		FETCH c_values INTO v_region_sid, v_start_dtm, v_end_dtm, v_val;
		EXIT WHEN c_values%NOTFOUND;
		csr.indicator_pkg.SetValueWithReason(
			in_act_id => security_pkg.getAct,
			in_ind_sid => in_ind_sid,
			in_region_sid => v_region_sid,
			in_period_start => v_start_dtm,
			in_period_end => v_end_dtm,
			in_val_number => v_val,
			in_flags => 0,
			in_reason => in_reason,
			in_note => NULL,
			out_val_id => v_val_id);
	END LOOP;
END;

END SCHEME_Pkg;
/