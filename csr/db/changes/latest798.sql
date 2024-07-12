-- Please update version.sql too -- this keeps clean builds in sync
define version=798
@update_header


ALTER TABLE CHAIN.CUSTOMER_OPTIONS
ADD (INV_MGR_NORM_USER_FULL_ACCESS NUMBER(1) DEFAULT 0 NOT NULL);


@update_tail
