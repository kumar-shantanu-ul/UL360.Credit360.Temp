-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE  "CSR"."IMAGE_UPLOAD_PORTLET_SEQ"  MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 129 CACHE 20 NOORDER  NOCYCLE;

CREATE TABLE CSR.IMAGE_UPLOAD_PORTLET(
  APP_SID     NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
  IMG_ID      NUMBER(10) 		NOT NULL,
  FILE_NAME   VARCHAR(255) 	    NOT NULL,
  IMAGE       BLOB  			NOT NULL,
  MIME_TYPE   VARCHAR(255) 		NOT NULL,
	CONSTRAINT PK_IMAGE_UPLOAD_PORTLET PRIMARY KEY (APP_SID, IMG_ID)
);


CREATE TABLE CSRIMP.IMAGE_UPLOAD_PORTLET (
	CSRIMP_SESSION_ID 	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	FILE_NAME 			VARCHAR2(255) NOT NULL,
	IMAGE BLOB 			NOT NULL,
	IMG_ID 				NUMBER(10,0) NOT NULL,
	MIME_TYPE 			VARCHAR2(255) NOT NULL,
	CONSTRAINT FK_IMAGE_UPLOAD_PORTLET_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_IMAGE_UPLOAD_PORTLET (
	CSRIMP_SESSION_ID 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IMAGE_UPLOAD_PORTLET_ID NUMBER(10) NOT NULL,
	NEW_IMAGE_UPLOAD_PORTLET_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_IMAGE_UPLOAD_PORTLET PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IMAGE_UPLOAD_PORTLET_ID) USING INDEX,
	CONSTRAINT UK_MAP_IMAGE_UPLOAD_PORTLET UNIQUE (CSRIMP_SESSION_ID, NEW_IMAGE_UPLOAD_PORTLET_ID) USING INDEX,
	CONSTRAINT FK_MAP_IMAGE_UPLOAD_PORTLET_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1058,'Image Upload Button', 'Credit360.Portlets.ImageUploadButton', EMPTY_CLOB(), '/csr/site/portal/Portlets/ImageUploadButton.js');

-- ** New package grants **
CREATE OR REPLACE PACKAGE CSR.IMAGE_UPLOAD_PORTLET_PKG AS END;
/

GRANT execute ON CSR.IMAGE_UPLOAD_PORTLET_PKG TO web_user;

GRANT SELECT, INSERT, UPDATE ON CSR.IMAGE_UPLOAD_PORTLET to csrimp;

GRANT SELECT ON CSR.IMAGE_UPLOAD_PORTLET_SEQ to csrimp;
GRANT SELECT ON CSR.IMAGE_UPLOAD_PORTLET_SEQ to csr;
-- *** Conditional Packages ***

-- *** Packages ***
@..\image_upload_portlet_pkg
@..\schema_pkg
@..\csrimp\imp_pkg

@..\image_upload_portlet_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
