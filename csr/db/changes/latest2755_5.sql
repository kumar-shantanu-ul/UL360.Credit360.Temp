-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
create unique index csr.ux_supplier_cmp_surv_response on csr.supplier_survey_response (app_sid, supplier_sid, component_id, survey_response_id);
create index csr.ix_qs_answer_log_date on csr.qs_answer_log (app_sid, survey_response_id, set_dtm desc, set_by_user_sid);

-- *** Grants ***
GRANT SELECT ON csr.qs_answer_log TO CHAIN;

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../chain/questionnaire_body;

@update_tail
