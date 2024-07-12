-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=28
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
create index surveys.ix_question_matrix_parent on surveys.question (app_sid, matrix_parent_id);
create index surveys.ix_question_maps_to_ind_s on surveys.question (app_sid, maps_to_ind_sid, measure_sid);
create index surveys.ix_question_opti_language_code on surveys.question_option_tr (language_code);
create index surveys.ix_question_vers_language_code on surveys.question_version_tr (language_code);
create index surveys.ix_survey_s_survey_sid_su on surveys.survey_section (app_sid, survey_sid, survey_version, parent_id);
create index surveys.ix_survey_sq_survey_sid_su on surveys.survey_section_question (app_sid, survey_sid, survey_version, section_id);
create index surveys.ix_survey_sectio_language_code on surveys.survey_section_tr (language_code);
create index surveys.ix_survey_versio_language_code on surveys.survey_version_tr (language_code);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
