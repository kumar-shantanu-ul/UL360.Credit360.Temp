-- Please update version.sql too -- this keeps clean builds in sync
define version=2744
@update_header

-- *** DDL ***

ALTER TABLE CHEM.PROCESS_CAS_DEFAULT DROP CONSTRAINT FK_SUBST_CAS_PROC_CAS;

ALTER TABLE CHEM.PROCESS_CAS_DEFAULT ADD CONSTRAINT FK_SUBST_CAS_PROC_CAS
  FOREIGN KEY (APP_SID, SUBSTANCE_ID, CAS_CODE)
  REFERENCES CHEM.SUBSTANCE_CAS(APP_SID, SUBSTANCE_ID, CAS_CODE) ON DELETE CASCADE;
  
  -- *** Packages ***
@..\chem\substance_pkg
@..\chem\substance_body


@update_tail
