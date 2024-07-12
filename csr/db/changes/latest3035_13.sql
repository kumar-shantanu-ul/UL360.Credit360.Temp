-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.user_measure_conversion AS
SELECT app_sid, csr_user_sid, measure_sid, measure_conversion_id
  FROM csr.last_used_measure_conversion
 WHERE measure_conversion_id IS NOT NULL;

CREATE OR REPLACE TYPE CSR.T_GENERIC_SO_ROW AS 
	OBJECT ( 
		sid_id 			NUMBER(10,0),
		description		VARCHAR2(255),
		position		NUMBER(10,0)
  );
/

CREATE OR REPLACE TYPE CSR.T_GENERIC_SO_TABLE AS 
  TABLE OF CSR.T_GENERIC_SO_ROW;
/

-- Alter tables
ALTER TABLE csr.user_measure_conversion ADD CONSTRAINT pk_user_measure_conversion PRIMARY KEY (app_sid, csr_user_sid, measure_sid);
ALTER TABLE csr.user_measure_conversion MODIFY app_sid DEFAULT SYS_CONTEXT('SECURITY', 'APP');
ALTER TABLE csr.user_measure_conversion MODIFY measure_conversion_id NOT NULL;

ALTER TABLE CSR.USER_MEASURE_CONVERSION ADD CONSTRAINT FK_MSRE_CONV_USER_MSRE_CONV
    FOREIGN KEY (APP_SID, MEASURE_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.USER_MEASURE_CONVERSION ADD CONSTRAINT FK_USER_USED_MEASURE_CONV
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

create index csr.ix_user_mea_measure_conv on csr.user_measure_conversion (app_sid, measure_conversion_id, measure_sid);
create index csr.ix_user_measure_user on csr.user_measure_conversion (app_sid, csr_user_sid);

-- CSR IMP CHANGES
DELETE FROM csrimp.last_used_measure_conversion WHERE measure_conversion_id IS NULL;
ALTER TABLE csrimp.last_used_measure_conversion RENAME TO user_measure_conversion;
ALTER TABLE csrimp.user_measure_conversion MODIFY measure_conversion_id NOT NULL;

ALTER TABLE CSRIMP.USER_MEASURE_CONVERSION DROP CONSTRAINT PK_LAST_USED_MEASURE_CONV;
ALTER TABLE CSRIMP.USER_MEASURE_CONVERSION ADD CONSTRAINT PK_USER_MEASURE_CONVERSION
	PRIMARY KEY (CSRIMP_SESSION_ID, CSR_USER_SID, MEASURE_SID);

ALTER TABLE CSRIMP.USER_MEASURE_CONVERSION DROP CONSTRAINT FK_LAST_USED_MEAS_CONV_IS;
ALTER TABLE CSRIMP.USER_MEASURE_CONVERSION ADD CONSTRAINT FK_USER_MEASURE_CONV_IS FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE;

-- DROP FKS ON CSR.LAST_USED_MEASURE_CONVERSION AND RENAME AS BACKUP FOR NOW
ALTER TABLE csr.last_used_measure_conversion DROP CONSTRAINT FK_MEASURE_LAST_USED_MEASURE;
ALTER TABLE csr.last_used_measure_conversion DROP CONSTRAINT FK_MSRE_CONV_LAST_USED_MSRE;
ALTER TABLE csr.last_used_measure_conversion DROP CONSTRAINT FK_USER_LAST_USED_MEASURE;

ALTER TABLE csr.last_used_measure_conversion RENAME TO xx_last_used_measure_conv;

-- *** Grants ***
grant insert on csr.user_measure_conversion to csrimp;
grant select,insert,update,delete on csrimp.user_measure_conversion to tool_user;


-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- Change My details menu action and add new web resource for registered users
DECLARE
	v_act_id 				security.security_pkg.T_ACT_ID;
	v_wwwroot_sid			security.security_pkg.T_SID_ID;
	v_www_csr_site			security.security_pkg.T_SID_ID;
	v_www_user_settings		security.security_pkg.T_SID_ID;
	v_registered_users		security.security_pkg.T_SID_ID;
	v_manage_templates		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	v_act_id := security.security_pkg.GetAct();
	
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer
	  ORDER BY host
	) LOOP
		BEGIN
			v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_wwwroot_sid, 'csr/site');
			v_registered_users := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'groups/RegisteredUsers');

			-- Add web resource for new folder
			BEGIN
				security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_www_csr_site, 'userSettings', v_www_user_settings);
				
				security.securableobject_pkg.SetFlags(v_act_id, v_www_user_settings, 0); -- unset inherited
				security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_user_settings));
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_user_settings), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_registered_users, security.security_pkg.PERMISSION_STANDARD_READ);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					null;
			END;

			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					NULL;
		END;

	END LOOP;
	
	-- Change menu actions
	FOR x IN (
		SELECT m.sid_id, m.description, m.action, REGEXP_REPLACE(m.action, '/csr/site/usersettings.acds', '/csr/site/usersettings/edit.acds', 1, 1, 'i') new_action
		  FROM security.menu m
		  JOIN security.securable_object so
				 ON m.sid_id = so.sid_id
		 WHERE LOWER(m.action) LIKE '/csr/site/usersettings.acds%'
	)
	LOOP
		security.menu_pkg.SetMenuAction(SYS_CONTEXT('security', 'act'), x.sid_id, x.new_action);
	END LOOP;
	
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../measure_pkg
@../schema_pkg

@../csr_app_body
@../csr_user_body
@../delegation_body
@../measure_body
@../schema_body
@../util_script_body
@../csrimp/imp_body

@update_tail
