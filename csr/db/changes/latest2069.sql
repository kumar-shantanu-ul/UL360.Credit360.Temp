define version=2069
@update_header

ALTER TABLE CSR.AUTOCREATE_USER ADD REQUIRE_NEW_PASSWORD NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.AUTOCREATE_USER ADD REDIRECT_TO_URL VARCHAR2(255);

@..\csr_user_pkg
@..\teamroom_pkg

@..\csr_user_body
@..\teamroom_body

@update_tail
