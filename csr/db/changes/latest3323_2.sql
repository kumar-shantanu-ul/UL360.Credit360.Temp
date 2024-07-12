-- Please update version.sql too -- this keeps clean builds in sync
define version=3323
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
CREATE TABLE csr.temp_ud327 AS
(SELECT sv.app_sid, sv.section_sid, sv.version_number 
   FROM csr.section s
   JOIN csr.section_version sv ON sv.app_sid = s.app_sid AND s.section_sid = sv.section_sid AND s.visible_version_number = sv.version_number
  WHERE s.plugin IS NOT NULL AND REGEXP_LIKE(body, '\^ [^#]')
);

DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT MAX(REGEXP_COUNT(body, '\^ [^#]'))
      INTO v_cnt
      FROM csr.temp_ud327 s
      JOIN csr.section_version sv ON sv.app_sid = s.app_sid AND s.section_sid = sv.section_sid AND s.version_number = sv.version_number; 
	IF v_cnt > 0 THEN
		FOR i IN 1..v_cnt LOOP
			UPDATE csr.section_version sv SET body = regexp_replace(body, '(\^ )([^#])', '\1#IMPORT_'||i||'#\2', i, 1)
			 WHERE EXISTS (SELECT NULL FROM csr.temp_ud327 WHERE app_sid = sv.app_sid AND section_sid = sv.section_sid AND version_number = sv.version_number);
		END LOOP;
	END IF;
END;
/

DROP TABLE csr.temp_ud327;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
