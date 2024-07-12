-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=32
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 21, 'Permit applications tab', '/csr/site/compliance/controls/PermitApplicationTab.js', 'Credit360.Compliance.Controls.PermitApplicationTab', 'Credit360.Compliance.Plugins.PermitApplicationTab', 'Shows all of the applications for a permit.');

DECLARE
	v_plugin_id						NUMBER;
BEGIN 
	security.user_pkg.logonadmin();
	
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM csr.plugin
	 WHERE js_class = 'Credit360.Compliance.Controls.PermitApplicationTab';
	
	FOR r IN (
		SELECT co.app_sid, c.host
		  FROM csr.compliance_options co 
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE permit_flow_sid IS NOT NULL
	) LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
		
			INSERT INTO csr.compliance_permit_tab (plugin_type_id, plugin_id, pos, tab_label)
				VALUES (21, v_plugin_id, 2, 'Applications');
				
			-- default access
			INSERT INTO csr.compliance_permit_tab_group (plugin_id, group_sid)
				 VALUES (
					v_plugin_id, 
					security.securableobject_pkg.GetSidFromPath(
						security.security_pkg.GetAct, 
						r.app_sid, 
						'groups/RegisteredUsers'
					)
				);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.compliance_permit_tab
				   SET tab_label = 'Applications',
					   pos = 2
				 WHERE plugin_id = v_plugin_id;
		END;
	END LOOP;
	
	security.user_pkg.logonadmin();
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../permit_pkg
@../permit_body
@../enable_body

@update_tail
