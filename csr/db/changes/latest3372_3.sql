-- Please update version.sql too -- this keeps clean builds in sync
define version=3372
define minor_version=3
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
INSERT INTO csr.plugin 
(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES 
(csr.plugin_id_seq.nextval, 13, 'Integration Question/Answers List', '/csr/site/audit/controls/IntegrationQuestionAnswerTab.js',
	'Audit.Controls.IntegrationQuestionAnswerTab', 'Credit360.Audit.Plugins.IntegrationQuestionAnswerList',
	'This tab shows question and answer records usually received via an integration',
	'/csr/shared/plugins/screenshots/audit_tab_iqa_list.png');
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../integration_question_answer_report_body

@update_tail
