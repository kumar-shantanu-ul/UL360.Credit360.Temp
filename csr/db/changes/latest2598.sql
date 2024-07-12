-- Please update version.sql too -- this keeps clean builds in sync
define version=2598
@update_header


ALTER TABLE CSR.CUSTOMER ADD 
(
  -- Adjust factor set values for reporting year
  ADJ_FACTORSET_STARTMONTH NUMBER(1) DEFAULT 0 NOT NULL
);


@update_tail