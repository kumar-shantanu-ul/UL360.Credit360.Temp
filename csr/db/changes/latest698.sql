-- Please update version.sql too -- this keeps clean builds in sync
define version=698
@update_header

DECLARE
	v_new_class_id	security_pkg.T_CLASS_ID;
	v_act			security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_act);
	v_new_class_id:=class_pkg.GetClassId('CSRQuickSurvey');
	class_pkg.AddPermission(v_act, v_new_class_id, 65536, 'View all results');
	class_PKG.createmapping(v_act, security_pkg.SO_CONTAINER,security_pkg.PERMISSION_WRITE,
		v_new_class_id, 65536 -- csr_data_pkg.PERMISSION_VIEW_ALL_RESULTS);
	);
END;
/

ALTER TABLE csr.ALL_METER ADD (
    COST_IND_SID                     NUMBER(10, 0),
    COST_MEASURE_CONVERSION_ID       NUMBER(10, 0)
);
 
ALTER TABLE csr.ALL_METER ADD CONSTRAINT RefIND2154 
    FOREIGN KEY (APP_SID, COST_IND_SID)
    REFERENCES csr.IND(APP_SID, IND_SID);
 
ALTER TABLE csr.ALL_METER ADD CONSTRAINT RefMEASURE_CONVERSION2155 
    FOREIGN KEY (APP_SID, COST_MEASURE_CONVERSION_ID)
    REFERENCES csr.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID);


CREATE OR REPLACE VIEW csr.METER
	(REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER, COST_IND_SID, COST_MEASURE_CONVERSION_ID) AS
  SELECT REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER,
	COST_IND_SID, COST_MEASURE_CONVERSION_ID
    FROM ALL_METER
   WHERE ACTIVE = 1;
   

ALTER TABLE csr.quick_survey_question ADD (
	POS				NUMBER(10) DEFAULT 0 NOT NULL,
	LABEL 			VARCHAR2(4000) NULL,
	IS_VISIBLE		NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT CK_QSQ_IS_VISIBLE CHECK (IS_VISIBLE IN (0,1))
);

INSERT INTO csr.quick_survey_question 
	(app_sid, survey_sid, pos, question_id, label)
	SELECT *
	  FROM (
		SELECT app_sid, survey_sid, rownum, EXTRACT(value(x), '*/@id').getStringVal() question_id,
			EXTRACT(VALUE(x), '*/description/text()').getStringVal() label	  
		  FROM csr.quick_survey qs,
			TABLE(XMLSEQUENCE(EXTRACT(qs.question_xml,'//*[@id]')))x
	  )
	 WHERE REGEXP_SUBSTR(question_id,'^[0-9]*$', 1, 1) IS NOT NULL
	   AND question_id NOT IN (
		SELECT question_id FROM csr.quick_survey_question		 
	   )
	   AND question_id != '0';

@..\csr_data_pkg
@..\region_pkg
@..\meter_pkg
@..\quick_survey_pkg

@..\region_body
@..\meter_body
@..\quick_survey_body

@update_tail
