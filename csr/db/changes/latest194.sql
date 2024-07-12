-- Please update version.sql too -- this keeps clean builds in sync
define version=194
@update_header

-- fixes issue with constraints on issue_pending_val
alter table issue_pending_val drop constraint PK_ISSUE_PENDING_VAL;

alter table issue_pending_val add
    CONSTRAINT PK_ISSUE_PENDING_VAL PRIMARY KEY (PENDING_REGION_ID, PENDING_IND_ID, PENDING_PERIOD_ID);


ALTER TABLE ISSUE_PENDING_VAL DROP CONSTRAINT FK_ISSUE_PENDVAL_ISSUE; 

ALTER TABLE ISSUE_PENDING_VAL ADD CONSTRAINT FK_ISSUE_PENDVAL_ISSUE 
    FOREIGN KEY (ISSUE_ID)
    REFERENCES ISSUE(ISSUE_ID) DEFERRABLE INITIALLY DEFERRED
;


@..\issue_body

@update_tail

