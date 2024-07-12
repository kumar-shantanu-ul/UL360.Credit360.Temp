/* ---------------------------------------------------------------------- */
/* Script generated with: DeZign for Databases V7.1.2                     */
/* Target DBMS:           Oracle 10g                                      */
/* Project file:          schema.dez                                      */
/* Project name:                                                          */
/* Author:                                                                */
/* Script type:           Database creation script                        */
/* Created on:            2016-07-21 09:37                                */
/* ---------------------------------------------------------------------- */


/* ---------------------------------------------------------------------- */
/* Sequences                                                              */
/* ---------------------------------------------------------------------- */

CREATE SEQUENCE CT.REGION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    noorder;

CREATE SEQUENCE CT.BREAKDOWN_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.BREAKDOWN_TYPE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.ADVICE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.BT_TRIP_ENTRY_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.DATA_SOURCE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.EC_TRANSPORT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.EC_MANUFACTURER_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.EC_CAR_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.BT_TRAVEL_MODE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.EC_QUESTIONNAIRE_ANS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.EC_QUESTIONNAIRE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.BREAKDOWN_GROUP_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.WORKSHEET_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    noorder;

CREATE SEQUENCE CT.PS_ITEM_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 20
    noorder;

CREATE SEQUENCE CT.SUPPLIER_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    noorder;

CREATE SEQUENCE CT.SUPPLIER_CONTACT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    noorder;

CREATE SEQUENCE CT.PS_CATEGORY_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    noorder;

CREATE SEQUENCE CT.PS_SEGMENT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    noorder;

CREATE SEQUENCE CT.PS_FAMILY_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    noorder;

CREATE SEQUENCE CT.PS_CLASS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    noorder;

CREATE SEQUENCE CT.PS_BRICK_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    noorder;

/* ---------------------------------------------------------------------- */
/* Tables                                                                 */
/* ---------------------------------------------------------------------- */

/* ---------------------------------------------------------------------- */
/* Add table "EC_BUS_TYPE"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_BUS_TYPE (
    BUS_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_EC_BUS_TY PRIMARY KEY (BUS_TYPE_ID)
);

ALTER TABLE CT.EC_BUS_TYPE ADD CONSTRAINT CC_EC_BUS_TY_IS_DEFAULT 
    CHECK (IS_DEFAULT IN (1,0));

ALTER TABLE CT.EC_BUS_TYPE ADD CONSTRAINT CC_EC_BUS_TY_KG_CO2_PER_KM 
    CHECK (KG_CO2_PER_KM_CONTRIBUTION >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "BUSINESS_TYPE"                                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BUSINESS_TYPE (
    BUSINESS_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    CONSTRAINT PK_BUSINESS_TYPE PRIMARY KEY (BUSINESS_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EC_CAR_TYPE"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_CAR_TYPE (
    CAR_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_EC_CAR_TY PRIMARY KEY (CAR_TYPE_ID)
);

ALTER TABLE CT.EC_CAR_TYPE ADD CONSTRAINT CC_EC_CAR_TY_IS_DEFAULT 
    CHECK (IS_DEFAULT IN (1,0));

ALTER TABLE CT.EC_CAR_TYPE ADD CONSTRAINT CC_EC_CAR_TY_KG_CO2_PER_KM 
    CHECK (KG_CO2_PER_KM_CONTRIBUTION >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "CONSUMPTION_TYPE"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CONSUMPTION_TYPE (
    CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(10) NOT NULL,
    KWH_TO_CO2_CONVERSION NUMBER(20,10) NOT NULL,
    UOM_DESC VARCHAR2(32) NOT NULL,
    CONSTRAINT PK_CONS_TYPE PRIMARY KEY (CONSUMPTION_TYPE_ID)
);

ALTER TABLE CT.CONSUMPTION_TYPE ADD CONSTRAINT CC_CONS_TYPE_KWH_TO_CO2 
    CHECK (KWH_TO_CO2_CONVERSION >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "CURRENCY"                                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CURRENCY (
    CURRENCY_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    ACRONYM VARCHAR2(4) NOT NULL,
    SYMBOL VARCHAR2(3) NOT NULL,
    CONSTRAINT PK_CURRENCY PRIMARY KEY (CURRENCY_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EIO_GROUP"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EIO_GROUP (
    EIO_GROUP_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    HIDE NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_EIO_GROUP PRIMARY KEY (EIO_GROUP_ID)
);

ALTER TABLE CT.EIO_GROUP ADD CONSTRAINT CC_EIO_GROUP_HIDE 
    CHECK (HIDE IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "EC_CAR_MANUFACTURER"                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_CAR_MANUFACTURER (
    MANUFACTURER_ID NUMBER(10) NOT NULL,
    MANUFACTURER VARCHAR2(256) NOT NULL,
    IS_DONT_KNOW NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_EC_CAR_MAN PRIMARY KEY (MANUFACTURER_ID)
);

ALTER TABLE CT.EC_CAR_MANUFACTURER ADD CONSTRAINT CC_EC_CAR_MAN_IS_DONT_KNOW 
    CHECK (IS_DONT_KNOW IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "EC_MOTORBIKE_TYPE"                                          */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_MOTORBIKE_TYPE (
    MOTORBIKE_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_EC_MB_TY PRIMARY KEY (MOTORBIKE_TYPE_ID)
);

ALTER TABLE CT.EC_MOTORBIKE_TYPE ADD CONSTRAINT CC_EC_MB_TY_IS_DEFAULT 
    CHECK (IS_DEFAULT IN (1,0));

ALTER TABLE CT.EC_MOTORBIKE_TYPE ADD CONSTRAINT CC_EC_MB_TY_KG_CO2_PER_KM 
    CHECK (KG_CO2_PER_KM_CONTRIBUTION >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "PERIOD"                                                     */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PERIOD (
    PERIOD_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    USD_RATIO_TO_BASE_YR NUMBER(20,10) DEFAULT 1 NOT NULL,
    START_DATE DATE NOT NULL,
    END_DATE DATE NOT NULL,
    CONSTRAINT PK_PERIOD PRIMARY KEY (PERIOD_ID)
);

ALTER TABLE CT.PERIOD ADD CONSTRAINT CC_PERIOD_USD_RATIO_TO_BASE_YR 
    CHECK (USD_RATIO_TO_BASE_YR > 0);

/* ---------------------------------------------------------------------- */
/* Add table "SCOPE_INPUT_TYPE"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.SCOPE_INPUT_TYPE (
    SCOPE_INPUT_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    CONSTRAINT PK_SCOPE_INPUT_TYPE PRIMARY KEY (SCOPE_INPUT_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EC_TRAIN_TYPE"                                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_TRAIN_TYPE (
    TRAIN_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_EC_TRAIN_TY PRIMARY KEY (TRAIN_TYPE_ID)
);

ALTER TABLE CT.EC_TRAIN_TYPE ADD CONSTRAINT CC_EC_TRAIN_TY_IS_DEFAULT 
    CHECK (IS_DEFAULT IN (1,0));

ALTER TABLE CT.EC_TRAIN_TYPE ADD CONSTRAINT CC_EC_TRAIN_TY_KG_CO2_PER_KM 
    CHECK (KG_CO2_PER_KM_CONTRIBUTION >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "ADVICE"                                                     */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.ADVICE (
    ADVICE_ID NUMBER(10) NOT NULL,
    ADVICE CLOB NOT NULL,
    CONSTRAINT PK_ADVICE PRIMARY KEY (ADVICE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "ADVICE_URL"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.ADVICE_URL (
    ADVICE_ID NUMBER(10) NOT NULL,
    URL_POS_ID NUMBER(10) NOT NULL,
    TEXT VARCHAR2(4000) NOT NULL,
    URL VARCHAR2(4000) NOT NULL,
    CONSTRAINT PK_ADVICE_URL PRIMARY KEY (ADVICE_ID, URL_POS_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "SCOPE_3_CATEGORY"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.SCOPE_3_CATEGORY (
    SCOPE_CATEGORY_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(255) NOT NULL,
    CONSTRAINT PK_S_3_CAT PRIMARY KEY (SCOPE_CATEGORY_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "SCOPE_3_ADVICE"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.SCOPE_3_ADVICE (
    SCOPE_CATEGORY_ID NUMBER(10) NOT NULL,
    ADVICE_ID NUMBER(10) NOT NULL,
    ADVICE_KEY VARCHAR2(40) NOT NULL,
    CONSTRAINT PK_S_3_ADV PRIMARY KEY (SCOPE_CATEGORY_ID, ADVICE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "TEMPLATE_KEY"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.TEMPLATE_KEY (
    LOOKUP_KEY VARCHAR2(255) NOT NULL,
    DESCRIPTION VARCHAR2(255) NOT NULL,
    POSITION NUMBER(10) NOT NULL,
    CONSTRAINT PK_TEMPLATE_KEY PRIMARY KEY (LOOKUP_KEY),
    CONSTRAINT TCC_TEMPLATE_KEY_1 CHECK (LOOKUP_KEY = LOWER(TRIM(LOOKUP_KEY)))
);

ALTER TABLE CT.TEMPLATE_KEY ADD CONSTRAINT CC_TEMPLATE_KEY_POSITION 
    CHECK (POSITION >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "DATA_SOURCE"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.DATA_SOURCE (
    DATA_SOURCE_ID NUMBER(10) NOT NULL,
    KEY VARCHAR2(100) NOT NULL,
    SOURCE_DESCRIPTION VARCHAR(4000) NOT NULL,
    CONSTRAINT PK_DATA_SOURCE PRIMARY KEY (DATA_SOURCE_ID)
);

CREATE UNIQUE INDEX CT.IDX_DATA_SOURCE_1 ON CT.DATA_SOURCE (KEY);

/* ---------------------------------------------------------------------- */
/* Add table "DATA_SOURCE_URL"                                            */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.DATA_SOURCE_URL (
    DATA_SOURCE_ID NUMBER(10) NOT NULL,
    URL_POS_ID NUMBER(10) NOT NULL,
    TEXT VARCHAR2(500) NOT NULL,
    URL VARCHAR2(500) NOT NULL,
    CONSTRAINT PK_ PRIMARY KEY (DATA_SOURCE_ID, URL_POS_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "TRAVEL_MODE"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.TRAVEL_MODE (
    TRAVEL_MODE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    CONSTRAINT PK_TRAVEL_MODE PRIMARY KEY (TRAVEL_MODE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "BT_FUEL"                                                    */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_FUEL (
    BT_FUEL_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(500) NOT NULL,
    CONSTRAINT PK_BT_FUEL PRIMARY KEY (BT_FUEL_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "VOLUME_UNIT"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.VOLUME_UNIT (
    VOLUME_UNIT_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    SYMBOL VARCHAR2(40) NOT NULL,
    CONVERSION_TO_LITRES NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_VOLUME_UNIT PRIMARY KEY (VOLUME_UNIT_ID)
);

ALTER TABLE CT.VOLUME_UNIT ADD
    CHECK (CONVERSION_TO_LITRES > 0);

/* ---------------------------------------------------------------------- */
/* Add table "DISTANCE_UNIT"                                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.DISTANCE_UNIT (
    DISTANCE_UNIT_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    SYMBOL VARCHAR2(40) NOT NULL,
    CONVERSION_TO_KM NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_DIST_UNIT PRIMARY KEY (DISTANCE_UNIT_ID)
);

ALTER TABLE CT.DISTANCE_UNIT ADD CONSTRAINT CC_DIST_UNIT_CONV_TO_KM 
    CHECK (CONVERSION_TO_KM > 0);

/* ---------------------------------------------------------------------- */
/* Add table "BT_ESTIMATE_TYPE"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_ESTIMATE_TYPE (
    BT_ESTIMATE_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    CONSTRAINT PK_BT_EST_TYPE PRIMARY KEY (BT_ESTIMATE_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EC_FUEL_TYPE"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_FUEL_TYPE (
    FUEL_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    KG_CO2_PER_LITRE NUMBER(30,20) NOT NULL,
    CONSTRAINT PK_FUEL_TYPE PRIMARY KEY (FUEL_TYPE_ID)
);

ALTER TABLE CT.EC_FUEL_TYPE ADD CONSTRAINT CC_FUEL_TYPE_KG_CO2_PER_LITRE 
    CHECK (KG_CO2_PER_LITRE > 0);

/* ---------------------------------------------------------------------- */
/* Add table "MASS_UNIT"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.MASS_UNIT (
    MASS_UNIT_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    SYMBOL VARCHAR2(40) NOT NULL,
    CONVERSION_TO_KG NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_MASS PRIMARY KEY (MASS_UNIT_ID)
);

ALTER TABLE CT.MASS_UNIT ADD
    CHECK (CONVERSION_TO_KG > 0);

/* ---------------------------------------------------------------------- */
/* Add table "POWER_UNIT"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.POWER_UNIT (
    POWER_UNIT_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    SYMBOL VARCHAR2(40) NOT NULL,
    CONVERSION_TO_WATT NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_PWR PRIMARY KEY (POWER_UNIT_ID)
);

ALTER TABLE CT.POWER_UNIT ADD CONSTRAINT CC_PWR_CONV_TO_WATT 
    CHECK (CONVERSION_TO_WATT > 0);

/* ---------------------------------------------------------------------- */
/* Add table "HT_CONSUMPTION_CATEGORY"                                    */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HT_CONSUMPTION_CATEGORY (
    HT_CONSUMPTION_CATEGORY_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    CONSTRAINT PK_HT_CONS_CAT PRIMARY KEY (HT_CONSUMPTION_CATEGORY_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "WORKSHEET_VALUE_MAP_CURRENCY"                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.WORKSHEET_VALUE_MAP_CURRENCY (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    VALUE_MAP_ID NUMBER(10) NOT NULL,
    VALUE_MAPPER_ID NUMBER(10) DEFAULT 100 NOT NULL,
    CURRENCY_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_WSVM_CURRENCY PRIMARY KEY (APP_SID, VALUE_MAP_ID, VALUE_MAPPER_ID)
);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_CURRENCY ADD CONSTRAINT CC_WSVM_CURRENCY_VHID 
    CHECK (VALUE_MAPPER_ID = 100);

/* ---------------------------------------------------------------------- */
/* Add table "SUPPLIER_STATUS"                                            */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.SUPPLIER_STATUS (
    STATUS_ID VARCHAR2(40) NOT NULL,
    DESCRIPTION VARCHAR2(1000) NOT NULL,
    CONSTRAINT PK_SUPPLIER_STATUS PRIMARY KEY (STATUS_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_IMPORT"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_IMPORT (
    CATEGORY VARCHAR2(1024) NOT NULL,
    SEGMENT_CODE VARCHAR2(1024) NOT NULL,
    SEGMENT VARCHAR2(1024) NOT NULL,
    FAMILY_CODE VARCHAR2(1024),
    FAMILY VARCHAR2(1024),
    CLASS_CODE VARCHAR2(1024),
    CLASS VARCHAR2(1024),
    BRICK_CODE VARCHAR2(1024),
    BRICK VARCHAR2(1024),
    EIO_CODE VARCHAR2(1024) NOT NULL,
    EIO VARCHAR2(1024) NOT NULL,
    EIO_RAW VARCHAR2(1024) NOT NULL,
    CORE_ATTRIBUTE_TYPE VARCHAR2(1024),
    CORE_ATTRIBUTE VARCHAR2(1024),
    CORE_ATTRIBUTE_RAW VARCHAR2(1024)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_ATTRIBUTE_SOURCE"                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_ATTRIBUTE_SOURCE (
    PS_ATTRIBUTE_SOURCE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    CONSTRAINT PK_PS_AS PRIMARY KEY (PS_ATTRIBUTE_SOURCE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_STEM_METHOD"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_STEM_METHOD (
    PS_STEM_METHOD_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    CONSTRAINT PK_PS_SM PRIMARY KEY (PS_STEM_METHOD_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_CATEGORY"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_CATEGORY (
    PS_CATEGORY_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    CONSTRAINT PK_PS_CT PRIMARY KEY (PS_CATEGORY_ID),
    CONSTRAINT TUC_PS_CT_DESCRIPTION UNIQUE (DESCRIPTION)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_SEGMENT"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_SEGMENT (
    PS_SEGMENT_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    CONSTRAINT PK_PS_SG PRIMARY KEY (PS_SEGMENT_ID),
    CONSTRAINT TUC_PS_SG_DESCRIPTION UNIQUE (DESCRIPTION)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_FAMILY"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_FAMILY (
    PS_FAMILY_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    PS_SEGMENT_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_PS_FM PRIMARY KEY (PS_FAMILY_ID),
    CONSTRAINT TUC_PS_FM_DESCRIPTION UNIQUE (DESCRIPTION)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_CLASS"                                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_CLASS (
    PS_CLASS_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    PS_FAMILY_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_PS_CLS PRIMARY KEY (PS_CLASS_ID),
    CONSTRAINT TUC_PS_CLS_DESCRIPTION UNIQUE (DESCRIPTION)
);

/* ---------------------------------------------------------------------- */
/* Add table "EXTRAPOLATION_TYPE"                                         */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EXTRAPOLATION_TYPE (
    EXTRAPOLATION_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1000) NOT NULL,
    CONSTRAINT PK_EXTRAP_TYPE PRIMARY KEY (EXTRAPOLATION_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "WORKSHEET_VALUE_MAP_DISTANCE"                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.WORKSHEET_VALUE_MAP_DISTANCE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    VALUE_MAP_ID NUMBER(10) NOT NULL,
    VALUE_MAPPER_ID NUMBER(10) DEFAULT 110 NOT NULL,
    DISTANCE_UNIT_ID NUMBER(10),
    CONSTRAINT PK_WSVM_DISTANCE PRIMARY KEY (APP_SID, VALUE_MAP_ID, VALUE_MAPPER_ID)
);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_DISTANCE ADD CONSTRAINT CC_WSVM_DISTANCE_VHID 
    CHECK (VALUE_MAPPER_ID = 110);

/* ---------------------------------------------------------------------- */
/* Add table "PS_CALCULATION_SOURCE"                                      */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_CALCULATION_SOURCE (
    CALCULATION_SOURCE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    CONSTRAINT PK_CALCULATION_SOURCE PRIMARY KEY (CALCULATION_SOURCE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "BT_TRAVEL_MODE_TYPE"                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_TRAVEL_MODE_TYPE (
    BT_TRAVEL_MODE_TYPE_ID NUMBER(10) NOT NULL,
    TRAVEL_MODE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(200) NOT NULL,
    CONSTRAINT PK_BT_TR_MDT PRIMARY KEY (BT_TRAVEL_MODE_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "BT_CALCULATION_SOURCE"                                      */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_CALCULATION_SOURCE (
    CALCULATION_SOURCE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    CONSTRAINT PK_BT_CALCULATION_SOURCE PRIMARY KEY (CALCULATION_SOURCE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EC_CALCULATION_SOURCE"                                      */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_CALCULATION_SOURCE (
    CALCULATION_SOURCE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    CONSTRAINT PK_EC_CALCULATION_SOURCE PRIMARY KEY (CALCULATION_SOURCE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "TIME_UNIT"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.TIME_UNIT (
    TIME_UNIT_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    SYMBOL VARCHAR2(40) NOT NULL,
    CONVERSION_TO_SECS NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_TU PRIMARY KEY (TIME_UNIT_ID)
);

ALTER TABLE CT.TIME_UNIT ADD CONSTRAINT CC_TIME_UNIT_CS 
    CHECK (CONVERSION_TO_SECS >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "EC_CAR_MODEL"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_CAR_MODEL (
    CAR_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    MANUFACTURER_ID NUMBER(10) NOT NULL,
    EFFICIENCY_LTR_PER_KM NUMBER(20,10) NOT NULL,
    FUEL_TYPE_ID NUMBER(10) NOT NULL,
    TRANSMISSION VARCHAR2(40),
    CONSTRAINT PK_EC_CAR_MOD PRIMARY KEY (CAR_ID)
);

ALTER TABLE CT.EC_CAR_MODEL ADD CONSTRAINT CC_EC_CAR_MOD_EFF_KM_L 
    CHECK (EFFICIENCY_LTR_PER_KM > 0);

/* ---------------------------------------------------------------------- */
/* Add table "CURRENCY_PERIOD"                                            */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CURRENCY_PERIOD (
    PERIOD_ID NUMBER(10) NOT NULL,
    CURRENCY_ID NUMBER(10) NOT NULL,
    PURCHSE_PWR_PARITY_FACT NUMBER(30,20) NOT NULL,
    CONVERSION_TO_DOLLAR NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_CURRENCY_PERIOD PRIMARY KEY (PERIOD_ID, CURRENCY_ID)
);

ALTER TABLE CT.CURRENCY_PERIOD ADD CONSTRAINT CC_CP_CONVERSION_TO_DOLLAR 
    CHECK (CONVERSION_TO_DOLLAR > 0);

/* ---------------------------------------------------------------------- */
/* Add table "EIO"                                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EIO (
    EIO_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    EIO_GROUP_ID NUMBER(10) NOT NULL,
    EMIS_FCTR_C_TO_G_INC_USE_PH NUMBER(30,20) CONSTRAINT NN_EIO_C_TO_G_INC_USE_PH NOT NULL,
    EMIS_FCTR_C_TO_G NUMBER(30,20) NOT NULL,
    PCT_ELEC_ENERGY NUMBER(30,20) NOT NULL,
    PCT_OTHER_ENERGY NUMBER(30,20) NOT NULL,
    PCT_USE_PHASE NUMBER(30,20) NOT NULL,
    PCT_WAREHOUSE NUMBER(30,20) NOT NULL,
    PCT_WASTE NUMBER(30,20) NOT NULL,
    PCT_UPSTREAM_TRANS NUMBER(30,20) NOT NULL,
    PCT_DOWNSTREAM_TRANS NUMBER(30,20) NOT NULL,
    PCT_CTFC_SCOPE_ONE_TWO NUMBER(30,20) NOT NULL,
    OLD_DESCRIPTION VARCHAR2(1024),
    CONSTRAINT PK_EIO PRIMARY KEY (EIO_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EIO_RELATIONSHIP"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EIO_RELATIONSHIP (
    PRIMARY_EIO_CAT_ID NUMBER(10) NOT NULL,
    RELATED_EIO_CAT_ID NUMBER(10) NOT NULL,
    PCT NUMBER(30,25) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_EIO_RELATIONSHIP PRIMARY KEY (PRIMARY_EIO_CAT_ID, RELATED_EIO_CAT_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EIO_GROUP_ADVICE"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EIO_GROUP_ADVICE (
    EIO_GROUP_ID NUMBER(10) NOT NULL,
    ADVICE_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_E_G_A PRIMARY KEY (EIO_GROUP_ID, ADVICE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EIO_ADVICE"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EIO_ADVICE (
    EIO_ID NUMBER(10) NOT NULL,
    ADVICE_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_E_A PRIMARY KEY (EIO_ID, ADVICE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "REPORT_TEMPLATE"                                            */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.REPORT_TEMPLATE (
    LOOKUP_KEY VARCHAR2(255) NOT NULL,
    FILENAME VARCHAR2(256),
    MIME_TYPE VARCHAR2(255),
    DATA BLOB NOT NULL,
    LAST_MODIFIED_DTM DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_REPORT_TPL PRIMARY KEY (LOOKUP_KEY)
);

/* ---------------------------------------------------------------------- */
/* Add table "BT_TRAVEL_MODE"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_TRAVEL_MODE (
    BT_TRAVEL_MODE_TYPE_ID NUMBER(10) NOT NULL,
    BT_TRAVEL_MODE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100),
    EF_KG_CO2_PER_KM NUMBER(20,10) NOT NULL,
    EIO_KG_CO2_PER_GBP NUMBER(20,10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_BT_TR_MD PRIMARY KEY (BT_TRAVEL_MODE_TYPE_ID, BT_TRAVEL_MODE_ID)
);

ALTER TABLE CT.BT_TRAVEL_MODE ADD CONSTRAINT CC_BT_TR_MD_EF_KG_CO2_PER_KM 
    CHECK (EF_KG_CO2_PER_KM >= 0);

ALTER TABLE CT.BT_TRAVEL_MODE ADD CONSTRAINT CC_BT_TR_MD_EIO_KG_CO2 
    CHECK (EIO_KG_CO2_PER_GBP >= 0);

ALTER TABLE CT.BT_TRAVEL_MODE ADD CONSTRAINT CC_BT_TR_MD_IS_DEFAULT 
    CHECK (IS_DEFAULT IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "HT_CONSUMPTION_TYPE"                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HT_CONSUMPTION_TYPE (
    HT_CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_CATEGORY_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    CONSTRAINT PK_HT_CONS_TYPE PRIMARY KEY (HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "HT_CONSUMPTION_TYPE_VOL_UNIT"                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HT_CONSUMPTION_TYPE_VOL_UNIT (
    HT_CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_CATEGORY_ID NUMBER(10) NOT NULL,
    VOLUME_UNIT_ID NUMBER(10) NOT NULL,
    CO2_FACTOR NUMBER(30,20) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_HT_CONS_TYPE_VOL PRIMARY KEY (HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID, VOLUME_UNIT_ID)
);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_VOL_UNIT ADD CONSTRAINT CC_CONS_TYP_VOL_CO2_FACTOR 
    CHECK (CO2_FACTOR>=0);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_VOL_UNIT ADD CONSTRAINT CC_HT_CONS_TYPE_VOL_IS_DEFAULT 
    CHECK (IS_DEFAULT IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "CUSTOMER_OPTIONS"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CUSTOMER_OPTIONS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    IS_VALUE_CHAIN NUMBER(1) DEFAULT 0,
    SNAPSHOT_TAKEN NUMBER(1) DEFAULT 0,
    TOP_COMPANY_TYPE_ID NUMBER(10) NOT NULL,
    SUPPLIER_COMPANY_TYPE_ID NUMBER(10) NOT NULL,
    IS_ALONGSIDE_CHAIN NUMBER(1) DEFAULT 0,
    CONSTRAINT PK_CUSTOMER_OPTIONS PRIMARY KEY (APP_SID)
);

ALTER TABLE CT.CUSTOMER_OPTIONS ADD CONSTRAINT CC_CO_IS_ALONGSIDE_CHAIN 
    CHECK (IS_ALONGSIDE_CHAIN IN (1,0));

ALTER TABLE CT.CUSTOMER_OPTIONS ADD CONSTRAINT CC_CUST_OPTS_IS_VALUE_CHAIN 
    CHECK (IS_VALUE_CHAIN IN (1,0));

ALTER TABLE CT.CUSTOMER_OPTIONS ADD CONSTRAINT CC_CUST_OPT_SNPSHT_TKN 
    CHECK (SNAPSHOT_TAKEN IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "PS_BRICK"                                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_BRICK (
    PS_BRICK_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    PS_CLASS_ID NUMBER(10) NOT NULL,
    PS_CATEGORY_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_PS_BRK PRIMARY KEY (PS_BRICK_ID),
    CONSTRAINT TUC_PS_BRK_DESCRIPTION UNIQUE (DESCRIPTION)
);

/* ---------------------------------------------------------------------- */
/* Add table "HT_CONS_SOURCE"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HT_CONS_SOURCE (
    HT_CONS_SOURCE_ID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_CATEGORY_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    IS_REMAINDER NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_HT_CONS_SOURCE PRIMARY KEY (HT_CONS_SOURCE_ID)
);

ALTER TABLE CT.HT_CONS_SOURCE ADD CONSTRAINT CC_HT_CONS_SOURCE_IS_REMAINDER 
    CHECK (IS_REMAINDER IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "COMPANY"                                                    */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.COMPANY (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    FTE NUMBER(10) NOT NULL,
    TURNOVER NUMBER(25) NOT NULL,
    CURRENCY_ID NUMBER(10) NOT NULL,
    PERIOD_ID NUMBER(10) NOT NULL,
    BUSINESS_TYPE_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    SCOPE_INPUT_TYPE_ID NUMBER(10),
    SCOPE_1 NUMBER(15,2),
    SCOPE_2 NUMBER(15,2),
    INCLUDE_HOTEL_STAYS NUMBER(1) DEFAULT 0 NOT NULL,
    USE_RADIATIVE_FORCING NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT PK_COMPANY PRIMARY KEY (APP_SID, COMPANY_SID)
);

ALTER TABLE CT.COMPANY ADD CONSTRAINT CC_COMPANY_INCLUDE_HOTEL_STAYS 
    CHECK (INCLUDE_HOTEL_STAYS IN (1,0));

ALTER TABLE CT.COMPANY ADD CONSTRAINT CC_COMPANY_USE_RADIATIVE_FORC 
    CHECK (USE_RADIATIVE_FORCING IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "COMPANY_CONSUMPTION_TYPE"                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.COMPANY_CONSUMPTION_TYPE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    VALUE NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_COMPANY_CONS_TYPE PRIMARY KEY (APP_SID, COMPANY_SID, CONSUMPTION_TYPE_ID)
);

ALTER TABLE CT.COMPANY_CONSUMPTION_TYPE ADD CONSTRAINT CC_COMPANY_CONS_TYPE_VALUE 
    CHECK (VALUE >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "SUPPLIER"                                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.SUPPLIER (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    SUPPLIER_ID NUMBER(10) NOT NULL,
    OWNER_COMPANY_SID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10),
    NAME VARCHAR2(200) NOT NULL,
    DESCRIPTION VARCHAR2(200),
    STATUS_ID VARCHAR2(40) DEFAULT '0' NOT NULL,
    CONSTRAINT PK_SUPPLIER PRIMARY KEY (APP_SID, SUPPLIER_ID)
);

CREATE UNIQUE INDEX CT.IDX_SUPPLIER_1 ON CT.SUPPLIER (APP_SID,CASE WHEN COMPANY_SID IS NULL THEN 'S'||SUPPLIER_ID ELSE 'C'||COMPANY_SID END);

/* ---------------------------------------------------------------------- */
/* Add table "HT_CONSUMPTION_TYPE_MASS_UNIT"                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HT_CONSUMPTION_TYPE_MASS_UNIT (
    HT_CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_CATEGORY_ID NUMBER(10) NOT NULL,
    MASS_UNIT_ID NUMBER(10) NOT NULL,
    CO2_FACTOR NUMBER(30,20) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_HT_CONS_TYP_MASS PRIMARY KEY (HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID, MASS_UNIT_ID)
);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_MASS_UNIT ADD CONSTRAINT CC_CONS_TYP_MASS_CO2_FACTOR 
    CHECK (CO2_FACTOR>=0);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_MASS_UNIT ADD CONSTRAINT CC_HT_CONS_TYP_MASS_IS_DEFAULT 
    CHECK (IS_DEFAULT IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "HT_CONSUMPTION_TYPE_POWER_UNIT"                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HT_CONSUMPTION_TYPE_POWER_UNIT (
    HT_CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_CATEGORY_ID NUMBER(10) NOT NULL,
    POWER_UNIT_ID NUMBER(10) NOT NULL,
    CO2_FACTOR NUMBER(30,20),
    IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_HT_CONS_TYPE_PWR PRIMARY KEY (HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID, POWER_UNIT_ID)
);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_POWER_UNIT ADD CONSTRAINT CC_CONS_TYP_PWR_CO2_FACTOR 
    CHECK (CO2_FACTOR>=0);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_POWER_UNIT ADD CONSTRAINT CC_HT_CONS_TYPE_PWR_IS_DEFAULT 
    CHECK (IS_DEFAULT IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "HT_CONSUMPTION"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HT_CONSUMPTION (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_CATEGORY_ID NUMBER(10) NOT NULL,
    MASS_UNIT_ID NUMBER(10),
    POWER_UNIT_ID NUMBER(10),
    VOLUME_UNIT_ID NUMBER(10),
    AMOUNT NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_HT_CONS PRIMARY KEY (APP_SID, COMPANY_SID, HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID),
    CONSTRAINT TCC_MASS_PWR_VOL CHECK ((MASS_UNIT_ID IS NOT NULL AND POWER_UNIT_ID IS NULL AND VOLUME_UNIT_ID IS NULL) OR (MASS_UNIT_ID IS NULL AND POWER_UNIT_ID IS NOT NULL AND VOLUME_UNIT_ID IS NULL) OR (MASS_UNIT_ID IS NULL AND POWER_UNIT_ID IS NULL AND VOLUME_UNIT_ID IS NOT NULL))
);

ALTER TABLE CT.HT_CONSUMPTION ADD CONSTRAINT CC_AMOUNT 
    CHECK (AMOUNT > 0);

/* ---------------------------------------------------------------------- */
/* Add table "WORKSHEET_VALUE_MAP_SUPPLIER"                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.WORKSHEET_VALUE_MAP_SUPPLIER (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    VALUE_MAP_ID NUMBER(10) NOT NULL,
    VALUE_MAPPER_ID NUMBER(10) DEFAULT 103 NOT NULL,
    SUPPLIER_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_WSVM_SUPPLIER PRIMARY KEY (APP_SID, VALUE_MAP_ID, VALUE_MAPPER_ID)
);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_SUPPLIER ADD CONSTRAINT CC_WSVM_SUPPLIER_VHID 
    CHECK (VALUE_MAPPER_ID = 103);

/* ---------------------------------------------------------------------- */
/* Add table "SUPPLIER_CONTACT"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.SUPPLIER_CONTACT (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    SUPPLIER_ID NUMBER(10) NOT NULL,
    SUPPLIER_CONTACT_ID NUMBER(10) NOT NULL,
    USER_SID NUMBER(10),
    FULL_NAME VARCHAR2(1000) NOT NULL,
    EMAIL VARCHAR2(1000) NOT NULL,
    CONSTRAINT PK_SUPPLIER_CONTACT PRIMARY KEY (APP_SID, SUPPLIER_ID, SUPPLIER_CONTACT_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_ATTRIBUTE"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_ATTRIBUTE (
    PS_BRICK_ID NUMBER(10) NOT NULL,
    PS_STEM_METHOD_ID NUMBER(10) NOT NULL,
    PS_ATTRIBUTE_SOURCE_ID NUMBER(10) NOT NULL,
    ATTRIBUTE VARCHAR2(1024) NOT NULL,
    WORDS_IN_PHRASE NUMBER(10) NOT NULL,
    CONSTRAINT PK_PS_ATT PRIMARY KEY (PS_BRICK_ID, PS_STEM_METHOD_ID, PS_ATTRIBUTE_SOURCE_ID, ATTRIBUTE)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_SUPPLIER_EIO_FREQ"                                       */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_SUPPLIER_EIO_FREQ (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    SUPPLIER_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    MANUAL_COUNT NUMBER(10) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_PS_SEF PRIMARY KEY (APP_SID, SUPPLIER_ID, EIO_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "HT_CONS_SOURCE_BREAKDOWN"                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HT_CONS_SOURCE_BREAKDOWN (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_CATEGORY_ID NUMBER(10) NOT NULL,
    HT_CONS_SOURCE_ID NUMBER(10) NOT NULL,
    AMOUNT NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_HT_CONS_SRC_BD PRIMARY KEY (APP_SID, COMPANY_SID, HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID, HT_CONS_SOURCE_ID)
);

ALTER TABLE CT.HT_CONS_SOURCE_BREAKDOWN ADD CONSTRAINT CC_CONS_SOURCE_BREAKDOWN_AMNT 
    CHECK (AMOUNT >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN_TYPE"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN_TYPE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    SINGULAR VARCHAR2(1024) NOT NULL,
    PLURAL VARCHAR2(1024) NOT NULL,
    BY_TURNOVER NUMBER(1) DEFAULT 0 NOT NULL,
    BY_FTE NUMBER(1) DEFAULT 0 NOT NULL,
    IS_REGION NUMBER(1) DEFAULT 0 NOT NULL,
    REST_OF VARCHAR2(1024) NOT NULL,
    IS_HOTSPOT NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_BD_TYPE PRIMARY KEY (APP_SID, BREAKDOWN_TYPE_ID)
);

CREATE UNIQUE INDEX CT.IDX_BD_TYPE_1 ON CT.BREAKDOWN_TYPE (APP_SID,LOWER(SINGULAR),IS_HOTSPOT,COMPANY_SID);

CREATE UNIQUE INDEX CT.IDX_BD_TYPE_2 ON CT.BREAKDOWN_TYPE (APP_SID,LOWER(PLURAL),IS_HOTSPOT,COMPANY_SID);

CREATE UNIQUE INDEX CT.IDX_BD_TYPE_3 ON CT.BREAKDOWN_TYPE (APP_SID, CASE WHEN IS_REGION = 1  THEN -1 ELSE BREAKDOWN_TYPE_ID END,IS_HOTSPOT,COMPANY_SID);

ALTER TABLE CT.BREAKDOWN_TYPE ADD
    CHECK (IS_REGION IN (1,0));

ALTER TABLE CT.BREAKDOWN_TYPE ADD
    CHECK (BY_FTE IN (1,0));

ALTER TABLE CT.BREAKDOWN_TYPE ADD
    CHECK (BY_TURNOVER IN (1,0));

ALTER TABLE CT.BREAKDOWN_TYPE ADD CONSTRAINT CC_BD_TYPE_COMPANY_SID 
    CHECK ((COMPANY_SID IS NULL AND IS_REGION = 1) OR (COMPANY_SID IS NOT NULL));

ALTER TABLE CT.BREAKDOWN_TYPE ADD CONSTRAINT CC_BD_TYPE_IS_HOTSPOT 
    CHECK (IS_HOTSPOT IN (NULL, 1,0));

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN_GROUP"                                            */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN_GROUP (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
    BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 NOT NULL,
    NAME VARCHAR2(1024) NOT NULL,
    GROUP_KEY VARCHAR2(40) NOT NULL,
    DELETED NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_BD_GROUP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID)
);

ALTER TABLE CT.BREAKDOWN_GROUP ADD CONSTRAINT CC_BD_GROUP_DELETED 
    CHECK (DELETED IN (1,0));

ALTER TABLE CT.BREAKDOWN_GROUP ADD CONSTRAINT CC_BD_GROUP_IS_DEFAULT 
    CHECK (IS_DEFAULT IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "EC_OPTIONS"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_OPTIONS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    ANNUAL_LEAVE_DAYS NUMBER(20,10) NOT NULL,
    BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
    EXTRAPOLATION_PCT NUMBER(10) DEFAULT 15 NOT NULL,
    EXTRAPOLATE NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_EC_OPT PRIMARY KEY (APP_SID, COMPANY_SID)
);

ALTER TABLE CT.EC_OPTIONS ADD CONSTRAINT CC_EC_OPT_ANNUAL_LEAVE_DAYS 
    CHECK (ANNUAL_LEAVE_DAYS >= 0 AND ANNUAL_LEAVE_DAYS <=366);

ALTER TABLE CT.EC_OPTIONS ADD CONSTRAINT CC_EC_OPT_EXTRAPOLATE 
    CHECK (EXTRAPOLATE IN (1,0));

/* ---------------------------------------------------------------------- */
/* Add table "BT_OPTIONS"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_OPTIONS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    INCLUDE_HOTEL_STAYS NUMBER(1) DEFAULT 0 NOT NULL,
    BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
    TEMPORAL_EXTRAPOLATION_TYPE_ID NUMBER(10) DEFAULT 0 NOT NULL,
    TEMPORAL_EXTRAPOLATION_MONTHS NUMBER(10) DEFAULT 3 NOT NULL,
    EMPLOYEE_EXTRAPOLATION_TYPE_ID NUMBER(10) DEFAULT 0 NOT NULL,
    EMPLOYEE_EXTRAPOLATION_PCT NUMBER(10) DEFAULT 25 NOT NULL,
    CONSTRAINT PK_BT_OPT PRIMARY KEY (APP_SID, COMPANY_SID)
);

ALTER TABLE CT.BT_OPTIONS ADD CONSTRAINT CC_BT_OPT_EMP_EXT_TYPE_ID 
    CHECK (EMPLOYEE_EXTRAPOLATION_TYPE_ID IN (0, 3));

ALTER TABLE CT.BT_OPTIONS ADD CONSTRAINT CC_BT_OPT_INCLUDE_HOTEL_STAYS 
    CHECK (INCLUDE_HOTEL_STAYS IN (1,0));

ALTER TABLE CT.BT_OPTIONS ADD CONSTRAINT CC_BT_OPT_TEMP_EXT_TYPE_ID 
    CHECK (TEMPORAL_EXTRAPOLATION_TYPE_ID IN (0, 2));

/* ---------------------------------------------------------------------- */
/* Add table "UP_OPTIONS"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.UP_OPTIONS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_UP_OPT PRIMARY KEY (APP_SID, COMPANY_SID)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_OPTIONS"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_OPTIONS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
    PERIOD_ID NUMBER(10),
    AUTO_MATCH_THRESH NUMBER(5,2) NOT NULL,
    CONSTRAINT PK_PS_OPT PRIMARY KEY (APP_SID, COMPANY_SID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EC_PROFILE"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_PROFILE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
    ANNUAL_LEAVE_DAYS NUMBER(20,10) NOT NULL,
    CAR_PCT_USE NUMBER(20,17) NOT NULL,
    CAR_AVG_DIST NUMBER(20,10) NOT NULL,
    CAR_DISTANCE_UNIT_ID NUMBER(10),
    BUS_PCT_USE NUMBER(20,17) NOT NULL,
    BUS_AVG_DIST NUMBER(20,10) NOT NULL,
    BUS_DISTANCE_UNIT_ID NUMBER(10),
    TRAIN_PCT_USE NUMBER(20,17) NOT NULL,
    TRAIN_AVG_DIST NUMBER(20,10) NOT NULL,
    TRAIN_DISTANCE_UNIT_ID NUMBER(10),
    MOTORBIKE_PCT_USE NUMBER(20,17) NOT NULL,
    MOTORBIKE_AVG_DIST NUMBER(20,10) NOT NULL,
    MOTORBIKE_DISTANCE_UNIT_ID NUMBER(10),
    BIKE_PCT_USE NUMBER(20,17) NOT NULL,
    BIKE_AVG_DIST NUMBER(20,10) NOT NULL,
    BIKE_DISTANCE_UNIT_ID NUMBER(10),
    WALK_PCT_USE NUMBER(20,17) NOT NULL,
    WALK_AVG_DIST NUMBER(20,10) NOT NULL,
    WALK_DISTANCE_UNIT_ID NUMBER(10),
    MODIFIED_BY_SID NUMBER(10),
    LAST_MODIFIED_DTM DATE,
    CONSTRAINT PK_EC_PROFILE PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID),
    CONSTRAINT CC_EC_PROFILE_MODIFIED_BY_SID CHECK ((MODIFIED_BY_SID IS NULL AND LAST_MODIFIED_DTM IS NULL) OR (MODIFIED_BY_SID IS NOT NULL AND LAST_MODIFIED_DTM IS NOT NULL))
);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_ANN_LEAVE 
    CHECK (ANNUAL_LEAVE_DAYS >= 0 AND ANNUAL_LEAVE_DAYS <=366);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_BIKE_AVG_DIST 
    CHECK (BIKE_AVG_DIST >= 0);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_BIKE_PCT_USE 
    CHECK (BIKE_PCT_USE>=0 AND BIKE_PCT_USE<=100);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_BUS_AVG_DIST 
    CHECK (BUS_AVG_DIST >= 0);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_BUS_PCT_USE 
    CHECK (BUS_PCT_USE>=0 AND BUS_PCT_USE<=100);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_CAR_AVG_DIST 
    CHECK (CAR_AVG_DIST >= 0);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_CAR_PCT_USE 
    CHECK (CAR_PCT_USE>=0 AND CAR_PCT_USE<=100);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_MB_JOURNEY_KM 
    CHECK (MOTORBIKE_AVG_DIST >= 0);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_MB_PCT_USE 
    CHECK (MOTORBIKE_PCT_USE>=0 AND MOTORBIKE_PCT_USE<=100);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_TRAIN_AVG_DIST 
    CHECK (TRAIN_AVG_DIST >= 0);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_TRAIN_PCT_USE 
    CHECK (TRAIN_PCT_USE>=0 AND TRAIN_PCT_USE<=100);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_WALK_AVG_DIST 
    CHECK (WALK_AVG_DIST >= 0);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CC_EC_PROFILE_WALK_PCT_USE 
    CHECK (WALK_PCT_USE>=0 AND WALK_PCT_USE<=100);

/* ---------------------------------------------------------------------- */
/* Add table "EC_CAR_ENTRY"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_CAR_ENTRY (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    CAR_TYPE_ID NUMBER(10) NOT NULL,
    PCT NUMBER(3) NOT NULL,
    BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_EC_CAR_ENTRY PRIMARY KEY (APP_SID, COMPANY_SID, CAR_TYPE_ID, BREAKDOWN_GROUP_ID)
);

ALTER TABLE CT.EC_CAR_ENTRY ADD CONSTRAINT CC_EC_CAR_ENTRY_PCT 
    CHECK (PCT>=0 AND PCT<=100);

/* ---------------------------------------------------------------------- */
/* Add table "EC_BUS_ENTRY"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_BUS_ENTRY (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    BUS_TYPE_ID NUMBER(10) NOT NULL,
    PCT NUMBER(3) NOT NULL,
    BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_EC_BUS_ENTRY PRIMARY KEY (APP_SID, COMPANY_SID, BUS_TYPE_ID, BREAKDOWN_GROUP_ID)
);

ALTER TABLE CT.EC_BUS_ENTRY ADD CONSTRAINT CC_EC_BUS_ENTRY_PCT 
    CHECK (PCT>=0 AND PCT<=100);

/* ---------------------------------------------------------------------- */
/* Add table "EC_TRAIN_ENTRY"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_TRAIN_ENTRY (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    TRAIN_TYPE_ID NUMBER(10) NOT NULL,
    PCT NUMBER(3) NOT NULL,
    BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_EC_TRAIN_ENTRY PRIMARY KEY (APP_SID, COMPANY_SID, TRAIN_TYPE_ID, BREAKDOWN_GROUP_ID)
);

ALTER TABLE CT.EC_TRAIN_ENTRY ADD CONSTRAINT CC_EC_TRAIN_ENTRY_PCT 
    CHECK (PCT>=0 AND PCT<=100);

/* ---------------------------------------------------------------------- */
/* Add table "EC_MOTORBIKE_ENTRY"                                         */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_MOTORBIKE_ENTRY (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    MOTORBIKE_TYPE_ID NUMBER(10) NOT NULL,
    PCT NUMBER(3) NOT NULL,
    BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_EC_MB_ENTRY PRIMARY KEY (APP_SID, COMPANY_SID, MOTORBIKE_TYPE_ID, BREAKDOWN_GROUP_ID)
);

ALTER TABLE CT.EC_MOTORBIKE_ENTRY ADD CONSTRAINT CC_EC_MB_ENTRY_PCT 
    CHECK (PCT>=0 AND PCT<=100);

/* ---------------------------------------------------------------------- */
/* Add table "BT_PROFILE"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_PROFILE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
    FTE_WHO_TRAVEL_PCT NUMBER(3) NOT NULL,
    CAR_TRIPS_PPY NUMBER(20,10) NOT NULL,
    CAR_USE_PCT NUMBER(3) NOT NULL,
    CAR_TRIP_TIME_MIN NUMBER(20,10),
    CAR_TRIP_DIST NUMBER(20,10),
    CAR_DISTANCE_UNIT_ID NUMBER(10),
    CAR_ESTIMATE_TYPE_ID NUMBER(10) DEFAULT 2 NOT NULL,
    BUS_TRIPS_PPY NUMBER(20,10) NOT NULL,
    BUS_USE_PCT NUMBER(3) NOT NULL,
    BUS_TRIP_TIME_MIN NUMBER(20,10),
    BUS_TRIP_DIST NUMBER(20,10),
    BUS_DISTANCE_UNIT_ID NUMBER(10),
    BUS_ESTIMATE_TYPE_ID NUMBER(10) DEFAULT 2 NOT NULL,
    TRAIN_TRIPS_PPY NUMBER(20,10) NOT NULL,
    TRAIN_USE_PCT NUMBER(3) NOT NULL,
    TRAIN_TRIP_TIME_MIN NUMBER(20,10),
    TRAIN_TRIP_DIST NUMBER(20,10),
    TRAIN_DISTANCE_UNIT_ID NUMBER(10),
    TRAIN_ESTIMATE_TYPE_ID NUMBER(10) DEFAULT 2 NOT NULL,
    MOTORBIKE_TRIPS_PPY NUMBER(20,10) NOT NULL,
    MOTORBIKE_USE_PCT NUMBER(3) NOT NULL,
    MOTORBIKE_TRIP_TIME_MIN NUMBER(20,10),
    MOTORBIKE_TRIP_DIST NUMBER(20,10),
    MOTORBIKE_DISTANCE_UNIT_ID NUMBER(10),
    MOTORBIKE_ESTIMATE_TYPE_ID NUMBER(10) DEFAULT 2 NOT NULL,
    BIKE_TRIPS_PPY NUMBER(20,10) NOT NULL,
    BIKE_USE_PCT NUMBER(3) NOT NULL,
    BIKE_TRIP_TIME_MIN NUMBER(20,10),
    BIKE_TRIP_DIST NUMBER(20,10),
    BIKE_DISTANCE_UNIT_ID NUMBER(10),
    BIKE_ESTIMATE_TYPE_ID NUMBER(10) DEFAULT 2 NOT NULL,
    WALK_TRIPS_PPY NUMBER(20,10) NOT NULL,
    WALK_USE_PCT NUMBER(3) NOT NULL,
    WALK_TRIP_TIME_MIN NUMBER(20,10),
    WALK_TRIP_DIST NUMBER(20,10),
    WALK_DISTANCE_UNIT_ID NUMBER(10),
    WALK_ESTIMATE_TYPE_ID NUMBER(10) DEFAULT 2 NOT NULL,
    AIR_TRIPS_PPY NUMBER(20,10) NOT NULL,
    AIR_USE_PCT NUMBER(3) NOT NULL,
    AIR_TRIP_TIME_MIN NUMBER(20,10),
    AIR_TRIP_DIST NUMBER(20,10),
    AIR_DISTANCE_UNIT_ID NUMBER(10),
    AIR_ESTIMATE_TYPE_ID NUMBER(10) DEFAULT 2 NOT NULL,
    MODIFIED_BY_SID NUMBER(10),
    LAST_MODIFIED_DTM DATE,
    CAR_OCCUPANCY_RATE NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_BT_PRF PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID),
    CONSTRAINT TCC_BT_PRF_CAR CHECK (((CAR_ESTIMATE_TYPE_ID = 2) AND (CAR_TRIP_DIST IS NOT NULL) AND (CAR_DISTANCE_UNIT_ID IS NOT NULL) OR (CAR_ESTIMATE_TYPE_ID = 3) AND (CAR_TRIP_TIME_MIN IS NOT NULL))),
    CONSTRAINT TCC_BT_PRF_BUS CHECK (((BUS_ESTIMATE_TYPE_ID = 2) AND (BUS_TRIP_DIST IS NOT NULL) AND (BUS_DISTANCE_UNIT_ID IS NOT NULL) OR (BUS_ESTIMATE_TYPE_ID = 3) AND (BUS_TRIP_TIME_MIN IS NOT NULL))),
    CONSTRAINT TCC_BT_PRF_TRAIN CHECK (((TRAIN_ESTIMATE_TYPE_ID = 2) AND (TRAIN_TRIP_DIST IS NOT NULL) AND (TRAIN_DISTANCE_UNIT_ID IS NOT NULL) OR (TRAIN_ESTIMATE_TYPE_ID = 3) AND (TRAIN_TRIP_TIME_MIN IS NOT NULL))),
    CONSTRAINT TCC_BT_PRF_MOTORBIKE CHECK (((MOTORBIKE_ESTIMATE_TYPE_ID = 2) AND (MOTORBIKE_TRIP_DIST IS NOT NULL) AND (MOTORBIKE_DISTANCE_UNIT_ID IS NOT NULL) OR (MOTORBIKE_ESTIMATE_TYPE_ID = 3) AND (MOTORBIKE_TRIP_TIME_MIN IS NOT NULL))),
    CONSTRAINT TCC_BT_PRF_WALK CHECK (((WALK_ESTIMATE_TYPE_ID = 2) AND (WALK_TRIP_DIST IS NOT NULL) AND (WALK_DISTANCE_UNIT_ID IS NOT NULL) OR (WALK_ESTIMATE_TYPE_ID = 3) AND (WALK_TRIP_TIME_MIN IS NOT NULL))),
    CONSTRAINT TCC_BT_PRF_BIKE CHECK (((BIKE_ESTIMATE_TYPE_ID = 2) AND (BIKE_TRIP_DIST IS NOT NULL) AND (BIKE_DISTANCE_UNIT_ID IS NOT NULL) OR (BIKE_ESTIMATE_TYPE_ID = 3) AND (BIKE_TRIP_TIME_MIN IS NOT NULL))),
    CONSTRAINT TCC_BT_PRF_AIR CHECK (((AIR_ESTIMATE_TYPE_ID = 2) AND (AIR_TRIP_DIST IS NOT NULL) AND (AIR_DISTANCE_UNIT_ID IS NOT NULL) OR (AIR_ESTIMATE_TYPE_ID = 3) AND (AIR_TRIP_TIME_MIN IS NOT NULL))),
    CONSTRAINT CC_BT_PRF_MODIFIED_BY_SID CHECK ((MODIFIED_BY_SID IS NULL AND LAST_MODIFIED_DTM IS NULL) OR (MODIFIED_BY_SID IS NOT NULL AND LAST_MODIFIED_DTM IS NOT NULL))
);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_AIR_EST_TYPE_ID 
    CHECK (AIR_ESTIMATE_TYPE_ID IN (2,3));

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_AIR_TRIPS_PPY 
    CHECK (AIR_TRIPS_PPY >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_AIR_TRIP_DIST 
    CHECK (AIR_TRIP_DIST >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_AIR_TRIP_TIME_MIN 
    CHECK (AIR_TRIP_TIME_MIN >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_AIR_USE_PCT 
    CHECK (AIR_USE_PCT>=0 AND AIR_USE_PCT<=100);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BIKE_EST_TYPE_ID 
    CHECK (BIKE_ESTIMATE_TYPE_ID IN (2,3));

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BIKE_TRIPS_PPY 
    CHECK (BIKE_TRIPS_PPY >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BIKE_TRIP_DIST 
    CHECK (BIKE_TRIP_DIST >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BIKE_TRIP_TIME_MIN 
    CHECK (BIKE_TRIP_TIME_MIN >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BIKE_USE_PCT 
    CHECK (BIKE_USE_PCT>=0 AND BIKE_USE_PCT<=100);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BUS_EST_TYPE_ID 
    CHECK (BUS_ESTIMATE_TYPE_ID IN (2,3));

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BUS_TRIPS_PPY 
    CHECK (BUS_TRIPS_PPY >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BUS_TRIP_DIST 
    CHECK (BUS_TRIP_DIST >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BUS_TRIP_TIME_MIN 
    CHECK (BUS_TRIP_TIME_MIN >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_BUS_USE_PCT 
    CHECK (BUS_USE_PCT>=0 AND BUS_USE_PCT<=100);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_CAR_EST_TYPE_ID 
    CHECK (CAR_ESTIMATE_TYPE_ID IN (2,3));

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_CAR_OCCUPANCY_RATE 
    CHECK (CAR_OCCUPANCY_RATE >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_CAR_TRIPS_PPY 
    CHECK (CAR_TRIPS_PPY >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_CAR_TRIP_DIST 
    CHECK (CAR_TRIP_DIST >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_CAR_TRIP_TIME_MIN 
    CHECK (CAR_TRIP_TIME_MIN >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_CAR_USE_PCT 
    CHECK (CAR_USE_PCT>=0 AND CAR_USE_PCT<=100);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_FTE_WHO_TRAVEL_PCT 
    CHECK (FTE_WHO_TRAVEL_PCT>=0 AND FTE_WHO_TRAVEL_PCT<=100);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_MB_EST_TYPE_ID 
    CHECK (MOTORBIKE_ESTIMATE_TYPE_ID IN (2,3));

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_MB_TRIP_TIME_MIN 
    CHECK (MOTORBIKE_TRIP_TIME_MIN >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_MOTORBIKE_TRIPS_PPY 
    CHECK (MOTORBIKE_TRIPS_PPY >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_MOTORBIKE_TRIP_DIST 
    CHECK (MOTORBIKE_TRIP_DIST >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_MOTORBIKE_USE_PCT 
    CHECK (MOTORBIKE_USE_PCT>=0 AND MOTORBIKE_USE_PCT<=100);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_TRAIN_EST_TYPE_ID 
    CHECK (TRAIN_ESTIMATE_TYPE_ID IN (2,3));

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_TRAIN_TRIPS_PPY 
    CHECK (TRAIN_TRIPS_PPY >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_TRAIN_TRIP_DIST 
    CHECK (TRAIN_TRIP_DIST >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_TRAIN_TRIP_TIME_MIN 
    CHECK (TRAIN_TRIP_TIME_MIN >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_TRAIN_USE_PCT 
    CHECK (TRAIN_USE_PCT>=0 AND TRAIN_USE_PCT<=100);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_WALK_EST_TYPE_ID 
    CHECK (WALK_ESTIMATE_TYPE_ID IN (2,3));

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_WALK_TRIPS_PPY 
    CHECK (WALK_TRIPS_PPY >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_WALK_TRIP_DIST 
    CHECK (WALK_TRIP_DIST >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_WALK_TRIP_TIME_MIN 
    CHECK (WALK_TRIP_TIME_MIN >= 0);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CC_BT_PRF_WALK_USE_PCT 
    CHECK (WALK_USE_PCT>=0 AND WALK_USE_PCT<=100);

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10),
    BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    FTE NUMBER(10) NOT NULL,
    TURNOVER NUMBER(25) NOT NULL,
    FTE_TRAVEL NUMBER(10) NOT NULL,
    IS_REMAINDER NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_BREAKDOWN PRIMARY KEY (APP_SID, BREAKDOWN_ID)
);

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT CC_BREAKDOWN_FTE 
    CHECK (FTE >= 0);

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT CC_BREAKDOWN_FTE_TRAVEL 
    CHECK (FTE_TRAVEL >= 0);

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT CC_BREAKDOWN_IS_REMAINDER 
    CHECK (IS_REMAINDER IN (1,0));

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT CC_BREAKDOWN_TURNOVER 
    CHECK (TURNOVER >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN_REGION_EIO"                                       */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN_REGION_EIO (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    PCT NUMBER(3) NOT NULL,
    FTE NUMBER(20,10) NOT NULL,
    TURNOVER NUMBER(35,10) NOT NULL,
    CONSTRAINT PK_B_R_E PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID, EIO_ID)
);

ALTER TABLE CT.BREAKDOWN_REGION_EIO ADD
    CHECK (PCT>=0 AND PCT<=100);

ALTER TABLE CT.BREAKDOWN_REGION_EIO ADD CONSTRAINT CC_B_R_E_FTE 
    CHECK (FTE >= 0);

ALTER TABLE CT.BREAKDOWN_REGION_EIO ADD CONSTRAINT CC_B_R_E_TURNOVER 
    CHECK (TURNOVER >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "EC_QUESTIONNAIRE_ANSWERS"                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_QUESTIONNAIRE_ANSWERS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    EC_QUESTIONNAIRE_ID NUMBER(10) NOT NULL,
    EC_QUESTIONNAIRE_ANSWERS_ID NUMBER(10) NOT NULL,
    WORKING_DAYS_PER_WK NUMBER(20,10) NOT NULL,
    VACATION_DAYS_PER_YR NUMBER(20,10),
    OTHER_LEAVE_DAYS_PER_YR NUMBER(20,10),
    CAR_DAYS NUMBER(10) NOT NULL,
    CAR_DISTANCE NUMBER(20,10),
    CAR_DISTANCE_UNIT_ID NUMBER(10),
    CAR_ID NUMBER(10),
    BUS_DAYS NUMBER(10) NOT NULL,
    BUS_DISTANCE NUMBER(20,10),
    BUS_DISTANCE_UNIT_ID NUMBER(10),
    BUS_TYPE_ID NUMBER(10),
    TRAIN_DAYS NUMBER(10) NOT NULL,
    TRAIN_DISTANCE NUMBER(20,10),
    TRAIN_DISTANCE_UNIT_ID NUMBER(10),
    TRAIN_TYPE_ID NUMBER(10),
    MOTORBIKE_DAYS NUMBER(10) NOT NULL,
    MOTORBIKE_DISTANCE NUMBER(20,10),
    MOTORBIKE_DISTANCE_UNIT_ID NUMBER(10),
    MOTORBIKE_TYPE_ID NUMBER(10),
    BIKE_DAYS NUMBER(10) NOT NULL,
    BIKE_DISTANCE NUMBER(20,10),
    BIKE_DISTANCE_UNIT_ID NUMBER(10),
    WALK_DAYS NUMBER(10) NOT NULL,
    WALK_DISTANCE NUMBER(20,10),
    WALK_DISTANCE_UNIT_ID NUMBER(10),
    PRIMARY KEY (APP_SID, COMPANY_SID, EC_QUESTIONNAIRE_ID, EC_QUESTIONNAIRE_ANSWERS_ID)
);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_BIKE_DAYS 
    CHECK (BIKE_DAYS >= 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_BIKE_DIST 
    CHECK (BIKE_DISTANCE > 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_BUS_DAYS 
    CHECK (BUS_DAYS >= 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_BUS_DIST 
    CHECK (BUS_DISTANCE > 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_CAR_DAYS 
    CHECK (CAR_DAYS >= 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_CAR_DISTANCE 
    CHECK (CAR_DISTANCE > 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_MB_DIST 
    CHECK (MOTORBIKE_DISTANCE > 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_MOTORBIKE_DAYS 
    CHECK (MOTORBIKE_DAYS >= 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_OTHER_LEAVE_DAYS 
    CHECK (OTHER_LEAVE_DAYS_PER_YR >= 0 AND OTHER_LEAVE_DAYS_PER_YR <=366);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_TRAIN_DAYS 
    CHECK (TRAIN_DAYS >= 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_TRAIN_DIST 
    CHECK (TRAIN_DISTANCE > 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_VACATION_DAYS 
    CHECK (VACATION_DAYS_PER_YR >= 0 AND VACATION_DAYS_PER_YR <=366);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_WALK_DAYS 
    CHECK (WALK_DAYS >= 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_WALK_DIST 
    CHECK (WALK_DISTANCE > 0);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EC_QA_WORKING_DAYS 
    CHECK (WORKING_DAYS_PER_WK > 0 AND WORKING_DAYS_PER_WK <=7);

/* ---------------------------------------------------------------------- */
/* Add table "EC_REGION_FACTORS"                                          */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_REGION_FACTORS (
    REGION_ID NUMBER(10) NOT NULL,
    HOLIDAYS NUMBER(20,10) NOT NULL,
    CAR_AVG_PCT_USE NUMBER(20,17) NOT NULL,
    BUS_AVG_PCT_USE NUMBER(20,17) NOT NULL,
    TRAIN_AVG_PCT_USE NUMBER(20,17) NOT NULL,
    MOTORBIKE_AVG_PCT_USE NUMBER(20,17) NOT NULL,
    BIKE_AVG_PCT_USE NUMBER(20,17) NOT NULL,
    WALK_AVG_PCT_USE NUMBER(20,17) NOT NULL,
    CAR_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    BUS_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    TRAIN_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    MOTORBIKE_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    BIKE_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    WALK_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_ERF PRIMARY KEY (REGION_ID)
);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_BIKE_AVG_JOURNEY_KM 
    CHECK (BIKE_AVG_JOURNEY_KM > 0);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_BIKE_AVG_PCT_USE 
    CHECK (BIKE_AVG_PCT_USE>=0 AND BIKE_AVG_PCT_USE<=100);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_BUS_AVG_JOURNEY_KM 
    CHECK (BUS_AVG_JOURNEY_KM > 0);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_BUS_AVG_PCT_USE 
    CHECK (BUS_AVG_PCT_USE>=0 AND BUS_AVG_PCT_USE<=100);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_CAR_AVG_JOURNEY_KM 
    CHECK (CAR_AVG_JOURNEY_KM > 0);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_CAR_AVG_PCT_USE 
    CHECK (CAR_AVG_PCT_USE>=0 AND CAR_AVG_PCT_USE<=100);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_MB_AVG_JOURNEY_KM 
    CHECK (MOTORBIKE_AVG_JOURNEY_KM > 0);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_MOTORBIKE_AVG_PCT_USE 
    CHECK (MOTORBIKE_AVG_PCT_USE>=0 AND MOTORBIKE_AVG_PCT_USE<=100);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_TRAIN_AVG_JOURNEY_KM 
    CHECK (TRAIN_AVG_JOURNEY_KM > 0);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_TRAIN_AVG_PCT_USE 
    CHECK (TRAIN_AVG_PCT_USE>=0 AND TRAIN_AVG_PCT_USE<=100);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_WALK_AVG_JOURNEY_KM 
    CHECK (WALK_AVG_JOURNEY_KM > 0);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT CC_ERF_WALK_AVG_PCT_USE 
    CHECK (WALK_AVG_PCT_USE>=0 AND WALK_AVG_PCT_USE<=100);

/* ---------------------------------------------------------------------- */
/* Add table "HOT_REGION"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HOT_REGION (
    REGION_ID NUMBER(10) NOT NULL,
    FULL_LIFECYCLE_EF NUMBER(30,20) NOT NULL,
    COMBUSITION_EF NUMBER(30,20) NOT NULL,
    CONSTRAINT PK_HOT_REGION PRIMARY KEY (REGION_ID)
);

ALTER TABLE CT.HOT_REGION ADD CONSTRAINT CC_HOT_REGION_COMBUSITION_EF 
    CHECK (COMBUSITION_EF >= 0);

ALTER TABLE CT.HOT_REGION ADD CONSTRAINT CC_HOT_REGION_LIFECYCLE_EF 
    CHECK (FULL_LIFECYCLE_EF >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "REGION"                                                     */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.REGION (
    REGION_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    COUNTRY VARCHAR2(2),
    PARENT_ID NUMBER(10),
    CONSTRAINT PK_REGION PRIMARY KEY (REGION_ID),
    CONSTRAINT UK_REGION_COUNTRY UNIQUE (COUNTRY),
    CONSTRAINT UK_REGION_DESCRIPTION UNIQUE (DESCRIPTION)
);

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN_REGION"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN_REGION (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    PCT NUMBER(3) NOT NULL,
    FTE_TRAVEL NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_B_R PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID)
);

ALTER TABLE CT.BREAKDOWN_REGION ADD
    CHECK (PCT>=0 AND PCT<=100);

ALTER TABLE CT.BREAKDOWN_REGION ADD CONSTRAINT CC_B_R_FTE_TRAVEL 
    CHECK (FTE_TRAVEL >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "HOTSPOT_RESULT"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HOTSPOT_RESULT (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
    PG_EMISSIONS NUMBER(30,10) NOT NULL,
    SCOPE_ONE_TWO_EMISSIONS NUMBER(30,10) NOT NULL,
    UPSTREAM_EMISSIONS NUMBER(30,10) NOT NULL,
    DOWNSTREAM_EMISSIONS NUMBER(30,10) NOT NULL,
    USE_EMISSIONS NUMBER(30,10) NOT NULL,
    WASTE_EMISSIONS NUMBER(30,10) NOT NULL,
    EMP_COMM_EMISSIONS NUMBER(30,10) NOT NULL,
    BUSINESS_TRAVEL_EMISSIONS NUMBER(30,10) NOT NULL,
    CONSTRAINT PK_H_R PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID, EIO_ID)
);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT CC_H_R_BT_EMISSIONS 
    CHECK (BUSINESS_TRAVEL_EMISSIONS >= 0);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT CC_H_R_DOWNSTREAM_EMISSIONS 
    CHECK (DOWNSTREAM_EMISSIONS >= 0);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT CC_H_R_EMP_COMM_EMISSIONS 
    CHECK (EMP_COMM_EMISSIONS >= 0);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT CC_H_R_PG_EMISSIONS 
    CHECK (PG_EMISSIONS >= 0);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT CC_H_R_SCOPE_ONE_TWO_EMISSIONS 
    CHECK (SCOPE_ONE_TWO_EMISSIONS >= 0);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT CC_H_R_UPSTREAM_EMISSIONS 
    CHECK (UPSTREAM_EMISSIONS >= 0);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT CC_H_R_USE_EMISSIONS 
    CHECK (USE_EMISSIONS >= 0);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT CC_H_R_WASTE_EMISSIONS 
    CHECK (WASTE_EMISSIONS >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "BRICK"                                                      */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BRICK (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BRICK_ID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    PARENT_BRICK_ID NUMBER(10),
    EIO_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_BRICK PRIMARY KEY (APP_SID, BRICK_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "CORE_BRICK"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CORE_BRICK (
    CORE_BRICK_ID NUMBER(10) NOT NULL,
    PARENT_CORE_BRICK_ID NUMBER(10),
    EIO_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_CORE_BRICK PRIMARY KEY (CORE_BRICK_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "UP_PRODUCT"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.UP_PRODUCT (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') NOT NULL,
    UP_PRODUCT_ID NUMBER(10) NOT NULL,
    BRICK_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_UP_PRODUCT PRIMARY KEY (APP_SID, COMPANY_SID, UP_PRODUCT_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "BT_REGION_FACTORS"                                          */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_REGION_FACTORS (
    REGION_ID NUMBER(10) NOT NULL,
    TEMP_EMISSION_FACTOR NUMBER(20,10) NOT NULL,
    CAR_USE_PCT NUMBER(20,17) DEFAULT 0 NOT NULL,
    CAR_AVG_DIST_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    CAR_AVG_SPEED_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    CAR_OCCUPANCY_RATE NUMBER(20,10) DEFAULT 0 NOT NULL,
    BUS_USE_PCT NUMBER(20,17) DEFAULT 0 NOT NULL,
    BUS_AVG_DIST_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    BUS_AVG_SPEED_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    TRAIN_USE_PCT NUMBER(20,17) DEFAULT 0 NOT NULL,
    TRAIN_AVG_DIST_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    TRAIN_AVG_SPEED_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    MOTORBIKE_USE_PCT NUMBER(20,17) DEFAULT 0 NOT NULL,
    MOTORBIKE_AVG_DIST_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    MOTORBIKE_AVG_SPEED_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    BIKE_USE_PCT NUMBER(20,17) DEFAULT 0 NOT NULL,
    BIKE_AVG_DIST_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    BIKE_AVG_SPEED_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    WALK_USE_PCT NUMBER(20,17) DEFAULT 0 NOT NULL,
    WALK_AVG_DIST_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    WALK_AVG_SPEED_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    AIR_USE_PCT NUMBER(20,17) DEFAULT 0 NOT NULL,
    AIR_AVG_DIST_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    AIR_AVG_SPEED_KM NUMBER(20,10) DEFAULT 0 NOT NULL,
    AIR_RADIATIVE_FORCING NUMBER(20,10) DEFAULT 0 NOT NULL,
    AVG_NUM_TRIPS_YR NUMBER(20,10) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_BTRF PRIMARY KEY (REGION_ID)
);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_AIR_AVG_DIST_KM 
    CHECK (AIR_AVG_DIST_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_AIR_AVG_SPEED_KM 
    CHECK (AIR_AVG_SPEED_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_AIR_RADIATIVE_FORCING 
    CHECK (AIR_RADIATIVE_FORCING >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_AIR_USE_PCT 
    CHECK (AIR_USE_PCT>=0 AND AIR_USE_PCT<=100);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_AVG_NUM_TRIPS_YR 
    CHECK (AVG_NUM_TRIPS_YR >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_BIKE_AVG_DIST_KM 
    CHECK (BIKE_AVG_DIST_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_BIKE_AVG_SPEED_KM 
    CHECK (BIKE_AVG_SPEED_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_BIKE_USE_PCT 
    CHECK (BIKE_USE_PCT>=0 AND BIKE_USE_PCT<=100);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_BUS_AVG_DIST_KM 
    CHECK (BUS_AVG_DIST_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_BUS_AVG_SPEED_KM 
    CHECK (BUS_AVG_SPEED_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_BUS_USE_PCT 
    CHECK (BUS_USE_PCT>=0 AND BUS_USE_PCT<=100);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_CAR_AVG_DIST_KM 
    CHECK (CAR_AVG_DIST_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_CAR_AVG_SPEED_KM 
    CHECK (CAR_AVG_SPEED_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_CAR_OCCUPANCY_RATE 
    CHECK (CAR_OCCUPANCY_RATE >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_CAR_USE_PCT 
    CHECK (CAR_USE_PCT>=0 AND CAR_USE_PCT<=100);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_MOTORBIKE_AVG_DIST_KM 
    CHECK (MOTORBIKE_AVG_DIST_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_MOTORBIKE_AVG_SPEED_KM 
    CHECK (MOTORBIKE_AVG_SPEED_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_MOTORBIKE_USE_PCT 
    CHECK (MOTORBIKE_USE_PCT>=0 AND MOTORBIKE_USE_PCT<=100);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_TEMP_EMISSION_FACTOR 
    CHECK (TEMP_EMISSION_FACTOR >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_TRAIN_AVG_DIST_KM 
    CHECK (TRAIN_AVG_DIST_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_TRAIN_AVG_SPEED_KM 
    CHECK (TRAIN_AVG_SPEED_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_TRAIN_USE_PCT 
    CHECK (TRAIN_USE_PCT>=0 AND TRAIN_USE_PCT<=100);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_WALK_AVG_DIST_KM 
    CHECK (WALK_AVG_DIST_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_WALK_AVG_SPEED_KM 
    CHECK (WALK_AVG_SPEED_KM >= 0);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT CC_BTRF_WALK_USE_PCT 
    CHECK (WALK_USE_PCT>=0 AND WALK_USE_PCT<=100);

/* ---------------------------------------------------------------------- */
/* Add table "BT_CAR_TRIP"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_CAR_TRIP (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    TRIP_ID NUMBER NOT NULL,
    BT_TRAVEL_MODE_ID NUMBER(10) NOT NULL,
    BT_TRAVEL_MODE_TYPE_ID NUMBER(10) NOT NULL,
    FUEL_AMOUNT NUMBER(20,10),
    BT_FUEL_ID NUMBER(10),
    FUEL_UNIT_ID NUMBER(10),
    DISTANCE_AMOUNT NUMBER(20,10),
    DISTANCE_UNIT_ID NUMBER(10),
    TIME_AMOUNT NUMBER(20,10),
    TIME_UNIT_ID NUMBER(10),
    SPEND_AMOUNT NUMBER(20,10),
    CURRENCY_ID NUMBER(10),
    JOURNEY_DATE DATE,
    TRANSACTION_DATE DATE,
    LAST_EDITED_DTM DATE DEFAULT SYSDATE NOT NULL,
    LAST_EDITED_BY_SID NUMBER(10) NOT NULL,
    BT_ESTIMATE_TYPE_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_BT_CAR_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID),
    CONSTRAINT TCC_BT_CAR_TRIP_COMPLETE CHECK (((BT_ESTIMATE_TYPE_ID = 1) AND (FUEL_AMOUNT IS NOT NULL) AND (BT_FUEL_ID IS NOT NULL) AND (FUEL_UNIT_ID IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 2) AND (DISTANCE_AMOUNT IS NOT NULL) AND (DISTANCE_UNIT_ID IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 3) AND (TIME_AMOUNT IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 4) AND (SPEND_AMOUNT IS NOT NULL) AND (CURRENCY_ID IS NOT NULL)))
);

ALTER TABLE CT.BT_CAR_TRIP ADD
    CHECK (SPEND_AMOUNT > 0);

ALTER TABLE CT.BT_CAR_TRIP ADD
    CHECK (TIME_AMOUNT > 0);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT CC_BT_CAR_TRIP_BT_TMT 
    CHECK (BT_TRAVEL_MODE_TYPE_ID = 1);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT CC_BT_CAR_TRIP_DISTANCE_AMOUNT 
    CHECK (DISTANCE_AMOUNT > 0);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT CC_BT_CAR_TRIP_FUEL_AMOUNT 
    CHECK (FUEL_AMOUNT > 0);

/* ---------------------------------------------------------------------- */
/* Add table "BT_BUS_TRIP"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_BUS_TRIP (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    TRIP_ID NUMBER NOT NULL,
    BT_TRAVEL_MODE_ID NUMBER(10) NOT NULL,
    BT_TRAVEL_MODE_TYPE_ID NUMBER(10) NOT NULL,
    DISTANCE_AMOUNT NUMBER(20,10),
    DISTANCE_UNIT_ID NUMBER(10),
    TIME_AMOUNT NUMBER(20,10),
    JOURNEY_DATE DATE,
    TRANSACTION_DATE DATE,
    LAST_EDITED_DTM DATE DEFAULT SYSDATE NOT NULL,
    LAST_EDITED_BY_SID NUMBER(10) NOT NULL,
    BT_ESTIMATE_TYPE_ID NUMBER(10) NOT NULL,
    TIME_UNIT_ID NUMBER(10),
    CONSTRAINT PK_BT_BUS_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID),
    CONSTRAINT TCC_BT_BUS_TRIP_COMPLETE CHECK (((BT_ESTIMATE_TYPE_ID = 2) AND (DISTANCE_AMOUNT IS NOT NULL) AND (DISTANCE_UNIT_ID IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 3) AND (TIME_AMOUNT IS NOT NULL)))
);

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT CC_BT_BUS_TRIP_BT_EST_TYPE_ID 
    CHECK (BT_ESTIMATE_TYPE_ID IN (2,3));

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT CC_BT_BUS_TRIP_BT_TMT 
    CHECK (BT_TRAVEL_MODE_TYPE_ID = 3);

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT CC_BT_BUS_TRIP_DISTANCE_AMOUNT 
    CHECK (DISTANCE_AMOUNT > 0);

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT CC_BT_BUS_TRIP_TIME_AMOUNT 
    CHECK (TIME_AMOUNT > 0);

/* ---------------------------------------------------------------------- */
/* Add table "BT_TRAIN_TRIP"                                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_TRAIN_TRIP (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    TRIP_ID NUMBER NOT NULL,
    BT_TRAVEL_MODE_ID NUMBER(10) NOT NULL,
    BT_TRAVEL_MODE_TYPE_ID NUMBER(10) NOT NULL,
    DISTANCE_AMOUNT NUMBER(20,10),
    DISTANCE_UNIT_ID NUMBER(10),
    TIME_AMOUNT NUMBER(20,10),
    JOURNEY_DATE DATE,
    TRANSACTION_DATE DATE,
    LAST_EDITED_DTM DATE DEFAULT SYSDATE NOT NULL,
    LAST_EDITED_BY_SID NUMBER(10) NOT NULL,
    BT_ESTIMATE_TYPE_ID NUMBER(10) NOT NULL,
    TIME_UNIT_ID NUMBER(10),
    CONSTRAINT PK_BT_TR_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID),
    CONSTRAINT TCC_BT_TR_TRIP_COMPLETE CHECK (((BT_ESTIMATE_TYPE_ID = 2) AND (DISTANCE_AMOUNT IS NOT NULL) AND (DISTANCE_UNIT_ID IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 3) AND (TIME_AMOUNT IS NOT NULL)))
);

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT CC_BT_TR_TRIP_BT_EST_TYPE_ID 
    CHECK (BT_ESTIMATE_TYPE_ID IN (2,3));

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT CC_BT_TR_TRIP_BT_TMT 
    CHECK (BT_TRAVEL_MODE_TYPE_ID = 4);

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT CC_BT_TR_TRIP_DISTANCE_AMOUNT 
    CHECK (DISTANCE_AMOUNT > 0);

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT CC_BT_TR_TRIP_TIME_AMOUNT 
    CHECK (TIME_AMOUNT > 0);

/* ---------------------------------------------------------------------- */
/* Add table "BT_AIR_TRIP"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_AIR_TRIP (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    TRIP_ID NUMBER NOT NULL,
    BT_TRAVEL_MODE_ID NUMBER(10) NOT NULL,
    BT_TRAVEL_MODE_TYPE_ID NUMBER(10) NOT NULL,
    DISTANCE_AMOUNT NUMBER(20,10),
    DISTANCE_UNIT_ID NUMBER(10),
    TIME_AMOUNT NUMBER(20,10),
    JOURNEY_DATE DATE,
    TRANSACTION_DATE DATE,
    LAST_EDITED_DTM DATE DEFAULT SYSDATE NOT NULL,
    LAST_EDITED_BY_SID NUMBER(10) NOT NULL,
    BT_ESTIMATE_TYPE_ID NUMBER(10),
    TIME_UNIT_ID NUMBER(10),
    CONSTRAINT PK_BT_AIR_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID),
    CONSTRAINT TCC_BT_AIR_TRIP_COMPLETE CHECK (((BT_ESTIMATE_TYPE_ID = 2) AND (DISTANCE_AMOUNT IS NOT NULL) AND (DISTANCE_UNIT_ID IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 3) AND (TIME_AMOUNT IS NOT NULL)))
);

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT CC_BT_AIR_TRIP_APP_SID 
    CHECK (APP_SID IN (2,3));

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT CC_BT_AIR_TRIP_BT_EST_TYPE_ID 
    CHECK (BT_ESTIMATE_TYPE_ID IN (2, 3));

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT CC_BT_AIR_TRIP_BT_TMT 
    CHECK (BT_TRAVEL_MODE_TYPE_ID = 6);

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT CC_BT_AIR_TRIP_DISTANCE_AMOUNT 
    CHECK (DISTANCE_AMOUNT > 0);

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT CC_BT_AIR_TRIP_TIME_AMOUNT 
    CHECK (TIME_AMOUNT > 0);

/* ---------------------------------------------------------------------- */
/* Add table "BT_CAB_TRIP"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_CAB_TRIP (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    TRIP_ID NUMBER NOT NULL,
    BT_TRAVEL_MODE_ID NUMBER(10) NOT NULL,
    BT_TRAVEL_MODE_TYPE_ID NUMBER(10) NOT NULL,
    SPEND_AMOUNT NUMBER(20,10),
    CURRENCY_ID NUMBER(10),
    TIME_AMOUNT NUMBER(20,10),
    TIME_UNIT_ID NUMBER(10),
    JOURNEY_DATE DATE,
    TRANSACTION_DATE DATE,
    LAST_EDITED_DTM DATE DEFAULT SYSDATE NOT NULL,
    LAST_EDITED_BY_SID NUMBER(10) NOT NULL,
    BT_ESTIMATE_TYPE_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_BT_CAB_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID),
    CONSTRAINT TCC_BT_CAB_TRIP_COMPLETE CHECK (((BT_ESTIMATE_TYPE_ID = 3) AND (TIME_AMOUNT IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 4) AND (SPEND_AMOUNT IS NOT NULL) AND (CURRENCY_ID IS NOT NULL)) )
);

ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT CC_BT_CAB_TRIP_BT_TMT 
    CHECK (BT_TRAVEL_MODE_TYPE_ID = 2);

ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT CC_BT_CAB_TRIP_SPEND_AMOUNT 
    CHECK (SPEND_AMOUNT > 0);

ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT CC_BT_CAB_TRIP_TIME_AMOUNT 
    CHECK (TIME_AMOUNT > 0);

/* ---------------------------------------------------------------------- */
/* Add table "BT_MOTORBIKE_TRIP"                                          */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_MOTORBIKE_TRIP (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    TRIP_ID NUMBER NOT NULL,
    BT_TRAVEL_MODE_ID NUMBER(10) NOT NULL,
    BT_TRAVEL_MODE_TYPE_ID NUMBER(10) NOT NULL,
    FUEL_AMOUNT NUMBER(20,10) NOT NULL,
    BT_FUEL_ID NUMBER(10),
    FUEL_UNIT_ID NUMBER(10),
    DISTANCE_AMOUNT NUMBER(20,10),
    DISTANCE_UNIT_ID NUMBER(10),
    TIME_AMOUNT NUMBER(20,10),
    TIME_UNIT_ID NUMBER(10),
    SPEND_AMOUNT NUMBER(20,10),
    CURRENCY_ID NUMBER(10),
    JOURNEY_DATE DATE,
    TRANSACTION_DATE DATE,
    LAST_EDITED_DTM DATE DEFAULT SYSDATE NOT NULL,
    LAST_EDITED_BY_SID NUMBER(10) NOT NULL,
    BT_ESTIMATE_TYPE_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_BT_MB_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID),
    CONSTRAINT TCC_BT_MB_TRIP_COMPLETE CHECK (((BT_ESTIMATE_TYPE_ID = 1) AND (FUEL_AMOUNT IS NOT NULL) AND (BT_FUEL_ID IS NOT NULL) AND (FUEL_UNIT_ID IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 2) AND (DISTANCE_AMOUNT IS NOT NULL) AND (DISTANCE_UNIT_ID IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 3) AND (TIME_AMOUNT IS NOT NULL)) OR ((BT_ESTIMATE_TYPE_ID = 4) AND (SPEND_AMOUNT IS NOT NULL) AND (CURRENCY_ID IS NOT NULL)))
);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT CC_BT_MB_TRIP_BT_TMT 
    CHECK (BT_TRAVEL_MODE_TYPE_ID = 5);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT CC_BT_MB_TRIP_DISTANCE_AMOUNT 
    CHECK (DISTANCE_AMOUNT > 0);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT CC_BT_MB_TRIP_FUEL_AMOUNT 
    CHECK (FUEL_AMOUNT > 0);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT CC_BT_MB_TRIP_SPEND_AMOUNT 
    CHECK (SPEND_AMOUNT > 0);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT CC_BT_MB_TRIP_TIME_AMOUNT 
    CHECK (TIME_AMOUNT > 0);

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN_REGION_GROUP"                                     */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN_REGION_GROUP (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    CONSTRAINT PK_BD_REGION_GROUP PRIMARY KEY (APP_SID, BREAKDOWN_GROUP_ID, BREAKDOWN_ID, REGION_ID, COMPANY_SID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EC_QUESTIONNAIRE"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_QUESTIONNAIRE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    EC_QUESTIONNAIRE_ID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    GUID RAW(16) NOT NULL,
    CONSTRAINT PK_EC_QUESTIONNAIRE PRIMARY KEY (APP_SID, COMPANY_SID, EC_QUESTIONNAIRE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_ITEM"                                                    */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_ITEM (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    ITEM_ID NUMBER(10) NOT NULL,
    SUPPLIER_ID NUMBER(10),
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    SPEND NUMBER(20,10) NOT NULL,
    CURRENCY_ID NUMBER(10) NOT NULL,
    PURCHASE_DATE DATE NOT NULL,
    CREATED_BY_SID NUMBER(10) NOT NULL,
    CREATED_DTM DATE NOT NULL,
    MODIFIED_BY_SID NUMBER(10),
    LAST_MODIFIED_DTM DATE,
    ROW_NUMBER NUMBER(10),
    WORKSHEET_ID NUMBER(10),
    KG_CO2 NUMBER(10,30),
    AUTO_EIO_ID NUMBER(10),
    AUTO_EIO_ID_SCORE NUMBER(20,10),
    AUTO_EIO_ID_TWO NUMBER(10),
    AUTO_EIO_ID_SCORE_TWO NUMBER(20,10),
    MATCH_AUTO_ACCEPTED NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_PS_ITEM PRIMARY KEY (APP_SID, COMPANY_SID, ITEM_ID),
    CONSTRAINT TUC_PS_ITEM_ID UNIQUE (ITEM_ID),
    CONSTRAINT TCC_PS_ITEM_SPEND CHECK (SPEND > 0),
    CONSTRAINT TCC_PS_ITEM_NOSUPPLYSELF CHECK (COMPANY_SID <> SUPPLIER_ID),
    CONSTRAINT TUC_PS_ITEM_UNIQUE_ROW UNIQUE (WORKSHEET_ID, ROW_NUMBER),
    CONSTRAINT TCC_PS_ITEM_WORKHSEET CHECK ((WORKSHEET_ID IS NULL AND ROW_NUMBER IS NULL) OR (WORKSHEET_ID IS NOT NULL AND ROW_NUMBER IS NOT NULL)),
    CONSTRAINT TCC_PS_ITEM_MODIFIED_VALID CHECK ((MODIFIED_BY_SID IS NULL AND LAST_MODIFIED_DTM IS NULL) OR (MODIFIED_BY_SID IS NOT NULL AND LAST_MODIFIED_DTM IS NOT NULL))
);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CC_PS_ITEM_AUTO_EIO_ID_SCORE 
    CHECK (AUTO_EIO_ID_SCORE >= 0);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CC_PS_ITEM_KG_CO2 
    CHECK (KG_CO2 >= 0);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CC_PS_ITEM_MATCH_AUTO_ACCEPTED 
    CHECK (MATCH_AUTO_ACCEPTED IN (1,0));

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CC_PS_ITM_AUTO_EIO_ID_SCORE_2 
    CHECK (AUTO_EIO_ID_SCORE_TWO >= 0);

COMMENT ON TABLE CT.PS_ITEM IS 'Purchased products and services';

/* ---------------------------------------------------------------------- */
/* Add table "HT_CONSUMPTION_REGION"                                      */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HT_CONSUMPTION_REGION (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    HT_CONSUMPTION_CATEGORY_ID NUMBER(10) NOT NULL,
    AMOUNT NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_HT_CONS_RG PRIMARY KEY (APP_SID, COMPANY_SID, HT_CONSUMPTION_TYPE_ID, REGION_ID, HT_CONSUMPTION_CATEGORY_ID)
);

ALTER TABLE CT.HT_CONSUMPTION_REGION ADD CONSTRAINT CC_CONS_REGION_AMOUNT 
    CHECK (AMOUNT >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "WORKSHEET_VALUE_MAP_BREAKDOWN"                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.WORKSHEET_VALUE_MAP_BREAKDOWN (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    VALUE_MAP_ID NUMBER(10) NOT NULL,
    VALUE_MAPPER_ID NUMBER(10) DEFAULT 102 NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_WSVM_BREAKDOWN PRIMARY KEY (APP_SID, VALUE_MAP_ID, VALUE_MAPPER_ID)
);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_BREAKDOWN ADD CONSTRAINT CC_WSVM_BREAKDOWN_VHID 
    CHECK (VALUE_MAPPER_ID = 102);

/* ---------------------------------------------------------------------- */
/* Add table "WORKSHEET_VALUE_MAP_REGION"                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.WORKSHEET_VALUE_MAP_REGION (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    VALUE_MAP_ID NUMBER(10) NOT NULL,
    VALUE_MAPPER_ID NUMBER(10) DEFAULT 101 NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    CONSTRAINT PK_WSVM_REGION PRIMARY KEY (APP_SID, VALUE_MAP_ID, VALUE_MAPPER_ID)
);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_REGION ADD CONSTRAINT CC_WSVM_REGION_VHID 
    CHECK (VALUE_MAPPER_ID = 101);

/* ---------------------------------------------------------------------- */
/* Add table "BT_EMISSIONS"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_EMISSIONS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    CALCULATION_SOURCE_ID NUMBER(10) NOT NULL,
    CAR_KG_CO2 NUMBER(30,10) NOT NULL,
    BUS_KG_CO2 NUMBER(30,10) NOT NULL,
    TRAIN_KG_CO2 NUMBER(30,10) NOT NULL,
    MOTORBIKE_KG_CO2 NUMBER(30,10) NOT NULL,
    BIKE_KG_CO2 NUMBER(30,10) NOT NULL,
    WALK_KG_CO2 NUMBER(30,10) NOT NULL,
    AIR_KG_CO2 NUMBER(30,10) NOT NULL,
    CONSTRAINT PK_BT_EM PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID, CALCULATION_SOURCE_ID)
);

ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT CC_BT_EM_AIR_KG_CO2 
    CHECK (AIR_KG_CO2 >= 0);

ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT CC_BT_EM_BIKE_KG_CO2 
    CHECK (BIKE_KG_CO2 >= 0);

ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT CC_BT_EM_BUS_KG_CO2 
    CHECK (BUS_KG_CO2 >= 0);

ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT CC_BT_EM_CAR_KG_CO2 
    CHECK (CAR_KG_CO2 >= 0);

ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT CC_BT_EM_MOTORBIKE_KG_CO2 
    CHECK (MOTORBIKE_KG_CO2 >= 0);

ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT CC_BT_EM_TRAIN_KG_CO2 
    CHECK (TRAIN_KG_CO2 >= 0);

ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT CC_BT_EM_WALK_KG_CO2 
    CHECK (WALK_KG_CO2 >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "EC_EMISSIONS_ALL"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_EMISSIONS_ALL (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    CALCULATION_SOURCE_ID NUMBER(10) NOT NULL,
    CONTRIBUTION_SOURCE_ID NUMBER(10) NOT NULL,
    CAR_KG_CO2 NUMBER(30,10) NOT NULL,
    BUS_KG_CO2 NUMBER(30,10) NOT NULL,
    TRAIN_KG_CO2 NUMBER(30,10) NOT NULL,
    MOTORBIKE_KG_CO2 NUMBER(30,10) NOT NULL,
    BIKE_KG_CO2 NUMBER(30,10) NOT NULL,
    WALK_KG_CO2 NUMBER(30,10) NOT NULL,
    CONSTRAINT PK_EC_EM PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID, CALCULATION_SOURCE_ID, CONTRIBUTION_SOURCE_ID)
);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD CONSTRAINT CC_EC_EM_BIKE_KG_CO2 
    CHECK (BIKE_KG_CO2 >= 0);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD CONSTRAINT CC_EC_EM_BUS_KG_CO2 
    CHECK (BUS_KG_CO2 >= 0);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD CONSTRAINT CC_EC_EM_CAR_KG_CO2 
    CHECK (CAR_KG_CO2 >= 0);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD CONSTRAINT CC_EC_EM_MOTORBIKE_KG_CO2 
    CHECK (MOTORBIKE_KG_CO2 >= 0);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD CONSTRAINT CC_EC_EM_TRAIN_KG_CO2 
    CHECK (TRAIN_KG_CO2 >= 0);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD CONSTRAINT CC_EC_EM_WALK_KG_CO2 
    CHECK (WALK_KG_CO2 >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "PS_EMISSIONS_ALL"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_EMISSIONS_ALL (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    CALCULATION_SOURCE_ID NUMBER(10) NOT NULL,
    CONTRIBUTION_SOURCE_ID NUMBER(10) NOT NULL,
    KG_CO2 NUMBER(30,10) NOT NULL,
    CONSTRAINT PK_PS_EM PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID, EIO_ID, CALCULATION_SOURCE_ID, CONTRIBUTION_SOURCE_ID)
);

ALTER TABLE CT.PS_EMISSIONS_ALL ADD CONSTRAINT CC_PS_EM_KG_CO2 
    CHECK (KG_CO2 >= 0);

/* ---------------------------------------------------------------------- */
/* Add table "PS_SPEND_BREAKDOWN"                                         */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_SPEND_BREAKDOWN (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    SPEND NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_PS_SPEND PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "PS_ITEM_EIO"                                                */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PS_ITEM_EIO (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    ITEM_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    PCT NUMBER(3) NOT NULL,
    CONSTRAINT PK_PS_ITEM_EIO PRIMARY KEY (APP_SID, COMPANY_SID, ITEM_ID, EIO_ID)
);

ALTER TABLE CT.PS_ITEM_EIO ADD CONSTRAINT CC_PS_ITEM_EIO_PCT 
    CHECK (PCT>=0 AND PCT<=100);

/* ---------------------------------------------------------------------- */
/* Foreign key constraints                                                */
/* ---------------------------------------------------------------------- */

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT BD_TYPE_BREAKDOWN 
    FOREIGN KEY (APP_SID, BREAKDOWN_TYPE_ID) REFERENCES CT.BREAKDOWN_TYPE (APP_SID,BREAKDOWN_TYPE_ID);

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT COMPANY_BREAKDOWN 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT REGION_BREAKDOWN 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.BREAKDOWN_REGION_EIO ADD CONSTRAINT EIO_B_R_E 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.BREAKDOWN_REGION_EIO ADD CONSTRAINT B_R_B_R_E 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.BREAKDOWN_TYPE ADD CONSTRAINT COMPANY_BD_TYPE 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BREAKDOWN_TYPE ADD CONSTRAINT CUSTOMER_OPTIONS_BD_TYPE 
    FOREIGN KEY (APP_SID) REFERENCES CT.CUSTOMER_OPTIONS (APP_SID);

ALTER TABLE CT.EC_CAR_MODEL ADD CONSTRAINT EC_CAR_MAN_EC_CAR_MOD 
    FOREIGN KEY (MANUFACTURER_ID) REFERENCES CT.EC_CAR_MANUFACTURER (MANUFACTURER_ID);

ALTER TABLE CT.EC_CAR_MODEL ADD CONSTRAINT FUEL_TYPE_EC_CAR_MOD 
    FOREIGN KEY (FUEL_TYPE_ID) REFERENCES CT.EC_FUEL_TYPE (FUEL_TYPE_ID);

ALTER TABLE CT.COMPANY ADD CONSTRAINT CURRENCY_PERIOD_COMPANY 
    FOREIGN KEY (PERIOD_ID, CURRENCY_ID) REFERENCES CT.CURRENCY_PERIOD (PERIOD_ID,CURRENCY_ID);

ALTER TABLE CT.COMPANY ADD CONSTRAINT BUSINESS_TYPE_COMPANY 
    FOREIGN KEY (BUSINESS_TYPE_ID) REFERENCES CT.BUSINESS_TYPE (BUSINESS_TYPE_ID);

ALTER TABLE CT.COMPANY ADD CONSTRAINT EIO_COMPANY 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.COMPANY ADD CONSTRAINT SCOPE_INPUT_TYPE_COMPANY 
    FOREIGN KEY (SCOPE_INPUT_TYPE_ID) REFERENCES CT.SCOPE_INPUT_TYPE (SCOPE_INPUT_TYPE_ID);

ALTER TABLE CT.COMPANY ADD CONSTRAINT CUSTOMER_OPTIONS_COMPANY 
    FOREIGN KEY (APP_SID) REFERENCES CT.CUSTOMER_OPTIONS (APP_SID);

ALTER TABLE CT.COMPANY_CONSUMPTION_TYPE ADD CONSTRAINT COMPANY_COMPANY_CONS_TYPE 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.COMPANY_CONSUMPTION_TYPE ADD CONSTRAINT CONS_TYPE_COMPANY_CONS_TYPE 
    FOREIGN KEY (CONSUMPTION_TYPE_ID) REFERENCES CT.CONSUMPTION_TYPE (CONSUMPTION_TYPE_ID);

ALTER TABLE CT.CURRENCY_PERIOD ADD CONSTRAINT CURRENCY_CURRENCY_PERIOD 
    FOREIGN KEY (CURRENCY_ID) REFERENCES CT.CURRENCY (CURRENCY_ID);

ALTER TABLE CT.CURRENCY_PERIOD ADD CONSTRAINT PERIOD_CURRENCY_PERIOD 
    FOREIGN KEY (PERIOD_ID) REFERENCES CT.PERIOD (PERIOD_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT EC_CAR_MOD_EC_QA 
    FOREIGN KEY (CAR_ID) REFERENCES CT.EC_CAR_MODEL (CAR_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CR_DIST_UNIT_EC_QA 
    FOREIGN KEY (CAR_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT BS_DIST_UNIT_EC_QA 
    FOREIGN KEY (BUS_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT TR_DIST_UNIT_EC_QA 
    FOREIGN KEY (TRAIN_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT MB_DIST_UNIT_EC_QA 
    FOREIGN KEY (MOTORBIKE_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT BK_DIST_UNIT_EC_QA 
    FOREIGN KEY (BIKE_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT WK_DIST_UNIT_EC_QA 
    FOREIGN KEY (WALK_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT EC_BUS_TY_EC_QA 
    FOREIGN KEY (BUS_TYPE_ID) REFERENCES CT.EC_BUS_TYPE (BUS_TYPE_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT EC_TRAIN_TY_EC_QA 
    FOREIGN KEY (TRAIN_TYPE_ID) REFERENCES CT.EC_TRAIN_TYPE (TRAIN_TYPE_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT EC_MB_TY_EC_QA 
    FOREIGN KEY (MOTORBIKE_TYPE_ID) REFERENCES CT.EC_MOTORBIKE_TYPE (MOTORBIKE_TYPE_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT EC_QUESTIONNAIRE_EC_QA 
    FOREIGN KEY (COMPANY_SID, EC_QUESTIONNAIRE_ID, APP_SID) REFERENCES CT.EC_QUESTIONNAIRE (COMPANY_SID,EC_QUESTIONNAIRE_ID,APP_SID);

ALTER TABLE CT.EC_REGION_FACTORS ADD CONSTRAINT REGION_ERF 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.EIO ADD CONSTRAINT EIO_GROUP_EIO 
    FOREIGN KEY (EIO_GROUP_ID) REFERENCES CT.EIO_GROUP (EIO_GROUP_ID);

ALTER TABLE CT.EIO_RELATIONSHIP ADD CONSTRAINT EIO_EIO_RELATIONSHIP_PRI 
    FOREIGN KEY (PRIMARY_EIO_CAT_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.EIO_RELATIONSHIP ADD CONSTRAINT EIO_EIO_RELATIONSHIP_REL 
    FOREIGN KEY (RELATED_EIO_CAT_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.HOT_REGION ADD CONSTRAINT REGION_HOT_REGION 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.REGION ADD CONSTRAINT REGION_REGION_PARENT 
    FOREIGN KEY (PARENT_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.BREAKDOWN_REGION ADD CONSTRAINT BREAKDOWN_B_R 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID) REFERENCES CT.BREAKDOWN (APP_SID,BREAKDOWN_ID);

ALTER TABLE CT.BREAKDOWN_REGION ADD CONSTRAINT REGION_B_R 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT B_R_E_H_R 
    FOREIGN KEY (APP_SID, REGION_ID, BREAKDOWN_ID, EIO_ID) REFERENCES CT.BREAKDOWN_REGION_EIO (APP_SID,REGION_ID,BREAKDOWN_ID,EIO_ID);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT COMPANY_H_R 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.EIO_GROUP_ADVICE ADD CONSTRAINT EIO_GROUP_E_G_A 
    FOREIGN KEY (EIO_GROUP_ID) REFERENCES CT.EIO_GROUP (EIO_GROUP_ID);

ALTER TABLE CT.EIO_GROUP_ADVICE ADD CONSTRAINT ADVICE_E_G_A 
    FOREIGN KEY (ADVICE_ID) REFERENCES CT.ADVICE (ADVICE_ID);

ALTER TABLE CT.EIO_ADVICE ADD CONSTRAINT EIO_E_A 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.EIO_ADVICE ADD CONSTRAINT ADVICE_E_A 
    FOREIGN KEY (ADVICE_ID) REFERENCES CT.ADVICE (ADVICE_ID);

ALTER TABLE CT.ADVICE_URL ADD CONSTRAINT ADVICE_ADVICE_URL 
    FOREIGN KEY (ADVICE_ID) REFERENCES CT.ADVICE (ADVICE_ID);

ALTER TABLE CT.SCOPE_3_ADVICE ADD CONSTRAINT S_3_CAT_S_3_ADV 
    FOREIGN KEY (SCOPE_CATEGORY_ID) REFERENCES CT.SCOPE_3_CATEGORY (SCOPE_CATEGORY_ID);

ALTER TABLE CT.SCOPE_3_ADVICE ADD CONSTRAINT ADVICE_S_3_ADV 
    FOREIGN KEY (ADVICE_ID) REFERENCES CT.ADVICE (ADVICE_ID);

ALTER TABLE CT.REPORT_TEMPLATE ADD CONSTRAINT TEMPLATE_KEY_REPORT_TPL 
    FOREIGN KEY (LOOKUP_KEY) REFERENCES CT.TEMPLATE_KEY (LOOKUP_KEY);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT CR_DIST_UNIT_EC_PROFILE 
    FOREIGN KEY (CAR_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT BS_DIST_UNIT_EC_PROFILE 
    FOREIGN KEY (BUS_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT TR_DIST_UNIT_EC_PROFILE 
    FOREIGN KEY (TRAIN_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT MB_DIST_UNIT_EC_PROFILE 
    FOREIGN KEY (MOTORBIKE_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT BK_DIST_UNIT_EC_PROFILE 
    FOREIGN KEY (BIKE_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT WK_DIST_UNIT_EC_PROFILE 
    FOREIGN KEY (WALK_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.EC_PROFILE ADD CONSTRAINT BD_GROUP_EC_PROFILE 
    FOREIGN KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID) REFERENCES CT.BREAKDOWN_GROUP (APP_SID,COMPANY_SID,BREAKDOWN_GROUP_ID);

ALTER TABLE CT.EC_CAR_ENTRY ADD CONSTRAINT EC_CAR_TY_EC_CAR_ENTRY 
    FOREIGN KEY (CAR_TYPE_ID) REFERENCES CT.EC_CAR_TYPE (CAR_TYPE_ID);

ALTER TABLE CT.EC_CAR_ENTRY ADD CONSTRAINT EC_PROFILE_EC_CAR_ENTRY 
    FOREIGN KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID) REFERENCES CT.EC_PROFILE (APP_SID,COMPANY_SID,BREAKDOWN_GROUP_ID);

ALTER TABLE CT.EC_BUS_ENTRY ADD CONSTRAINT EC_PROFILE_EC_BUS_ENTRY 
    FOREIGN KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID) REFERENCES CT.EC_PROFILE (APP_SID,COMPANY_SID,BREAKDOWN_GROUP_ID);

ALTER TABLE CT.EC_BUS_ENTRY ADD CONSTRAINT EC_BUS_TY_EC_BUS_ENTRY 
    FOREIGN KEY (BUS_TYPE_ID) REFERENCES CT.EC_BUS_TYPE (BUS_TYPE_ID);

ALTER TABLE CT.EC_TRAIN_ENTRY ADD CONSTRAINT EC_PROFILE_EC_TRAIN_ENTRY 
    FOREIGN KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID) REFERENCES CT.EC_PROFILE (APP_SID,COMPANY_SID,BREAKDOWN_GROUP_ID);

ALTER TABLE CT.EC_TRAIN_ENTRY ADD CONSTRAINT EC_TRAIN_TY_EC_TRAIN_ENTRY 
    FOREIGN KEY (TRAIN_TYPE_ID) REFERENCES CT.EC_TRAIN_TYPE (TRAIN_TYPE_ID);

ALTER TABLE CT.EC_MOTORBIKE_ENTRY ADD CONSTRAINT EC_PROFILE_EC_MB_ENTRY 
    FOREIGN KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID) REFERENCES CT.EC_PROFILE (APP_SID,COMPANY_SID,BREAKDOWN_GROUP_ID);

ALTER TABLE CT.EC_MOTORBIKE_ENTRY ADD CONSTRAINT EC_MB_TY_EC_MB_ENTRY 
    FOREIGN KEY (MOTORBIKE_TYPE_ID) REFERENCES CT.EC_MOTORBIKE_TYPE (MOTORBIKE_TYPE_ID);

ALTER TABLE CT.BRICK ADD CONSTRAINT COMPANY_BRICK 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BRICK ADD CONSTRAINT BRICK_BRICK 
    FOREIGN KEY (PARENT_BRICK_ID, APP_SID) REFERENCES CT.BRICK (BRICK_ID,APP_SID);

ALTER TABLE CT.BRICK ADD CONSTRAINT EIO_BRICK 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.BRICK ADD CONSTRAINT CUSTOMER_OPTIONS_BRICK 
    FOREIGN KEY (APP_SID) REFERENCES CT.CUSTOMER_OPTIONS (APP_SID);

ALTER TABLE CT.CORE_BRICK ADD CONSTRAINT CORE_BRICK_CORE_BRICK 
    FOREIGN KEY (PARENT_CORE_BRICK_ID) REFERENCES CT.CORE_BRICK (CORE_BRICK_ID);

ALTER TABLE CT.CORE_BRICK ADD CONSTRAINT EIO_CORE_BRICK 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.UP_PRODUCT ADD CONSTRAINT COMPANY_UP_PRODUCT 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.UP_PRODUCT ADD CONSTRAINT BRICK_UP_PRODUCT 
    FOREIGN KEY (APP_SID, BRICK_ID) REFERENCES CT.BRICK (APP_SID,BRICK_ID);

ALTER TABLE CT.BT_REGION_FACTORS ADD CONSTRAINT REGION_BTRF 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CR_BT_EST_TYPE_BT_PRF 
    FOREIGN KEY (CAR_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT BS_BT_EST_TYPE_BT_PRF 
    FOREIGN KEY (BUS_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT TR_BT_EST_TYPE_BT_PRF 
    FOREIGN KEY (TRAIN_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT MB_BT_EST_TYPE_BT_PRF 
    FOREIGN KEY (MOTORBIKE_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT BK_BT_EST_TYPE_BT_PRF 
    FOREIGN KEY (BIKE_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT WK_BT_EST_TYPE_BT_PRF 
    FOREIGN KEY (WALK_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT AR_BT_EST_TYPE_BT_PRF 
    FOREIGN KEY (AIR_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT CR_DIST_UNIT_BT_PRF 
    FOREIGN KEY (CAR_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT BS_DIST_UNIT_BT_PRF 
    FOREIGN KEY (BUS_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT BK_DIST_UNIT_BT_PRF 
    FOREIGN KEY (BIKE_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT WK_DIST_UNIT_BT_PRF 
    FOREIGN KEY (WALK_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT AR_DIST_UNIT_BT_PRF 
    FOREIGN KEY (AIR_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT TR_DIST_UNIT_BT_PRF 
    FOREIGN KEY (TRAIN_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT MB_DIST_UNIT_BT_PRF 
    FOREIGN KEY (MOTORBIKE_DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT BD_GROUP_BT_PRF 
    FOREIGN KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID) REFERENCES CT.BREAKDOWN_GROUP (APP_SID,COMPANY_SID,BREAKDOWN_GROUP_ID);

ALTER TABLE CT.DATA_SOURCE_URL ADD CONSTRAINT DATA_SOURCE_ 
    FOREIGN KEY (DATA_SOURCE_ID) REFERENCES CT.DATA_SOURCE (DATA_SOURCE_ID);

ALTER TABLE CT.BT_TRAVEL_MODE ADD CONSTRAINT BT_TR_MDT_BT_TR_MD 
    FOREIGN KEY (BT_TRAVEL_MODE_TYPE_ID) REFERENCES CT.BT_TRAVEL_MODE_TYPE (BT_TRAVEL_MODE_TYPE_ID);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT BT_TR_MD_BT_CAR_TRIP 
    FOREIGN KEY (BT_TRAVEL_MODE_ID, BT_TRAVEL_MODE_TYPE_ID) REFERENCES CT.BT_TRAVEL_MODE (BT_TRAVEL_MODE_ID,BT_TRAVEL_MODE_TYPE_ID);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT CURRENCY_BT_CAR_TRIP 
    FOREIGN KEY (CURRENCY_ID) REFERENCES CT.CURRENCY (CURRENCY_ID);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT DIST_UNIT_BT_CAR_TRIP 
    FOREIGN KEY (DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT VOLUME_UNIT_BT_CAR_TRIP 
    FOREIGN KEY (FUEL_UNIT_ID) REFERENCES CT.VOLUME_UNIT (VOLUME_UNIT_ID);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT BT_FUEL_BT_CAR_TRIP 
    FOREIGN KEY (BT_FUEL_ID) REFERENCES CT.BT_FUEL (BT_FUEL_ID);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT BT_EST_TYPE_BT_CAR_TRIP 
    FOREIGN KEY (BT_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT COMPANY_BT_CAR_TRIP 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT B_R_BT_CAR_TRIP 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT TU_BT_CAR_TRIP 
    FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID);

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT BT_TR_MD_BT_BUS_TRIP 
    FOREIGN KEY (BT_TRAVEL_MODE_TYPE_ID, BT_TRAVEL_MODE_ID) REFERENCES CT.BT_TRAVEL_MODE (BT_TRAVEL_MODE_TYPE_ID,BT_TRAVEL_MODE_ID);

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT DIST_UNIT_BT_BUS_TRIP 
    FOREIGN KEY (DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT BT_EST_TYPE_BT_BUS_TRIP 
    FOREIGN KEY (BT_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT COMPANY_BT_BUS_TRIP 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT B_R_BT_BUS_TRIP 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT TU_BT_BUS_TRIP 
    FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID);

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT BT_TR_MD_BT_TR_TRIP 
    FOREIGN KEY (BT_TRAVEL_MODE_TYPE_ID, BT_TRAVEL_MODE_ID) REFERENCES CT.BT_TRAVEL_MODE (BT_TRAVEL_MODE_TYPE_ID,BT_TRAVEL_MODE_ID);

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT DIST_UNIT_BT_TR_TRIP 
    FOREIGN KEY (DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT BT_EST_TYPE_BT_TR_TRIP 
    FOREIGN KEY (BT_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT COMPANY_BT_TR_TRIP 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT B_R_BT_TR_TRIP 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT TU_BT_TR_TRIP 
    FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID);

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT BT_TR_MD_BT_AIR_TRIP 
    FOREIGN KEY (BT_TRAVEL_MODE_TYPE_ID, BT_TRAVEL_MODE_ID) REFERENCES CT.BT_TRAVEL_MODE (BT_TRAVEL_MODE_TYPE_ID,BT_TRAVEL_MODE_ID);

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT DIST_UNIT_BT_AIR_TRIP 
    FOREIGN KEY (DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT BT_EST_TYPE_BT_AIR_TRIP 
    FOREIGN KEY (BT_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT COMPANY_BT_AIR_TRIP 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT B_R_BT_AIR_TRIP 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT TU_BT_AIR_TRIP 
    FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID);

ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT BT_TR_MD_BT_CAB_TRIP 
    FOREIGN KEY (BT_TRAVEL_MODE_TYPE_ID, BT_TRAVEL_MODE_ID) REFERENCES CT.BT_TRAVEL_MODE (BT_TRAVEL_MODE_TYPE_ID,BT_TRAVEL_MODE_ID);

ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT CURRENCY_BT_CAB_TRIP 
    FOREIGN KEY (CURRENCY_ID) REFERENCES CT.CURRENCY (CURRENCY_ID);

ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT BT_EST_TYPE_BT_CAB_TRIP 
    FOREIGN KEY (BT_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT COMPANY_BT_CAB_TRIP 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT B_R_BT_CAB_TRIP 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT TU_BT_CAB_TRIP 
    FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT BT_TR_MD_BT_MB_TRIP 
    FOREIGN KEY (BT_TRAVEL_MODE_TYPE_ID, BT_TRAVEL_MODE_ID) REFERENCES CT.BT_TRAVEL_MODE (BT_TRAVEL_MODE_TYPE_ID,BT_TRAVEL_MODE_ID);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT CURRENCY_BT_MB_TRIP 
    FOREIGN KEY (CURRENCY_ID) REFERENCES CT.CURRENCY (CURRENCY_ID);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT DIST_UNIT_BT_MB_TRIP 
    FOREIGN KEY (DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT VOLUME_UNIT_BT_MB_TRIP 
    FOREIGN KEY (FUEL_UNIT_ID) REFERENCES CT.VOLUME_UNIT (VOLUME_UNIT_ID);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT BT_FUEL_BT_MB_TRIP 
    FOREIGN KEY (BT_FUEL_ID) REFERENCES CT.BT_FUEL (BT_FUEL_ID);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT BT_EST_TYPE_BT_MB_TRIP 
    FOREIGN KEY (BT_ESTIMATE_TYPE_ID) REFERENCES CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT COMPANY_BT_MB_TRIP 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT B_R_BT_MB_TRIP 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT TU_BT_MB_TRIP 
    FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID);

ALTER TABLE CT.BREAKDOWN_GROUP ADD CONSTRAINT BD_TYPE_BD_GROUP 
    FOREIGN KEY (APP_SID, BREAKDOWN_TYPE_ID) REFERENCES CT.BREAKDOWN_TYPE (APP_SID,BREAKDOWN_TYPE_ID);

ALTER TABLE CT.BREAKDOWN_GROUP ADD CONSTRAINT COMPANY_BD_GROUP 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BREAKDOWN_REGION_GROUP ADD CONSTRAINT BD_GROUP_BD_REGION_GROUP 
    FOREIGN KEY (APP_SID, BREAKDOWN_GROUP_ID, COMPANY_SID) REFERENCES CT.BREAKDOWN_GROUP (APP_SID,BREAKDOWN_GROUP_ID,COMPANY_SID);

ALTER TABLE CT.BREAKDOWN_REGION_GROUP ADD CONSTRAINT B_R_BD_REGION_GROUP 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE ADD CONSTRAINT COMPANY_EC_QUESTIONNAIRE 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.EC_QUESTIONNAIRE ADD CONSTRAINT B_R_EC_QUESTIONNAIRE 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.EC_OPTIONS ADD CONSTRAINT COMPANY_EC_OPT 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.EC_OPTIONS ADD CONSTRAINT BD_TYPE_EC_OPT 
    FOREIGN KEY (APP_SID, BREAKDOWN_TYPE_ID) REFERENCES CT.BREAKDOWN_TYPE (APP_SID,BREAKDOWN_TYPE_ID);

ALTER TABLE CT.BT_OPTIONS ADD CONSTRAINT COMPANY_BT_OPT 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BT_OPTIONS ADD CONSTRAINT BD_TYPE_BT_OPT 
    FOREIGN KEY (APP_SID, BREAKDOWN_TYPE_ID) REFERENCES CT.BREAKDOWN_TYPE (APP_SID,BREAKDOWN_TYPE_ID);

ALTER TABLE CT.BT_OPTIONS ADD CONSTRAINT EXTRAP_TYPE_BT_OPT_TMP 
    FOREIGN KEY (TEMPORAL_EXTRAPOLATION_TYPE_ID) REFERENCES CT.EXTRAPOLATION_TYPE (EXTRAPOLATION_TYPE_ID);

ALTER TABLE CT.BT_OPTIONS ADD CONSTRAINT EXTRAP_TYPE_BT_OPT_EMP 
    FOREIGN KEY (EMPLOYEE_EXTRAPOLATION_TYPE_ID) REFERENCES CT.EXTRAPOLATION_TYPE (EXTRAPOLATION_TYPE_ID);

ALTER TABLE CT.UP_OPTIONS ADD CONSTRAINT COMPANY_UP_OPT 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.UP_OPTIONS ADD CONSTRAINT BD_TYPE_UP_OPT 
    FOREIGN KEY (APP_SID, BREAKDOWN_TYPE_ID) REFERENCES CT.BREAKDOWN_TYPE (APP_SID,BREAKDOWN_TYPE_ID);

ALTER TABLE CT.PS_OPTIONS ADD CONSTRAINT COMPANY_PS_OPT 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.PS_OPTIONS ADD CONSTRAINT BD_TYPE_PS_OPT 
    FOREIGN KEY (APP_SID, BREAKDOWN_TYPE_ID) REFERENCES CT.BREAKDOWN_TYPE (APP_SID,BREAKDOWN_TYPE_ID);

ALTER TABLE CT.PS_OPTIONS ADD CONSTRAINT PERIOD_PS_OPT 
    FOREIGN KEY (PERIOD_ID) REFERENCES CT.PERIOD (PERIOD_ID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT COMPANY_PS_ITEM 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CURRENCY_PS_ITEM 
    FOREIGN KEY (CURRENCY_ID) REFERENCES CT.CURRENCY (CURRENCY_ID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT B_R_PS_ITEM 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT SUPPLIER_PS_ITEM 
    FOREIGN KEY (APP_SID, SUPPLIER_ID) REFERENCES CT.SUPPLIER (APP_SID,SUPPLIER_ID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT EIO_PS_ITEM_AUTO 
    FOREIGN KEY (AUTO_EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT EIO_PS_ITEM_AUTO2 
    FOREIGN KEY (AUTO_EIO_ID_TWO) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.SUPPLIER ADD CONSTRAINT COMPANY_SUPPLIER_1 
    FOREIGN KEY (APP_SID, OWNER_COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.SUPPLIER ADD CONSTRAINT SUPPLIER_STATUS_SUPPLIER 
    FOREIGN KEY (STATUS_ID) REFERENCES CT.SUPPLIER_STATUS (STATUS_ID);

ALTER TABLE CT.SUPPLIER ADD CONSTRAINT CUSTOMER_OPTIONS_SUPPLIER 
    FOREIGN KEY (APP_SID) REFERENCES CT.CUSTOMER_OPTIONS (APP_SID);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_MASS_UNIT ADD CONSTRAINT MASS_HT_CONS_TYP_MASS 
    FOREIGN KEY (MASS_UNIT_ID) REFERENCES CT.MASS_UNIT (MASS_UNIT_ID);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_MASS_UNIT ADD CONSTRAINT HT_CONS_TYPE_MASS_UNIT 
    FOREIGN KEY (HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID) REFERENCES CT.HT_CONSUMPTION_TYPE (HT_CONSUMPTION_TYPE_ID,HT_CONSUMPTION_CATEGORY_ID);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_POWER_UNIT ADD CONSTRAINT PWR_HT_CONS_TYPE_PWR 
    FOREIGN KEY (POWER_UNIT_ID) REFERENCES CT.POWER_UNIT (POWER_UNIT_ID);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_POWER_UNIT ADD CONSTRAINT HT_CONS_TYPE_PWR_UNIT 
    FOREIGN KEY (HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID) REFERENCES CT.HT_CONSUMPTION_TYPE (HT_CONSUMPTION_TYPE_ID,HT_CONSUMPTION_CATEGORY_ID);

ALTER TABLE CT.HT_CONSUMPTION_TYPE ADD CONSTRAINT HT_CONS_CAT_HT_CONS_TYPE 
    FOREIGN KEY (HT_CONSUMPTION_CATEGORY_ID) REFERENCES CT.HT_CONSUMPTION_CATEGORY (HT_CONSUMPTION_CATEGORY_ID);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_VOL_UNIT ADD CONSTRAINT VOLUME_UNIT_HT_CONS_TYPE_VOL 
    FOREIGN KEY (VOLUME_UNIT_ID) REFERENCES CT.VOLUME_UNIT (VOLUME_UNIT_ID);

ALTER TABLE CT.HT_CONSUMPTION_TYPE_VOL_UNIT ADD CONSTRAINT HT_CONS_TYPE_VOL_UNIT 
    FOREIGN KEY (HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID) REFERENCES CT.HT_CONSUMPTION_TYPE (HT_CONSUMPTION_TYPE_ID,HT_CONSUMPTION_CATEGORY_ID);

ALTER TABLE CT.HT_CONSUMPTION ADD CONSTRAINT HT_CONS_TYPE_HT_CONS 
    FOREIGN KEY (HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID) REFERENCES CT.HT_CONSUMPTION_TYPE (HT_CONSUMPTION_TYPE_ID,HT_CONSUMPTION_CATEGORY_ID);

ALTER TABLE CT.HT_CONSUMPTION ADD CONSTRAINT COMPANY_HT_CONS 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.HT_CONSUMPTION ADD CONSTRAINT MASS_HT_CONS 
    FOREIGN KEY (MASS_UNIT_ID) REFERENCES CT.MASS_UNIT (MASS_UNIT_ID);

ALTER TABLE CT.HT_CONSUMPTION ADD CONSTRAINT PWR_HT_CONS 
    FOREIGN KEY (POWER_UNIT_ID) REFERENCES CT.POWER_UNIT (POWER_UNIT_ID);

ALTER TABLE CT.HT_CONSUMPTION ADD CONSTRAINT VOLUME_UNIT_HT_CONS 
    FOREIGN KEY (VOLUME_UNIT_ID) REFERENCES CT.VOLUME_UNIT (VOLUME_UNIT_ID);

ALTER TABLE CT.HT_CONSUMPTION_REGION ADD CONSTRAINT HT_CONS_HT_CONS_RG 
    FOREIGN KEY (APP_SID, COMPANY_SID, HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID) REFERENCES CT.HT_CONSUMPTION (APP_SID,COMPANY_SID,HT_CONSUMPTION_TYPE_ID,HT_CONSUMPTION_CATEGORY_ID);

ALTER TABLE CT.HT_CONSUMPTION_REGION ADD CONSTRAINT REGION_HT_CONS_RG 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_CURRENCY ADD CONSTRAINT CURRENCY_WSVM_CURRENCY 
    FOREIGN KEY (CURRENCY_ID) REFERENCES CT.CURRENCY (CURRENCY_ID);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_BREAKDOWN ADD CONSTRAINT BREAKDOWN_WSVM_BREAKDOWN 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID) REFERENCES CT.BREAKDOWN (APP_SID,BREAKDOWN_ID);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_REGION ADD CONSTRAINT REGION_WSVM_REGION 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_SUPPLIER ADD CONSTRAINT SUPPLIER_WSVM_SUPPLIER 
    FOREIGN KEY (APP_SID, SUPPLIER_ID) REFERENCES CT.SUPPLIER (APP_SID,SUPPLIER_ID);

ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT B_R_BT_EM 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT BT_CALCULATION_SOURCE_BT_EM 
    FOREIGN KEY (CALCULATION_SOURCE_ID) REFERENCES CT.BT_CALCULATION_SOURCE (CALCULATION_SOURCE_ID);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD CONSTRAINT B_R_EC_EM 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD CONSTRAINT EC_CONTRIBUTION_SOURCE_EC_EM 
    FOREIGN KEY (CONTRIBUTION_SOURCE_ID) REFERENCES CT.EC_CALCULATION_SOURCE (CALCULATION_SOURCE_ID);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD CONSTRAINT EC_CALCULATION_SOURCE_EC_EM 
    FOREIGN KEY (CALCULATION_SOURCE_ID) REFERENCES CT.EC_CALCULATION_SOURCE (CALCULATION_SOURCE_ID);

ALTER TABLE CT.SUPPLIER_CONTACT ADD CONSTRAINT SUPPLIER_SUPPLIER_CONTACT 
    FOREIGN KEY (APP_SID, SUPPLIER_ID) REFERENCES CT.SUPPLIER (APP_SID,SUPPLIER_ID);

ALTER TABLE CT.PS_EMISSIONS_ALL ADD CONSTRAINT B_R_PS_EM 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.PS_EMISSIONS_ALL ADD CONSTRAINT EIO_PS_EM 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.PS_EMISSIONS_ALL ADD CONSTRAINT CONTRIBUTION_SOURCE_PS_EM 
    FOREIGN KEY (CONTRIBUTION_SOURCE_ID) REFERENCES CT.PS_CALCULATION_SOURCE (CALCULATION_SOURCE_ID);

ALTER TABLE CT.PS_EMISSIONS_ALL ADD CONSTRAINT CALCULATION_SOURCE_PS_EM 
    FOREIGN KEY (CALCULATION_SOURCE_ID) REFERENCES CT.PS_CALCULATION_SOURCE (CALCULATION_SOURCE_ID);

ALTER TABLE CT.PS_SPEND_BREAKDOWN ADD CONSTRAINT PS_OPT_PS_SPEND 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.PS_OPTIONS (APP_SID,COMPANY_SID);

ALTER TABLE CT.PS_SPEND_BREAKDOWN ADD CONSTRAINT B_R_PS_SPEND 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.PS_ATTRIBUTE ADD CONSTRAINT PS_AS_PS_ATT 
    FOREIGN KEY (PS_ATTRIBUTE_SOURCE_ID) REFERENCES CT.PS_ATTRIBUTE_SOURCE (PS_ATTRIBUTE_SOURCE_ID);

ALTER TABLE CT.PS_ATTRIBUTE ADD CONSTRAINT PS_SM_PS_ATT 
    FOREIGN KEY (PS_STEM_METHOD_ID) REFERENCES CT.PS_STEM_METHOD (PS_STEM_METHOD_ID);

ALTER TABLE CT.PS_ATTRIBUTE ADD CONSTRAINT PS_BRK_PS_ATT 
    FOREIGN KEY (PS_BRICK_ID) REFERENCES CT.PS_BRICK (PS_BRICK_ID);

ALTER TABLE CT.PS_FAMILY ADD CONSTRAINT PS_SG_PS_FM 
    FOREIGN KEY (PS_SEGMENT_ID) REFERENCES CT.PS_SEGMENT (PS_SEGMENT_ID);

ALTER TABLE CT.PS_CLASS ADD CONSTRAINT PS_FM_PS_CLS 
    FOREIGN KEY (PS_FAMILY_ID) REFERENCES CT.PS_FAMILY (PS_FAMILY_ID);

ALTER TABLE CT.PS_BRICK ADD CONSTRAINT PS_CLS_PS_BRK 
    FOREIGN KEY (PS_CLASS_ID) REFERENCES CT.PS_CLASS (PS_CLASS_ID);

ALTER TABLE CT.PS_BRICK ADD CONSTRAINT PS_CT_PS_BRK 
    FOREIGN KEY (PS_CATEGORY_ID) REFERENCES CT.PS_CATEGORY (PS_CATEGORY_ID);

ALTER TABLE CT.PS_BRICK ADD CONSTRAINT EIO_PS_BRK 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.PS_SUPPLIER_EIO_FREQ ADD CONSTRAINT SUPPLIER_PS_SEF 
    FOREIGN KEY (APP_SID, SUPPLIER_ID) REFERENCES CT.SUPPLIER (APP_SID,SUPPLIER_ID);

ALTER TABLE CT.PS_SUPPLIER_EIO_FREQ ADD CONSTRAINT EIO_PS_SEF 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.WORKSHEET_VALUE_MAP_DISTANCE ADD CONSTRAINT DIST_UNIT_WSVM_DISTANCE 
    FOREIGN KEY (DISTANCE_UNIT_ID) REFERENCES CT.DISTANCE_UNIT (DISTANCE_UNIT_ID);

ALTER TABLE CT.BT_TRAVEL_MODE_TYPE ADD CONSTRAINT TRAVEL_MODE_BT_TR_MDT 
    FOREIGN KEY (TRAVEL_MODE_ID) REFERENCES CT.TRAVEL_MODE (TRAVEL_MODE_ID);

ALTER TABLE CT.HT_CONS_SOURCE ADD CONSTRAINT HT_CONS_TYPE_HT_CONS_SOURCE 
    FOREIGN KEY (HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID) REFERENCES CT.HT_CONSUMPTION_TYPE (HT_CONSUMPTION_TYPE_ID,HT_CONSUMPTION_CATEGORY_ID);

ALTER TABLE CT.HT_CONS_SOURCE_BREAKDOWN ADD CONSTRAINT HT_CONS_HT_CONS_SRC_BD 
    FOREIGN KEY (APP_SID, COMPANY_SID, HT_CONSUMPTION_TYPE_ID, HT_CONSUMPTION_CATEGORY_ID) REFERENCES CT.HT_CONSUMPTION (APP_SID,COMPANY_SID,HT_CONSUMPTION_TYPE_ID,HT_CONSUMPTION_CATEGORY_ID);

ALTER TABLE CT.HT_CONS_SOURCE_BREAKDOWN ADD CONSTRAINT HT_CONS_SOURCE_HT_CONS_SRC_BD 
    FOREIGN KEY (HT_CONS_SOURCE_ID) REFERENCES CT.HT_CONS_SOURCE (HT_CONS_SOURCE_ID);

ALTER TABLE CT.PS_ITEM_EIO ADD CONSTRAINT PS_ITEM_PS_ITEM_EIO 
    FOREIGN KEY (APP_SID, COMPANY_SID, ITEM_ID) REFERENCES CT.PS_ITEM (APP_SID,COMPANY_SID,ITEM_ID);

ALTER TABLE CT.PS_ITEM_EIO ADD CONSTRAINT EIO_PS_ITEM_EIO 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);
