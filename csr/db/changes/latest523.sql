-- Please update version.sql too -- this keeps clean builds in sync
define version=523
@update_header

ALTER TABLE delegation_grid ADD (
  ind_sid NUMBER(10)
);

ALTER TABLE delegation_grid ADD CONSTRAINT FK_DELEGATION_GRID_IND
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
;

@..\delegation_body

@update_tail


