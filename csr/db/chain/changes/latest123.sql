define version=123
@update_header

CREATE SEQUENCE chain.FILTER_FIELD_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE chain.FILTER_VALUE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

DROP TABLE chain.COMPANY_FILTER;

CREATE TABLE chain.FILTER_COMPARATOR(
    FILTER_COMPARATOR_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION             VARCHAR2(20),
    CONSTRAINT PK_FLT_CMPTR PRIMARY KEY (FILTER_COMPARATOR_ID)
);

CREATE TABLE chain.FILTER_FIELD(
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILTER_FIELD_ID         NUMBER(10, 0)    NOT NULL,
    FILTER_ID               NUMBER(10, 0)    NOT NULL,
    NAME                    VARCHAR2(255),
    FILTER_VALUE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    FILTER_COMPARATOR_ID    NUMBER(10, 0),
    CONSTRAINT PK_FLT_FLD PRIMARY KEY (APP_SID, FILTER_FIELD_ID)
);

CREATE TABLE chain.FILTER_NUM_VALUE(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILTER_VALUE_ID    NUMBER(10, 0)    NOT NULL,
    VALUE              NUMBER(10, 0),
    CONSTRAINT PK_FLT_NUM_VAL PRIMARY KEY (APP_SID, FILTER_VALUE_ID)
);

CREATE TABLE chain.FILTER_STR_VALUE(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILTER_VALUE_ID    NUMBER(10, 0)    NOT NULL,
    VALUE              VARCHAR2(255),
    CONSTRAINT PK_FLT_STR_VAL PRIMARY KEY (APP_SID, FILTER_VALUE_ID)
);

CREATE TABLE chain.FILTER_VALUE(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILTER_VALUE_ID    NUMBER(10, 0)    NOT NULL,
    FILTER_FIELD_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLT_VAL PRIMARY KEY (APP_SID, FILTER_VALUE_ID)
);

CREATE TABLE chain.FILTER_VALUE_TYPE(
    FILTER_VALUE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION             VARCHAR2(255),
    CONSTRAINT PK_FLT_VAL_TYPE PRIMARY KEY (FILTER_VALUE_TYPE_ID)
);

ALTER TABLE chain.FILTER_FIELD ADD CONSTRAINT FLT_FLD_COMPTR 
    FOREIGN KEY (FILTER_COMPARATOR_ID)
    REFERENCES chain.FILTER_COMPARATOR(FILTER_COMPARATOR_ID);

ALTER TABLE chain.FILTER_FIELD ADD CONSTRAINT FK_FLT_FLD_APP_SID 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID);

ALTER TABLE chain.FILTER_FIELD ADD CONSTRAINT FK_FLT_FLT_FLD 
    FOREIGN KEY (APP_SID, FILTER_ID)
    REFERENCES chain.FILTER(APP_SID, FILTER_ID) ON DELETE CASCADE;

ALTER TABLE chain.FILTER_FIELD ADD CONSTRAINT FK_FLT_FLD_VAL_TYP 
    FOREIGN KEY (FILTER_VALUE_TYPE_ID)
    REFERENCES chain.FILTER_VALUE_TYPE(FILTER_VALUE_TYPE_ID);

ALTER TABLE chain.FILTER_NUM_VALUE ADD CONSTRAINT FK_FLT_VAL_NUM_VAL 
    FOREIGN KEY (APP_SID, FILTER_VALUE_ID)
    REFERENCES chain.FILTER_VALUE(APP_SID, FILTER_VALUE_ID) ON DELETE CASCADE;

ALTER TABLE chain.FILTER_STR_VALUE ADD CONSTRAINT FK_FLT_VAL_STR_VAL 
    FOREIGN KEY (APP_SID, FILTER_VALUE_ID)
    REFERENCES chain.FILTER_VALUE(APP_SID, FILTER_VALUE_ID) ON DELETE CASCADE;

ALTER TABLE chain.FILTER_VALUE ADD CONSTRAINT FK_FLT_VAL_FLD 
    FOREIGN KEY (APP_SID, FILTER_FIELD_ID)
    REFERENCES chain.FILTER_FIELD(APP_SID, FILTER_FIELD_ID) ON DELETE CASCADE;

ALTER TABLE chain.FILTER_VALUE ADD CONSTRAINT FK_FLT_VAL_APP_SID 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID);


CREATE OR REPLACE VIEW chain.v$filter_value AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fsv.value str_value, fnv.value num_value
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN filter_num_value fnv ON fv.app_sid = fnv.app_sid AND fv.filter_value_id = fnv.filter_value_id AND ff.filter_value_type_id = 1
	  LEFT JOIN filter_str_value fsv ON fv.app_sid = fsv.app_sid AND fv.filter_value_id = fsv.filter_value_id AND ff.filter_value_type_id = 2
	 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP');

CREATE OR REPLACE VIEW chain.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP');

INSERT INTO chain.filter_comparator(filter_comparator_id, description)
VALUES (1, 'Contains');

INSERT INTO chain.filter_comparator(filter_comparator_id, description)
VALUES (2, 'Equals');

INSERT INTO chain.filter_value_type(filter_value_type_id, description)
VALUES (1, 'Number');

INSERT INTO chain.filter_value_type(filter_value_type_id, description)
VALUES (2, 'String');

@..\rls
@..\chain_pkg
@..\filter_pkg
@..\company_filter_pkg
@..\filter_body
@..\company_filter_body
@..\helper_body

@update_tail
