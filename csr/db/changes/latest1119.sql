-- Please update version.sql too -- this keeps clean builds in sync
define version=1119
@update_header

ALTER TABLE CHAIN.FILE_UPLOAD DROP CONSTRAINT RefTRANSLATION_SET886;

@update_tail
