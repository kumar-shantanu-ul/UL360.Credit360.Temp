CREATE OR REPLACE PACKAGE CSR.INCIDENT_PKG AS

PROCEDURE GetIncidentTypes(
	out_cur	  					OUT  SYS_REFCURSOR,
	out_user_columns			OUT  SYS_REFCURSOR
);

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
);

END;
/
