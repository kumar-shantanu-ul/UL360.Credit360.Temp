-- Please update version.sql too -- this keeps clean builds in sync
define version=1407
@update_header

UPDATE CSR.CAPABILITY SET NAME = 'Logon directly' WHERE NAME = 'Logon Directly';
 
@update_tail
