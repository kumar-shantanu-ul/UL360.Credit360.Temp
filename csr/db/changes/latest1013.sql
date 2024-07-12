-- Please update version.sql too -- this keeps clean builds in sync
define version=1013
@update_header

create user CT identified by CT temporary tablespace temp default tablespace users quota unlimited on users;

declare
	v_user varchar2(30) := 'CT';
	v_synonyms varchar2(30) := 'Y';
	type t_pkgs is table of varchar2(30);
	v_list t_pkgs;
	i integer;
	object_exists EXCEPTION;
	PRAGMA EXCEPTION_INIT(object_exists,-955);	
begin
	v_list := t_pkgs(
		'ACL_PKG', 'Y',
		'ACT_PKG', 'Y',
		'ATTRIBUTE_PKG', 'Y',
		'BITWISE_PKG', 'Y',
		'CLASS_PKG', 'Y',
		'GROUP_PKG', 'Y',
		'SECURABLEOBJECT_PKG', 'Y',
		'SECURITY_PKG', 'Y',
		'USER_PKG', 'Y',
		'WEB_PKG', 'Y',
		'SOFTLINK_PKG', 'N',
		'ACCOUNTPOLICY_PKG', 'N',
		'ACCOUNTPOLICYHELPER_PKG', 'N',
		'SESSION_PKG', 'N',
		'MENU_PKG', 'N',
		'CONN_PKG', 'N',
		'T_ORDERED_SID_ROW', 'N',
		'T_ORDERED_SID_TABLE', 'N'
	);

	i := 0;
	loop
		execute immediate 'grant execute on SECURITY.'||v_list(1 + i * 2)||' to '||v_user;
		if v_list(i * 2 + 2) = 'Y' and v_synonyms = 'Y' then
			begin
				execute immediate 'create synonym '||v_user||'.'||v_list(1 + i * 2)||' for SECURITY.'||v_list(1 + i * 2);
			exception
				when object_exists then
					null;
			end;
		end if;
		i := i + 1;
		exit when i >= v_list.count / 2;
	end loop;
end;
/

grant select, references on csr.csr_user to CT;
grant select, references on csr.customer to CT;
grant select on csr.portlet to CT;
grant select on csr.tab_portlet to CT;
grant select on csr.tab_id_seq to CT;
grant select, insert on csr.tab to CT;
grant select on csr.customer_portlet to CT;
grant execute on csr.portlet_pkg to CT;

grant select, references on chain.company to CT;
grant select, references on chain.customer_options to CT;
grant execute on chain.chain_pkg to CT;
grant execute on chain.capability_pkg to CT;

CREATE OR REPLACE PROCEDURE chain.T$RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		T$RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		T$RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type);
		RETURN;	
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.v$capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.v$capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.v$capability
	 WHERE capability_name = in_capability
	   AND (
	   			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   		 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type);
END;
/

CREATE OR REPLACE PROCEDURE chain.T$GrantCapability (
	in_capability_type		IN  number,
	in_capability			IN  varchar2,
	in_group				IN  varchar2,
	in_permission_set		IN  number
)
AS
	v_gc_id					chain.group_capability.group_capability_id%TYPE;
	v_cap_id				number;
BEGIN
	BEGIN
		SELECT capability_id
		  INTO v_cap_id
		  FROM chain.v$capability
		 WHERE capability_type_id = in_capability_type
		   AND capability_name = in_capability;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Capability ('||in_capability||') with type '''||in_capability_type||'''not found');
	END;
	
	BEGIN
		INSERT INTO chain.group_capability
		(group_capability_id, company_group_name, capability_id)
		VALUES
		(group_capability_id_seq.NEXTVAL, in_group, v_cap_id)
		RETURNING group_capability_id INTO v_gc_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT group_capability_id
			  INTO v_gc_id
			  FROM group_capability
			 WHERE company_group_name = in_group
			   AND capability_id = v_cap_id;
	END;
	
	BEGIN
		INSERT INTO group_capability_perm
		(group_capability_id, permission_set)
		VALUES
		(v_gc_id, in_permission_set);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE group_capability_perm
			   SET permission_set = in_permission_set
			 WHERE group_capability_id = v_gc_id;
	END;
END;
/

-- if the above fails, it's not a sql error for some reason
declare
	v_cnt number;
begin
	select count(*) into v_cnt from all_errors where name in ('T$GRANTCAPABILITY', 'T$REGISTERCAPABILITY')  and owner='CHAIN';
	if v_cnt != 0 then
		raise_application_error(-20001, 'RegisterCapability failed to compile');
	end if;
end;
/

BEGIN
	-- logon as builtin admin, no app
	security.user_pkg.logonadmin;

	chain.T$RegisterCapability(3 /*chain.chain_pkg.CT_COMPANIES*/, 'CT Hotspotter', 0);
	chain.T$GrantCapability(1 /*chain.chain_pkg.CT_COMPANY*/, 'CT Hotspotter', 'Administrators', security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.T$GrantCapability(1 /*chain.chain_pkg.CT_COMPANY*/, 'CT Hotspotter', 'Users', security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.T$GrantCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'CT Hotspotter', 'Administrators', security.security_pkg.PERMISSION_WRITE);
	chain.T$GrantCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'CT Hotspotter', 'Users', security.security_pkg.PERMISSION_WRITE);
END;
/

commit;

drop procedure chain.T$GrantCapability;
drop procedure chain.T$RegisterCapability;

grant select, references on postcode.country to CT;

grant execute on aspen2.filecache_pkg to CT;

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

/* ---------------------------------------------------------------------- */
/* Tables                                                                 */
/* ---------------------------------------------------------------------- */

/* ---------------------------------------------------------------------- */
/* Add table "BUS_TYPE"                                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BUS_TYPE (
    BUS_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 CONSTRAINT NN_BUS_TYPE_IS_DEFAULT NOT NULL,
    CONSTRAINT PK_BUS_TYPE PRIMARY KEY (BUS_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "BUSINESS_TYPE"                                              */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BUSINESS_TYPE (
    BUSINESS_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    CONSTRAINT PK_BUSINESS_TYPE PRIMARY KEY (BUSINESS_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "CAR_TYPE"                                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CAR_TYPE (
    CAR_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 CONSTRAINT NN_CAR_TYPE_IS_DEFAULT NOT NULL,
    CONSTRAINT PK_CAR_TYPE PRIMARY KEY (CAR_TYPE_ID)
);

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

/* ---------------------------------------------------------------------- */
/* Add table "CURRENCY"                                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CURRENCY (
    CURRENCY_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    SYMBOL VARCHAR2(4) NOT NULL,
    CONSTRAINT PK_CURRENCY PRIMARY KEY (CURRENCY_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "CUSTOMER_OPTIONS"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CUSTOMER_OPTIONS (
    APP_SID NUMBER(10) NOT NULL,
    CONSTRAINT PK_CUSTOMER_OPTIONS PRIMARY KEY (APP_SID)
);

/* ---------------------------------------------------------------------- */
/* Add table "ECQ_BUS_TYPE"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.ECQ_BUS_TYPE (
    ECQ_BUS_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_ECQ_BUS_TYPE PRIMARY KEY (ECQ_BUS_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "ECQ_CAR_TYPE"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.ECQ_CAR_TYPE (
    ECQ_CAR_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    EFFICIENCY_KM_LITRE NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_ECQ_CAR_TYPE PRIMARY KEY (ECQ_CAR_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "ECQ_MOTORBIKE_TYPE"                                         */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.ECQ_MOTORBIKE_TYPE (
    ECQ_MOTORBIKE_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_ECQ_MOTORBIKE_TYPE PRIMARY KEY (ECQ_MOTORBIKE_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "ECQ_TRAIN_TYPE"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.ECQ_TRAIN_TYPE (
    ECQ_TRAIN_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_ECQ_TRAIN_TYPE PRIMARY KEY (ECQ_TRAIN_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EIO_GROUP"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EIO_GROUP (
    EIO_GROUP_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    HIDE NUMBER(1) DEFAULT 0 CONSTRAINT NN_EIO_GROUP_HIDE NOT NULL,
    CONSTRAINT PK_EIO_GROUP PRIMARY KEY (EIO_GROUP_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "FUEL_TYPE"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.FUEL_TYPE (
    FUEL_TYPE_ID CHAR(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    COST_GBP_PER_LITRE NUMBER(10,3) NOT NULL,
    CONSTRAINT PK_FUEL_TYPE PRIMARY KEY (FUEL_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "MANUFACTURER"                                               */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.MANUFACTURER (
    MANUFACTURER_ID NUMBER(10) NOT NULL,
    MANUFACTURER VARCHAR2(256) NOT NULL,
    CONSTRAINT PK_MANUFACTURER PRIMARY KEY (MANUFACTURER_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "MOTORBIKE_TYPE"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.MOTORBIKE_TYPE (
    MOTORBIKE_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 CONSTRAINT NN_MOTORBIKE_TYPE_IS_DEFAULT NOT NULL,
    CONSTRAINT PK_MOTORBIKE_TYPE PRIMARY KEY (MOTORBIKE_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "PERIOD"                                                     */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.PERIOD (
    PERIOD_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    USD_RATIO_TO_BASE_YR NUMBER DEFAULT 0 CONSTRAINT NN_PERIOD_USD_RATIO_TO_BASE_YR NOT NULL,
    CONSTRAINT PK_PERIOD PRIMARY KEY (PERIOD_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "SCOPE_INPUT_TYPE"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.SCOPE_INPUT_TYPE (
    SCOPE_INPUT_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    CONSTRAINT PK_SCOPE_INPUT_TYPE PRIMARY KEY (SCOPE_INPUT_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "TRAIN_TYPE"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.TRAIN_TYPE (
    TRAIN_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    KG_CO2_PER_KM_CONTRIBUTION NUMBER(20,10) NOT NULL,
    IS_DEFAULT NUMBER(1) DEFAULT 0 CONSTRAINT NN_TRAIN_TYPE_IS_DEFAULT NOT NULL,
    CONSTRAINT PK_TRAIN_TYPE PRIMARY KEY (TRAIN_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "ADVICE"                                                     */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.ADVICE (
    ADVICE_ID NUMBER(10) CONSTRAINT NN_ADVICE_ADVICE_ID NOT NULL,
    ADVICE CLOB CONSTRAINT NN_ADVICE_ADVICE NOT NULL,
    CONSTRAINT PK_ADVICE PRIMARY KEY (ADVICE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "ADVICE_URL"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.ADVICE_URL (
    ADVICE_ID NUMBER(10) CONSTRAINT NN_ADVICE_URL_ADVICE_ID NOT NULL,
    URL_POS_ID NUMBER(10) CONSTRAINT NN_ADVICE_URL_URL_POS_ID NOT NULL,
    TEXT VARCHAR2(4000) CONSTRAINT NN_ADVICE_URL_TEXT NOT NULL,
    URL VARCHAR2(4000) CONSTRAINT NN_ADVICE_URL_URL NOT NULL,
    CONSTRAINT PK_ADVICE_URL PRIMARY KEY (ADVICE_ID, URL_POS_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "SCOPE_3_CATEGORY"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.SCOPE_3_CATEGORY (
    SCOPE_CATEGORY_ID NUMBER(10) CONSTRAINT NN_S_3_CAT_SCOPE_CATEGORY_ID NOT NULL,
    DESCRIPTION VARCHAR2(255) CONSTRAINT NN_S_3_CAT_DESCRIPTION NOT NULL,
    CONSTRAINT PK_S_3_CAT PRIMARY KEY (SCOPE_CATEGORY_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "SCOPE_3_ADVICE"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.SCOPE_3_ADVICE (
    SCOPE_CATEGORY_ID NUMBER(10) CONSTRAINT NN_S_3_ADV_SCOPE_CATEGORY_ID NOT NULL,
    ADVICE_ID NUMBER(10) CONSTRAINT NN_S_3_ADV_ADVICE_ID NOT NULL,
    ADVICE_KEY VARCHAR2(40) CONSTRAINT NN_S_3_ADV_ADVICE_KEY NOT NULL,
    CONSTRAINT PK_S_3_ADV PRIMARY KEY (SCOPE_CATEGORY_ID, ADVICE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN_TYPE"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN_TYPE (
    APP_SID NUMBER(10) NOT NULL,
    BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
    SINGULAR VARCHAR2(1024) NOT NULL,
    PLURAL VARCHAR2(1024) NOT NULL,
    BY_TURNOVER NUMBER(1) DEFAULT 0 NOT NULL,
    BY_FTE NUMBER(1) DEFAULT 0 NOT NULL,
    IS_REGION NUMBER(1) DEFAULT 0 NOT NULL,
    REST_OF VARCHAR2(1024) NOT NULL,
    CONSTRAINT PK_BRD_TYPE PRIMARY KEY (APP_SID, BREAKDOWN_TYPE_ID)
);

CREATE UNIQUE INDEX CT.IDX_BRD_TYPE_1 ON CT.BREAKDOWN_TYPE (APP_SID,LOWER(SINGULAR));

CREATE UNIQUE INDEX CT.IDX_BRD_TYPE_2 ON CT.BREAKDOWN_TYPE (APP_SID,LOWER(PLURAL));

/* ---------------------------------------------------------------------- */
/* Add table "CAR"                                                        */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CAR (
    CAR_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(256) NOT NULL,
    MANUFACTURER_ID NUMBER(10) NOT NULL,
    EFFICIENCY_KM_LITRE NUMBER(10,3) NOT NULL,
    FUEL_TYPE_ID CHAR(10) NOT NULL,
    TRANSMISSION_CODE VARCHAR2(10) NOT NULL,
    ENGINE_CAPACITY_CC NUMBER(10,3) NOT NULL,
    KM_PER_LITRE_URBAN NUMBER(10,3) NOT NULL,
    KM_PER_LITRE_EX_URBAN NUMBER(10,3) NOT NULL,
    MILES_PER_GALLON_URBAN NUMBER(10,3) NOT NULL,
    MILES_PER_GALLON_EX_URBAN NUMBER(10,3) NOT NULL,
    MILES_PER_GALLON_COMBINED NUMBER(10,3) NOT NULL,
    CO2_KG_PER_KM NUMBER(10,3) NOT NULL,
    CO_G_PER_KM NUMBER(10,3),
    HC_G_PER_KM NUMBER(10,3),
    NOX_G_PER_KM NUMBER(10,3),
    HC_NOX_G_PER_KM NUMBER(10,3),
    EMISSION_PARTIC_G_PER_KM NUMBER(10,3),
    EURO_STANDARD NUMBER(10) NOT NULL,
    NOISE_LEVEL_DBA NUMBER(10,3) NOT NULL,
    CONSTRAINT PK_CAR PRIMARY KEY (CAR_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "CURRENCY_PERIOD"                                            */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.CURRENCY_PERIOD (
    PERIOD_ID NUMBER(10) NOT NULL,
    CURRENCY_ID NUMBER(10) NOT NULL,
    PURCHSE_PWR_PARITY_FACT NUMBER(30,20),
    CONSTRAINT PK_CURRENCY_PERIOD PRIMARY KEY (PERIOD_ID, CURRENCY_ID)
);

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
    PCT_WAREHOUSE NUMBER(30,20) CONSTRAINT NN_EIO_PCT_WAREHOUSE NOT NULL,
    PCT_WASTE NUMBER(30,20) NOT NULL,
    PCT_UPSTREAM_TRANS NUMBER(30,20) NOT NULL,
    PCT_DOWNSTREAM_TRANS NUMBER(30,20) NOT NULL,
    PCT_CTFC_SCOPE_ONE_TWO NUMBER(30,20) NOT NULL,
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
    EIO_GROUP_ID NUMBER(10) CONSTRAINT NN_E_G_A_EIO_GROUP_ID NOT NULL,
    ADVICE_ID NUMBER(10) CONSTRAINT NN_E_G_A_ADVICE_ID NOT NULL,
    CONSTRAINT PK_E_G_A PRIMARY KEY (EIO_GROUP_ID, ADVICE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EIO_ADVICE"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EIO_ADVICE (
    EIO_ID NUMBER(10) CONSTRAINT NN_E_A_EIO_ID NOT NULL,
    ADVICE_ID NUMBER(10) CONSTRAINT NN_E_A_ADVICE_ID NOT NULL,
    CONSTRAINT PK_E_A PRIMARY KEY (EIO_ID, ADVICE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "COMPANY"                                                    */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.COMPANY (
    APP_SID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    FTE NUMBER(10) NOT NULL,
    TURNOVER NUMBER(25) NOT NULL,
    CURRENCY_ID NUMBER(10) NOT NULL,
    PERIOD_ID NUMBER(10) NOT NULL,
    BUSINESS_TYPE_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    SCOPE_INPUT_TYPE_ID NUMBER(10),
    SCOPE_1 NUMBER(10),
    SCOPE_2 NUMBER(10),
    CONSTRAINT PK_COMPANY PRIMARY KEY (APP_SID, COMPANY_SID)
);

/* ---------------------------------------------------------------------- */
/* Add table "COMPANY_CONSUMPTION_TYPE"                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.COMPANY_CONSUMPTION_TYPE (
    APP_SID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    CONSUMPTION_TYPE_ID NUMBER(10) NOT NULL,
    VALUE NUMBER(10) NOT NULL,
    CONSTRAINT PK_COMPANY_CONS_TYPE PRIMARY KEY (APP_SID, COMPANY_SID, CONSUMPTION_TYPE_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EC_QUESTIONNAIRE_ANSWERS"                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_QUESTIONNAIRE_ANSWERS (
    APP_SID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    RESPONDANT_ID NUMBER(10) NOT NULL,
    FULL_TIME_EMPLOYEE NUMBER(1) NOT NULL,
    WORKING_DAYS_PER_WK NUMBER(10,3) NOT NULL,
    TRAVEL_DAYS_PER_YR NUMBER(10,3) NOT NULL,
    VACATION_DAYS_PER_YR NUMBER(10,3) NOT NULL,
    OTHER_LEAVE_DAYS_PER_YR NUMBER(10,3) NOT NULL,
    CAR_DAYS_PER_WK NUMBER(10,3) NOT NULL,
    CAR_JOURNEY_KM NUMBER(10,3) NOT NULL,
    ECQ_CAR_TYPE_ID NUMBER(10),
    CAR_ID NUMBER(10),
    MOTORBIKE_DAYS_PER_WK NUMBER(10,3) NOT NULL,
    MOTORBIKE_JOURNEY_KM NUMBER(10,3) NOT NULL,
    ECQ_MOTORBIKE_TYPE_ID NUMBER(10),
    TRAIN_DAYS_PER_WK NUMBER(10,3) NOT NULL,
    TRAIN_JOURNEY_KM NUMBER(10,3) NOT NULL,
    ECQ_TRAIN_TYPE_ID NUMBER(10),
    BUS_DAYS_PER_WK NUMBER(10,3) NOT NULL,
    BUS_JOURNEY_KM NUMBER(10,3) NOT NULL,
    ECQ_BUS_TYPE_ID NUMBER(10),
    BIKE_DAYS_PER_WK NUMBER(10,3) NOT NULL,
    BIKE_JOURNEY_KM NUMBER(10,3) NOT NULL,
    WALK_DAYS_PER_WK NUMBER(10,3) NOT NULL,
    WALK_JOURNEY_KM NUMBER(10,3) NOT NULL,
    HOME_DAYS_PER_WK NUMBER(10,3) NOT NULL,
    CONSTRAINT PK_EC_QNR_ANS PRIMARY KEY (APP_SID, COMPANY_SID, RESPONDANT_ID)
);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (HOME_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (FULL_TIME_EMPLOYEE  IN (1,0));

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (CAR_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (MOTORBIKE_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (TRAIN_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (TRAIN_JOURNEY_KM <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (BUS_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (BUS_JOURNEY_KM <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (BIKE_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (BIKE_JOURNEY_KM <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (WALK_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD
    CHECK (WALK_JOURNEY_KM <= 7);

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN (
    APP_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    FTE NUMBER(10) NOT NULL,
    TURNOVER NUMBER(25) NOT NULL,
    FTE_TRAVEL NUMBER(10) NOT NULL,
    IS_REMAINDER NUMBER(1) DEFAULT 0 NOT NULL,
    REGION_ID NUMBER(10),
    CONSTRAINT PK_BREAKDOWN PRIMARY KEY (APP_SID, BREAKDOWN_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN_REGION_EIO"                                       */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN_REGION_EIO (
    APP_SID NUMBER(10) NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) CONSTRAINT NN_B_R_E_REGION_ID NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    PCT NUMBER(10) NOT NULL,
    FTE NUMBER(20,10) CONSTRAINT NN_B_R_E_FTE NOT NULL,
    TURNOVER NUMBER(35,10) CONSTRAINT NN_B_R_E_TURNOVER NOT NULL,
    CONSTRAINT PK_B_R_E PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID, EIO_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "EC_REGION"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.EC_REGION (
    REGION_ID NUMBER(10) NOT NULL,
    HOLIDAYS NUMBER(20,10) NOT NULL,
    CAR_AVG_PCT_USE NUMBER(20,10) NOT NULL,
    BUS_AVG_PCT_USE NUMBER(20,10) NOT NULL,
    TRAIN_AVG_PCT_USE NUMBER(20,10) NOT NULL,
    MOTORBIKE_AVG_PCT_USE NUMBER(20,10) NOT NULL,
    BIKE_AVG_PCT_USE NUMBER(20,10) NOT NULL,
    WALK_AVG_PCT_USE NUMBER(20,10) NOT NULL,
    CAR_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    BUS_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    TRAIN_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    MOTORBIKE_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    BIKE_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    WALK_AVG_JOURNEY_KM NUMBER(20,10) NOT NULL,
    CONSTRAINT PK_EC_REGION PRIMARY KEY (REGION_ID)
);

ALTER TABLE CT.EC_REGION ADD
    CHECK ((WALK_AVG_JOURNEY_KM <= 100) AND (WALK_AVG_JOURNEY_KM >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((CAR_AVG_PCT_USE <= 100) AND (CAR_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((BUS_AVG_PCT_USE <= 100) AND (BUS_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((TRAIN_AVG_PCT_USE <= 100) AND (TRAIN_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((MOTORBIKE_AVG_PCT_USE <= 100) AND (MOTORBIKE_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((BIKE_AVG_PCT_USE <= 100) AND (BIKE_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((WALK_AVG_PCT_USE <= 100) AND (WALK_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((CAR_AVG_JOURNEY_KM <= 100) AND (CAR_AVG_JOURNEY_KM >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((BUS_AVG_JOURNEY_KM <= 100) AND (BUS_AVG_JOURNEY_KM >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((TRAIN_AVG_JOURNEY_KM <= 100) AND (TRAIN_AVG_JOURNEY_KM >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((MOTORBIKE_AVG_JOURNEY_KM <= 100) AND (MOTORBIKE_AVG_JOURNEY_KM >= 0));

ALTER TABLE CT.EC_REGION ADD
    CHECK ((BIKE_AVG_JOURNEY_KM <= 100) AND (BIKE_AVG_JOURNEY_KM >= 0));

/* ---------------------------------------------------------------------- */
/* Add table "HOT_REGION"                                                 */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HOT_REGION (
    REGION_ID NUMBER(10) NOT NULL,
    FULL_LIFECYCLE_EF NUMBER(30,20) NOT NULL,
    COMBUSITION_EF NUMBER(30,20) NOT NULL,
    CONSTRAINT PK_HOT_REGION PRIMARY KEY (REGION_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "REGION"                                                     */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.REGION (
    REGION_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1024) NOT NULL,
    COUNTRY VARCHAR2(2),
    PARENT_ID NUMBER(10),
    CONSTRAINT PK_REGION PRIMARY KEY (REGION_ID),
    CONSTRAINT UK_REGION_DESCRIPTION UNIQUE (DESCRIPTION),
    CONSTRAINT UK_REGION_COUNTRY UNIQUE (COUNTRY)
);

/* ---------------------------------------------------------------------- */
/* Add table "BREAKDOWN_REGION"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BREAKDOWN_REGION (
    APP_SID NUMBER(10) CONSTRAINT NN_B_R_APP_SID NOT NULL,
    BREAKDOWN_ID NUMBER(10) CONSTRAINT NN_B_R_BREAKDOWN_ID NOT NULL,
    REGION_ID NUMBER(10) CONSTRAINT NN_B_R_REGION_ID NOT NULL,
    PCT NUMBER(10) CONSTRAINT NN_B_R_PCT NOT NULL,
    FTE_TRAVEL NUMBER(20,10) CONSTRAINT NN_B_R_FTE_TRAVEL NOT NULL,
    CONSTRAINT PK_B_R PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "HOTSPOT_RESULT"                                             */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.HOTSPOT_RESULT (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') CONSTRAINT NN_H_R_APP_SID NOT NULL,
    BREAKDOWN_ID NUMBER(10) CONSTRAINT NN_H_R_BREAKDOWN_ID NOT NULL,
    REGION_ID NUMBER(10) CONSTRAINT NN_H_R_REGION_ID NOT NULL,
    EIO_ID NUMBER(10) CONSTRAINT NN_H_R_EIO_ID NOT NULL,
    COMPANY_SID NUMBER(10),
    PG_EMISSIONS NUMBER(30,10) CONSTRAINT NN_H_R_PG_EMISSIONS NOT NULL,
    SCOPE_ONE_TWO_EMISSIONS NUMBER(30,10) CONSTRAINT NN_H_R_SCOPE_ONE_TWO_EMISSIONS NOT NULL,
    UPSTREAM_EMISSIONS NUMBER(30,10) CONSTRAINT NN_H_R_UPSTREAM_EMISSIONS NOT NULL,
    DOWNSTREAM_EMISSIONS NUMBER(30,10) CONSTRAINT NN_H_R_DOWNSTREAM_EMISSIONS NOT NULL,
    USE_EMISSIONS NUMBER(30,10) CONSTRAINT NN_H_R_USE_EMISSIONS NOT NULL,
    WASTE_EMISSIONS NUMBER(30,10) CONSTRAINT NN_H_R_WASTE_EMISSIONS NOT NULL,
    EMP_COMM_EMISSIONS NUMBER(30,10) CONSTRAINT NN_H_R_EMP_COMM_EMISSIONS NOT NULL,
    BUSINESS_TRAVEL_EMISSIONS NUMBER(30,10) CONSTRAINT NN_H_R_BUSINESS_TRAVEL_EMISS NOT NULL,
    CONSTRAINT PK_H_R PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID, EIO_ID)
);

/* ---------------------------------------------------------------------- */
/* Add table "BT_REGION"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CT.BT_REGION (
    REGION_ID NUMBER(10) CONSTRAINT NN__REGION_ID NOT NULL,
    TEMP_EMISSION_FACTOR NUMBER(20,10) CONSTRAINT NN__TEMP_EMISSION_FACTOR NOT NULL,
    CONSTRAINT PK_ PRIMARY KEY (REGION_ID)
);

/* ---------------------------------------------------------------------- */
/* Foreign key constraints                                                */
/* ---------------------------------------------------------------------- */

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT BRD_TYPE_BREAKDOWN 
    FOREIGN KEY (APP_SID, BREAKDOWN_TYPE_ID) REFERENCES CT.BREAKDOWN_TYPE (APP_SID,BREAKDOWN_TYPE_ID);

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT COMPANY_BREAKDOWN 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BREAKDOWN ADD CONSTRAINT REGION_BREAKDOWN 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.BREAKDOWN_REGION_EIO ADD CONSTRAINT EIO_B_R_E 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.BREAKDOWN_REGION_EIO ADD CONSTRAINT B_R_B_R_E 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.BREAKDOWN_TYPE ADD CONSTRAINT CUSTOMER_OPTIONS_BRD_TYPE 
    FOREIGN KEY (APP_SID) REFERENCES CT.CUSTOMER_OPTIONS (APP_SID);

ALTER TABLE CT.CAR ADD CONSTRAINT MANUFACTURER_CAR 
    FOREIGN KEY (MANUFACTURER_ID) REFERENCES CT.MANUFACTURER (MANUFACTURER_ID);

ALTER TABLE CT.CAR ADD CONSTRAINT FUEL_TYPE_CAR 
    FOREIGN KEY (FUEL_TYPE_ID) REFERENCES CT.FUEL_TYPE (FUEL_TYPE_ID);

ALTER TABLE CT.COMPANY ADD CONSTRAINT CHAIN_COMPANY_COMPANY 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID,COMPANY_SID);

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

ALTER TABLE CT.CUSTOMER_OPTIONS ADD CONSTRAINT CHAIN_CO_CUSTOMER_OPTIONS 
    FOREIGN KEY (APP_SID) REFERENCES CHAIN.CUSTOMER_OPTIONS (APP_SID);

ALTER TABLE CT.CUSTOMER_OPTIONS ADD CONSTRAINT CSR_CUSTOMER_CUSTOMER_OPTIONS 
    FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER (APP_SID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT ECQ_TRAIN_TYPE_EC_QNR_ANS 
    FOREIGN KEY (ECQ_TRAIN_TYPE_ID) REFERENCES CT.ECQ_TRAIN_TYPE (ECQ_TRAIN_TYPE_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT ECQ_MOTORBIKE_TYPE_EC_QNR_ANS 
    FOREIGN KEY (ECQ_MOTORBIKE_TYPE_ID) REFERENCES CT.ECQ_MOTORBIKE_TYPE (ECQ_MOTORBIKE_TYPE_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT COMPANY_EC_QNR_ANS 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT ECQ_CAR_TYPE_EC_QNR_ANS 
    FOREIGN KEY (ECQ_CAR_TYPE_ID) REFERENCES CT.ECQ_CAR_TYPE (ECQ_CAR_TYPE_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CAR_EC_QNR_ANS 
    FOREIGN KEY (CAR_ID) REFERENCES CT.CAR (CAR_ID);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT ECQ_BUS_TYPE_EC_QNR_ANS 
    FOREIGN KEY (ECQ_BUS_TYPE_ID) REFERENCES CT.ECQ_BUS_TYPE (ECQ_BUS_TYPE_ID);

ALTER TABLE CT.EC_REGION ADD CONSTRAINT REGION_EC_REGION 
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

ALTER TABLE CT.REGION ADD CONSTRAINT POSTCODE_COUNTRY_REGION 
    FOREIGN KEY (COUNTRY) REFERENCES POSTCODE.COUNTRY (COUNTRY);

ALTER TABLE CT.BREAKDOWN_REGION ADD CONSTRAINT BREAKDOWN_B_R 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID) REFERENCES CT.BREAKDOWN (APP_SID,BREAKDOWN_ID);

ALTER TABLE CT.BREAKDOWN_REGION ADD CONSTRAINT REGION_B_R 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT B_R_E_H_R 
    FOREIGN KEY (APP_SID, REGION_ID, BREAKDOWN_ID, EIO_ID) REFERENCES CT.BREAKDOWN_REGION_EIO (APP_SID,REGION_ID,BREAKDOWN_ID,EIO_ID);

ALTER TABLE CT.HOTSPOT_RESULT ADD CONSTRAINT COMPANY_H_R 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.BT_REGION ADD CONSTRAINT REGION_ 
    FOREIGN KEY (REGION_ID) REFERENCES CT.REGION (REGION_ID);

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
	
CREATE GLOBAL TEMPORARY TABLE CT.CHART_VALUE
(
	BREAKDOWN_ID				NUMBER(10) DEFAULT -1 NOT NULL,
	DESCRIPTION					VARCHAR2(4000)	NOT NULL,
	VAL							NUMBER(30,10)	NOT NULL, 
	POS							NUMBER(10) DEFAULT 0 NOT NULL,
	SCOPE_3_CATEGORY_ID			NUMBER(10)
) ON COMMIT DELETE ROWS;

CREATE OR REPLACE FUNCTION ct.appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- This is:
	--
	-- Allow data for superadmins (must exist for joins for names and so on, needs to be fixed);
	-- OR not logged on (i.e. needs to be fixed);
	-- OR logged on and data is for the current application
	--
	RETURN 'app_sid = 0 or app_sid = sys_context(''SECURITY'', ''APP'') or sys_context(''SECURITY'', ''APP'') is null';
END;
/

BEGIN
	
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		 INNER JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner = 'CT' AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'APP_SID'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => r.owner,
			policy_function => (CASE WHEN r.nullable ='N' THEN 'appSidCheck' ELSE 'nullableAppSidCheck' END),
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static);
	END LOOP;
	
END;
/


create or replace package ct.admin_pkg as
procedure dummy;
end;
/
create or replace package body ct.admin_pkg as
procedure dummy
as
begin
	null;
end;
end;
/


create or replace package ct.admin_pkg as
procedure dummy;
end;
/
create or replace package body ct.admin_pkg as
procedure dummy
as
begin
	null;
end;
end;
/


create or replace package ct.util_pkg as
procedure dummy;
end;
/
create or replace package body ct.util_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package ct.emp_commmute_pkg as
procedure dummy;
end;
/
create or replace package body ct.emp_commmute_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package ct.business_travel_pkg as
procedure dummy;
end;
/
create or replace package body ct.business_travel_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package ct.hotspot_pkg as
procedure dummy;
end;
/
create or replace package body ct.hotspot_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package ct.company_pkg as
procedure dummy;
end;
/
create or replace package body ct.company_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package ct.breakdown_pkg as
procedure dummy;
end;
/
create or replace package body ct.breakdown_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package ct.advice_pkg as
procedure dummy;
end;
/
create or replace package body ct.advice_pkg as
procedure dummy
as
begin
	null;
end;
end;
/


create or replace package ct.link_pkg as
procedure dummy;
end;
/
create or replace package body ct.link_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package ct.emp_commute_pkg as
procedure dummy;
end;
/
create or replace package body ct.emp_commute_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on ct.link_pkg TO chain;
grant execute on ct.admin_pkg to web_user;
grant execute on ct.util_pkg to web_user;
grant execute on ct.emp_commute_pkg to web_user;
grant execute on ct.business_travel_pkg to web_user;
grant execute on ct.hotspot_pkg to web_user;
grant execute on ct.company_pkg to web_user;
grant execute on ct.breakdown_pkg to web_user;
grant execute on ct.advice_pkg to web_user;


DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_ct_site_sid				security.security_pkg.T_SID_ID;
	v_ct_mgmt_sid				security.security_pkg.T_SID_ID;	
BEGIN

	security.user_pkg.logonadmin;
	v_act_id := security.security_pkg.GetAct;

	FOR r IN (
		SELECT app_sid FROM ct.customer_options
	) LOOP
	
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
		v_ct_site_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot/csr/site/ct');
	
		security.web_pkg.CreateResource(v_act_id, v_www_sid, v_ct_site_sid, 'management', v_ct_mgmt_sid);

		-- don't inherit dacls
		security.securableobject_pkg.SetFlags(v_act_id, v_ct_mgmt_sid, 0);
		-- clean existing ACE's
		security.acl_pkg.DeleteAllACEs(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_ct_mgmt_sid));

		-- give SuperAdmins group READ permission on the resource - everyone else is blocked
		security.acl_pkg.AddACE(v_act_id, security.Acl_pkg.GetDACLIDForSID(v_ct_mgmt_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_INHERITABLE, 
			security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins'), security.security_pkg.PERMISSION_STANDARD_READ);	
	
	END LOOP;

END;
/


@update_tail