-- Please update version.sql too -- this keeps clean builds in sync
define version=1796
@update_header

ALTER TABLE csr.deleg_ind_group ADD (start_collapsed NUMBER(1) DEFAULT 0 NOT NULL);

@update_tail