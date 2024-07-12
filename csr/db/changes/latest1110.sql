-- Please update version.sql too -- this keeps clean builds in sync
define version=1110
@update_header

insert into cms.col_type values (27, 'Flow state');

--@../../../aspen2/cms/db/tab_pkg
--@../../../aspen2/cms/db/tab_body

@update_tail
