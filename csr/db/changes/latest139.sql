-- Please update version.sql too -- this keeps clean builds in sync
define version=139
@update_header

PROMPT If you did a clean build, you might not need to run this
PROMPT If the tables below do not exist then do not worry about it,
PROMPT Just bump the version table to 139 manually

drop sequence pending_val_comment_id_seq;
drop table pending_val_comment_read;
drop table pending_val_comment;

@..\schema_pkg
@..\schema_body
@..\..\..\..\aspen2\tools\recompile_packages

@update_tail
