CREATE OR REPLACE PACKAGE BODY CSR.INCIDENT_PKG AS

-- add in all the Excel/Word template stuff here
-- make sure it works with XML in the database

PROCEDURE GetIncidentTypes(
	out_cur	  					OUT  SYS_REFCURSOR,
	out_user_columns	  		OUT  SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.tab_sid, i.label, i.plural, i.base_css_class,
		    i.list_url, i.edit_url, i.new_case_url, 
		    i.mobile_form_path, i.mobile_form_sid,
			t.oracle_schema, t.oracle_table, t.issues, t.managed, 
		    f.flow_sid, f.label flow_label, f.default_state_id default_state_id,
		    i.group_key, i.description
		  FROM incident_type i
		  JOIN cms.tab t ON i.tab_sid = t.tab_sid AND i.app_sid = t.app_sid
		  LEFT JOIN flow f ON t.flow_sid = f.flow_sid
		 WHERE security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), i.tab_sid, security_pkg.PERMISSION_READ) = 1
		  ORDER BY i.pos;
		  
	OPEN out_user_columns FOR
		SELECT c.tab_sid, c.column_sid, c.oracle_column
		  FROM cms.tab_column c
		 WHERE security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), c.tab_sid, security_pkg.PERMISSION_READ) = 1
		   AND c.incl_in_active_user_filter = 1
		 ORDER BY c.tab_sid;
END;

PROCEDURE SetIncidentType(
	in_oracle_user				IN  VARCHAR2				 				DEFAULT NULL,
	in_oracle_table				IN  VARCHAR2,
	in_label					IN  incident_type.label%TYPE   				DEFAULT NULL,
	in_plural					IN  incident_type.plural%TYPE   			DEFAULT NULL,
	in_base_css_class			IN  incident_type.base_css_class%TYPE 		DEFAULT 'csr-incident',
	in_list_url					IN  incident_type.list_url%TYPE,
	in_edit_url					IN  incident_type.edit_url%TYPE,
	in_new_case_url				IN  incident_type.new_case_url%TYPE  		DEFAULT NULL,
	in_group_Key				IN  incident_type.group_key%TYPE			DEFAULT NULL,
	in_pos						IN  incident_type.pos%TYPE 					DEFAULT NULL,
	in_mobile_form_path			IN	incident_type.mobile_form_path%TYPE		DEFAULT NULL,
	in_mobile_form_sid			IN	incident_type.mobile_form_sid%TYPE		DEFAULT NULL,
	in_description				IN	incident_type.description%TYPE			DEFAULT NULL
)
AS
	v_tab_sid		security_pkg.T_SID_ID;
	v_pos 			incident_type.pos%TYPE;
	v_oracle_user	customer.oracle_schema%TYPE;
	v_label			incident_type.label%TYPE;
BEGIN
	-- if no oracle_user passed, take the user from the customer table
	SELECT UPPER(NVL(in_oracle_user, oracle_schema))
	  INTO v_oracle_user
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	IF v_oracle_user IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Oracle user not specified and schema not set for client');
	END IF;

	v_tab_sid := cms.tab_pkg.GetTableSid(v_oracle_user, in_oracle_table);
	
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can manage incident types');
	END IF;		

	-- if no label passed, take the description from the CMS table or failing that just use the table name
	SELECT COALESCE(in_label, description, in_oracle_table)
	  INTO v_label
	  FROM cms.tab
	 WHERE tab_sid = v_tab_sid;

	IF in_pos IS NOT NULL THEN
		-- make space (umm - this is a bit of a crap idea on updates if keeping the same?)
		UPDATE incident_type
		   SET pos = pos + 1
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND pos >= in_pos;
	ELSE
		-- assume this is going at the end
		SELECT NVL(MAX(pos), 0) + 1
		  INTO v_pos
		  FROM incident_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	END IF;

	BEGIN
		INSERT INTO incident_type (tab_Sid, label, plural, base_css_class, pos, list_url, edit_url, 
		                           new_case_url, group_key, mobile_form_path, mobile_form_sid, 
								   description)
			VALUES (v_tab_sid, v_label, NVL(in_plural, v_label), in_base_css_class, NVL(v_pos, in_pos), 
			        in_list_url, in_edit_url, in_new_case_url, in_group_key, in_mobile_form_path, in_mobile_form_sid,
					 in_description);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE incident_type
			   SET label = v_label,
			    plural = NVL(in_plural, v_label),
			   	base_css_class = in_base_css_class,
			   	pos = NVL(in_pos, pos),
			   	list_url = in_list_url,
			   	edit_url = in_edit_url,
			   	group_key = in_group_key,
			   	new_case_url = in_new_case_url,
				mobile_form_path = in_mobile_form_path,
				mobile_form_sid = in_mobile_form_sid,
				description = in_description
			 WHERE tab_sid = v_tab_sid;
	END;
END;

END;
/
