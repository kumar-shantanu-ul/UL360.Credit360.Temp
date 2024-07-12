-- Please update version.sql too -- this keeps clean builds in sync
define version=985
@update_header

alter table csr.calc_tag_dependency drop primary key drop index;
alter table csr.calc_tag_dependency add constraint PK_CALC_TAG_DEP PRIMARY KEY (APP_SID, CALC_IND_SID, TAG_ID);

@../calc_body


@update_tail
