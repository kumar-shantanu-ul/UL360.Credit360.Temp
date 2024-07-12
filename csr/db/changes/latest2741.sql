-- Please update version.sql too -- this keeps clean builds in sync
define version=2741
@update_header

-- *** DDL ***
-- Create tables
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

BEGIN
  UPDATE csr.attachment a2
	 SET a2.url = (SELECT new_url
					 FROM (
						SELECT a.attachment_id as a_id, substr(a.url, 1, instr(a.url, '#page=' || ah.pg_num, 1) - 1) as new_url
						  FROM csr.attachment a
						  JOIN csr.attachment_history ah on a.attachment_id = ah.attachment_id
						 WHERE a.url IS NOT NULL
						   AND ah.pg_num IS NOT NULL
						   AND a.url LIKE '%#page=' || ah.pg_num
						) a3 
					WHERE a2.attachment_id = a3.a_id
				  )
   WHERE EXISTS (
					  SELECT 1
						FROM csr.attachment a
						JOIN csr.attachment_history ah ON a.attachment_id = ah.attachment_id
					   WHERE a.url IS NOT NULL
						 AND ah.pg_num IS NOT NULL
						 AND a.url LIKE '%#page=' || ah.pg_num
						 AND a2.attachment_id = a.attachment_id
				  );
END;
/

-- ** New package grants **

-- *** Packages ***

@update_tail
