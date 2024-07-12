-- Please update version.sql too -- this keeps clean builds in sync
define version=83
@update_header

ALTER TABLE SUPPLIER.QUESTIONNAIRE_GROUP
 ADD (COLOUR  VARCHAR2(6));

@update_tail
