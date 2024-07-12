define version=3337
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

--Failed to locate all sections of latest3336_10.sql












DECLARE
	v_act	security.security_pkg.T_ACT_ID;
	v_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.regions', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/
INSERT INTO CSR.EGRID (EGRID_REF, NAME) VALUES ('PRMS', 'Puerto Rico Miscellaneous');
DECLARE
    v_flashMapPortletId csr.portlet.portlet_id%TYPE;
BEGIN
	-- Find the portlet we want to delete
    SELECT PORTLET_ID INTO v_flashMapPortletId
    FROM CSR.PORTLET
    WHERE TYPE = 'Credit360.Portlets.Map';
    
	-- Find all the customer portlets that use that portlet
    FOR cp IN (
        SELECT customer_portlet_sid
        FROM CSR.CUSTOMER_PORTLET
        WHERE PORTLET_ID = v_flashMapPortletId
        )
    LOOP
		-- Delete all instances of those customer portlets
        DELETE FROM CSR.TAB_PORTLET
        WHERE CUSTOMER_PORTLET_SID = cp.customer_portlet_sid;
        
		-- Delete the customer portlet
        DELETE FROM CSR.CUSTOMER_PORTLET
        WHERE CUSTOMER_PORTLET_SID = cp.customer_portlet_sid;
    END LOOP;
    
	-- Finally, delete the portlet itself
    DELETE FROM CSR.PORTLET
    WHERE PORTLET_ID = v_flashMapPortletId;
END;
/

DELETE FROM CSR.MODULE
WHERE ENABLE_SP = 'EnableMap';


@../scenario_body




@..\portlet_pkg
@..\supplier_pkg
@..\region_api_pkg
@..\enable_pkg


@..\enable_body
@..\portlet_body
@..\region_tree_body
@..\role_body
@..\supplier_body
@..\region_api_body
@..\audit_body
@..\indicator_body
@..\data_bucket_body



@update_tail
