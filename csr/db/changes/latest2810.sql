-- Please update version.sql too -- this keeps clean builds in sync
define version=2810
define minor_version=0
@update_header

-- Alter tables
ALTER TABLE csr.attachment_history
  ADD pg_num_temp VARCHAR2(255);

UPDATE csr.attachment_history 
  SET pg_num_temp = pg_num;
  
ALTER TABLE  csr.attachment_history DROP COLUMN pg_num;

ALTER TABLE  csr.attachment_history RENAME COLUMN pg_num_temp TO pg_num;

@update_tail
