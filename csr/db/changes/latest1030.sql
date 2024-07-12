-- Please update version.sql too -- this keeps clean builds in sync
define version=1030
@update_header

ALTER TABLE CT.COMPANY MODIFY (SCOPE_1 NUMBER(15,2));
ALTER TABLE CT.COMPANY MODIFY (SCOPE_2 NUMBER(15,2));    

@update_tail
