-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE SURVEYS.SECTION_TEMPLATE ADD SECTION_DEPTH NUMBER(10);

UPDATE surveys.section_template st
   SET st.section_depth = (
	   SELECT max(level)
		FROM surveys.section_template_section sts
		START WITH sts.parent_id IS NULL AND sts.section_template_id = st.section_template_id
		CONNECT BY PRIOR sts.section_id = sts.parent_id
);

ALTER TABLE SURVEYS.SECTION_TEMPLATE MODIFY SECTION_DEPTH NOT NULL;

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
--@..\surveys\survey_pkg
--@..\surveys\template_pkg

--@..\surveys\survey_body
--@..\surveys\template_body

@update_tail
