-- Please update version.sql too -- this keeps clean builds in sync
define version=3394
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX csr.ix_ci_title_search;   
ALTER TABLE csr.compliance_item_description MODIFY title VARCHAR2(2048);
CREATE INDEX csr.ix_ci_title_search on csr.compliance_item_description(title) indextype IS ctxsys.context
PARAMETERS('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO ASPEN2.LANG (LANG, DESCRIPTION, LANG_ID, PARENT_LANG_ID, OVERRIDE_LANG)
VALUES('zh', 'Chinese', 204, NULL, NULL);
UPDATE aspen2.lang SET parent_lang_id = 204 WHERE lang_id in (38,41);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
