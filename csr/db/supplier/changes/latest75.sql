-- Please update version.sql too -- this keeps clean builds in sync
define version=75
@update_header

CREATE SEQUENCE SUPPLIER.questionnaire_group_id_seq
  START WITH 5
  MAXVALUE 999999999999999999999999999
  MINVALUE 5
  NOCYCLE
  CACHE 20
  NOORDER;
  

@update_tail
