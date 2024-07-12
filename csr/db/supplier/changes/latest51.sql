-- Please update version.sql too -- this keeps clean builds in sync
define version=51
@update_header

PROMPT update questionnaire tables to have new revision number in them

-- auto generated with ER studio




ALTER TABLE SUPPLIER.GT_FA_ANC_MAT DROP CONSTRAINT REFGT_FORMULATION_ANSWERS348
;
ALTER TABLE SUPPLIER.GT_FA_HAZ_CHEM DROP CONSTRAINT REFGT_FORMULATION_ANSWERS350
;
ALTER TABLE SUPPLIER.GT_FA_PALM_IND DROP CONSTRAINT REFGT_FORMULATION_ANSWERS352
;
ALTER TABLE SUPPLIER.GT_PACK_ITEM DROP CONSTRAINT REFGT_PACKAGING_ANSWERS360
;
ALTER TABLE SUPPLIER.GT_PA_PACK_REQ DROP CONSTRAINT REFGT_PACKAGING_ANSWERS357
;
ALTER TABLE SUPPLIER.GT_LINK_PRODUCT DROP CONSTRAINT REFGT_PRODUCT_ANSWERS415
;
ALTER TABLE SUPPLIER.GT_COUNTRY_MADE_IN DROP CONSTRAINT REFGT_TRANSPORT_ANSWERS345
;
ALTER TABLE SUPPLIER.GT_COUNTRY_SOLD_IN DROP CONSTRAINT REFGT_TRANSPORT_ANSWERS347
;

-- Drop Constraint, Rename and Create Table SQL

ALTER TABLE SUPPLIER.GT_COUNTRY_MADE_IN DROP CONSTRAINT REFCOUNTRY344
;
ALTER TABLE SUPPLIER.GT_COUNTRY_MADE_IN DROP CONSTRAINT REFGT_TRANSPORT_TYPE419
;
ALTER TABLE SUPPLIER.GT_COUNTRY_MADE_IN DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_COUNTRY_MADE_IN RENAME TO GT_COUNTRY_04282009125759000
;
CREATE TABLE GT_COUNTRY_MADE_IN
(
    PRODUCT_ID           NUMBER(10)  NOT NULL,
    COUNTRY_CODE         VARCHAR2(8) NOT NULL,
    GT_TRANSPORT_TYPE_ID NUMBER(10)  NOT NULL,
    REVISION_ID          NUMBER(10)  NOT NULL,
    MADE_INTERNALLY      NUMBER(1)   DEFAULT 0 NOT NULL,
    PCT                  NUMBER(6,3)     NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_COUNTRY_SOLD_IN DROP CONSTRAINT REFCOUNTRY346
;
ALTER TABLE SUPPLIER.GT_COUNTRY_SOLD_IN DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_COUNTRY_SOLD_IN RENAME TO GT_COUNTRY_04282009125800000
;
CREATE TABLE GT_COUNTRY_SOLD_IN
(
    PRODUCT_ID   NUMBER(10)  NOT NULL,
    COUNTRY_CODE VARCHAR2(8) NOT NULL,
    REVISION_ID  NUMBER(10)  NOT NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_FA_ANC_MAT DROP CONSTRAINT REFGT_ANCILLARY_MATERIAL402
;
ALTER TABLE SUPPLIER.GT_FA_ANC_MAT DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_FA_ANC_MAT RENAME TO GT_FA_ANC__04282009125801000
;
CREATE TABLE GT_FA_ANC_MAT
(
    GT_ANCILLARY_MATERIAL_ID NUMBER(10) NOT NULL,
    PRODUCT_ID               NUMBER(10) NOT NULL,
    REVISION_ID              NUMBER(10) NOT NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_FA_HAZ_CHEM DROP CONSTRAINT REFGT_HAZZARD_CHEMICAL351
;
ALTER TABLE SUPPLIER.GT_FA_HAZ_CHEM DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_FA_HAZ_CHEM RENAME TO GT_FA_HAZ__04282009125802000
;
CREATE TABLE GT_FA_HAZ_CHEM
(
    GT_HAZZARD_CHEMICAL_ID NUMBER(10) NOT NULL,
    PRODUCT_ID             NUMBER(10) NOT NULL,
    REVISION_ID            NUMBER(10) NOT NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_FA_PALM_IND DROP CONSTRAINT REFGT_PALM_INGRED353
;
ALTER TABLE SUPPLIER.GT_FA_PALM_IND DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_FA_PALM_IND RENAME TO GT_FA_PALM_04282009125803000
;
CREATE TABLE GT_FA_PALM_IND
(
    GT_PALM_INGRED_ID NUMBER(10) NOT NULL,
    PRODUCT_ID        NUMBER(10) NOT NULL,
    REVISION_ID       NUMBER(10) NOT NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_FORMULATION_ANSWERS DROP CONSTRAINT REFALL_PRODUCT355
;
ALTER TABLE SUPPLIER.GT_FORMULATION_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP354
;
ALTER TABLE SUPPLIER.GT_FORMULATION_ANSWERS DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_FORMULATION_ANSWERS RENAME TO GT_FORMULA_04282009125804000
;
CREATE TABLE GT_FORMULATION_ANSWERS
(
    PRODUCT_ID                 NUMBER(10)     NOT NULL,
    REVISION_ID                NUMBER(10)     NOT NULL,
    INGREDIENT_COUNT           NUMBER(10)         NULL,
    SF_INGREDIENTS             CLOB               NULL,
    SF_ADDITIONAL_MATERIALS    CLOB               NULL,
    SF_SPECIAL_MATERIALS       CLOB               NULL,
    CONCENTRATE                NUMBER(1)      DEFAULT 0 NOT NULL,
    BP_CROPS_PCT               NUMBER(6,3)        NULL,
    BP_FISH_PCT                NUMBER(6,3)        NULL,
    BP_PALM_PCT                NUMBER(6,3)        NULL,
    BP_WILD_PCT                NUMBER(6,3)        NULL,
    BP_UNKNOWN_PCT             NUMBER(6,3)        NULL,
    BP_THREATENED_PCT          NUMBER(6,3)        NULL,
    BP_MINERAL_PCT             NUMBER(6,3)        NULL,
    SF_BIODIVERSITY            CLOB               NULL,
    BS_ACCREDITED_PRIORITY_PCT NUMBER(6,3)        NULL,
    BS_ACCREDITED_PRIORITY_SRC VARCHAR2(4000)     NULL,
    BS_ACCREDITED_OTHER_PCT    NUMBER(6,3)        NULL,
    BS_ACCREDITED_OTHER_SRC    VARCHAR2(4000)     NULL,
    BS_KNOWN_PCT               NUMBER(6,3)        NULL,
    BS_UNKNOWN_PCT             NUMBER(6,3)        NULL,
    BS_NO_NATURAL_PCT          NUMBER(6,3)        NULL,
    BS_DOCUMENT_GROUP          NUMBER(10)     NOT NULL
)
LOB(SF_INGREDIENTS) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SF_ADDITIONAL_MATERIALS) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SF_SPECIAL_MATERIALS) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SF_BIODIVERSITY) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_LINK_PRODUCT DROP CONSTRAINT REFALL_PRODUCT416
;
ALTER TABLE SUPPLIER.GT_LINK_PRODUCT DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_LINK_PRODUCT RENAME TO GT_LINK_PR_04282009125805000
;
CREATE TABLE GT_LINK_PRODUCT
(
    PRODUCT_ID      NUMBER(10) NOT NULL,
    LINK_PRODUCT_ID NUMBER(10) NOT NULL,
    REVISION_ID     NUMBER(10) NOT NULL,
    COUNT           NUMBER(10) NOT NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_PACKAGING_ANSWERS DROP CONSTRAINT REFALL_PRODUCT366
;
ALTER TABLE SUPPLIER.GT_PACKAGING_ANSWERS DROP CONSTRAINT REFGT_ACCESS_PACK_TYPE361
;
ALTER TABLE SUPPLIER.GT_PACKAGING_ANSWERS DROP CONSTRAINT REFGT_ACCESS_VISC_TYPE362
;
ALTER TABLE SUPPLIER.GT_PACKAGING_ANSWERS DROP CONSTRAINT REFGT_GIFT_CONT_TYPE363
;
ALTER TABLE SUPPLIER.GT_PACKAGING_ANSWERS DROP CONSTRAINT REFGT_PACK_LAYERS_TYPE364
;
ALTER TABLE SUPPLIER.GT_PACKAGING_ANSWERS DROP CONSTRAINT REFGT_TRANS_PACK_TYPE365
;
ALTER TABLE SUPPLIER.GT_PACKAGING_ANSWERS DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_PACKAGING_ANSWERS RENAME TO GT_PACKAGI_04282009125806000
;
CREATE TABLE GT_PACKAGING_ANSWERS
(
    PRODUCT_ID             NUMBER(10)   NOT NULL,
    REVISION_ID            NUMBER(10)   NOT NULL,
    GT_ACCESS_PACK_TYPE_ID NUMBER(10)       NULL,
    GT_ACCESS_VISC_TYPE_ID NUMBER(10)       NULL,
    PROD_WEIGHT_INC_PACK   NUMBER(10,2)     NULL,
    REFILL_PACK            NUMBER(1)    DEFAULT 0 NOT NULL,
    SF_INNOVATION          CLOB             NULL,
    SF_NOVEL_REFILL        CLOB             NULL,
    SINGLE_IN_PACK         NUMBER(1)    DEFAULT 0 NOT NULL,
    SETTLE_IN_TRANSIT      NUMBER(1)    DEFAULT 0 NOT NULL,
    GT_GIFT_CONT_TYPE_ID   NUMBER(10)       NULL,
    GT_PACK_LAYERS_TYPE_ID NUMBER(10)       NULL,
    PACK_FOR_PROTECTION    NUMBER(1)    DEFAULT 0 NOT NULL,
    VOL_PACKAGE            NUMBER(10,2)     NULL,
    RETAIL_PACKS_STACKABLE NUMBER(1)    DEFAULT 0 NOT NULL,
    VOL_PROD_TRAN_PACK     NUMBER(10,2)     NULL,
    VOL_TRAN_PACK          NUMBER(10,2)     NULL,
    CORRECT_BIOPOLYMER_USE NUMBER(1)    DEFAULT 0     NULL,
    SF_RECYCLED_THRESHOLD  CLOB             NULL,
    SF_NOVEL_MATERIAL      CLOB             NULL,
    PACK_MEET_REQ          NUMBER(1)    DEFAULT 0 NOT NULL,
    PACK_SHELF_READY       NUMBER(1)    DEFAULT 0 NOT NULL,
    PACK_CONSUM_RCYLD      NUMBER(1)    DEFAULT 0 NOT NULL,
    PACK_CONSUM_PCT        NUMBER(6,3)      NULL,
    PACK_CONSUM_MAT        CLOB             NULL,
    GT_TRANS_PACK_TYPE_ID  NUMBER(10)       NULL,
    SF_INNOVATION_TRANSIT  CLOB             NULL
)
LOB(SF_INNOVATION) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SF_NOVEL_REFILL) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SF_RECYCLED_THRESHOLD) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SF_NOVEL_MATERIAL) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(PACK_CONSUM_MAT) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SF_INNOVATION_TRANSIT) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_PACK_ITEM DROP CONSTRAINT REFGT_PACK_MATERIAL_TYPE359
;
ALTER TABLE SUPPLIER.GT_PACK_ITEM DROP CONSTRAINT REFGT_PACK_SHAPE_TYPE358
;
ALTER TABLE SUPPLIER.GT_PACK_ITEM DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_PACK_ITEM DROP CONSTRAINT CHK_WEIGHT_GRAMS
;
ALTER TABLE SUPPLIER.GT_PACK_ITEM RENAME TO GT_PACK_IT_04282009125807000
;
CREATE TABLE GT_PACK_ITEM
(
    PRODUCT_ID               NUMBER(10)   NOT NULL,
    GT_PACK_ITEM_ID          NUMBER(10)   NOT NULL,
    REVISION_ID              NUMBER(10)   NOT NULL,
    GT_PACK_SHAPE_TYPE_ID    NUMBER(10)   NOT NULL,
    GT_PACK_MATERIAL_TYPE_ID NUMBER(10)   NOT NULL,
    WEIGHT_GRAMS             NUMBER(10,2) DEFAULT 0 NOT NULL,
    PCT_RECYCLED             NUMBER(6,3)  DEFAULT 0 NOT NULL,
    CONTAINS_BIOPOLYMER      NUMBER(1)    DEFAULT 0 NOT NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_PA_PACK_REQ DROP CONSTRAINT REFGT_PACK_REQ_TYPE356
;
ALTER TABLE SUPPLIER.GT_PA_PACK_REQ DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_PA_PACK_REQ RENAME TO GT_PA_PACK_04282009125808000
;
CREATE TABLE GT_PA_PACK_REQ
(
    PRODUCT_ID          NUMBER(10) NOT NULL,
    GT_PACK_REQ_TYPE_ID NUMBER(10) NOT NULL,
    REVISION_ID         NUMBER(10) NOT NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFALL_PRODUCT367
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP368
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP369
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP370
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP371
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP372
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP373
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP374
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP375
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP376
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFGT_PRODUCT_RANGE379
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP CONSTRAINT REFGT_PRODUCT_TYPE377
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_PRODUCT_ANSWERS RENAME TO GT_PRODUCT_04282009125809000
;
CREATE TABLE GT_PRODUCT_ANSWERS
(
    PRODUCT_ID           NUMBER(10)   NOT NULL,
    REVISION_ID          NUMBER(10)   NOT NULL,
    GT_SCOPE_NOTES       CLOB             NULL,
    GT_PRODUCT_RANGE_ID  NUMBER(10)       NULL,
    GT_PRODUCT_TYPE_ID   NUMBER(10)       NULL,
    PRODUCT_VOLUME       NUMBER(10,2)     NULL,
    COMMUNITY_TRADE_PCT  NUMBER(6,3)      NULL,
    CT_DOC_GROUP_ID      NUMBER(10)       NULL,
    FAIRTRADE_PCT        NUMBER(6,3)      NULL,
    OTHER_FAIR_PCT       NUMBER(6,3)      NULL,
    NOT_FAIR_PCT         NUMBER(6,3)      NULL,
    CONSUMER_ADVICE_1    CLOB             NULL,
    CONSUMER_ADVICE_1_DG NUMBER(10)       NULL,
    CONSUMER_ADVICE_2    CLOB             NULL,
    CONSUMER_ADVICE_2_DG NUMBER(10)       NULL,
    CONSUMER_ADVICE_3    CLOB             NULL,
    CONSUMER_ADVICE_3_DG NUMBER(10)       NULL,
    CONSUMER_ADVICE_4    CLOB             NULL,
    CONSUMER_ADVICE_4_DG NUMBER(10)       NULL,
    SUSTAIN_ASSESS_1     CLOB             NULL,
    SUSTAIN_ASSESS_1_DG  NUMBER(10)       NULL,
    SUSTAIN_ASSESS_2     CLOB             NULL,
    SUSTAIN_ASSESS_2_DG  NUMBER(10)       NULL,
    SUSTAIN_ASSESS_3     CLOB             NULL,
    SUSTAIN_ASSESS_3_DG  NUMBER(10)       NULL,
    SUSTAIN_ASSESS_4     CLOB             NULL,
    SUSTAIN_ASSESS_4_DG  NUMBER(10)       NULL
)
LOB(GT_SCOPE_NOTES) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(CONSUMER_ADVICE_1) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(CONSUMER_ADVICE_2) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(CONSUMER_ADVICE_3) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(CONSUMER_ADVICE_4) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SUSTAIN_ASSESS_1) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SUSTAIN_ASSESS_2) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SUSTAIN_ASSESS_3) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SUSTAIN_ASSESS_4) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_PROFILE DROP CONSTRAINT REFALL_PRODUCT405
;
ALTER TABLE SUPPLIER.GT_PROFILE DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_PROFILE RENAME TO GT_PROFILE_04282009125810000
;
CREATE TABLE GT_PROFILE
(
    PRODUCT_ID              NUMBER(10)     NOT NULL,
    REVISION_ID             NUMBER(10)     NOT NULL,
    GT_LOW_ANC_LIST         CLOB               NULL,
    GT_MED_ANC_LIST         CLOB               NULL,
    GT_HIGH_ANC_LIST        CLOB               NULL,
    RATIO_PROD_PCK_WGHT_PCT NUMBER(6,3)        NULL,
    RENEWABLE_PACK_PCT      NUMBER(6,3)        NULL,
    BIOPOLYMER_USED         NUMBER(1)          NULL,
    BIOPOLYMER_LIST         CLOB               NULL,
    RECYCLED_PACK_CONT_MSG  VARCHAR2(1024)     NULL,
    RECYCLABLE_PACK_PCT     NUMBER(6,3)        NULL,
    RECOVERABLE_PACK_PCT    NUMBER(6,3)        NULL,
    COUNTRY_MADE_IN_LIST    CLOB               NULL,
    ORIGIN_TYPE             VARCHAR2(1024)     NULL
)
LOB(GT_LOW_ANC_LIST) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(GT_MED_ANC_LIST) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(GT_HIGH_ANC_LIST) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(BIOPOLYMER_LIST) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(COUNTRY_MADE_IN_LIST) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_SCORES DROP CONSTRAINT REFALL_PRODUCT406
;
ALTER TABLE SUPPLIER.GT_SCORES DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_SCORES RENAME TO GT_SCORES_04282009125811000
;
CREATE TABLE GT_SCORES
(
    PRODUCT_ID            NUMBER(10)   NOT NULL,
    REVISION_ID           NUMBER(10)   NOT NULL,
    SCORE_NAT_DERIVED     NUMBER(10,2)     NULL,
    SCORE_CHEMICALS       NUMBER(10,2)     NULL,
    SCORE_SOURCE_BIOD     NUMBER(10,2)     NULL,
    SCORE_ACCRED_BIOD     NUMBER(10,2)     NULL,
    SCORE_FAIR_TRADE      NUMBER(10,2)     NULL,
    SCORE_RENEW_PACK      NUMBER(10,2)     NULL,
    SCORE_WHATS_IN_PROD   NUMBER(10,2)     NULL,
    SCORE_WATER_IN_PROD   NUMBER(10,2)     NULL,
    SCORE_ENERGY_IN_PROD  NUMBER(10,2)     NULL,
    SCORE_PACK_IMPACT     NUMBER(10,2)     NULL,
    SCORE_PACK_OPT        NUMBER(10,2)     NULL,
    SCORE_RECYCLED_PACK   NUMBER(10,2)     NULL,
    SCORE_SUPP_MANAGEMENT NUMBER(10,2)     NULL,
    SCORE_TRANS_RAW_MAT   NUMBER(10,2)     NULL,
    SCORE_TRANS_TO_BOOTS  NUMBER(10,2)     NULL,
    SCORE_TRANS_PACKAGING NUMBER(10,2)     NULL,
    SCORE_TRANS_OPT       NUMBER(10,2)     NULL,
    SCORE_WATER_USE       NUMBER(10,2)     NULL,
    SCORE_ENERGY_USE      NUMBER(10,2)     NULL,
    SCORE_ANCILLARY_REQ   NUMBER(10,2)     NULL,
    SCORE_PROD_WASTE      NUMBER(10,2)     NULL,
    SCORE_RECYCLABLE_PACK NUMBER(10,2)     NULL,
    SCORE_RECOV_PACK      NUMBER(10,2)     NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;

ALTER TABLE SUPPLIER.GT_SUPPLIER_ANSWERS DROP CONSTRAINT REFALL_PRODUCT384
;
ALTER TABLE SUPPLIER.GT_SUPPLIER_ANSWERS DROP CONSTRAINT REFDOCUMENT_GROUP383
;
ALTER TABLE SUPPLIER.GT_SUPPLIER_ANSWERS DROP CONSTRAINT REFGT_SUS_RELATION_TYPE382
;
ALTER TABLE SUPPLIER.GT_SUPPLIER_ANSWERS DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_SUPPLIER_ANSWERS RENAME TO GT_SUPPLIE_04282009125812000
;
CREATE TABLE GT_SUPPLIER_ANSWERS
(
    PRODUCT_ID              NUMBER(10) NOT NULL,
    REVISION_ID             NUMBER(10) NOT NULL,
    GT_SUS_RELATION_TYPE_ID NUMBER(10)     NULL,
    SF_SUPPLIER_APPROACH    CLOB           NULL,
    SF_SUPPLIER_ASSISTED    CLOB           NULL,
    SUST_AUDIT_DESC         CLOB           NULL,
    SUST_DOC_GROUP_ID       NUMBER(10)     NULL
)
LOB(SF_SUPPLIER_APPROACH) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SF_SUPPLIER_ASSISTED) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
LOB(SUST_AUDIT_DESC) STORE AS 
(
    TABLESPACE USERS
    ENABLE STORAGE IN ROW
    NOCACHE
    )
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE SUPPLIER.GT_TRANSPORT_ANSWERS DROP CONSTRAINT REFALL_PRODUCT386
;
ALTER TABLE SUPPLIER.GT_TRANSPORT_ANSWERS DROP PRIMARY KEY DROP INDEX
;
ALTER TABLE SUPPLIER.GT_TRANSPORT_ANSWERS RENAME TO GT_TRANSPO_04282009125813000
;
CREATE TABLE GT_TRANSPORT_ANSWERS
(
    PRODUCT_ID         NUMBER(10)  NOT NULL,
    REVISION_ID        NUMBER(10)  NOT NULL,
    PROD_IN_CONT_PCT   NUMBER(6,3)     NULL,
    PROD_BTWN_CONT_PCT NUMBER(6,3)     NULL,
    PROD_CONT_UN_PCT   NUMBER(6,3)     NULL,
    PACK_IN_CONT_PCT   NUMBER(6,3)     NULL,
    PACK_BTWN_CONT_PCT NUMBER(6,3)     NULL,
    PACK_CONT_UN_PCT   NUMBER(6,3)     NULL
)
TABLESPACE USERS
NOLOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;

CREATE TABLE PRODUCT_REVISION
(
    PRODUCT_ID     NUMBER(10)     NOT NULL,
    REVISION_ID    NUMBER(10)     NOT NULL,
    DESCRIPTION    VARCHAR2(4000)     NULL,
    CREATED_BY_SID NUMBER(10)     NOT NULL,
    CREATED_DTM    TIMESTAMP(6)   NOT NULL,
    CREATED_STATUS NUMBER(10)     NOT NULL
)
LOGGING
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
;
ALTER TABLE PRODUCT_REVISION
    ADD CONSTRAINT PK283
    PRIMARY KEY (PRODUCT_ID,REVISION_ID)
    USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    ENABLE
    VALIDATE
;

PROMPT Set up Revision table

INSERT INTO PRODUCT_REVISION (PRODUCT_ID, REVISION_ID, DESCRIPTION, CREATED_BY_SID, CREATED_DTM, CREATED_STATUS)
SELECT p.PRODUCT_ID, 1, 'New product', (SELECT csr_user_sid FROM csr.CSR_USER WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootssupplier.credit360.com') AND lower(full_name) like '%andrew jenkins%'), sysdate, pqg.GROUP_STATUS_ID 
FROM product p, product_questionnaire_group pqg
WHERE p.product_id = pqg.product_id
AND group_id = (SELECT group_id FROM questionnaire_group WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootssupplier.credit360.com') AND LOWER(name) like '%green tick%');

INSERT INTO PRODUCT_REVISION (PRODUCT_ID, REVISION_ID, DESCRIPTION, CREATED_BY_SID, CREATED_DTM, CREATED_STATUS)
SELECT p.PRODUCT_ID, 1, 'New product', (SELECT csr_user_sid FROM csr.CSR_USER WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootstest.credit360.com') AND lower(full_name) like '%andrew jenkins%'), sysdate, pqg.GROUP_STATUS_ID 
FROM product p, product_questionnaire_group pqg
WHERE p.product_id = pqg.product_id
AND group_id = (SELECT group_id FROM questionnaire_group WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bootstest.credit360.com') AND LOWER(name) like '%green tick%');

INSERT INTO PRODUCT_REVISION (PRODUCT_ID, REVISION_ID, DESCRIPTION, CREATED_BY_SID, CREATED_DTM, CREATED_STATUS)
SELECT p.PRODUCT_ID, 1, 'New product', (SELECT csr_user_sid FROM csr.CSR_USER WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bs.credit360.com') AND lower(full_name) like '%andrew jenkins%'), sysdate, pqg.GROUP_STATUS_ID 
FROM product p, product_questionnaire_group pqg
WHERE p.product_id = pqg.product_id
AND group_id = (SELECT group_id FROM questionnaire_group WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bs.credit360.com') AND LOWER(name) like '%green tick%');

INSERT INTO PRODUCT_REVISION (PRODUCT_ID, REVISION_ID, DESCRIPTION, CREATED_BY_SID, CREATED_DTM, CREATED_STATUS)
SELECT p.PRODUCT_ID, 1, 'New product', (SELECT csr_user_sid FROM csr.CSR_USER WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bsstage.credit360.com') AND lower(full_name) like '%andrew jenkins%'), sysdate, pqg.GROUP_STATUS_ID 
FROM product p, product_questionnaire_group pqg
WHERE p.product_id = pqg.product_id
AND group_id = (SELECT group_id FROM questionnaire_group WHERE app_sid = (SELECT app_sid FROM csr.customer WHERE host = 'bsstage.credit360.com') AND LOWER(name) like '%green tick%');



COMMIT;

-- Insert Data SQL

ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_COUNTRY_MADE_IN(
                               PRODUCT_ID,
                               COUNTRY_CODE,
                               GT_TRANSPORT_TYPE_ID,
                               REVISION_ID,
                               MADE_INTERNALLY,
                               PCT
                              )
                        SELECT 
                               PRODUCT_ID,
                               COUNTRY_CODE,
                               GT_TRANSPORT_TYPE_ID,
                               0,
                               MADE_INTERNALLY,
                               PCT
                          FROM SUPPLIER.GT_COUNTRY_04282009125759000 
;
COMMIT
;
ALTER TABLE GT_COUNTRY_MADE_IN LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_COUNTRY_SOLD_IN(
                               PRODUCT_ID,
                               COUNTRY_CODE,
                               REVISION_ID
                              )
                        SELECT 
                               PRODUCT_ID,
                               COUNTRY_CODE,
                               0
                          FROM SUPPLIER.GT_COUNTRY_04282009125800000 
;
COMMIT
;
ALTER TABLE GT_COUNTRY_SOLD_IN LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_FA_ANC_MAT(
                          GT_ANCILLARY_MATERIAL_ID,
                          PRODUCT_ID,
                          REVISION_ID
                         )
                   SELECT 
                          GT_ANCILLARY_MATERIAL_ID,
                          PRODUCT_ID,
                          0
                     FROM SUPPLIER.GT_FA_ANC__04282009125801000 
;
COMMIT
;
ALTER TABLE GT_FA_ANC_MAT LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_FA_HAZ_CHEM(
                           GT_HAZZARD_CHEMICAL_ID,
                           PRODUCT_ID,
                           REVISION_ID
                          )
                    SELECT 
                           GT_HAZZARD_CHEMICAL_ID,
                           PRODUCT_ID,
                           0
                      FROM SUPPLIER.GT_FA_HAZ__04282009125802000 
;
COMMIT
;
ALTER TABLE GT_FA_HAZ_CHEM LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_FA_PALM_IND(
                           GT_PALM_INGRED_ID,
                           PRODUCT_ID,
                           REVISION_ID
                          )
                    SELECT 
                           GT_PALM_INGRED_ID,
                           PRODUCT_ID,
                           0
                      FROM SUPPLIER.GT_FA_PALM_04282009125803000 
;
COMMIT
;
ALTER TABLE GT_FA_PALM_IND LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_FORMULATION_ANSWERS(
                                   PRODUCT_ID,
                                   REVISION_ID,
                                   INGREDIENT_COUNT,
                                   SF_INGREDIENTS,
                                   SF_ADDITIONAL_MATERIALS,
                                   SF_SPECIAL_MATERIALS,
                                   CONCENTRATE,
                                   BP_CROPS_PCT,
                                   BP_FISH_PCT,
                                   BP_PALM_PCT,
                                   BP_WILD_PCT,
                                   BP_UNKNOWN_PCT,
                                   BP_THREATENED_PCT,
                                   BP_MINERAL_PCT,
                                   SF_BIODIVERSITY,
                                   BS_ACCREDITED_PRIORITY_PCT,
                                   BS_ACCREDITED_PRIORITY_SRC,
                                   BS_ACCREDITED_OTHER_PCT,
                                   BS_ACCREDITED_OTHER_SRC,
                                   BS_KNOWN_PCT,
                                   BS_UNKNOWN_PCT,
                                   BS_NO_NATURAL_PCT,
                                   BS_DOCUMENT_GROUP
                                  )
                            SELECT 
                                   PRODUCT_ID,
                                   0,
                                   INGREDIENT_COUNT,
                                   SF_INGREDIENTS,
                                   SF_ADDITIONAL_MATERIALS,
                                   SF_SPECIAL_MATERIALS,
                                   CONCENTRATE,
                                   BP_CROPS_PCT,
                                   BP_FISH_PCT,
                                   BP_PALM_PCT,
                                   BP_WILD_PCT,
                                   BP_UNKNOWN_PCT,
                                   BP_THREATENED_PCT,
                                   BP_MINERAL_PCT,
                                   SF_BIODIVERSITY,
                                   BS_ACCREDITED_PRIORITY_PCT,
                                   BS_ACCREDITED_PRIORITY_SRC,
                                   BS_ACCREDITED_OTHER_PCT,
                                   BS_ACCREDITED_OTHER_SRC,
                                   BS_KNOWN_PCT,
                                   BS_UNKNOWN_PCT,
                                   BS_NO_NATURAL_PCT,
                                   BS_DOCUMENT_GROUP
                              FROM SUPPLIER.GT_FORMULA_04282009125804000 
;
COMMIT
;
ALTER TABLE GT_FORMULATION_ANSWERS LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_LINK_PRODUCT(
                            PRODUCT_ID,
                            LINK_PRODUCT_ID,
                            REVISION_ID,
                            COUNT
                           )
                     SELECT 
                            PRODUCT_ID,
                            LINK_PRODUCT_ID,
                            0,
                            COUNT
                       FROM SUPPLIER.GT_LINK_PR_04282009125805000 
;
COMMIT
;
ALTER TABLE GT_LINK_PRODUCT LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_PACKAGING_ANSWERS(
                                 PRODUCT_ID,
                                 REVISION_ID,
                                 GT_ACCESS_PACK_TYPE_ID,
                                 GT_ACCESS_VISC_TYPE_ID,
                                 PROD_WEIGHT_INC_PACK,
                                 REFILL_PACK,
                                 SF_INNOVATION,
                                 SF_NOVEL_REFILL,
                                 SINGLE_IN_PACK,
                                 SETTLE_IN_TRANSIT,
                                 GT_GIFT_CONT_TYPE_ID,
                                 GT_PACK_LAYERS_TYPE_ID,
                                 PACK_FOR_PROTECTION,
                                 VOL_PACKAGE,
                                 RETAIL_PACKS_STACKABLE,
                                 VOL_PROD_TRAN_PACK,
                                 VOL_TRAN_PACK,
                                 CORRECT_BIOPOLYMER_USE,
                                 SF_RECYCLED_THRESHOLD,
                                 SF_NOVEL_MATERIAL,
                                 PACK_MEET_REQ,
                                 PACK_SHELF_READY,
                                 PACK_CONSUM_RCYLD,
                                 PACK_CONSUM_PCT,
                                 PACK_CONSUM_MAT,
                                 GT_TRANS_PACK_TYPE_ID,
                                 SF_INNOVATION_TRANSIT
                                )
                          SELECT 
                                 PRODUCT_ID,
                                 0,
                                 GT_ACCESS_PACK_TYPE_ID,
                                 GT_ACCESS_VISC_TYPE_ID,
                                 PROD_WEIGHT_INC_PACK,
                                 REFILL_PACK,
                                 SF_INNOVATION,
                                 SF_NOVEL_REFILL,
                                 SINGLE_IN_PACK,
                                 SETTLE_IN_TRANSIT,
                                 GT_GIFT_CONT_TYPE_ID,
                                 GT_PACK_LAYERS_TYPE_ID,
                                 PACK_FOR_PROTECTION,
                                 VOL_PACKAGE,
                                 RETAIL_PACKS_STACKABLE,
                                 VOL_PROD_TRAN_PACK,
                                 VOL_TRAN_PACK,
                                 CORRECT_BIOPOLYMER_USE,
                                 SF_RECYCLED_THRESHOLD,
                                 SF_NOVEL_MATERIAL,
                                 PACK_MEET_REQ,
                                 PACK_SHELF_READY,
                                 PACK_CONSUM_RCYLD,
                                 PACK_CONSUM_PCT,
                                 PACK_CONSUM_MAT,
                                 GT_TRANS_PACK_TYPE_ID,
                                 SF_INNOVATION_TRANSIT
                            FROM SUPPLIER.GT_PACKAGI_04282009125806000 
;
COMMIT
;
ALTER TABLE GT_PACKAGING_ANSWERS LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_PACK_ITEM(
                         PRODUCT_ID,
                         GT_PACK_ITEM_ID,
                         REVISION_ID,
                         GT_PACK_SHAPE_TYPE_ID,
                         GT_PACK_MATERIAL_TYPE_ID,
                         WEIGHT_GRAMS,
                         PCT_RECYCLED,
                         CONTAINS_BIOPOLYMER
                        )
                  SELECT 
                         PRODUCT_ID,
                         GT_PACK_ITEM_ID,
                         0,
                         GT_PACK_SHAPE_TYPE_ID,
                         GT_PACK_MATERIAL_TYPE_ID,
                         WEIGHT_GRAMS,
                         PCT_RECYCLED,
                         CONTAINS_BIOPOLYMER
                    FROM SUPPLIER.GT_PACK_IT_04282009125807000 
;
COMMIT
;
ALTER TABLE GT_PACK_ITEM LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_PA_PACK_REQ(
                           PRODUCT_ID,
                           GT_PACK_REQ_TYPE_ID,
                           REVISION_ID
                          )
                    SELECT 
                           PRODUCT_ID,
                           GT_PACK_REQ_TYPE_ID,
                           0
                      FROM SUPPLIER.GT_PA_PACK_04282009125808000 
;
COMMIT
;
ALTER TABLE GT_PA_PACK_REQ LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_PRODUCT_ANSWERS(
                               PRODUCT_ID,
                               REVISION_ID,
                               GT_SCOPE_NOTES,
                               GT_PRODUCT_RANGE_ID,
                               GT_PRODUCT_TYPE_ID,
                               PRODUCT_VOLUME,
                               COMMUNITY_TRADE_PCT,
                               CT_DOC_GROUP_ID,
                               FAIRTRADE_PCT,
                               OTHER_FAIR_PCT,
                               NOT_FAIR_PCT,
                               CONSUMER_ADVICE_1,
                               CONSUMER_ADVICE_1_DG,
                               CONSUMER_ADVICE_2,
                               CONSUMER_ADVICE_2_DG,
                               CONSUMER_ADVICE_3,
                               CONSUMER_ADVICE_3_DG,
                               CONSUMER_ADVICE_4,
                               CONSUMER_ADVICE_4_DG,
                               SUSTAIN_ASSESS_1,
                               SUSTAIN_ASSESS_1_DG,
                               SUSTAIN_ASSESS_2,
                               SUSTAIN_ASSESS_2_DG,
                               SUSTAIN_ASSESS_3,
                               SUSTAIN_ASSESS_3_DG,
                               SUSTAIN_ASSESS_4,
                               SUSTAIN_ASSESS_4_DG
                              )
                        SELECT 
                               PRODUCT_ID,
                               0,
                               GT_SCOPE_NOTES,
                               GT_PRODUCT_RANGE_ID,
                               GT_PRODUCT_TYPE_ID,
                               PRODUCT_VOLUME,
                               COMMUNITY_TRADE_PCT,
                               CT_DOC_GROUP_ID,
                               FAIRTRADE_PCT,
                               OTHER_FAIR_PCT,
                               NOT_FAIR_PCT,
                               CONSUMER_ADVICE_1,
                               CONSUMER_ADVICE_1_DG,
                               CONSUMER_ADVICE_2,
                               CONSUMER_ADVICE_2_DG,
                               CONSUMER_ADVICE_3,
                               CONSUMER_ADVICE_3_DG,
                               CONSUMER_ADVICE_4,
                               CONSUMER_ADVICE_4_DG,
                               SUSTAIN_ASSESS_1,
                               SUSTAIN_ASSESS_1_DG,
                               SUSTAIN_ASSESS_2,
                               SUSTAIN_ASSESS_2_DG,
                               SUSTAIN_ASSESS_3,
                               SUSTAIN_ASSESS_3_DG,
                               SUSTAIN_ASSESS_4,
                               SUSTAIN_ASSESS_4_DG
                          FROM SUPPLIER.GT_PRODUCT_04282009125809000 
;
COMMIT
;
ALTER TABLE GT_PRODUCT_ANSWERS LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_PROFILE(
                       PRODUCT_ID,
                       REVISION_ID,
                       GT_LOW_ANC_LIST,
                       GT_MED_ANC_LIST,
                       GT_HIGH_ANC_LIST,
                       RATIO_PROD_PCK_WGHT_PCT,
                       RENEWABLE_PACK_PCT,
                       BIOPOLYMER_USED,
                       BIOPOLYMER_LIST,
                       RECYCLED_PACK_CONT_MSG,
                       RECYCLABLE_PACK_PCT,
                       RECOVERABLE_PACK_PCT,
                       COUNTRY_MADE_IN_LIST,
                       ORIGIN_TYPE
                      )
                SELECT 
                       PRODUCT_ID,
                       0,
                       GT_LOW_ANC_LIST,
                       GT_MED_ANC_LIST,
                       GT_HIGH_ANC_LIST,
                       RATIO_PROD_PCK_WGHT_PCT,
                       RENEWABLE_PACK_PCT,
                       BIOPOLYMER_USED,
                       BIOPOLYMER_LIST,
                       RECYCLED_PACK_CONT_MSG,
                       RECYCLABLE_PACK_PCT,
                       RECOVERABLE_PACK_PCT,
                       COUNTRY_MADE_IN_LIST,
                       ORIGIN_TYPE
                  FROM SUPPLIER.GT_PROFILE_04282009125810000 
;
COMMIT
;
ALTER TABLE GT_PROFILE LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_SCORES(
                      PRODUCT_ID,
                      REVISION_ID,
                      SCORE_NAT_DERIVED,
                      SCORE_CHEMICALS,
                      SCORE_SOURCE_BIOD,
                      SCORE_ACCRED_BIOD,
                      SCORE_FAIR_TRADE,
                      SCORE_RENEW_PACK,
                      SCORE_WHATS_IN_PROD,
                      SCORE_WATER_IN_PROD,
                      SCORE_ENERGY_IN_PROD,
                      SCORE_PACK_IMPACT,
                      SCORE_PACK_OPT,
                      SCORE_RECYCLED_PACK,
                      SCORE_SUPP_MANAGEMENT,
                      SCORE_TRANS_RAW_MAT,
                      SCORE_TRANS_TO_BOOTS,
                      SCORE_TRANS_PACKAGING,
                      SCORE_TRANS_OPT,
                      SCORE_WATER_USE,
                      SCORE_ENERGY_USE,
                      SCORE_ANCILLARY_REQ,
                      SCORE_PROD_WASTE,
                      SCORE_RECYCLABLE_PACK,
                      SCORE_RECOV_PACK
                     )
               SELECT 
                      PRODUCT_ID,
                      0,
                      SCORE_NAT_DERIVED,
                      SCORE_CHEMICALS,
                      SCORE_SOURCE_BIOD,
                      SCORE_ACCRED_BIOD,
                      SCORE_FAIR_TRADE,
                      SCORE_RENEW_PACK,
                      SCORE_WHATS_IN_PROD,
                      SCORE_WATER_IN_PROD,
                      SCORE_ENERGY_IN_PROD,
                      SCORE_PACK_IMPACT,
                      SCORE_PACK_OPT,
                      SCORE_RECYCLED_PACK,
                      SCORE_SUPP_MANAGEMENT,
                      SCORE_TRANS_RAW_MAT,
                      SCORE_TRANS_TO_BOOTS,
                      SCORE_TRANS_PACKAGING,
                      SCORE_TRANS_OPT,
                      SCORE_WATER_USE,
                      SCORE_ENERGY_USE,
                      SCORE_ANCILLARY_REQ,
                      SCORE_PROD_WASTE,
                      SCORE_RECYCLABLE_PACK,
                      SCORE_RECOV_PACK
                 FROM SUPPLIER.GT_SCORES_04282009125811000 
;
COMMIT
;
ALTER TABLE GT_SCORES LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_SUPPLIER_ANSWERS(
                                PRODUCT_ID,
                                REVISION_ID,
                                GT_SUS_RELATION_TYPE_ID,
                                SF_SUPPLIER_APPROACH,
                                SF_SUPPLIER_ASSISTED,
                                SUST_AUDIT_DESC,
                                SUST_DOC_GROUP_ID
                               )
                         SELECT 
                                PRODUCT_ID,
                                0,
                                GT_SUS_RELATION_TYPE_ID,
                                SF_SUPPLIER_APPROACH,
                                SF_SUPPLIER_ASSISTED,
                                SUST_AUDIT_DESC,
                                SUST_DOC_GROUP_ID
                           FROM SUPPLIER.GT_SUPPLIE_04282009125812000 
;
COMMIT
;
ALTER TABLE GT_SUPPLIER_ANSWERS LOGGING
;
ALTER SESSION ENABLE PARALLEL DML
;
INSERT INTO GT_TRANSPORT_ANSWERS(
                                 PRODUCT_ID,
                                 REVISION_ID,
                                 PROD_IN_CONT_PCT,
                                 PROD_BTWN_CONT_PCT,
                                 PROD_CONT_UN_PCT,
                                 PACK_IN_CONT_PCT,
                                 PACK_BTWN_CONT_PCT,
                                 PACK_CONT_UN_PCT
                                )
                          SELECT 
                                 PRODUCT_ID,
                                 0,
                                 PROD_IN_CONT_PCT,
                                 PROD_BTWN_CONT_PCT,
                                 PROD_CONT_UN_PCT,
                                 PACK_IN_CONT_PCT,
                                 PACK_BTWN_CONT_PCT,
                                 PACK_CONT_UN_PCT
                            FROM SUPPLIER.GT_TRANSPO_04282009125813000 
;
COMMIT
;
ALTER TABLE GT_TRANSPORT_ANSWERS LOGGING
;

-- Add Constraint SQL

ALTER TABLE GT_COUNTRY_MADE_IN ADD CONSTRAINT PK199
PRIMARY KEY (PRODUCT_ID,COUNTRY_CODE,GT_TRANSPORT_TYPE_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_COUNTRY_SOLD_IN ADD CONSTRAINT PK201
PRIMARY KEY (PRODUCT_ID,COUNTRY_CODE,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_FA_ANC_MAT ADD CONSTRAINT PK212
PRIMARY KEY (GT_ANCILLARY_MATERIAL_ID,PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_FA_HAZ_CHEM ADD CONSTRAINT PK213
PRIMARY KEY (GT_HAZZARD_CHEMICAL_ID,PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_FA_PALM_IND ADD CONSTRAINT PK214
PRIMARY KEY (GT_PALM_INGRED_ID,PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_FORMULATION_ANSWERS ADD CONSTRAINT PK192
PRIMARY KEY (PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_LINK_PRODUCT ADD CONSTRAINT PK269
PRIMARY KEY (PRODUCT_ID,LINK_PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_PACKAGING_ANSWERS ADD CONSTRAINT PK193
PRIMARY KEY (PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_PACK_ITEM ADD CONSTRAINT PK194
PRIMARY KEY (PRODUCT_ID,GT_PACK_ITEM_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_PACK_ITEM ADD CONSTRAINT CHK_WEIGHT_GRAMS
CHECK (WEIGHT_GRAMS > 0)
;
ALTER TABLE GT_PA_PACK_REQ ADD CONSTRAINT PK220
PRIMARY KEY (PRODUCT_ID,GT_PACK_REQ_TYPE_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD CONSTRAINT PK205
PRIMARY KEY (PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_PROFILE ADD CONSTRAINT PK259
PRIMARY KEY (PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_SCORES ADD CONSTRAINT PK258
PRIMARY KEY (PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_SUPPLIER_ANSWERS ADD CONSTRAINT PK203
PRIMARY KEY (PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;
ALTER TABLE GT_TRANSPORT_ANSWERS ADD CONSTRAINT PK198
PRIMARY KEY (PRODUCT_ID,REVISION_ID)
USING INDEX STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
;

-- Add Dependencies SQL

ALTER VIEW SUPPLIER.GT_PROFILE_REPORT COMPILE
/

UPDATE GT_LINK_PRODUCT SET REVISION_ID = 1;
UPDATE GT_PACK_ITEM SET REVISION_ID = 1;
UPDATE GT_PACK_ITEM SET REVISION_ID = 1;
UPDATE GT_PA_PACK_REQ SET REVISION_ID = 1;
UPDATE GT_PA_PACK_REQ SET REVISION_ID = 1;

UPDATE GT_COUNTRY_MADE_IN SET REVISION_ID = 1;
UPDATE GT_COUNTRY_SOLD_IN SET REVISION_ID = 1;
UPDATE GT_FA_ANC_MAT SET REVISION_ID = 1;
UPDATE GT_FA_HAZ_CHEM SET REVISION_ID = 1;
UPDATE GT_FA_PALM_IND SET REVISION_ID = 1;

UPDATE GT_PROFILE SET REVISION_ID = 1;
UPDATE GT_SCORES SET REVISION_ID = 1;

UPDATE GT_PRODUCT_ANSWERS SET REVISION_ID = 1;
UPDATE GT_SUPPLIER_ANSWERS SET REVISION_ID = 1;
UPDATE GT_TRANSPORT_ANSWERS SET REVISION_ID = 1;
UPDATE GT_PACKAGING_ANSWERS SET REVISION_ID = 1;
UPDATE GT_FORMULATION_ANSWERS SET REVISION_ID = 1;



-- Add Referencing Foreign Keys SQL

ALTER TABLE PRODUCT_REVISION 
    ADD FOREIGN KEY (CREATED_STATUS)
REFERENCES SUPPLIER.GROUP_STATUS (GROUP_STATUS_ID)
ENABLE
;
ALTER TABLE PRODUCT_REVISION 
    ADD FOREIGN KEY (PRODUCT_ID)
REFERENCES SUPPLIER.ALL_PRODUCT (PRODUCT_ID)
ENABLE
;

ALTER TABLE GT_COUNTRY_MADE_IN ADD FOREIGN KEY (COUNTRY_CODE)
REFERENCES SUPPLIER.COUNTRY (COUNTRY_CODE)
ENABLE
;
ALTER TABLE GT_COUNTRY_MADE_IN ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES GT_TRANSPORT_ANSWERS (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_COUNTRY_MADE_IN ADD FOREIGN KEY (GT_TRANSPORT_TYPE_ID)
REFERENCES SUPPLIER.GT_TRANSPORT_TYPE (GT_TRANSPORT_TYPE_ID)
ENABLE
;
ALTER TABLE GT_COUNTRY_SOLD_IN ADD FOREIGN KEY (COUNTRY_CODE)
REFERENCES SUPPLIER.COUNTRY (COUNTRY_CODE)
ENABLE
;
ALTER TABLE GT_COUNTRY_SOLD_IN ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES GT_TRANSPORT_ANSWERS (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_FA_ANC_MAT ADD FOREIGN KEY (GT_ANCILLARY_MATERIAL_ID)
REFERENCES SUPPLIER.GT_ANCILLARY_MATERIAL (GT_ANCILLARY_MATERIAL_ID)
ENABLE
;
ALTER TABLE GT_FA_ANC_MAT ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES GT_FORMULATION_ANSWERS (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_FA_HAZ_CHEM ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES GT_FORMULATION_ANSWERS (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_FA_HAZ_CHEM ADD FOREIGN KEY (GT_HAZZARD_CHEMICAL_ID)
REFERENCES SUPPLIER.GT_HAZZARD_CHEMICAL (GT_HAZZARD_CHEMICAL_ID)
ENABLE
;
ALTER TABLE GT_FA_PALM_IND ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES GT_FORMULATION_ANSWERS (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_FA_PALM_IND ADD FOREIGN KEY (GT_PALM_INGRED_ID)
REFERENCES SUPPLIER.GT_PALM_INGRED (GT_PALM_INGRED_ID)
ENABLE
;
ALTER TABLE GT_FORMULATION_ANSWERS ADD FOREIGN KEY (PRODUCT_ID)
REFERENCES SUPPLIER.ALL_PRODUCT (PRODUCT_ID)
ENABLE
;
ALTER TABLE GT_FORMULATION_ANSWERS ADD FOREIGN KEY (BS_DOCUMENT_GROUP)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
--
ALTER TABLE GT_FORMULATION_ANSWERS ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES PRODUCT_REVISION (PRODUCT_ID,REVISION_ID)
ENABLE
;




ALTER TABLE GT_LINK_PRODUCT ADD FOREIGN KEY (LINK_PRODUCT_ID)
REFERENCES SUPPLIER.ALL_PRODUCT (PRODUCT_ID)
ENABLE
;



ALTER TABLE GT_LINK_PRODUCT ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES GT_PRODUCT_ANSWERS (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_PACKAGING_ANSWERS ADD FOREIGN KEY (PRODUCT_ID)
REFERENCES SUPPLIER.ALL_PRODUCT (PRODUCT_ID)
ENABLE
;
ALTER TABLE GT_PACKAGING_ANSWERS ADD FOREIGN KEY (GT_ACCESS_PACK_TYPE_ID)
REFERENCES SUPPLIER.GT_ACCESS_PACK_TYPE (GT_ACCESS_PACK_TYPE_ID)
ENABLE
;
ALTER TABLE GT_PACKAGING_ANSWERS ADD FOREIGN KEY (GT_ACCESS_VISC_TYPE_ID)
REFERENCES SUPPLIER.GT_ACCESS_VISC_TYPE (GT_ACCESS_VISC_TYPE_ID)
ENABLE
;
ALTER TABLE GT_PACKAGING_ANSWERS ADD FOREIGN KEY (GT_GIFT_CONT_TYPE_ID)
REFERENCES SUPPLIER.GT_GIFT_CONT_TYPE (GT_GIFT_CONT_TYPE_ID)
ENABLE
;
ALTER TABLE GT_PACKAGING_ANSWERS ADD FOREIGN KEY (GT_PACK_LAYERS_TYPE_ID)
REFERENCES SUPPLIER.GT_PACK_LAYERS_TYPE (GT_PACK_LAYERS_TYPE_ID)
ENABLE
;
ALTER TABLE GT_PACKAGING_ANSWERS ADD FOREIGN KEY (GT_TRANS_PACK_TYPE_ID)
REFERENCES SUPPLIER.GT_TRANS_PACK_TYPE (GT_TRANS_PACK_TYPE_ID)
ENABLE
;



ALTER TABLE GT_PACKAGING_ANSWERS ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES PRODUCT_REVISION (PRODUCT_ID,REVISION_ID)
ENABLE
;



ALTER TABLE GT_PACK_ITEM ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES GT_PACKAGING_ANSWERS (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_PACK_ITEM ADD FOREIGN KEY (GT_PACK_MATERIAL_TYPE_ID)
REFERENCES SUPPLIER.GT_PACK_MATERIAL_TYPE (GT_PACK_MATERIAL_TYPE_ID)
ENABLE
;
ALTER TABLE GT_PACK_ITEM ADD FOREIGN KEY (GT_PACK_SHAPE_TYPE_ID)
REFERENCES SUPPLIER.GT_PACK_SHAPE_TYPE (GT_PACK_SHAPE_TYPE_ID)
ENABLE
;



ALTER TABLE GT_PACK_ITEM ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES PRODUCT_REVISION (PRODUCT_ID,REVISION_ID)
ENABLE
;

ALTER TABLE GT_PA_PACK_REQ ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES GT_PACKAGING_ANSWERS (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_PA_PACK_REQ ADD FOREIGN KEY (GT_PACK_REQ_TYPE_ID)
REFERENCES SUPPLIER.GT_PACK_REQ_TYPE (GT_PACK_REQ_TYPE_ID)
ENABLE
;



ALTER TABLE GT_PA_PACK_REQ ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES PRODUCT_REVISION (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (PRODUCT_ID)
REFERENCES SUPPLIER.ALL_PRODUCT (PRODUCT_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (CT_DOC_GROUP_ID)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (CONSUMER_ADVICE_1_DG)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (CONSUMER_ADVICE_2_DG)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (CONSUMER_ADVICE_3_DG)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (CONSUMER_ADVICE_4_DG)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (SUSTAIN_ASSESS_1_DG)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (SUSTAIN_ASSESS_2_DG)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (SUSTAIN_ASSESS_3_DG)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (SUSTAIN_ASSESS_4_DG)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (GT_PRODUCT_RANGE_ID)
REFERENCES SUPPLIER.GT_PRODUCT_RANGE (GT_PRODUCT_RANGE_ID)
ENABLE
;
ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (GT_PRODUCT_TYPE_ID)
REFERENCES SUPPLIER.GT_PRODUCT_TYPE (GT_PRODUCT_TYPE_ID)
ENABLE
;


ALTER TABLE GT_PRODUCT_ANSWERS ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES PRODUCT_REVISION (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_PROFILE ADD FOREIGN KEY (PRODUCT_ID)
REFERENCES SUPPLIER.ALL_PRODUCT (PRODUCT_ID)
ENABLE
;



ALTER TABLE GT_PROFILE ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES PRODUCT_REVISION (PRODUCT_ID,REVISION_ID)
ENABLE
;


ALTER TABLE GT_SCORES ADD FOREIGN KEY (PRODUCT_ID)
REFERENCES SUPPLIER.ALL_PRODUCT (PRODUCT_ID)
ENABLE
;
ALTER TABLE GT_SCORES ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES PRODUCT_REVISION (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_SUPPLIER_ANSWERS ADD FOREIGN KEY (PRODUCT_ID)
REFERENCES SUPPLIER.ALL_PRODUCT (PRODUCT_ID)
ENABLE
;
ALTER TABLE GT_SUPPLIER_ANSWERS ADD FOREIGN KEY (SUST_DOC_GROUP_ID)
REFERENCES SUPPLIER.DOCUMENT_GROUP (DOCUMENT_GROUP_ID)
ENABLE
;
ALTER TABLE GT_SUPPLIER_ANSWERS ADD FOREIGN KEY (GT_SUS_RELATION_TYPE_ID)
REFERENCES SUPPLIER.GT_SUS_RELATION_TYPE (GT_SUS_RELATION_TYPE_ID)
ENABLE
;


ALTER TABLE GT_SUPPLIER_ANSWERS ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES PRODUCT_REVISION (PRODUCT_ID,REVISION_ID)
ENABLE
;
ALTER TABLE GT_TRANSPORT_ANSWERS ADD FOREIGN KEY (PRODUCT_ID)
REFERENCES SUPPLIER.ALL_PRODUCT (PRODUCT_ID)
ENABLE
;



ALTER TABLE GT_TRANSPORT_ANSWERS ADD FOREIGN KEY (PRODUCT_ID,REVISION_ID)
REFERENCES PRODUCT_REVISION (PRODUCT_ID,REVISION_ID)
ENABLE
;



@update_tail
