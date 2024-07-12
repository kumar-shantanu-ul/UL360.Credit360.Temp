-- Please update version.sql too -- this keeps clean builds in sync
define version=1196
@update_header

GRANT SELECT,REFERENCES ON aspen2.translation_set TO csr WITH GRANT OPTION;

@update_tail
