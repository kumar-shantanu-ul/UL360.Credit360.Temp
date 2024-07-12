-- Please update version.sql too -- this keeps clean builds in sync
define version=1012
@update_header

ALTER TABLE CSR.CUSTOMER ADD (
     CHECK_TOLERANCE_AGAINST_ZERO     NUMBER(1, 0)      DEFAULT 1 NOT NULL,
     CONSTRAINT CHK_CUS_CHK_TOL_ZERO CHECK (CHECK_TOLERANCE_AGAINST_ZERO IN (0,1))
);

UPDATE CSR.CUSTOMER SET CHECK_TOLERANCE_AGAINST_ZERO = 0;

@..\csr_app_body

@update_tail