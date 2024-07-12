-- Please update version.sql too -- this keeps clean builds in sync
define version=960;
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback
--ADD New SID
ALTER TABLE csr.customer_portlet ADD (customer_portlet_sid NUMBER(10));
ALTER TABLE csr.tab_portlet ADD (customer_portlet_sid NUMBER(10));
INSERT INTO csr.portlet (portlet_id, NAME, TYPE, default_state, script_path) 
	VALUES (0, 'Access Denied', 'Credit360.Portlets.AccessDeniedPortlet', null, '/csr/site/portal/Portlets/AccessDeniedPortlet.js'); 

GRANT EXECUTE ON csr.portlet_pkg TO SECURITY;

--Reconnect Data
DECLARE
	v_sid           security.security_pkg.T_SID_ID;
	v_container     security.security_pkg.T_SID_ID;
	v_portlet_cls   security.security_pkg.T_CLASS_ID;
	CURSOR cp_cur IS SELECT portlet_id
			   FROM csr.customer_portlet
			  WHERE customer_portlet_sid IS NULL
			    AND app_sid = sys_context('SECURITY', 'APP')
			    FOR UPDATE OF customer_portlet_sid;
BEGIN 
  security.user_pkg.LogonAdmin();

  security.class_pkg.CreateClass(
    sys_context('SECURITY','ACT'),
    NULL, --Parent
    'CSRPortlet',
    NULL,--Helper
    NULL, --Helper_Prog_ID
    v_portlet_cls
  );

  FOR app IN (SELECT DISTINCT host FROM csr.customer c JOIN csr.customer_portlet p ON c.app_sid = p.app_sid JOIN security.website w ON LOWER(w.website_name) = LOWER(c.host))
  LOOP
    security.user_pkg.LogonAdmin(app.host);

	BEGIN
		v_container := security.securableobject_pkg.GetSidFromPath(sys_context('SECURITY','ACT'), sys_context('SECURITY','APP'), 'Portlets');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(sys_context('SECURITY','ACT'), sys_context('SECURITY','APP'), security.security_pkg.SO_CONTAINER, 'Portlets', v_container);
			
			security.acl_pkg.AddACE(sys_context('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_container), security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
				security.securableobject_pkg.GetSIDFromPath(sys_context('SECURITY','ACT'),sys_context('SECURITY','APP'),'Groups/RegisteredUsers'),
				security.security_pkg.PERMISSION_STANDARD_READ);
	END;

    --Fill in new sid column
    FOR r IN cp_cur
    LOOP
      security.securableobject_pkg.CreateSO(sys_context('SECURITY','ACT'), v_container, v_portlet_cls, r.portlet_id, v_sid);
      UPDATE csr.customer_portlet SET customer_portlet_sid = v_sid 
       WHERE CURRENT OF cp_cur;
    END LOOP;	
  END LOOP;
  
  security.user_pkg.Logoff(sys_context('SECURITY', 'ACT'));

  UPDATE csr.tab_portlet tp SET tp.customer_portlet_sid = (
                SELECT cp.customer_portlet_sid
                  FROM csr.customer_portlet cp
                WHERE cp.portlet_id = tp.portlet_id and cp.app_sid = tp.app_sid
  );

  -- Deal with apps that don't exist as websites anymore but for which we still hold data.

  DELETE FROM csr.customer_portlet WHERE customer_portlet_sid IS NULL;
  DELETE FROM csr.tab_portlet WHERE customer_portlet_sid IS NULL;
END;
/

ALTER TABLE csr.customer_portlet MODIFY (customer_portlet_sid NOT NULL ENABLE);
ALTER TABLE csr.tab_portlet MODIFY (customer_portlet_sid NOT NULL ENABLE);
--MAKE SID PK with APP_SID
ALTER TABLE csr.customer_portlet DROP PRIMARY KEY DROP INDEX;

ALTER TABLE csr.customer_portlet ADD CONSTRAINT PK_CUSTOMER_PORTLET PRIMARY KEY (app_sid, customer_portlet_sid) ENABLE;
--REMOVE FK from portlet_ID
ALTER TABLE csr.tab_portlet DROP CONSTRAINT REFPORTLET799;
--ADD FK to SID
ALTER TABLE csr.tab_portlet ADD CONSTRAINT FK_CUSTOMER_PORTLET FOREIGN KEY (app_sid, customer_portlet_sid)
	  REFERENCES csr.customer_portlet (app_sid, customer_portlet_sid) ENABLE;
-- This can go eventually
ALTER TABLE csr.tab_portlet RENAME COLUMN portlet_id TO portlet_id_old;
ALTER TABLE csr.tab_portlet MODIFY (portlet_id_old NULL);
DROP INDEX csr.ix_cust_portlet_portlet;

@../portlet_pkg
@../portlet_body

UPDATE security.securable_object_class SET helper_pkg = 'csr.portlet_pkg' WHERE class_name = 'CSRPortlet';

@update_tail
