/* ---------------------------------------------------------------------- */
/* Script generated with: DeZign for Databases V7.1.2                     */
/* Target DBMS:           Oracle 10g                                      */
/* Project file:          hotspot.dez                                     */
/* Project name:                                                          */
/* Author:                                                                */
/* Script type:           Database drop script                            */
/* Created on:            2012-06-12 22:41                                */
/* ---------------------------------------------------------------------- */


/* ---------------------------------------------------------------------- */
/* Drop foreign key constraints                                           */
/* ---------------------------------------------------------------------- */

ALTER TABLE CP_FACTORS DROP CONSTRAINT PERIOD_CP_FACTORS;

ALTER TABLE CP_FACTORS DROP CONSTRAINT CURRENCY_CP_FACTORS;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT EBCT_ECT;

ALTER TABLE EIO_RELATIONSHIP DROP CONSTRAINT ECT_ER_RELATED;

ALTER TABLE EIO_RELATIONSHIP DROP CONSTRAINT ECT_ER_PRIMARY;

/* ---------------------------------------------------------------------- */
/* Drop table "EIO_RELATIONSHIP"                                          */
/* ---------------------------------------------------------------------- */

/* Drop constraints */

ALTER TABLE EIO_RELATIONSHIP DROP CONSTRAINT ;

ALTER TABLE EIO_RELATIONSHIP DROP CONSTRAINT ;

ALTER TABLE EIO_RELATIONSHIP DROP CONSTRAINT PK_EIO_RELATIONSHIP;

/* Drop table */

DROP TABLE EIO_RELATIONSHIP;

/* ---------------------------------------------------------------------- */
/* Drop table "EIO_CATEGORY_TMP"                                          */
/* ---------------------------------------------------------------------- */

/* Drop constraints */

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_CATEGORY_TMP DROP CONSTRAINT PK_EIO_CATEGORY_TMP;

/* Drop table */

DROP TABLE EIO_CATEGORY_TMP;

/* ---------------------------------------------------------------------- */
/* Drop table "EIO_BROAD_CATEGORY_TMP"                                    */
/* ---------------------------------------------------------------------- */

/* Drop constraints */

ALTER TABLE EIO_BROAD_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_BROAD_CATEGORY_TMP DROP CONSTRAINT ;

ALTER TABLE EIO_BROAD_CATEGORY_TMP DROP CONSTRAINT PK_EIO_BROAD_CATEGORY_TMP;

/* Drop table */

DROP TABLE EIO_BROAD_CATEGORY_TMP;

/* ---------------------------------------------------------------------- */
/* Drop table "CP_FACTORS"                                                */
/* ---------------------------------------------------------------------- */

/* Drop constraints */

ALTER TABLE CP_FACTORS DROP CONSTRAINT NN_CPF_PERIOD_ID;

ALTER TABLE CP_FACTORS DROP CONSTRAINT NN_CPF_CURRENCY_ID;

ALTER TABLE CP_FACTORS DROP CONSTRAINT NN_CPF_REL_PURCHSE_PWR_PARITY;

ALTER TABLE CP_FACTORS DROP CONSTRAINT NN_CPF_EXCH_RATE_X_PER_DLLR;

ALTER TABLE CP_FACTORS DROP CONSTRAINT PK_CP_FACTORS;

/* Drop table */

DROP TABLE CP_FACTORS;

/* ---------------------------------------------------------------------- */
/* Drop table "CURRENCY"                                                  */
/* ---------------------------------------------------------------------- */

/* Drop constraints */

ALTER TABLE CURRENCY DROP CONSTRAINT NN_CURRENCY_CURRENCY_ID;

ALTER TABLE CURRENCY DROP CONSTRAINT NN_CURRENCY_DESCRIPTION;

ALTER TABLE CURRENCY DROP CONSTRAINT NN_CURRENCY_SYMBOL;

ALTER TABLE CURRENCY DROP CONSTRAINT PK_CURRENCY;

/* Drop table */

DROP TABLE CURRENCY;

/* ---------------------------------------------------------------------- */
/* Drop table "PERIOD"                                                    */
/* ---------------------------------------------------------------------- */

/* Drop constraints */

ALTER TABLE PERIOD DROP CONSTRAINT NN_PERIOD_PERIOD_ID;

ALTER TABLE PERIOD DROP CONSTRAINT NN_PERIOD_DESCRIPTION;

ALTER TABLE PERIOD DROP CONSTRAINT NN_PERIOD_DOLLAR_WORTH_VS_2002;

ALTER TABLE PERIOD DROP CONSTRAINT PK_PERIOD;

/* Drop table */

DROP TABLE PERIOD;
