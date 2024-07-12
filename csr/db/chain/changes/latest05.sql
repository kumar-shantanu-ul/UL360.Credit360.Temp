define version=5
@update_header

ALTER TABLE USER_SETTING ADD (NAME VARCHAR2(100));

UPDATE user_setting
   SET name = 'business unit id'
 WHERE setting_id = 1;

UPDATE user_setting
   SET name = 'business unit country'
 WHERE setting_id = 2;
 
 UPDATE user_setting
   SET name = 'many business units'
 WHERE setting_id = 3;

ALTER TABLE USER_SETTING MODIFY (NAME NOT NULL);

ALTER TABLE USER_SETTING DROP CONSTRAINT PK53;
ALTER TABLE USER_SETTING DROP COLUMN SETTING_ID;

ALTER TABLE USER_SETTING ADD CONSTRAINT PK53 PRIMARY KEY (APP_SID, USER_SID, NAME);

@..\chain_pkg
@..\questionnaire_pkg

@..\chain_body
@..\questionnaire_body

@update_tail