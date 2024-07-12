-- Please update version.sql too -- this keeps clean builds in sync
define version=61
@update_header

-- Allow donations to access the filecache tabe
grant select, references on filecache to donations;


@update_tail
