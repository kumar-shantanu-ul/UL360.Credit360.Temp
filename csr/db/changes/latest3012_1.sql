-- Please update version.sql too -- this keeps clean builds in sync
define version=3012
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CHAIN.HIGG_QUESTION_OPT_CONVERSION
MODIFY MEASURE_CONVERSION_ID NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28220, 3, 'yards', 0.9144, 1, 0, 1);

INSERT INTO CHAIN.HIGG_QUESTION_OPTION ( HIGG_QUESTION_option_id,HIGG_QUESTION_id,higg_module_id,option_value,display_order) VALUES ( 8313,1137,6,'yards',5);
INSERT INTO CHAIN.HIGG_QUESTION_OPTION ( HIGG_QUESTION_option_id,HIGG_QUESTION_id,higg_module_id,option_value,display_order) VALUES ( 8314,1137,6,'metres',6);

INSERT INTO CHAIN.HIGG_QUESTION_OPTION ( HIGG_QUESTION_option_id,HIGG_QUESTION_id,higg_module_id,option_value,display_order) VALUES ( 8315,1139,6,'yards',5);
INSERT INTO CHAIN.HIGG_QUESTION_OPTION ( HIGG_QUESTION_option_id,HIGG_QUESTION_id,higg_module_id,option_value,display_order) VALUES ( 8316,1139,6,'metres',6);

BEGIN
	UPDATE chain.higg_question
	   SET indicator_name = NULL,
		   indicator_lookup = NULL,
		   measure_name = NULL,
		   measure_lookup = NULL,
		   measure_divisibility = NULL,
		   std_measure_conversion_id = NULL
	 WHERE higg_question_id IN (1136, 1138);

	UPDATE chain.higg_question
	   SET units_question_id = 1137
	 WHERE higg_question_id = 1136;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = NULL,
		   std_measure_conversion_id = NULL
	 WHERE higg_question_id IN (1137,1139);

	DELETE
	  FROM chain.higg_question_survey
	 WHERE higg_question_id IN (1136, 1138);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/higg_setup_pkg
@../chain/higg_pkg

@../chain/higg_setup_body
@../chain/higg_body

@update_tail
