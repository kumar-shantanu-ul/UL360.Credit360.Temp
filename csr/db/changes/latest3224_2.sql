-- Please update version.sql too -- this keeps clean builds in sync
define version=3224
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.tpl_report_tag_suggestion MODIFY (
  campaign_sid NUMBER(10, 0) NULL
);

ALTER TABLE csr.tpl_report_tag_suggestion ADD (
  survey_sid  NUMBER(10,0),
  CONSTRAINT chk_tpl_report_tag_suggestion CHECK ((campaign_sid IS NULL AND survey_sid IS NOT NULL) OR (campaign_sid IS NOT NULL AND survey_sid IS NULL))
);

ALTER TABLE csrimp.tpl_report_tag_suggestion MODIFY (
  campaign_sid NUMBER(10, 0) NULL
);

ALTER TABLE csrimp.tpl_report_tag_suggestion ADD (
  survey_sid  NUMBER(10,0)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

CREATE OR REPLACE PACKAGE campaigns.campaign_treeview_pkg AS
END;
/

GRANT EXECUTE ON campaigns.campaign_treeview_pkg TO csr;
GRANT EXECUTE ON campaigns.campaign_treeview_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../templated_report_pkg
@../campaigns/campaign_treeview_pkg
@../templated_report_body
@../schema_body
@../csrimp/imp_body
@../campaigns/campaign_treeview_body
@update_tail
