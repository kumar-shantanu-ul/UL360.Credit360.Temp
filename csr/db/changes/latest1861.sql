-- Please update version.sql too -- this keeps clean builds in sync
define version=1861
@update_header

-- Missing from schema and copied from latest985
ALTER TABLE csr.calc_tag_dependency DROP PRIMARY KEY DROP INDEX;
ALTER TABLE csr.calc_tag_dependency ADD CONSTRAINT pk_calc_tag_dep PRIMARY KEY (app_sid, calc_ind_sid, tag_id);

@update_tail