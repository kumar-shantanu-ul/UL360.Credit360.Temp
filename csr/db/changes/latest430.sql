-- Please update version.sql too -- this keeps clean builds in sync
define version=430
@update_header

ALTER TABLE MODEL_INSTANCE_REGION DROP CONSTRAINT PK_MODEL_INSTANCE_REGION;
ALTER TABLE MODEL_INSTANCE_REGION ADD (BASE_MODEL_SID NUMBER(10, 0));
UPDATE model_instance_region mir
   SET base_model_sid = (
		SELECT base_model_sid
		  FROM model_instance mi
		 WHERE mi.model_instance_sid = mir.model_instance_sid
);	 
ALTER TABLE MODEL_INSTANCE_REGION MODIFY BASE_MODEL_SID NOT NULL;
ALTER TABLE MODEL_INSTANCE_REGION ADD CONSTRAINT PK_MODEL_INSTANCE_REGION PRIMARY KEY (APP_SID, MODEL_INSTANCE_SID, REGION_SID, BASE_MODEL_SID);

@../model_body

@update_tail
