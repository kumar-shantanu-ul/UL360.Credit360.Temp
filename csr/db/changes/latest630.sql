-- Please update version.sql too -- this keeps clean builds in sync
define version=630
@update_header

ALTER TABLE csr.FACTOR ADD CONSTRAINT CK_FACTOR_DATES CHECK (END_DTM IS NULL OR TRUNC(START_DTM, 'MON') < TRUNC(END_DTM, 'MON'));
ALTER TABLE csr.STD_FACTOR ADD CONSTRAINT CK_STD_FACTOR_DATES CHECK (END_DTM IS NULL OR TRUNC(START_DTM, 'MON') < TRUNC(END_DTM, 'MON'));

@update_tail
