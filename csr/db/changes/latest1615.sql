-- Please update version.sql too -- this keeps clean builds in sync
define version=1615
@update_header

GRANT SELECT, REFERENCES ON postcode.country TO csr WITH GRANT OPTION;
CREATE UNIQUE INDEX CSR.UK_ROLE_NAME ON CSR.ROLE(APP_SID, UPPER(NAME));
ALTER TABLE CSR.ROUTE ADD CONSTRAINT UK_ROUTE  UNIQUE (APP_SID, SECTION_SID, FLOW_STATE_ID);

@..\section_pkg

@..\csr_data_body
@..\role_body
@..\section_body

@update_tail