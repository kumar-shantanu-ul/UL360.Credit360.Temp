-- Please update version.sql too -- this keeps clean builds in sync
define version=536
@update_header

ALTER TABLE ATTACHMENT MODIFY MIME_TYPE VARCHAR2(255);

@update_tail
