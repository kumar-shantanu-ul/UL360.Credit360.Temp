-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=12
@update_header
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

-- *** DDL ***
-- Create tables
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner = 'CMS'
		   AND table_name IN ('DOC_TEMPLATE_FILE', 'DOC_TEMPLATE_VERSION', 'DOC_TEMPLATE')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE CMS.' || r.table_name || ' CASCADE CONSTRAINTS';
	END LOOP;
END;
/

CREATE TABLE CMS.DOC_TEMPLATE (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DOC_TEMPLATE_ID			NUMBER(10) NOT NULL,
	NAME					VARCHAR2(128) NOT NULL,
	LOOKUP_KEY				VARCHAR2(128) NOT NULL,
	LANG					VARCHAR2(10),
	CONSTRAINT PK_DOC_TEMPLATE PRIMARY KEY (APP_SID, DOC_TEMPLATE_ID),
	CONSTRAINT UK_DOC_TEMPLATE UNIQUE (APP_SID, LOOKUP_KEY, LANG)
);

CREATE TABLE CMS.DOC_TEMPLATE_FILE (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DOC_TEMPLATE_FILE_ID	NUMBER(10) NOT NULL,
	FILE_NAME				VARCHAR2(256),
	FILE_MIME				VARCHAR2(256),
	FILE_DATA				BLOB,
	UPLOADED_DTM			DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_DOC_TEMPLATE_FILE PRIMARY KEY (APP_SID, DOC_TEMPLATE_FILE_ID)
);

CREATE TABLE CMS.DOC_TEMPLATE_VERSION (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DOC_TEMPLATE_ID			NUMBER(10) NOT NULL,
	VERSION					NUMBER(10) NOT NULL,
	COMMENTS				CLOB NOT NULL,
	DOC_TEMPLATE_FILE_ID	NUMBER(10) NOT NULL,
	LOG_DTM					DATE DEFAULT SYSDATE NOT NULL,
	USER_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
	PUBLISHED_DTM			DATE,
	ACTIVE					NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_CMS_DOC_TEMPLATE_VERSION PRIMARY KEY (APP_SID, DOC_TEMPLATE_ID, VERSION)
);

BEGIN
	FOR r IN (
		SELECT sequence_name
		  FROM all_sequences
		 WHERE sequence_owner = 'CMS'
		   AND sequence_name IN ('DOC_TEMPLATE_ID_SEQ', 'DOC_TEMPLATE_FILE_ID_SEQ')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP SEQUENCE CMS.' || r.sequence_name;
	END LOOP;
END;
/

CREATE SEQUENCE CMS.DOC_TEMPLATE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

CREATE SEQUENCE CMS.DOC_TEMPLATE_FILE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

-- CSR IMP/EXP TABLES
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner = 'CSRIMP'
		   AND table_name IN ('MAP_DOC_TEMPLATE', 'MAP_DOC_TEMPLATE_FILE', 'CMS_DOC_TEMPLATE_VERSION', 'CMS_DOC_TEMPLATE_FILE', 'CMS_DOC_TEMPLATE')
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE CSRIMP.' || r.table_name || ' CASCADE CONSTRAINTS';
	END LOOP;
END;
/

CREATE TABLE csrimp.map_cms_doc_template (
	CSRIMP_SESSION_ID		NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_template_id		NUMBER(10)	NOT NULL,
	new_doc_template_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_doc_template PRIMARY KEY (csrimp_session_id, old_doc_template_id) USING INDEX,
	CONSTRAINT uk_map_doc_template UNIQUE (csrimp_session_id, new_doc_template_id) USING INDEX,
    CONSTRAINT fk_map_doc_template_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_doc_template_file (
	csrimp_session_id			NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_template_file_id	NUMBER(10)	NOT NULL,
	new_doc_template_file_id	NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_doc_template_file PRIMARY KEY (csrimp_session_id, old_doc_template_file_id) USING INDEX,
	CONSTRAINT uk_map_doc_template_file UNIQUE (csrimp_session_id, new_doc_template_file_id) USING INDEX,
    CONSTRAINT fk_map_doc_template_file_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CMS_DOC_TEMPLATE (
	CSRIMP_SESSION_ID		NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DOC_TEMPLATE_ID			NUMBER(10)		NOT NULL,
	NAME					VARCHAR2(128)	NOT NULL,
	LOOKUP_KEY				VARCHAR2(128)	NOT NULL,
	LANG					VARCHAR2(10),
	CONSTRAINT PK_CMS_DOC_TEMPLATE PRIMARY KEY (CSRIMP_SESSION_ID, DOC_TEMPLATE_ID),
	CONSTRAINT UK_CMS_DOC_TEMPLATE UNIQUE (CSRIMP_SESSION_ID, LOOKUP_KEY, LANG),
	CONSTRAINT FK_CMS_DOC_TEMPLATE FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CMS_DOC_TEMPLATE_FILE (
	CSRIMP_SESSION_ID		NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DOC_TEMPLATE_FILE_ID	NUMBER(10)	NOT NULL,
	FILE_NAME				VARCHAR2(256),
	FILE_MIME				VARCHAR2(256),
	FILE_DATA				BLOB,
	UPLOADED_DTM			DATE		NOT NULL,
	CONSTRAINT PK_CMS_DOC_TEMPLATE_FILE PRIMARY KEY (CSRIMP_SESSION_ID, DOC_TEMPLATE_FILE_ID),
	CONSTRAINT FK_CMS_DOC_TEMPLATE_FILE FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CMS_DOC_TEMPLATE_VERSION (
	CSRIMP_SESSION_ID		NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DOC_TEMPLATE_ID			NUMBER(10)	NOT NULL,
	VERSION					NUMBER(10)	NOT NULL,
	COMMENTS				CLOB		NOT NULL,
	DOC_TEMPLATE_FILE_ID	NUMBER(10)	NOT NULL,
	LOG_DTM					DATE		NOT NULL,
	USER_SID				NUMBER(10)	NOT NULL,
	PUBLISHED_DTM			DATE,
	ACTIVE					NUMBER(1)	NOT NULL,
	CONSTRAINT PK_CMS_DOC_TEMPLATE_VERS PRIMARY KEY (CSRIMP_SESSION_ID, DOC_TEMPLATE_ID, VERSION),
	CONSTRAINT FK_CMS_DOC_TEMPLATE_VERSION FOREIGN KEY 
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables
GRANT SELECT, REFERENCES ON ASPEN2.TRANSLATION_SET TO CMS WITH GRANT OPTION;

ALTER TABLE	CMS.DOC_TEMPLATE ADD CONSTRAINT FK_DOC_TEMPLATE_LANG
	FOREIGN KEY (APP_SID, LANG) REFERENCES ASPEN2.TRANSLATION_SET (APPLICATION_SID, LANG);

ALTER TABLE	CMS.DOC_TEMPLATE_VERSION ADD CONSTRAINT FK_DOC_TEMPLATE_VERSION_FILE
	FOREIGN KEY (APP_SID, DOC_TEMPLATE_FILE_ID) REFERENCES CMS.DOC_TEMPLATE_FILE (APP_SID, DOC_TEMPLATE_FILE_ID);

-- *** Grants ***
grant insert on cms.doc_template to csrimp;
grant insert on cms.doc_template_file to csrimp;
grant insert on cms.doc_template_version to csrimp;

grant select on cms.doc_template_id_seq to csrimp;
grant select on cms.doc_template_file_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	--Create the menu item for all sites
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
	
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			v_setup_menu				security.security_pkg.T_SID_ID;
			v_cms_template_menu			security.security_pkg.T_SID_ID;
			
		BEGIN
			BEGIN
				v_setup_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Setup');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_menu, 'setup',  'Setup',  '/csr/site/admin/config/global.acds',  0, null, v_setup_menu);
			END;
		
			BEGIN
				v_cms_template_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_setup_menu, 'cms_admin_doctemplates');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_setup_menu, 'cms_admin_doctemplates',  'CMS document template manager',  '/fp/cms/admin/doctemplates/list.acds',  0, null, v_cms_template_menu);
			END;
			
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_cms_template_menu, 0);
			--Remove inherited ones
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_cms_template_menu));
			-- Add SA permission
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_cms_template_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		END;
	END LOOP;
	
	security.user_pkg.logonadmin;
	
END;
/

-- ** New package grants **
grant select,insert,update,delete on csrimp.cms_doc_template  to tool_user;
grant select,insert,update,delete on csrimp.cms_doc_template_file  to tool_user;
grant select,insert,update,delete on csrimp.cms_doc_template_version  to tool_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/doc_template_pkg
@../../../aspen2/cms/db/tab_pkg

@../../../aspen2/cms/db/doc_template_body
@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

GRANT EXECUTE ON cms.doc_template_pkg TO web_user;


@update_tail
