-- Please update version.sql too -- this keeps clean builds in sync
define version=177
@update_header

delete from error_log where val_change_id in (select val_change_id from val_change where ind_sid not in (select ind_sid from ind));

update val set last_val_change_id = null where ind_sid not in (select ind_sid from ind);

delete from val_change where val_id in (select val_id from val where ind_sid not in (select ind_sid from ind));

delete from val where ind_sid not in (select ind_sid from ind);

ALTER TABLE VAL ADD CONSTRAINT FK_VAL_IND
    FOREIGN KEY (IND_SID)
    REFERENCES IND(IND_SID);
    
@update_tail
