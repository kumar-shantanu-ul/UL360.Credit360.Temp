-- Please update version.sql too -- this keeps clean builds in sync
define version=3484
define minor_version=5
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
DELETE FROM cms.DATA_HELPER WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DATA_HELPER cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);

DELETE FROM cms.DEBUG_SQL_LOG WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DEBUG_SQL_LOG cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);

DELETE FROM cms.DOC_TEMPLATE_VERSION WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DOC_TEMPLATE_VERSION cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);

DELETE FROM cms.DOC_TEMPLATE_FILE WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DOC_TEMPLATE_FILE cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);

DELETE FROM cms.DOC_TEMPLATE WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DOC_TEMPLATE cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);

DELETE FROM cms.FORM_RESPONSE_IMPORT_OPTIONS WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.FORM_RESPONSE_IMPORT_OPTIONS cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/zap_body

@update_tail
