-- Please update version.sql too -- this keeps clean builds in sync
define version=2203
@update_header

ALTER TABLE CSR.SUPPLIER DROP CONSTRAINT FK_SUP_LAST_SCORE_ID;
DROP INDEX CSR.IX_SUP_LAST_SCORE_ID;

@update_tail
