-- Please update version.sql too -- this keeps clean builds in sync
define version=1362
@update_header 

ALTER TABLE csr.delegation_ind
 DROP CONSTRAINT CK_META_ROLE;

ALTER TABLE csr.delegation_ind
  ADD CONSTRAINT CK_META_ROLE
CHECK (META_ROLE IN('MERGED','MERGED_ON_TIME', 'DP_COMPLETE', 'COMP_TOTAL_DP', 'IND_SEL_COUNT', 'IND_SEL_TOTAL', 'DP_NOT_CHANGED_COUNT', 'ACC_TOTAL_DP')) ENABLE;

@../sheet_body;

@update_tail
