-- Please update version.sql too -- this keeps clean builds in sync
define version=42

@update_header

-- fix up tags to work around IE issue where was setting Gt type tag wether dropdown field visible or not
-- this is a workaround but a fair one
                     
	  delete from questionnaire_tag where questionnaire_id = 10 and mapped = 1
	  and tag_id not in (select tag_id from questionnaire_tag where questionnaire_id = 12);
	  
	  delete from  questionnaire_tag where questionnaire_id = 13 and mapped = 1
	  and tag_id not in (select tag_id from questionnaire_tag where questionnaire_id = 12);
	
@update_tail