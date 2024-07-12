-- Please update version.sql too -- this keeps clean builds in sync
define version=2430
@update_header

CREATE UNIQUE INDEX CSR.UK_TAG_GROUP_LOOKUP ON CSR.TAG_GROUP(APP_SID, NVL(UPPER(LOOKUP_KEY), TAG_GROUP_ID));

@../tag_pkg
@../chain/company_type_pkg

@../tag_body
@../chain/company_type_body

@update_tail
