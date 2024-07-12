-- Please update version.sql too -- this keeps clean builds in sync
define version=1128
@update_header

alter table donations.CUSTOMER_OPTIONS add (
	FC_STATUS_TAG_GROUP_SID            NUMBER(10, 0)
);

ALTER TABLE DONATIONS.CUSTOMER_OPTIONS ADD CONSTRAINT RefTAG_GROUP258 
    FOREIGN KEY (APP_SID, FC_STATUS_TAG_GROUP_SID)
    REFERENCES DONATIONS.TAG_GROUP(APP_SID, TAG_GROUP_SID)
;

@..\donations\scheme_pkg
@..\donations\donation_body
@..\donations\funding_commitment_pkg
@..\donations\funding_commitment_body

@update_tail