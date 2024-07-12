-- Please update version.sql too -- this keeps clean builds in sync
define version=1829
@update_header

ALTER TABLE CT.CUSTOMER_OPTIONS
ADD (IS_ALONGSIDE_CHAIN NUMBER(1,0));

UPDATE CT.CUSTOMER_OPTIONS SET IS_ALONGSIDE_CHAIN = 0;

ALTER TABLE CT.CUSTOMER_OPTIONS
MODIFY(IS_ALONGSIDE_CHAIN  NOT NULL);

ALTER TABLE CT.CUSTOMER_OPTIONS
MODIFY(IS_ALONGSIDE_CHAIN  DEFAULT 0);

@..\ct\company_pkg
@..\ct\company_body
@..\ct\supplier_pkg
@..\ct\supplier_body
@..\ct\setup_pkg
@..\ct\setup_body
@..\ct\util_pkg
@..\ct\util_body

--Case FB33790) Support Backlog - Invitation letter
@..\chain\alert_helper_pkg
@..\chain\alert_helper_body


@update_tail