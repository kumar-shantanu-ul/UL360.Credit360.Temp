-- Please update version.sql too -- this keeps clean builds in sync
define version=2249
@update_header

SET SERVEROUTPUT ON;

/*
	A follow-up script is needed to:
		- remove unnecessary calendar columns;
		- update csr.calendar_pkg, csr.initiative_pkg and csr.teamroom_pkg to remove temporary code
*/


CREATE SEQUENCE CSR.PLUGIN_IND_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 5
	NOORDER;
			
CREATE TABLE CSR.PLUGIN_INDICATOR (
	PLUGIN_INDICATOR_ID		NUMBER(10, 0)	NOT NULL,
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PLUGIN_ID 				NUMBER(10, 0)  	NOT NULL,
	LOOKUP_KEY				VARCHAR2(64)	NOT NULL,
	LABEL					VARCHAR2(128)	NOT NULL,
	POS						NUMBER(10, 0)	NULL,
	CONSTRAINT PK_PLUGIN_INDICATOR PRIMARY KEY (PLUGIN_INDICATOR_ID)
);
				
ALTER TABLE CSR.PLUGIN_INDICATOR ADD CONSTRAINT FK_PLUGIN_IND_APP FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER(APP_SID);
ALTER TABLE CSR.PLUGIN_INDICATOR ADD CONSTRAINT FK_PLUGININD_PLUGINID FOREIGN KEY(PLUGIN_ID) REFERENCES CSR.PLUGIN(PLUGIN_ID);

CREATE TABLE CSRIMP.PLUGIN_INDICATOR (
	CSRIMP_SESSION_ID 		NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PLUGIN_INDICATOR_ID		NUMBER(10, 0)	NOT NULL,
	PLUGIN_ID 				NUMBER(10, 0)  	NOT NULL,
	LOOKUP_KEY				VARCHAR2(64)	NOT NULL,
	LABEL					VARCHAR2(128)	NOT NULL,
	POS						NUMBER(10, 0)	NULL,
	CONSTRAINT PK_PLUGIN_INDICATOR PRIMARY KEY (CSRIMP_SESSION_ID, PLUGIN_INDICATOR_ID),
	CONSTRAINT FK_PLUGIN_IND_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


CREATE TABLE csrimp.map_plugin_ind (
	CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_plugin_ind_id   NUMBER(10) NOT NULL,
	new_plugin_ind_id   NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_plugin_ind primary key (csrimp_session_id, old_plugin_ind_id) USING INDEX,
	CONSTRAINT uk_map_plugin_ind unique (csrimp_session_id, new_plugin_ind_id) USING INDEX,
	CONSTRAINT fk_map_plugin_ind_is FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

-- RLS for new plugin table
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'PLUGIN_INDICATOR',
			policy_name     => SUBSTR('PLUGIN_INDICATOR', 1, 23)||'_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
			DBMS_OUTPUT.PUT_LINE('Policy added to PLUGIN_INDICATOR');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for CSR.PLUGIN_INDICATOR');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for PLUGIN_INDICATOR as feature not enabled');
	END;
	
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSRIMP',
			object_name     => 'PLUGIN_INDICATOR',
			policy_name     => SUBSTR('PLUGIN_INDICATOR', 1, 23)||'_POLICY',
			function_schema => 'CSRIMP',
			policy_function => 'sessionidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
			DBMS_OUTPUT.PUT_LINE('Policy added to PLUGIN_INDICATOR');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for CSRIMP.PLUGIN_INDICATOR');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for PLUGIN_INDICATOR as feature not enabled');
	END;
END;
/

GRANT SELECT,INSERT,UPDATE ON csr.PLUGIN_INDICATOR TO csrimp;
GRANT SELECT ON csr.plugin_ind_id_seq TO csrimp;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.plugin_indicator TO web_user;

ALTER TABLE csr.calendar ADD plugin_id NUMBER(10,0) NULL;

EXEC DBMS_OUTPUT.PUT_LINE('Create temp proc to move calendar data.');
CREATE OR REPLACE PROCEDURE csr.MoveCalendarToPlugin(
	in_js_class				csr.calendar.js_class_type%TYPE,
	in_js_include			csr.calendar.js_include%TYPE,
	in_plugin_type_id		csr.plugin_type.plugin_type_id%TYPE
)
AS
	v_js_class_cs			csr.calendar.js_class_type%TYPE;
	v_js_include_cs			csr.calendar.js_include%TYPE;
	v_description			csr.calendar.description%TYPE;
	v_default_cs_class		csr.plugin.cs_class%TYPE := 'Credit360.Plugins.PluginDto';
	v_plugin_id				csr.plugin.plugin_id%TYPE;
BEGIN
	SELECT js_include, js_class_type, description
	  INTO v_js_include_cs, v_js_class_cs, v_description
	  FROM csr.calendar
	 WHERE UPPER(js_include) = in_js_include
	   AND UPPER(js_class_type) = in_js_class
	   AND ROWNUM < 2;
	
	DBMS_OUTPUT.PUT_LINE('----- ADD ' || UPPER(v_description) || ' -------');

	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
			 VALUES (csr.plugin_id_seq.nextval, in_plugin_type_id, v_description,  v_js_include_cs, v_js_class_cs, v_default_cs_class)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE csr.plugin 
		   SET description = v_description,
		   	   js_include = v_js_include_cs,
		   	   cs_class = v_default_cs_class
		 WHERE plugin_type_id = in_plugin_type_id
		   AND js_class = v_js_class_cs
	    	   RETURNING plugin_id INTO v_plugin_id;
	END;
						
	DBMS_OUTPUT.PUT_LINE('Plugin added');
											
	UPDATE csr.calendar
	   SET plugin_id = v_plugin_id
	 WHERE UPPER(js_class_type) = UPPER(v_js_class_cs)
	   AND UPPER(js_include) = UPPER(v_js_include_cs);
	   
    DBMS_OUTPUT.PUT_LINE('Calendar table updated');
	
END;
/

-- Update calendar to have new plugin ID - have to create plugins for the existing
-- calendar items first.
DECLARE
	v_plugin_type_id				csr.plugin_type.plugin_type_id%TYPE;
	v_max_id						csr.plugin_type.plugin_type_id%TYPE;
BEGIN
	DBMS_OUTPUT.PUT_LINE('Add plug-in ID to calendar if not there.');
	DBMS_OUTPUT.PUT_LINE('For any calendar items not linked to a plug-in, create a corresponding plug-in');

	BEGIN
		SELECT plugin_type_id
		  INTO v_plugin_type_id
		  FROM csr.plugin_type
		 WHERE UPPER(description) = UPPER('Calendar');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN	
			SELECT MAX(plugin_type_id)
			  INTO v_max_id
			  FROM csr.plugin_type;
			  
			v_plugin_type_id := v_max_id + 1;
		
			INSERT INTO csr.plugin_type (plugin_type_id, description)
			VALUES (v_plugin_type_id, 'Calendar');
	END;

	FOR r IN (
		SELECT DISTINCT js_class, js_include FROM (
			SELECT UPPER(js_class_type) js_class, UPPER(js_include) js_include 
			  FROM csr.calendar
			 WHERE plugin_id IS NULL
		)
	) LOOP
		csr.MoveCalendarToPlugin(r.js_class, r.js_include, v_plugin_type_id);
	END LOOP;
	
	UPDATE csr.plugin
	   SET cs_class = 'Credit360.Chain.Activities.ActivityCalendarDto'
	 WHERE UPPER(description) = 'ACTIVITIES';
	  
	UPDATE csr.plugin
	   SET cs_class = 'Credit360.Issues.IssueCalendarDto'
	 WHERE UPPER(description) = 'ISSUES COMING DUE';	
END;
/

ALTER TABLE csr.calendar MODIFY (plugin_id NOT NULL);
ALTER TABLE csr.calendar ADD CONSTRAINT fk_calendar_plugin FOREIGN KEY(plugin_id) REFERENCES csr.plugin(plugin_id);
	
EXEC DBMS_OUTPUT.PUT_LINE('Drop temp procedure');
DROP PROCEDURE csr.MoveCalendarToPlugin;

-- Calendar is ignored by CSRIMP for some reason, so nothing to do here.

--Update packages

@../calendar_pkg
@../plugin_pkg
@../supplier_pkg
@../schema_pkg
@../chain/activity_pkg

@../calendar_body
@../initiative_body
@../plugin_body
@../teamroom_body
@../supplier_body
@../schema_body
@../csrimp/imp_body
@../chain/activity_body
@../chain/company_body

-- Run chain_setup_pkg.SetupVolumePlugin to create the volume plug-in and chain_setup_pkg.SetupCalendars to register the activities calendar if required.

@update_tail

