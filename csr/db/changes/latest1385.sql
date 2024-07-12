-- Please update version.sql too -- this keeps clean builds in sync
define version=1385
@update_header

ALTER TABLE csrimp.FACTOR_HISTORY DROP COLUMN CHANGED_DTM;
ALTER TABLE csrimp.FACTOR_HISTORY ADD (CHANGED_DTM DATE DEFAULT SYSDATE NOT NULL);

@update_tail
