PROMPT > Enter host:
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback
--PROMPT > Enter service name (e.g. ASPEN):

-- test data
DECLARE
	v_act_id			security.security_pkg.T_ACT_ID;
	v_app_sid			security.security_pkg.T_SID_ID;
	-- groups
	v_class_id				security.security_pkg.T_CLASS_ID;
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_supplier_users_sid	security.security_pkg.T_SID_ID;
	v_supplier_admins_sid	security.security_pkg.T_SID_ID;
	v_auditors_sid			security.security_pkg.T_SID_ID;
	v_admins_sid			security.security_pkg.T_SID_ID;
    -- menu
	v_menu  						security.security_pkg.T_SID_ID;
	v_menu_products				    security.security_pkg.T_SID_ID;
	v_menu_products_myproducts		security.security_pkg.T_SID_ID;
	v_menu_admin            		security.security_pkg.T_SID_ID;
	v_menu_admin_searchproduct 	    security.security_pkg.T_SID_ID;
	v_menu_admin_searchsupplier	    security.security_pkg.T_SID_ID;
	-- web resources	
	v_www           			    security.security_pkg.T_SID_ID;
	v_www_supplier 				    security.security_pkg.T_SID_ID;
	v_www_supplier_admin 	        security.security_pkg.T_SID_ID;
	-- containers
	v_supplier_sid 	        	    security.security_pkg.T_SID_ID;
	v_supplier_companies_sid        security.security_pkg.T_SID_ID;
	v_supplier_taggroups_sid        security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);
	v_app_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, '//aspen/applications/&&1');
	security.security_pkg.SetACT(v_act_id, v_app_sid);
	-- read groups
	v_groups_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_auditors_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Auditors');
    v_admins_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
    -- create groups
    v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
    begin
        security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Supplier Users', v_class_id, v_supplier_users_sid);
    exception
        when security.security_pkg.DUPLICATE_OBJECT_NAME then
            v_supplier_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Supplier Users');
    end;
    begin
        security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Supplier Admins', v_class_id, v_supplier_admins_sid);
    exception
        when security.security_pkg.DUPLICATE_OBJECT_NAME then
            v_supplier_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Supplier Admins');
    end;
    -- make supplier admins members of supplier users
    security.group_pkg.AddMember(v_act_id, v_supplier_admins_sid, v_supplier_users_sid);
    -- make admins members of supplier admins
    security.group_pkg.AddMember(v_act_id, v_admins_sid, v_supplier_admins_sid);
	--
	/* ADMIN MENU */
	-- add admin menu items (and grant supplier admins permissions)
	--
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin');
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_supplier_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	v_menu_admin_searchproduct := 130822;--security.menu_pkg.CreateMenu(v_act_id, v_menu_admin, 'supplier_admin_products',  'Products',  '/csr/site/supplier/admin/searchProduct.acds',  22, null, v_menu_admin_searchproduct);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_admin_searchproduct), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_supplier_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.menu_pkg.CreateMenu(v_act_id, v_menu_admin, 'supplier_admin_suppliers', 'Suppliers', '/csr/site/supplier/admin/searchSupplier.acds', 23, null, v_menu_admin_searchsupplier);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_admin_searchsupplier), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_supplier_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--
    security.acl_pkg.PropogateACEs(v_act_id, v_menu_admin);
	--
	/* PRODUCT MENU */
    -- add product menu items
	v_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu');
	security.menu_pkg.CreateMenu(v_act_id, v_menu, 'products', 'Products', '/csr/site/supplier/myProducts.acds', 6, null, v_menu_products);
	security.menu_pkg.CreateMenu(v_act_id, v_menu_products, 'supplier_myproducts', 'Questionnaires', '/csr/site/supplier/myProducts.acds', 1, null, v_menu_products_myproducts);
	--
	/*** add supplier users to TOP level menu options (inheritable) ***/
	-- top
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_products), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_supplier_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--
	security.acl_pkg.PropogateACEs(v_act_id, v_menu_products);
	--
	-- create web-resources
	v_www := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	-- create csr/site/supplier - this exists already probably
	BEGIN
        security.web_pkg.CreateResource(v_act_id, v_www, security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site'), 'supplier', v_www_supplier);
    EXCEPTION
        WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
            v_www_supplier := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site/supplier');
    END;
	-- now create /csr/site/supplier/admin
	security.web_pkg.CreateResource(v_act_id, v_www, v_www_supplier, 'admin', v_www_supplier_admin);

	--
	-- clear flag on supplier/admin and add supplier_admins
	security.securableobject_pkg.ClearFlag(v_act_id, v_www_supplier_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.AddACE(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_www_supplier_admin), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_supplier_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	--	
	-- add supplier users to supplier
	security.acl_pkg.AddACE(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_www_supplier), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_supplier_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
	security.acl_pkg.PropogateACEs(v_act_id, v_www_supplier);	
	
	/*** Create Supplier container ***/
	-- Supplier
	security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 
		'Supplier', v_supplier_sid);
		
	/*** Set permission for main Supplier container ***/ 
	-- Add ALL for Supplier Admins to Supplier
	security.acl_pkg.AddACE(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_supplier_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_supplier_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);	
	
	-- Add READ for Supplier Users to Supplier
	security.acl_pkg.AddACE(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_supplier_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_supplier_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
		
	
	/*** Create supplier sub containers ***/
	-- Companies
	security.securableobject_pkg.CreateSO(v_act_id, v_supplier_sid, security.security_pkg.SO_CONTAINER, 
		'Companies', v_supplier_companies_sid);
				
	-- TagGroups
	security.securableobject_pkg.CreateSO(v_act_id, v_supplier_sid, security.security_pkg.SO_CONTAINER, 
		'TagGroups', v_supplier_taggroups_sid);
		 	
	--
	security.acl_pkg.PropogateACEs(v_act_id, v_supplier_sid);		

    -- set up stuff in customer_options
    BEGIN
        INSERT INTO supplier.customer_options
            (app_sid)
        VALUES
            (v_app_sid);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN 
			NULL;
    END;	


	commit;
END;
/
exit
