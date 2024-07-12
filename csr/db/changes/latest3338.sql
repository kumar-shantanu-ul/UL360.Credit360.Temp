define version=3338
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



ALTER TABLE csr.AUTO_EXP_RETRIEVAL_DATAVIEW ADD (
   IND_SELECTION_TYPE_ID             NUMBER(10, 0)    DEFAULT 0 NOT NULL
);










DECLARE
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	
	FOR r IN (
		SELECT m.sid_id
		  FROM security.menu m
		  JOIN security.securable_object so ON so.sid_id = m.sid_id
		  JOIN csr.customer c ON c.app_sid = so.application_sid_id
		 WHERE LOWER(action) LIKE '%pending%'
	) LOOP
		security.securableobject_pkg.deleteso(v_act, r.sid_id);
	END LOOP;
END;
/
BEGIN
	FOR r IN (
		SELECT tab_portlet_id
		  FROM csr.tab_portlet
		 WHERE customer_portlet_sid in (
			SELECT customer_portlet_sid
			  FROM csr.customer_portlet
			 WHERE portlet_id = 204
		)
	) LOOP
		DELETE FROM csr.TAB_PORTLET_RSS_FEED
		 WHERE tab_portlet_id = r.tab_portlet_id;
		DELETE FROM csr.TAB_PORTLET_USER_REGION
		 WHERE tab_portlet_id = r.tab_portlet_id;
		DELETE FROM csr.USER_SETTING_ENTRY
		 WHERE tab_portlet_id = r.tab_portlet_id;
		DELETE FROM csr.TAB_PORTLET
		 WHERE tab_portlet_id = r.tab_portlet_id;
	END LOOP;
	DELETE FROM csr.customer_portlet
	 WHERE portlet_id = 204;
	DELETE FROM csr.portlet WHERE portlet_id = 204;
END;
/






@..\csr_data_pkg
@..\automated_export_pkg
@..\dataview_pkg
@..\customer_pkg
@..\issue_pkg
@..\schema_pkg


@..\automated_export_body
@..\dataview_body
@..\customer_body
@..\region_body
@..\issue_body
@..\schema_body



@update_tail
