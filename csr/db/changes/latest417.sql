-- Please update version.sql too -- this keeps clean builds in sync
define version=417
@update_header

ALTER TABLE HELP_TOPIC_FILE ADD CONSTRAINT RefHELP_FILE533 
    FOREIGN KEY (HELP_FILE_ID)
    REFERENCES HELP_FILE(HELP_FILE_ID)
;

@update_tail
