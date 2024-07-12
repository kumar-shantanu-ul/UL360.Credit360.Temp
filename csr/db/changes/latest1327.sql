-- Please update version.sql too -- this keeps clean builds in sync
define version=1327
@update_header

-- Clean up old columns from 1326
ALTER TABLE CSR.SUPPLIER DROP COLUMN SCORE;
ALTER TABLE CSR.SUPPLIER DROP COLUMN SCORE_LAST_CHANGED;
ALTER TABLE CSR.SUPPLIER DROP COLUMN SCORE_THRESHOLD_ID;

@update_tail
