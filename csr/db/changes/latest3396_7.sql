-- Please update version.sql too -- this keeps clean builds in sync
define version=3396
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer ADD show_feedback_fab NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE csr.customer ADD CONSTRAINT CK_SHOW_FEEDBACK_FAB CHECK (SHOW_FEEDBACK_FAB IN (0,1));
ALTER TABLE csrimp.customer ADD show_feedback_fab NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE csrimp.customer ADD CONSTRAINT CK_SHOW_FEEDBACK_FAB CHECK (SHOW_FEEDBACK_FAB IN (0,1));

INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
VALUES (71, 'Enable Feedback', 'Displays a feedback floating action button on the right side of screen to allow users to provide feedback. (LOGOUT REQUIRED)', 'EnableFeedbackFAB', null);
INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
VALUES (72, 'Disable Feedback', 'Removes the feedback floating action button on the right side of screen. (LOGOUT REQUIRED)', 'DisableFeedbackFAB', null);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\schema_body
@..\customer_body
@..\util_script_pkg
@..\util_script_body
@..\csrimp\imp_body

@update_tail
