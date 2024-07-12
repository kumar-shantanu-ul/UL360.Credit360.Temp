CREATE OR REPLACE PACKAGE BODY DONATIONS.fields_pkg
IS

FUNCTION GetFieldName(
  in_field_num    IN custom_field.field_num%TYPE
) RETURN VARCHAR2
AS
  v_label     varchar2(255);
BEGIN
  SELECT label 
    INTO v_label 
    FROM custom_field
   WHERE field_num = in_field_num
     AND app_sid = security_pkg.getApp();
     
   RETURN v_label;
END;

PROCEDURE GetFields(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT label, field_num, expr, is_mandatory, note, lookup_key, is_currency, detailed_note, section, pos 
		  FROM custom_field
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	  ORDER BY pos;
END;

PROCEDURE GetFieldsOrderByLabel(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT label, field_num, expr, is_mandatory, note, lookup_key, is_currency, detailed_note, section, pos 
		  FROM custom_field
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	  ORDER BY NLSSORT(label, 'NLS_SORT=BINARY_CI');
END;

PROCEDURE GetFieldDetails(
    in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_lookup_key       IN  custom_field.lookup_key%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT label, field_num, expr, is_mandatory, note, lookup_key, is_currency, detailed_note, section, pos 
		  FROM custom_field
		 WHERE app_sid = in_app_sid
		   AND lookup_key = in_lookup_key
	     ORDER BY pos;
END;

PROCEDURE GetFieldsByScheme(
    in_act				IN	security_pkg.T_ACT_ID,
    in_app_sid          IN	security_pkg.T_SID_ID,
	in_scheme_sid       IN security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_scheme_sid, security_pkg.PERMISSION_STANDARD_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme');
	END IF;
	
	OPEN out_cur FOR
        SELECT sf.scheme_sid, sf.show_in_browse, cf.label, cf.field_num
          FROM custom_field cf, scheme_field sf 
         WHERE cf.app_sid = in_app_sid 
           AND sf.field_num(+) = cf.field_num
           AND scheme_sid = in_scheme_sid
         ORDER BY cf.label;
		   --AND security_pkg.SQL_IsAccessAllowedSID(in_act, sf.scheme_sid, security_pkg.PERMISSION_READ)=1;
END;


PROCEDURE GetFieldsForSchemeSetup(
    in_act				IN	security_pkg.T_ACT_ID,
    in_app_sid          IN	security_pkg.T_SID_ID,
	in_scheme_sid       IN security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_scheme_sid, security_pkg.PERMISSION_STANDARD_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme');
	END IF;
	
	OPEN out_cur FOR
        SELECT sf.scheme_sid, sf.show_in_browse, cf.label, cf.field_num, cf.lookup_key
          FROM custom_field cf, scheme_field sf 
         WHERE cf.app_sid = in_app_sid 
           AND sf.field_num(+) = cf.field_num
           AND scheme_sid(+) = in_scheme_sid
     ORDER BY cf.label;
		   --AND security_pkg.SQL_IsAccessAllowedSID(in_act, sf.scheme_sid, security_pkg.PERMISSION_READ)=1;
END;

/*PROCEDURE AssociateFieldsToScheme(
    in_act				IN	security_pkg.T_ACT_ID,
    in_app_sid			IN	security_pkg.T_SID_ID,
	in_scheme_sid       IN security_pkg.T_SID_ID,
	in_field_nums		IN	VARCHAR2
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act, in_scheme_sid, security_pkg.PERMISSION_ALL) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	DELETE FROM SCHEME_FIELD
	 WHERE scheme_sid = in_scheme_sid;
	
	INSERT INTO SCHEME_FIELD
		(app_sid, scheme_sid, field_num, show_in_browse)
		-- hack to insert 1 to show in browse for time being
	SELECT in_app_sid, in_scheme_sid, item, 1 FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_field_nums,','));
END;
*/


PROCEDURE UpdateField(
	in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid			        IN	security_pkg.T_SID_ID,
    in_label                    IN  custom_field.label%TYPE,
    in_field_num                IN  custom_field.field_num%TYPE,
    in_expr                     IN  custom_field.expr%TYPE,
    in_mandatory                IN  custom_field.is_mandatory%TYPE,
    in_note                     IN  custom_field.note%TYPE,
    in_detailed_note            IN  VARCHAR2,
    in_lookup                   IN  custom_field.lookup_key%TYPE,
    in_currency                 IN  custom_field.is_currency%TYPE,
    in_section                  IN  custom_field.section%TYPE,
    in_pos                      IN  custom_field.pos%TYPE
)
AS
	v_expr			custom_field.expr%TYPE;
	v_lookup_key 	custom_field.lookup_key%TYPE;
BEGIN	
	-- check permission....
	IF NOT csr.csr_data_pkg.CheckCapability(in_act_id, 'Configure Community Involvement module') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on modify Community Involvement setup');
	END IF;
	
	SELECT expr, lookup_key
	  INTO v_expr, v_lookup_key
	  FROM custom_field
	 WHERE app_sid = in_app_sid
	   AND field_num = in_field_num;
	
	IF v_expr != in_expr OR v_lookup_key != in_lookup THEN
		sys_pkg.QueueRecalc(in_app_sid);
	END IF;

	UPDATE custom_field
	   SET label         = in_label,
            expr         = in_expr,
            is_mandatory = in_mandatory,
            note = in_note,
            detailed_note = in_detailed_note, 
            lookup_key = in_lookup,
            is_currency = in_currency,
            section = in_section,
            pos = in_pos
	 WHERE app_sid = in_app_sid 
	   AND field_num = in_field_num;
END;


PROCEDURE AddField(
    in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid			        IN	security_pkg.T_SID_ID,
    in_label                    IN  custom_field.label%TYPE,
    in_expr                     IN  custom_field.expr%TYPE,
    in_mandatory                IN  custom_field.is_mandatory%TYPE,
    in_note                     IN  custom_field.note%TYPE,
    in_detailed_note            IN  VARCHAR2,
    in_lookup                   IN  custom_field.lookup_key%TYPE,
    in_currency                 IN  custom_field.is_currency%TYPE,
    in_section                  IN  custom_field.section%TYPE,
    in_pos                      IN  custom_field.pos%TYPE,
    out_field_num				OUT	custom_field.field_num%TYPE
)
AS
    -- init field_num with not valid value (we'll check it after)
    -- field num is 1 based
    v_new_field_num             NUMBER(10):=0;
BEGIN
	-- check permission....
	IF NOT csr.csr_data_pkg.CheckCapability(in_act_id, 'Configure Community Involvement module') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on modify Community Involvement setup');
	END IF;
	
    -- find the gap in field_nums eg. 1,2,3,10 will add field 4
    SELECT 
    	CASE 
    		WHEN gap IS NULL THEN (SELECT nvl(MAX(field_num)+1,1) FROM custom_field WHERE app_sid = in_app_sid) 
    		ELSE gap 
    	END 
      INTO v_new_field_num
      FROM (
		SELECT MIN(prev_field_num)+1 gap
          FROM (
			SELECT field_num, lag(field_num,1,1) OVER (ORDER BY field_num) prev_field_num
              FROM custom_field 
             WHERE app_sid = in_app_sid
          )
        WHERE field_num - prev_field_num > 1
    );


    IF v_new_field_num > 260 THEN
        RAISE_APPLICATION_ERROR(scheme_pkg.ERR_MAX_FIELDS_NUMBER_OCCURED, 'Maximum number of fields error occured. Currently 260 fields are available for application.');
    END IF;
    
    INSERT INTO custom_field
			(app_sid, expr, field_num, label, is_mandatory, note,detailed_note, lookup_key,is_currency, section, pos)
		VALUES
			(in_app_sid, in_expr, v_new_field_num, in_label, in_mandatory, in_note, in_detailed_note, in_lookup, in_currency, in_section, in_pos)
    RETURNING field_num into out_field_num;
    
	sys_pkg.QueueRecalc(in_app_sid);
END;

-- this looks totally bonkers
-- NOTE: the fieldnums will REMAIN in DB; the others that belongs to same app_sid will be deleted
PROCEDURE DeleteFields(
    in_app_sid			    IN	security_pkg.T_SID_ID,
	in_field_nums_to_leave	IN	VARCHAR2
)
AS
BEGIN
    -- check permission....
	IF NOT csr.csr_data_pkg.CheckCapability(security_pkg.getACT, 'Configure Community Involvement module') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on modify Community Involvement setup');
	END IF;
	
	-- TODO: check if there are dependencies, if yes throw exception, so we can alert user
	
	-- clean up dependencies	
    DELETE FROM custom_field_dependency
     WHERE field_num NOT IN (
     	SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_field_nums_to_leave,','))
      );
    
    DELETE FROM custom_field_dependency
     WHERE dependent_field_num NOT IN (
     	SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_field_nums_to_leave,','))
      );
    
    -- delete from scheme_field mapping
    DELETE FROM scheme_field 
     WHERE app_sid = in_app_sid
       AND field_num NOT IN (
       	SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_field_nums_to_leave,','))
      );
        
    -- delete
    DELETE FROM custom_field 
	 WHERE app_sid = in_app_sid
	   AND field_num NOT IN (
		SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_field_nums_to_leave,','))
	);
END;


PROCEDURE GetFieldsDetails(
    in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid          IN	security_pkg.T_SID_ID,
    out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT field_num, label, is_currency, lookup_key 
          FROM custom_field
         WHERE app_sid = in_app_sid
         ORDER BY pos;
END;

PROCEDURE AssociateFieldWithScheme(
    in_act_id			IN	security_pkg.T_ACT_ID,
    in_app_sid          IN	security_pkg.T_SID_ID,
    in_scheme_sid       IN security_pkg.T_SID_ID,
    in_field_num		IN scheme_field.field_num%TYPE,
	in_show_in_browse   IN scheme_field.show_in_browse%TYPE
)
AS
BEGIN
    -- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing scheme');
	END IF;
	
    BEGIN
        INSERT INTO scheme_field (app_sid, scheme_sid, field_num, show_in_browse)
            VALUES (in_app_sid, in_scheme_sid, in_field_num, in_show_in_browse);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE scheme_field
               SET show_in_browse = in_show_in_browse 
             WHERE app_sid = in_app_sid
               AND field_num = in_field_num
               AND scheme_sid = in_scheme_sid;
    END;
END;

PROCEDURE UnmapFields(
    in_act_id					IN	security_pkg.T_ACT_ID,
    in_app_sid                  IN	security_pkg.T_SID_ID,
    in_scheme_sid               IN security_pkg.T_SID_ID,
    in_field_nums		        IN VARCHAR2
)
AS
BEGIN
    -- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing scheme');
	END IF;

    DELETE FROM SCHEME_FIELD 
     WHERE app_sid = in_app_sid
       AND scheme_sid = in_scheme_sid
       AND field_num IN (
		SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_field_nums,','))
	);

END;

PROCEDURE GetFieldsSchemeMapping(
    in_act_id		IN	security_pkg.T_ACT_ID,
    in_app_sid      IN	security_pkg.T_SID_ID,
    out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT scheme_sid,field_num, show_in_browse
		  FROM scheme_field 
		 WHERE app_sid = in_app_sid 
		 ORDER BY scheme_sid;
END;

PROCEDURE SetDependencies(
	in_field_num			IN	custom_field.field_num%TYPE,
	in_dependent_field_nums	IN	security_pkg.T_SID_IDS
)
AS
BEGIN
    -- check permission....
	IF NOT csr.csr_data_pkg.CheckCapability(security_pkg.getACT, 'Configure Community Involvement module') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on modify Community Involvement setup');
	END IF;
	
	DELETE FROM custom_field_dependency
	 WHERE app_sid = security_pkg.GetApp
	   AND field_num = in_field_num;
	
	IF in_dependent_field_nums.COUNT = 1 AND in_dependent_field_nums(in_dependent_field_nums.FIRST) IS NULL THEN
		-- hack for ODP.NET which doesn't support empty arrays - just delete everything
		RETURN;
	END IF;
	
	FORALL i IN INDICES OF in_dependent_field_nums
		INSERT INTO custom_field_dependency (field_num, dependent_field_num)
			VALUES (in_field_num, in_dependent_field_nums(i));	
END;


PROCEDURE GetCalcOrder(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- hmm -- no security: a) not sure what to secure, b) not sure it exposes much
	OPEN out_cur FOR
		SELECT field_num, MAX(lvl) max_lvl, MAX(is_cycle) contains_cycle
		  FROM (
		    SELECT cfd.field_num, level lvl, connect_by_iscycle is_cycle
		      FROM custom_field_dependency cfd
		     WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		     CONNECT BY NOCYCLE PRIOR app_sid = app_sid AND PRIOR dependent_field_num = field_num
		 )
		 GROUP BY field_num
		 ORDER BY max_lvl DESC; -- do them in the right order
END;

END fields_pkg;
/

