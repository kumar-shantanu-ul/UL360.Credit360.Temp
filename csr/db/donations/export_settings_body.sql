CREATE OR REPLACE PACKAGE BODY DONATIONS.export_settings_pkg
IS

PROCEDURE SaveExportSettings(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_name				IN	user_fieldset.name%TYPE,
	in_fields			IN	VARCHAR,
	out_fieldset_id		OUT	user_fieldset.user_fieldset_id%TYPE
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	
	-- Get user sid from act
	user_pkg.GetSID(in_act, v_user_sid);
	
	-- Check for existing name
	out_fieldset_id := -1;
	BEGIN
		SELECT user_fieldset_id
		  INTO out_fieldset_id
		  FROM user_fieldset
		 WHERE LOWER(name) LIKE(LOWER(in_name));
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			SELECT user_fieldset_id_seq.NEXTVAL
			  INTO out_fieldset_id
			  FROM dual;
	END;

	-- Remove any existing fields
	DELETE FROM user_fieldset_field
		WHERE user_fieldset_id = out_fieldset_id;

	-- Insert/update the filedset
	BEGIN
		INSERT INTO user_fieldset
			(user_fieldset_id, app_sid, csr_user_sid, name)
		  VALUES(out_fieldset_id, in_app_sid, v_user_sid, in_name); 
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_fieldset
			   SET app_sid = in_app_sid,
			   	   csr_user_sid = v_user_sid,
			   	   name = in_name
			 WHERE user_fieldset_id = out_fieldset_id;
	END;		
		
	-- Insert the fields
	FOR r IN (
		SELECT item, pos 
      	  FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_fields,',')))
    LOOP
   		INSERT INTO user_fieldset_field
   			(user_fieldset_id, field_name)
   		  VALUES(out_fieldset_id, LOWER(r.item));
   	END LOOP;
   	
END;


PROCEDURE GetExportFieldsById(
	in_act				IN	security_pkg.T_ACT_ID,
	in_fieldset_id		IN	user_fieldset.user_fieldset_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT field_name
		  FROM user_fieldset_field
		 WHERE user_fieldset_id = in_fieldset_id;
END;
	

PROCEDURE GetExportFieldsByName(
	in_act				IN	security_pkg.T_ACT_ID,
	in_name				IN	user_fieldset.name%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT field_name
		  FROM user_fieldset_field
		 WHERE user_fieldset_id = (
		 	SELECT user_fieldset_id
		 	  FROM user_fieldset
		 	 WHERE LOWER(name) LIKE(LOWER(in_name)));
END;


PROCEDURE GetFieldsetIds(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	-- Get user sid from act
	user_pkg.GetSID(in_act, v_user_sid);
	
	-- Get settings
	OPEN out_cur FOR
		SELECT user_fieldset_id, name
		  FROM user_fieldset
		 WHERE app_sid = in_app_sid
		   AND csr_user_sid = v_user_sid;
END;


END export_settings_pkg;
/
