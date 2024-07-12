-- Please update version.sql too -- this keeps clean builds in sync
define version=1015
@update_header

grant select on csr.v$flow_item to cms with grant option;
@..\..\..\aspen2\cms\db\tab_body

@update_tail