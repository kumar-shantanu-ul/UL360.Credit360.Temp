CREATE OR REPLACE PACKAGE BODY DONATIONS.browse_settings_pkg
IS

FUNCTION CanModify(
	in_filter_id	IN	filter.filter_id%TYPE
) RETURN BOOLEAN
AS
	v_cnt		NUMBER;
BEGIN
	-- we should allow to modify shared views only to their creators
	SELECT COUNT(filter_id)
	  INTO v_cnt
	  FROM filter
	 WHERE csr_user_sid != SYS_CONTEXT('SECURITY','SID')
	   AND filter_id = in_filter_id
	   AND is_shared = 1;

	RETURN v_cnt = 0;
END;

PROCEDURE SaveSetting(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_name				IN	filter.name%TYPE,
	in_description      IN  filter.description%TYPE,
	in_isshared         IN  NUMBER,
	in_filter_xml       IN  sys.xmltype,
	in_column_xml       IN  sys.xmltype,
	in_filter_type      IN  filter.filter_type%TYPE,
	out_filter_id		OUT	filter.filter_id%TYPE
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
    
	-- Get user sid from act
	v_user_sid := sys_context('security','sid');
	
	-- Check for existing name
	out_filter_id := -1;
	BEGIN
        SELECT filter_id
		  INTO out_filter_id
		  FROM filter
		 WHERE LOWER(name) LIKE (LOWER(in_name)) AND filter_type = in_filter_type;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			SELECT filter_id_seq.NEXTVAL
			  INTO out_filter_id
			  FROM dual;
	END;

	IF CanModify(out_filter_id) = FALSE THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied modyfing shared view');
	END IF;
	
	BEGIN
		INSERT INTO filter
            (filter_id, app_sid, csr_user_sid, name, description,is_shared, filter_xml, column_xml, filter_type)
		VALUES(out_filter_id, in_app_sid, v_user_sid, in_name, in_description, in_isshared,in_filter_xml,in_column_xml, in_filter_type);
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE filter
			   SET app_sid = in_app_sid,
			   	   csr_user_sid = v_user_sid,
			   	   name = in_name,
			   	   description = in_description, 
			   	   is_shared = in_isshared,
			   	   filter_xml = in_filter_xml,
			   	   column_xml = in_column_xml
			   WHERE filter_id = out_filter_id;
	END;
	
	-- stick filter_id to user so we know what to show on next login
	IF in_filter_type = browse_settings_pkg.FILTER_BROWSE  THEN 
		UPDATE csr.csr_user SET DONATIONS_BROWSE_FILTER_ID = out_filter_id
		WHERE csr_user_sid = v_user_sid;
	ELSIF in_filter_type = browse_settings_pkg.FILTER_PIVOT THEN
		UPDATE csr.csr_user SET DONATIONS_REPORTS_FILTER_ID = out_filter_id
		WHERE csr_user_sid = v_user_sid;
	END IF;
END;



PROCEDURE GetSettings(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_filter_type      IN  filter.filter_type%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	-- Get user sid from act
	v_user_sid := sys_context('security','sid');
	
	-- Get settings
	OPEN out_cur FOR
		SELECT filter_id, name, description, is_shared, last_used_dtm
		  FROM filter
		 WHERE app_sid = in_app_sid
		   AND filter_type = in_filter_type
		   AND (csr_user_sid = v_user_sid OR is_shared = 1) 
	  ORDER BY name;
END;

PROCEDURE LoadSetting(
    in_act				IN  security_pkg.T_ACT_ID,
	in_app_sid			IN  security_pkg.T_SID_ID,
    in_filter_id        IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_user_sid			security_pkg.T_SID_ID;
    v_filter_type		filter.filter_type%TYPE;
BEGIN    
    -- Get user sid from act
	v_user_sid := sys_context('security','sid');
	
	-- Update last_used_dtm
	UPDATE filter
       SET last_used_dtm = SYSDATE
     WHERE filter_id = in_filter_id
       AND app_sid = in_app_sid
    RETURNING filter_type into v_filter_type;
       
    -- Get xml
    OPEN out_cur FOR
        SELECT filter_xml, column_xml, is_shared, name, description, filter_id
          FROM filter
         WHERE app_sid = in_app_sid
		   AND (csr_user_sid = v_user_sid OR is_shared = 1)
		   AND filter_id = in_filter_id;
	
	-- browse filter
	IF v_filter_type = browse_settings_pkg.FILTER_BROWSE  THEN 
		UPDATE csr.csr_user SET DONATIONS_BROWSE_FILTER_ID = in_filter_id 
		WHERE csr_user_sid = v_user_sid;
	ELSIF v_filter_type = browse_settings_pkg.FILTER_PIVOT THEN 
		UPDATE csr.csr_user SET DONATIONS_REPORTS_FILTER_ID = in_filter_id 
		WHERE csr_user_sid = v_user_sid;
	END IF;
	
END;

PROCEDURE DeleteSetting(
    in_act				IN  security_pkg.T_ACT_ID,
	in_app_sid			IN  security_pkg.T_SID_ID,
    in_filter_id        IN  security_pkg.T_SID_ID
)
AS 
    v_user_sid          security_pkg.T_SID_ID;
	v_filter_type		filter.filter_type%TYPE;
BEGIN
    -- Get user sid from act
	v_user_sid := sys_context('security','sid');
    
	IF CanModify(in_filter_id) = false THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied modyfing shared view');
	END IF;
    
    DELETE FROM filter
           WHERE app_sid = in_app_sid
             AND csr_user_sid = v_user_sid
             AND filter_id = in_filter_id
       RETURNING filter_type into v_filter_type;
             
	-- update user's default filter
	IF v_filter_type = browse_settings_pkg.FILTER_BROWSE THEN 
		UPDATE csr.csr_user 
		   SET donations_browse_filter_id = null
		 WHERE csr_user_sid = v_user_sid
		   AND donations_browse_filter_id = in_filter_id;		   
	ELSIF v_filter_type = browse_settings_pkg.FILTER_PIVOT THEN 
		UPDATE csr.csr_user 
		   SET donations_reports_filter_id = null
		 WHERE csr_user_sid = v_user_sid
		   AND donations_reports_filter_id = in_filter_id;
	END IF;
END;

END browse_settings_pkg;
/
