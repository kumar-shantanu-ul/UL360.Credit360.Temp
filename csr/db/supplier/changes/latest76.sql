-- Please update version.sql too -- this keeps clean builds in sync
define version=76
@update_header

ALTER TABLE SUPPLIER.CONTACT_SHORTLIST
ADD (contact_user_sid NUMBER(10));



@update_tail
