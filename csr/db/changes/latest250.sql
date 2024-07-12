-- Please update version.sql too -- this keeps clean builds in sync
define version=250
@update_header

update alert set raised_by_user_sid = 3 where raised_by_user_sid not in (select csr_user_sid from csr_user);
ALTER TABLE ALERT ADD CONSTRAINT RefCSR_USER1047
    FOREIGN KEY (APP_SID, RAISED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID);
    
@update_tail
