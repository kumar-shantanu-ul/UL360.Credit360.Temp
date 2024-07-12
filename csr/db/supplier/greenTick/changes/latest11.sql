-- Please update version.sql too -- this keeps clean builds in sync
define version=11
@update_header

UPDATE tag SET tag = 'Boots Brand', explanation = 'Boots Brand' WHERE tag = 'Boots';

@update_tail