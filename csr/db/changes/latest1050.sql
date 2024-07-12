-- Please update version.sql too -- this keeps clean builds in sync
define version=1050
@update_header

CREATE GLOBAL TEMPORARY TABLE CSRIMP.FORM_EXPR
(
    FORM_EXPR_ID            NUMBER(10, 0) NOT NULL,
    DELEGATION_SID          NUMBER(10, 0) NOT NULL,
    DESCRIPTION             VARCHAR2(255 BYTE),
    EXPR                    SYS.XMLType NOT NULL,
    CONSTRAINT PK_FORM_EXPR PRIMARY KEY (FORM_EXPR_ID)
);

CREATE GLOBAL TEMPORARY TABLE CSRIMP.DELEG_IND_FORM_EXPR
(
    DELEGATION_SID          NUMBER(10, 0) NOT NULL,
    IND_SID                 NUMBER(10, 0) NOT NULL,
    FORM_EXPR_ID            NUMBER(10, 0) NOT NULL,
    CONSTRAINT PK_DELEG_IND_FORM_EXPR PRIMARY KEY (DELEGATION_SID, IND_SID, FORM_EXPR_ID)
);

CREATE GLOBAL TEMPORARY TABLE CSRIMP.DELEG_IND_GROUP
(
    DELEG_IND_GROUP_ID      NUMBER(10, 0) NOT NULL,
    DELEGATION_SID          NUMBER(10, 0) NOT NULL,
    TITLE                   VARCHAR2(255 BYTE),
    CONSTRAINT PK_DELEG_IND_GROUP PRIMARY KEY (DELEGATION_SID, DELEG_IND_GROUP_ID)
);

-- it needs to be called DELEG_IND_GROUP_MEMBER (needs renaming)
CREATE GLOBAL TEMPORARY TABLE CSRIMP.DELEG_IND_DELEG_IND_GROUP
(
    DELEGATION_SID          NUMBER(10, 0) NOT NULL,
    IND_SID                 NUMBER(10, 0) NOT NULL,
    DELEG_IND_GROUP_ID      NUMBER(10, 0) NOT NULL,
    CONSTRAINT PK_DEL_IND_DEL_IND_GROUP PRIMARY KEY (DELEGATION_SID, IND_SID, DELEG_IND_GROUP_ID)
);

CREATE GLOBAL TEMPORARY TABLE CSRIMP.FACTOR(
    FACTOR_ID                    NUMBER(10, 0)     NOT NULL,
    FACTOR_TYPE_ID               NUMBER(10, 0)     NOT NULL,
    GAS_TYPE_ID                  NUMBER(10, 0)     NOT NULL,
    REGION_SID                   NUMBER(10, 0),
    GEO_COUNTRY                  VARCHAR2(2),
    GEO_REGION                   VARCHAR2(2),
    EGRID_REF                    VARCHAR2(4),
    IS_SELECTED                  NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    START_DTM                    DATE              NOT NULL,
    END_DTM                      DATE,
    VALUE                        NUMBER(24, 10)    NOT NULL,
    NOTE                         CLOB,
    STD_MEASURE_CONVERSION_ID    NUMBER(10, 0)     NOT NULL,
    STD_FACTOR_ID                NUMBER(10, 0),
    ORIGINAL_FACTOR_ID           NUMBER(10, 0),
    CONSTRAINT CK_FACTOR_DATES CHECK ((START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM)),
    CONSTRAINT PK_FACTOR PRIMARY KEY (FACTOR_ID)
);


-- form_expr map
create global temporary table csrimp.map_form_expr(
	old_form_expr_id					number(10)	not null,
	new_form_expr_id					number(10)	not null,
	constraint pk_map_form_expr primary key (old_form_expr_id) using index,
	constraint uk_map_form_expr unique (new_form_expr_id) using index
) on commit delete rows;


-- factor map
create global temporary table csrimp.map_factor(
	old_factor_id					number(10)	not null,
	new_factor_id					number(10)	not null,
	constraint pk_map_factor primary key (old_factor_id) using index,
	constraint uk_map_factor unique (new_factor_id) using index
) on commit delete rows;


-- deleg_ind_group map
create global temporary table csrimp.map_deleg_ind_group(
	old_deleg_ind_group_id					number(10)	not null,
	new_deleg_ind_group_id					number(10)	not null,
	constraint pk_map_deleg_ind_group primary key (old_deleg_ind_group_id) using index,
	constraint uk_map_deleg_ind_group unique (new_deleg_ind_group_id) using index
) on commit delete rows;



grant select on csr.form_expr_id_seq to csrimp;
grant select on csr.deleg_ind_group_id_seq to csrimp;
grant select on csr.factor_id_seq to csrimp;


grant select,insert on csr.factor to csrimp;
grant select,insert on csr.deleg_ind_deleg_ind_group to csrimp;
grant select,insert on csr.deleg_ind_group to csrimp;
grant select,insert on csr.deleg_ind_form_expr to csrimp;
grant select,insert on csr.form_expr to csrimp;


grant insert,select,update,delete on csrimp.factor to csrimp;
grant insert,select,update,delete on csrimp.deleg_ind_deleg_ind_group to csrimp;
grant insert,select,update,delete on csrimp.deleg_ind_group to csrimp;
grant insert,select,update,delete on csrimp.deleg_ind_form_expr to csrimp;
grant insert,select,update,delete on csrimp.form_expr to csrimp;


@update_tail
