define version=2072
@update_header

ALTER TABLE CSR.TEAMROOM_TYPE ADD DEFAULT_COMPANY_SID NUMBER(10, 0) NULL;


@..\teamroom_pkg
@..\teamroom_body


@update_tail
