-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE cms.form_staging (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    lookup_key     			VARCHAR2(255) NOT NULL,
    description				VARCHAR2(2000) NOT NULL,
    file_name				VARCHAR2(255) NOT NULL,
    form_xml       			XMLTYPE NOT NULL,
    CONSTRAINT PK_FORM_STAGING PRIMARY KEY (app_sid, lookup_key)
);

CREATE TABLE cms.form_version(
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	form_sid				NUMBER(10) NOT NULL,
	form_version			NUMBER(10) NOT NULL,
	file_name				VARCHAR2(255) NOT NULL,
	form_xml				XMLTYPE NOT NULL,
	published_dtm			DATE DEFAULT SYSDATE NOT NULL,
	published_by_sid		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	version_comment			VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_FORM_VERSION PRIMARY KEY (app_sid, form_sid, form_version),
	CONSTRAINT FK_FORM_VERSION FOREIGN KEY (app_sid, form_sid) REFERENCES cms.form (app_sid, form_sid)
);

-- Alter tables
ALTER TABLE cms.form ADD(
	current_version			NUMBER(10),
	is_report_builder		NUMBER(1)  DEFAULT 0 NOT NULL,
	draft_form_xml			XMLTYPE,
	draft_file_name			VARCHAR2(255),
	short_path				VARCHAR2(255),
	use_quick_chart			NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT CK_FORM_USE_QUICK_CHART CHECK (use_quick_chart IN (0,1)),
	CONSTRAINT CK_FORM_IS_REPORT_BUILDER_1_0 CHECK (is_report_builder IN (0,1))
);


ALTER TABLE cms.form RENAME COLUMN form_xml TO xx_form_xml;
ALTER TABLE cms.form MODIFY xx_form_xml NULL;

-- Move all existing form records to new versioning structure. Insert required here for DDL.
INSERT INTO cms.form_version (app_sid, form_sid, form_version, file_name, form_xml, published_dtm, published_by_sid, version_comment)
SELECT app_sid, form_sid, 1, description, xx_form_xml, sysdate, 3, 'Initial version'
  FROM cms.form;

UPDATE cms.form SET current_version = 1, is_report_builder = 1;

ALTER TABLE cms.form ADD CONSTRAINT FK_FORM_FORM_VERSION 
	FOREIGN KEY (app_sid, form_sid, current_version) 
	REFERENCES cms.form_version(app_sid, form_sid, form_version) 
	DEFERRABLE INITIALLY DEFERRED;

CREATE UNIQUE INDEX CMS.IDX_FORM_SHORT_PATH ON cms.form (app_sid, NVL(LOWER(short_path), TO_CHAR(form_sid)));

ALTER TABLE csrimp.cms_form DROP COLUMN form_xml;
ALTER TABLE csrimp.cms_form ADD (	
	current_version			NUMBER(10),
	is_report_builder		NUMBER(1) NOT NULL,
	draft_form_xml			XMLTYPE,
	draft_file_name			VARCHAR2(255),
	short_path				VARCHAR2(255),
	use_quick_chart			NUMBER(1) NOT NULL,
	CONSTRAINT CK_CMS_FORM_USE_QUICK_CHART CHECK (USE_QUICK_CHART IN (0,1)),
	CONSTRAINT CK_FORM_IS_REPORT_BUILDER_1_0 CHECK (IS_REPORT_BUILDER IN (0,1))
);

CREATE TABLE CSRIMP.CMS_FORM_VERSION (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FORM_SID						NUMBER(10) NOT NULL,
	FORM_VERSION					NUMBER(10) NOT NULL,
	FILE_NAME						VARCHAR2(255) NOT NULL,
	FORM_XML						XMLTYPE NOT NULL,
	PUBLISHED_DTM					DATE NOT NULL,
	PUBLISHED_BY_SID				NUMBER(10) NOT NULL,
	VERSION_COMMENT					VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_FORM_VERSION PRIMARY KEY (CSRIMP_SESSION_ID, FORM_SID, FORM_VERSION),
	CONSTRAINT FK_CMS_FORM_VERSION_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

-- *** Grants ***
grant insert on cms.form_version to csrimp;
grant select,insert,update,delete on csrimp.cms_form_version to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- C:\cvs\aspen2\cms\db\create_views.sql
-- View gets the latest published version.
CREATE OR REPLACE VIEW cms.v$form AS
	SELECT f.app_sid, f.form_sid, f.description, f.lookup_key, f.parent_tab_sid, fv.form_version, f.current_version,
		   fv.file_name, fv.form_xml, fv.published_dtm, fv.published_by_sid, fv.version_comment, f.is_report_builder, f.short_path, f.use_quick_chart
	  FROM form f
	  JOIN form_version fv
		ON f.app_sid = fv.app_sid AND f.form_sid = fv.form_sid AND f.current_version = fv.form_version;
		

GRANT SELECT, REFERENCES ON cms.v$form TO csr;
-- *** Data changes ***

-- RLS

-- Data

-- Add wwwroot/forms web resource for sites that don't have one, add full aceess for superadmins
DECLARE
	v_act_id				security.security_pkg.T_ACT_ID;
	v_superadmins_sid		security.security_pkg.T_SID_ID;
	v_web_root_sid			security.security_pkg.T_SID_ID;
	v_web_forms_sid			security.security_pkg.T_SID_ID;
	v_registered_users_sid	security.security_pkg.T_SID_ID;
BEGIN
  security.user_pkg.logonAdmin();
  v_act_id := SYS_CONTEXT('SECURITY','ACT');
  v_superadmins_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, 0, '//csr/SuperAdmins');
  FOR r IN (
    SELECT host, app_sid
      FROM csr.customer
    ) LOOP
    BEGIN
      v_web_root_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, r.app_sid,'wwwroot');
      BEGIN
        v_web_forms_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_web_root_sid,'forms');
      EXCEPTION
        WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_web_root_sid, v_web_root_sid, 'forms', v_web_forms_sid);
			v_registered_users_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, r.app_sid,'Groups/RegisteredUsers');
			security.ACL_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSid(v_web_forms_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_registered_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
      END;
    END;
	security.ACL_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSid(v_web_forms_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
  END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@..\..\..\security\db\oracle\web_pkg
@@..\..\..\aspen2\cms\db\form_pkg
@@..\..\..\aspen2\cms\db\tab_pkg

@@..\campaign_body
@@..\templated_report_body
@@..\..\..\security\db\oracle\web_body
@@..\..\..\aspen2\cms\db\form_body
@@..\..\..\aspen2\cms\db\tab_body
@@..\csrimp\imp_body

@update_tail
