-- Please update version.sql too -- this keeps clean builds in sync
define version=1285
@update_header

ALTER TABLE csr.delegation_ind ADD META_ROLE VARCHAR2 (32);

ALTER TABLE csr.delegation_ind
ADD CONSTRAINT CK_META_ROLE
CHECK (META_ROLE IN(
'MERGED','MERGED_ON_TIME', 'DP_COMPLETE', 'TOTAL_DP')) ENABLE;

@..\sheet_body

@update_tail