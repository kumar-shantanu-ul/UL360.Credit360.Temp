-- Please update version.sql too -- this keeps clean builds in sync
define version=1972

@update_header

  CREATE TABLE CSR.SECTION_PLUGIN_LOOKUP (	
	APP_SID 		NUMBER(10,0) 	DEFAULT SYS_CONTEXT('security','app'), 
	PLUGIN_NAME 	VARCHAR2(255) 	NOT NULL, 
	FORM_PATH 		VARCHAR2(255) 	NOT NULL,
	TABLE_NAME		VARCHAR2(255) 	NOT NULL,
	TABLE_USER		VARCHAR2(255) 	NOT NULL,
	CONSTRAINT PK_SECTION_PLUGIN_LOOKUP 
		PRIMARY KEY (APP_SID, PLUGIN_NAME, FORM_PATH)
   );

   @../section_pkg
   @../section_body
   
@update_tail
