-- Please update version.sql too -- this keeps clean builds in sync
define version=246
@update_header

alter table val_change drop column status;
-- hmm, some things in val have a last_val_change_id pointing at a change made by a 
-- (really, really) deleted user -- seems a bit messed up!
update val_change set changed_by_sid=3 where changed_by_sid not in (select csr_user_sid from csr_user);
ALTER TABLE VAL_CHANGE ADD CONSTRAINT RefCSR_USER1045 
    FOREIGN KEY (APP_SID, CHANGED_BY_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
;

@update_tail
