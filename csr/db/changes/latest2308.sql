-- Please update version.sql too -- this keeps clean builds in sync
define version=2308
@update_header

BEGIN
  execute immediate 'alter table CSR.INTERNAL_AUDIT_FILE_DATA modify XXX_INTERNAL_AUDIT_SID null';
   
EXCEPTION
   WHEN OTHERS THEN
	 NULL;
END;
/

BEGIN
  execute immediate 'alter table CSRIMP.INTERNAL_AUDIT_FILE_DATA modify XXX_INTERNAL_AUDIT_SID null';
   
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END;
/

@update_tail
