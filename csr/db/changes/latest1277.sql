-- Please update version.sql too -- this keeps clean builds in sync
define version=1277
@update_header

ALTER TABLE CHAIN.MESSAGE_DEFINITION ADD(
	COMPLETION_TYPE_ID       NUMBER(10, 0)
);

ALTER TABLE CHAIN.MESSAGE_DEFINITION ADD CONSTRAINT FK_MSG_DEF_CMP_TYP 
    FOREIGN KEY (COMPLETION_TYPE_ID)
    REFERENCES CHAIN.COMPLETION_TYPE(COMPLETION_TYPE_ID)
;

CREATE OR REPLACE VIEW CHAIN.v$message_definition AS
	SELECT dmd.message_definition_id,  
	       NVL(md.message_template, dmd.message_template) message_template,
	       NVL(md.message_priority_id, dmd.message_priority_id) message_priority_id,
	       dmd.repeat_type_id,
	       dmd.addressing_type_id,
	       NVL(md.completion_type_id, dmd.completion_type_id) completion_type_id,
	       NVL(md.completed_template, dmd.completed_template) completed_template,
	       NVL(md.helper_pkg, dmd.helper_pkg) helper_pkg,
	       NVL(md.css_class, dmd.css_class) css_class
	  FROM default_message_definition dmd, (
	          SELECT *
	            FROM message_definition
	           WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	       ) md
	 WHERE dmd.message_definition_id = md.message_definition_id(+)
;

@..\chain\message_pkg
@..\chain\message_body

@update_tail
