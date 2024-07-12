-- Please update version.sql too -- this keeps clean builds in sync
define version=14
@update_header

alter table delegation add (editing_url varchar2(255) default '/csr/site/delegation/sheet.acds' not null);

--update delegation set editing_url ='/csr/site/ems/ems.acds' where delegation_sid >= bla;


ALTER TABLE CSR.IMP_VAL
MODIFY(VAL NUMBER(20,6));

ALTER TABLE CSR.IMP_VAL
MODIFY(CONVERSION_FACTOR NUMBER(20,6));

@update_tail
