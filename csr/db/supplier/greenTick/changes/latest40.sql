-- Please update version.sql too -- this keeps clean builds in sync
define version=40

@update_header

-- product design missed from needsGreenTick tag
INSERT INTO questionnaire_tag (tag_id, questionnaire_id , mapped)  
    select tag_id, 13, 1 from tag where tag like '%needsGreenTick%';


@update_tail