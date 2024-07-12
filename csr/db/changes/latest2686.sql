-- Please update version.sql too -- this keeps clean builds in sync
define version=2686
@update_header
-- Data changes:

/* FB 63250 Direct access - permission restrictions to Export functionality

----------------------------------------------------------------------------------
-- Create new securable object type for CMS containers
----------------------------------------------------------------------------------*/
grant update on security.acl to csr;

@latest2686_packages

DECLARE
	v_act           			security.security_pkg.T_ACT_ID;
    v_CmsContainer_id			SECURITY.Security_Pkg.T_CLASS_ID;
	v_check						NUMBER(1);
	v_export_permission			security.Security_Pkg.T_PERMISSION;
	v_bulk_export_permission	security.Security_Pkg.T_PERMISSION;
BEGIN   
    security.user_pkg.logonadmin;
	v_act := SYS_CONTEXT('SECURITY','ACT');
	
	DBMS_OUTPUT.PUT_LINE('Create SO class CmsContainer.');
	BEGIN
		security.class_pkg.CreateClass(
			in_act_id			=>  v_act,
			in_parent_class_id	=>  security.Security_Pkg.SO_CONTAINER,
			in_class_name		=>  'CmsContainer',
			in_helper_pkg		=>  NULL,
			in_helper_prog_id	=>  NULL,
			out_class_id		=>  v_CmsContainer_id
		);
		
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			DBMS_OUTPUT.PUT_LINE('SO class CmsContainer aleady exists.');
			v_CmsContainer_id := security.class_pkg.GetClassId('CmsContainer');
	END;
	
	-- Add new permission on to CmsContainer and CmsTable
	-- This will deliberately fail if soneone has used permission 65536 or 131072 for CmsTable
	v_export_permission := 65536;
	csr.fb63250_pkg.AddCmsPermission(v_export_permission, 'Export');

	v_bulk_export_permission := 131072;
	csr.fb63250_pkg.AddCmsPermission(v_bulk_export_permission, 'Bulk export');
	
	
	-- Turn every 'cms' Container under each application into a CmsContainer
	-- Set the permission 'Allow export' for every group which currently has READ permissions
	FOR r IN (
		SELECT so.sid_id cms_sid_id, 
				so.class_id, 
				c.host, 
				c.app_sid
		  FROM csr.customer c
		  JOIN security.website ws ON LOWER(c.host) = LOWER(ws.website_name)
		  JOIN security.securable_object so
					 ON c.app_sid = so.parent_sid_id
					AND LOWER(so.name) = 'cms'
					AND so.class_id = security.Security_Pkg.SO_CONTAINER
	  ORDER BY c.host
	)
	LOOP
		DBMS_OUTPUT.PUT_LINE('Processing ' || r.host);
		security.user_pkg.LogonAdmin(r.host);
		v_act := security.security_pkg.GetAct;
		
		DBMS_OUTPUT.PUT_LINE('Convert Cms to CmsContainer class');
		UPDATE security.securable_object
		   SET class_id = v_CmsContainer_id
		 WHERE sid_id = r.cms_sid_id
		   AND application_sid_id = SYS_CONTEXT('SECURITY', 'APP');


		DBMS_OUTPUT.PUT_LINE('Stop Cms Container from inheriting permissions');
		security.securableobject_pkg.ClearFlag(v_act, r.cms_sid_id, security.Security_pkg.SOFLAG_INHERIT_DACL);
		
		-- Clear Inherited flag on current permissions (It's like we've unchecked inherit then chosen "Copy ACES" in secmgr)
		UPDATE security.acl
		SET ace_flags = bitand(ace_flags, security.Bitwise_Pkg.bitnot(security.Security_pkg.ACE_FLAG_INHERITED))
		WHERE acl_id = security.acl_pkg.GetDACLIDForSID(r.cms_sid_id);
		

		DBMS_OUTPUT.PUT_LINE('Add permissions to CmsContainer SO');
		csr.fb63250_pkg.AddToCmsContainer(
			in_permission			=> v_export_permission,
			in_cms_container_so		=> r.cms_sid_id
		);

		csr.fb63250_pkg.AddToCmsContainer(
			in_permission			=> v_bulk_export_permission,
			in_cms_container_so		=> r.cms_sid_id
		);

		security.acl_pkg.PropogateACEs(security.Security_pkg.GetAct, r.cms_sid_id);
	
		-- Add permissions to CmsTables in case there are bespoke permissions saved lower down
		DBMS_OUTPUT.PUT_LINE('Add permissions to CmsTables SO');
		csr.fb63250_pkg.AddToCmsTables(
			in_permission			=> v_export_permission,
			in_cms_container_so		=> r.cms_sid_id
		);

		csr.fb63250_pkg.AddToCmsTables(
			in_permission			=> v_bulk_export_permission,
			in_cms_container_so		=> r.cms_sid_id
		);
		
	END LOOP;
	
END;
/

DROP PACKAGE csr.fb63250_pkg;

revoke update on security.acl from csr;

COMMIT;

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
