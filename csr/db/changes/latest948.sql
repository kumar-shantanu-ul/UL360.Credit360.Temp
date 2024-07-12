-- Please update version.sql too -- this keeps clean builds in sync
define version=948
@update_header

  CREATE TABLE CSR.DELEGATION_PLUGIN 
   (	APP_SID NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP'), 
	IND_SID NUMBER(10,0), 
	NAME VARCHAR2(255), 
	JS_CLASS_TYPE VARCHAR2(1000), 
	JS_INCLUDE VARCHAR2(1000), 
	HELPER_PKG VARCHAR2(255)
   ) ;
--------------------------------------------------------
--  DDL for Index DELEGATION_PLUGIN_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX CSR.DELEGATION_PLUGIN_PK ON CSR.DELEGATION_PLUGIN (APP_SID, IND_SID) 
  ;
--------------------------------------------------------
--  Constraints for Table DELEGATION_PLUGIN
--------------------------------------------------------

  ALTER TABLE CSR.DELEGATION_PLUGIN ADD CONSTRAINT DELEGATION_PLUGIN_PK PRIMARY KEY (APP_SID, IND_SID) ENABLE;
 
  ALTER TABLE CSR.DELEGATION_PLUGIN MODIFY (APP_SID NOT NULL ENABLE);
 
  ALTER TABLE CSR.DELEGATION_PLUGIN MODIFY (IND_SID NOT NULL ENABLE);
 
  ALTER TABLE CSR.DELEGATION_PLUGIN MODIFY (NAME NOT NULL ENABLE);
 
  ALTER TABLE CSR.DELEGATION_PLUGIN MODIFY (JS_CLASS_TYPE NOT NULL ENABLE);
--------------------------------------------------------
--  Ref Constraints for Table DELEGATION_PLUGIN
--------------------------------------------------------

  ALTER TABLE CSR.DELEGATION_PLUGIN ADD CONSTRAINT FK_DELEG_PLUGIN_CUST FOREIGN KEY (APP_SID)
	  REFERENCES CSR.CUSTOMER (APP_SID) ENABLE;
 
  ALTER TABLE CSR.DELEGATION_PLUGIN ADD CONSTRAINT FK_DELEG_PLUGIN_IND FOREIGN KEY (APP_SID, IND_SID)
	  REFERENCES CSR.IND (APP_SID, IND_SID) ENABLE;
	  
@..\delegation_pkg
@..\delegation_body

@update_tail