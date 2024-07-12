-- Please update version.sql too -- this keeps clean builds in sync
define version=644
@update_header

ALTER TABLE csr.deleg_tpl
ADD CONSTRAINT CK_DELEG_TPL_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

@update_tail
