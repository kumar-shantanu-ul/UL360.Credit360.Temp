-- Please update version.sql too -- this keeps clean builds in sync
define version=1026
@update_header

INSERT INTO cms.col_type (col_type, description) VALUES (25, 'Calc Column');

@update_tail
