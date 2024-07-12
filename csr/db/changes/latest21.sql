-- Please update version.sql too -- this keeps clean builds in sync
define version=21
@update_header


alter table error_log add (
    VAL_CHANGE_ID     NUMBER(10, 0)
);


ALTER TABLE ERROR_LOG ADD CONSTRAINT RefVAL_CHANGE217 
    FOREIGN KEY (VAL_CHANGE_ID)
    REFERENCES VAL_CHANGE(VAL_CHANGE_ID)
;

@update_tail
