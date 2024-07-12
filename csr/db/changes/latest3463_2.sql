-- Please update version.sql too -- this keeps clean builds in sync
define version=3463
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE ASPEN2.LANG_DEFAULT_INCLUDE ADD CONSTRAINT FK_APP_LANG_DEF_INC 
    FOREIGN KEY (application_sid)
    REFERENCES ASPEN2.APPLICATION(app_sid)
;
create index aspen2.ix_lang_default__application_s on aspen2.lang_default_include (application_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
-- Translation records with no application
DELETE FROM aspen2.translated WHERE application_sid IN (
  SELECT DISTINCT t.application_sid FROM aspen2.translated t
    LEFT JOIN aspen2.application a ON a.app_sid = t.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = t.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);

DELETE FROM aspen2.translation WHERE application_sid IN (
  SELECT DISTINCT t.application_sid FROM aspen2.translation t
    LEFT JOIN aspen2.application a ON a.app_sid = t.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = t.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);

DELETE FROM aspen2.translation_set_include WHERE application_sid IN (
  SELECT DISTINCT tsi.application_sid FROM aspen2.translation_set_include tsi
    LEFT JOIN aspen2.application a ON a.app_sid = tsi.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = tsi.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);

DELETE FROM aspen2.translation_set_include WHERE to_application_sid IN (
  SELECT DISTINCT tsi.to_application_sid FROM aspen2.translation_set_include tsi
    LEFT JOIN aspen2.application a ON a.app_sid = tsi.to_application_sid
    LEFT JOIN csr.customer c ON c.app_sid = tsi.to_application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);

DELETE FROM aspen2.translation_set WHERE application_sid IN (
  SELECT DISTINCT ts.application_sid FROM aspen2.translation_set ts
    LEFT JOIN aspen2.application a ON a.app_sid = ts.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = ts.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);

DELETE FROM aspen2.translation_application WHERE application_sid IN (
  SELECT DISTINCT ta.application_sid FROM aspen2.translation_application ta
    LEFT JOIN aspen2.application a ON a.app_sid = ta.application_sid
    LEFT JOIN csr.customer c ON c.app_sid = ta.application_sid
   WHERE c.app_sid IS NULL AND a.app_sid IS NULL
);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body

@update_tail
