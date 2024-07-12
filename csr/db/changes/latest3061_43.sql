-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=43
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.auto_imp_importer_cms
MODIFY tab_sid NULL;

BEGIN
	-- Clear any that aren't actually tabs
	security.user_pkg.logonadmin();
	
	UPDATE csr.auto_imp_importer_cms
	   SET tab_sid = NULL
	 WHERE tab_sid NOT IN (
		SELECT tab_sid
		  FROM cms.tab
	 );
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE CSR.AUTO_IMP_IMPORTER_CMS ADD CONSTRAINT FK_AUTO_IMP_IMPORTER_CMS_TAB
    FOREIGN KEY (APP_SID, TAB_SID)
    REFERENCES CMS.TAB(APP_SID, TAB_SID)
;

CREATE INDEX csr.ix_auto_imp_impo_tab_sid ON csr.auto_imp_importer_cms (app_sid, tab_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg

@../automated_import_body
@../../../aspen2/cms/db/tab_body

@update_tail
