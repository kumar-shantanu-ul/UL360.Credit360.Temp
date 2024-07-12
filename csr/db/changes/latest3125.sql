define version=3125
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/

CREATE SEQUENCE CHAIN.PRODUCT_METRIC_CALC_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE TABLE chain.product_metric_calc (
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	product_metric_calc_id			NUMBER(10, 0)	NOT NULL,
	destination_ind_sid				NUMBER(10, 0)	NOT NULL,
	applies_to_companies			NUMBER(1)		DEFAULT 0 NOT NULL,
	applies_to_products				NUMBER(1)		DEFAULT 0 NOT NULL,
	applies_to_product_suppliers	NUMBER(1)		DEFAULT 0 NOT NULL,
	calc_type						NUMBER(10, 0)	NOT NULL,
	operator						VARCHAR2(10)	NOT NULL,
	source_ind_sid_1				NUMBER(10, 0)	NOT NULL,
	source_ind_sid_2				NUMBER(10, 0),
	source_argument_2				NUMBER(24, 10),	
	user_values_only				NUMBER(1),
	CONSTRAINT pk_product_metric_calc PRIMARY KEY (app_sid, product_metric_calc_id),
	CONSTRAINT fk_product_metric_calc_dest FOREIGN KEY (app_sid, destination_ind_sid) REFERENCES chain.product_metric (app_sid, ind_sid),
	CONSTRAINT fk_product_metric_calc_src1 FOREIGN KEY (app_sid, source_ind_sid_1) REFERENCES chain.product_metric (app_sid, ind_sid),
	CONSTRAINT fk_product_metric_calc_src2 FOREIGN KEY (app_sid, source_ind_sid_2) REFERENCES chain.product_metric (app_sid, ind_sid),
	CONSTRAINT ck_product_metric_calc_type CHECK (
		(calc_type = 0 AND applies_to_companies = 0)
		OR
		(calc_type = 1)
		OR
		(calc_type = 2 AND applies_to_product_suppliers = 0)
	),
	CONSTRAINT ck_product_metric_calc_ap_p CHECK (applies_to_products IN (0, 1)),
	CONSTRAINT ck_product_metric_calc_ap_ps CHECK (applies_to_product_suppliers IN (0, 1)),
	CONSTRAINT ck_product_metric_calc_appl CHECK (
		applies_to_companies = 1 OR
		applies_to_products = 1 OR
		applies_to_product_suppliers = 1
	),
	CONSTRAINT ck_product_metric_calc_oper CHECK (
		(calc_type = 0 AND (operator IN ('+', '-', '*', '/')))
		OR
		(calc_type IN (1, 2) AND (operator IN ('count', 'sum', 'min', 'max', 'avg')))
	),
	CONSTRAINT ck_product_metric_calc_source CHECK (
		(calc_type = 0 AND (source_ind_sid_1 != destination_ind_sid) AND (
			(source_ind_sid_2 IS NOT NULL AND (source_ind_sid_2 != destination_ind_sid) AND source_argument_2 IS NULL) OR
			(source_ind_sid_2 IS NULL AND source_argument_2 IS NOT NULL)
		) AND user_values_only IS NULL)
		OR
		(calc_type IN (1, 2) AND (source_ind_sid_2 IS NULL OR source_ind_sid_2 != source_ind_sid_1) AND source_argument_2 IS NULL AND user_values_only IN (0, 1))
	)
);
CREATE UNIQUE INDEX chain.ux_product_metric_calc_comps ON chain.product_metric_calc (app_sid, destination_ind_sid, CASE WHEN applies_to_companies = 1 THEN 0 ELSE product_metric_calc_id END);
CREATE UNIQUE INDEX chain.ux_product_metric_calc_prods ON chain.product_metric_calc (app_sid, destination_ind_sid, CASE WHEN applies_to_products = 1 THEN 0 ELSE product_metric_calc_id END);
CREATE UNIQUE INDEX chain.ux_product_metric_calc_prsps ON chain.product_metric_calc (app_sid, destination_ind_sid, CASE WHEN applies_to_product_suppliers = 1 THEN 0 ELSE product_metric_calc_id END);
create index chain.ix_product_metric_calc_s_ind_1 on chain.product_metric_calc (app_sid, source_ind_sid_1);
create index chain.ix_product_metric_calc_s_ind_2 on chain.product_metric_calc (app_sid, source_ind_sid_2);
DROP TABLE chain.product_metric_calc;
CREATE TABLE chain.product_metric_calc (
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	product_metric_calc_id			NUMBER(10, 0)	NOT NULL,
	destination_ind_sid				NUMBER(10, 0)	NOT NULL,
	applies_to_products				NUMBER(1)		DEFAULT 0 NOT NULL,
	applies_to_product_companies	NUMBER(1)		DEFAULT 0 NOT NULL,
	applies_to_product_suppliers	NUMBER(1)		DEFAULT 0 NOT NULL,
	applies_to_prod_sup_purchasers	NUMBER(1)		DEFAULT 0 NOT NULL,
	applies_to_prod_sup_suppliers	NUMBER(1)		DEFAULT 0 NOT NULL,
	calc_type						NUMBER(10, 0)	NOT NULL,
	operator						VARCHAR2(10)	NOT NULL,
	source_ind_sid_1				NUMBER(10, 0)	NOT NULL,
	source_ind_sid_2				NUMBER(10, 0),
	source_argument_2				NUMBER(24, 10),	
	user_values_only				NUMBER(1),
	CONSTRAINT pk_product_metric_calc PRIMARY KEY (app_sid, product_metric_calc_id),
	CONSTRAINT fk_product_metric_calc_dest FOREIGN KEY (app_sid, destination_ind_sid) REFERENCES chain.product_metric (app_sid, ind_sid),
	CONSTRAINT fk_product_metric_calc_src1 FOREIGN KEY (app_sid, source_ind_sid_1) REFERENCES chain.product_metric (app_sid, ind_sid),
	CONSTRAINT fk_product_metric_calc_src2 FOREIGN KEY (app_sid, source_ind_sid_2) REFERENCES chain.product_metric (app_sid, ind_sid),
	CONSTRAINT ck_product_metric_calc_type CHECK (
		(calc_type = 0 AND applies_to_product_companies = 0 AND applies_to_prod_sup_purchasers = 0 AND applies_to_prod_sup_suppliers = 0)
		OR
		(calc_type = 1)
		OR
		(calc_type = 2 AND applies_to_product_suppliers = 0 AND applies_to_prod_sup_purchasers = 0 AND applies_to_prod_sup_suppliers = 0)
	),
	CONSTRAINT ck_product_metric_calc_ap_p CHECK (applies_to_products IN (0, 1)),
	CONSTRAINT ck_product_metric_calc_ap_pc CHECK (applies_to_product_companies IN (0, 1)),
	CONSTRAINT ck_product_metric_calc_ap_ps CHECK (applies_to_product_suppliers IN (0, 1)),
	CONSTRAINT ck_product_metric_calc_ap_psp CHECK (applies_to_prod_sup_purchasers IN (0, 1)),
	CONSTRAINT ck_product_metric_calc_ap_pss CHECK (applies_to_prod_sup_suppliers IN (0, 1)),
	CONSTRAINT ck_product_metric_calc_appl CHECK (
			applies_to_products = 1 OR
			applies_to_product_companies = 1 OR
			applies_to_product_suppliers = 1 OR
			applies_to_prod_sup_purchasers = 1 OR
			applies_to_prod_sup_suppliers = 1
	),
	CONSTRAINT ck_product_metric_calc_oper CHECK (
		(calc_type = 0 AND (operator IN ('+', '-', '*', '/')))
		OR
		(calc_type IN (1, 2) AND (operator IN ('count', 'sum', 'min', 'max', 'avg')))
	),
	CONSTRAINT ck_product_metric_calc_source CHECK (
		(calc_type = 0 AND (source_ind_sid_1 != destination_ind_sid) AND (
			(source_ind_sid_2 IS NOT NULL AND (source_ind_sid_2 != destination_ind_sid) AND source_argument_2 IS NULL) OR
			(source_ind_sid_2 IS NULL AND source_argument_2 IS NOT NULL)
		) AND user_values_only IS NULL)
		OR
		(calc_type IN (1, 2) AND (source_ind_sid_2 IS NULL OR source_ind_sid_2 != source_ind_sid_1) AND source_argument_2 IS NULL AND user_values_only IN (0, 1))
	)
);
CREATE UNIQUE INDEX chain.ux_product_metric_calc_prods ON chain.product_metric_calc (app_sid, destination_ind_sid, CASE WHEN applies_to_products = 1 THEN 0 ELSE product_metric_calc_id END);
CREATE UNIQUE INDEX chain.ux_product_metric_calc_prsps ON chain.product_metric_calc (app_sid, destination_ind_sid, CASE WHEN applies_to_product_suppliers = 1 THEN 0 ELSE product_metric_calc_id END);
CREATE UNIQUE INDEX chain.ux_product_metric_calc_comps ON chain.product_metric_calc (app_sid, destination_ind_sid, CASE WHEN applies_to_product_companies = 1
																														  OR applies_to_prod_sup_purchasers = 1
																														  OR applies_to_prod_sup_suppliers = 1 THEN 0 ELSE product_metric_calc_id END);
create index chain.ix_product_metric_calc_s_ind_1 on chain.product_metric_calc (app_sid, source_ind_sid_1);
create index chain.ix_product_metric_calc_s_ind_2 on chain.product_metric_calc (app_sid, source_ind_sid_2);
--Failed to process contents of latest3117_12.sql
--Failed to locate all sections of latest3117_12.sql
CREATE TABLE SURVEYS.SURVEY(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	PARENT_SID					NUMBER(10, 0)	NOT NULL,
	AUDIENCE					VARCHAR2(32) 	NULL,
	LATEST_PUBLISHED_VERSION 	NUMBER(10, 0) 	NULL,
	CONSTRAINT PK_SURVEY PRIMARY KEY (APP_SID, SURVEY_SID)
)
;
CREATE UNIQUE INDEX SURVEYS.IX_SURVEY ON SURVEYS.SURVEY(APP_SID, SURVEY_SID, LATEST_PUBLISHED_VERSION);


ALTER TABLE chain.product_metric_val ADD (
	SOURCE_TYPE						NUMBER(10, 0) DEFAULT 0 NOT NULL
);
ALTER TABLE chain.product_supplier_metric_val ADD (
	SOURCE_TYPE						NUMBER(10, 0) DEFAULT 0 NOT NULL
);
ALTER TABLE csr.dataview ADD (
	region_selection				NUMBER(1,0) DEFAULT(6) NOT NULL
);
ALTER TABLE csr.dataview_history ADD (
	region_selection				NUMBER(1,0) DEFAULT(6) NOT NULL
);
ALTER TABLE csrimp.dataview ADD (
	region_selection				NUMBER(1,0) DEFAULT(6) NOT NULL
);
ALTER TABLE csrimp.dataview_history ADD (
	region_selection				NUMBER(1,0) DEFAULT(6) NOT NULL
);
ALTER TABLE csr.auto_exp_retrieval_dataview ADD (
	period_span_pattern_id				NUMBER(10, 0)
);
ALTER TABLE csr.auto_exp_retrieval_dataview
ADD CONSTRAINT fk_auto_exp_rdv_psp_id FOREIGN KEY (app_sid, period_span_pattern_id) REFERENCES csr.period_span_pattern(app_sid, period_span_pattern_id);
UPDATE csr.auto_exp_retrieval_dataview aerd
   SET aerd.period_span_pattern_id = (
		SELECT DISTINCT aec.period_span_pattern_id
		  FROM csr.automated_export_class aec
		 WHERE aerd.auto_exp_retrieval_dataview_id = aec.auto_exp_retrieval_dataview_id);
ALTER TABLE csr.auto_exp_retrieval_dataview MODIFY period_span_pattern_id NOT NULL;
CREATE INDEX csr.ix_auto_exp_rdv_period_span_p ON csr.auto_exp_retrieval_dataview (app_sid, period_span_pattern_id);
ALTER TABLE csr.automated_export_class DROP CONSTRAINT FK_AUTO_EXP_CL_PER_SPAN_PAT_ID;
ALTER TABLE csr.automated_export_class DROP COLUMN period_span_pattern_id;
ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS DROP COLUMN PAYLOAD_PATH;
ALTER TABLE CSR.AUTOMATED_IMPORT_CLASS DROP COLUMN RERUN_ASAP;
ALTER TABLE surveys.response ADD (
	FLOW_ITEM_ID		NUMBER(10),
	CAMPAIGN_SID		NUMBER(10),
	REGION_SID			NUMBER(10)
);
ALTER TABLE SURVEYS.SURVEY ADD CONSTRAINT FK_SURVEY_PUBLISHED_VERSION
	FOREIGN KEY (APP_SID, SURVEY_SID, LATEST_PUBLISHED_VERSION)
	REFERENCES SURVEYS.SURVEY_VERSION (APP_SID, SURVEY_SID, SURVEY_VERSION)
;
ALTER TABLE surveys.answer_option
  ADD question_option_others VARCHAR2(4000);
  
BEGIN
	security.user_pkg.LogOnAdmin;
	FOR r IN (
		SELECT app_sid, survey_sid, parent_sid, audience, survey_version
		  FROM surveys.survey_version
	) LOOP
		INSERT INTO surveys.survey(app_sid, survey_sid, parent_sid, audience, latest_published_version)
			 VALUES (r.app_sid, r.survey_sid, r.parent_sid, r.audience, r.survey_version);
	END LOOP;
END;
/
ALTER TABLE surveys.survey_version DROP COLUMN start_dtm;
ALTER TABLE surveys.survey_version DROP COLUMN end_dtm;
ALTER TABLE surveys.survey_version DROP COLUMN parent_sid;
ALTER TABLE surveys.survey_version DROP COLUMN audience;
ALTER TABLE SURVEYS.SURVEY_VERSION ADD CONSTRAINT FK_SURVEY_VERSION
	FOREIGN KEY (APP_SID, SURVEY_SID)
	REFERENCES SURVEYS.SURVEY (APP_SID, SURVEY_SID)
;
ALTER TABLE surveys.condition_link ADD (
	TAG_GROUP_ID		NUMBER(10),
	TAG_ID				NUMBER(10)
);
ALTER TABLE CSR.QS_CAMPAIGN DROP CONSTRAINT FK_QS_CAMP_QS;
ALTER TABLE CSR.DELEG_PLAN_COL_SURVEY DROP CONSTRAINT FK_QUICK_SRV_DLG_PLN_COL_SRV;
CREATE TABLE SURVEYS.QUESTION_OPTION_DATA_SOURCES (
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DATA_SOURCE_ID				NUMBER(10, 0)	NOT NULL,
	DATA_SOURCE_NAME			VARCHAR2(255)	NOT NULL,
	DATA_SOURCE_DESCRIPTION		VARCHAR2(1024)	NOT NULL,
	DATA_SOURCE_HELPER_PKG		VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_DATA_SOURCE PRIMARY KEY (APP_SID, DATA_SOURCE_ID)
);
ALTER TABLE surveys.question_option_data_sources ADD (
	selected					NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_data_source_selected_0_1 CHECK (selected IN (0,1))
);
ALTER TABLE surveys.condition_link ADD (
	sub_type					VARCHAR2(255)
);
ALTER TABLE surveys.question ADD default_lang	VARCHAR2(50);
UPDATE surveys.question q
   SET (default_lang) = (SELECT MAX(tr.language_code)
						   FROM surveys.question_version_tr tr
						  WHERE q.question_id = tr.question_id
						  GROUP BY tr.question_id)
 WHERE EXISTS (
	SELECT 1
	  FROM surveys.question_version_tr tr
	 WHERE q.question_id = tr.question_id
	 GROUP BY tr.question_id);
UPDATE surveys.question q
   SET (default_lang) = 'en'
 WHERE q.default_lang IS NULL;
ALTER TABLE surveys.question MODIFY default_lang	NOT NULL;
ALTER TABLE surveys.clause ADD (
	question_sub_type			VARCHAR2(255)
);


GRANT EXECUTE ON security.web_pkg TO surveys;
GRANT SELECT ON security.web_resource TO surveys;
grant select, insert, delete on csr.temp_region_sid to surveys;
grant select on csr.qs_campaign to surveys;
grant select on csr.trash to surveys;
GRANT EXECUTE ON csr.campaign_pkg TO surveys;
grant execute on csr.flow_pkg to surveys;
grant execute on csr.csr_data_pkg to surveys;
grant select on csr.flow to surveys;
grant select on csr.flow_state_role to surveys;
grant select on csr.csr_user to surveys;
grant select on csr.region_role_member to surveys;
grant select on csr.v$region to surveys;
grant select on csr.flow_state_role_capability to surveys;
REVOKE SELECT ON chain.filter_value_id_seq FROM surveys;
REVOKE SELECT ON chain.debug_log FROM surveys;
REVOKE SELECT ON chain.filter FROM surveys;
REVOKE SELECT ON chain.filter_field FROM surveys;
REVOKE SELECT, INSERT ON chain.filter_value FROM surveys;
REVOKE SELECT ON chain.saved_filter FROM surveys;
REVOKE SELECT ON chain.compound_filter FROM surveys;
REVOKE SELECT ON chain.v$filter_field FROM surveys;
REVOKE SELECT, INSERT, delete ON chain.tt_filter_object_data FROM surveys;




INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15784, 12561, 'Accomodation ', NULL , 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15785, 15784, 'Hotel Stay',  NULL, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15786, 15785, 'Direct',  NULL, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15787, 15786, 'Hotel Stay (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15788, 14921, 'Transmission Loss (Electric Vehicle)', NULL, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15789, 14848, 'Air Passenger Distance - International - Average Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15790, 14848, 'Air Passenger Distance - International - Average Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15791, 14848, 'Air Passenger Distance - International - Economy Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15792, 14848, 'Air Passenger Distance - International - Economy Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15793, 14848, 'Air Passenger Distance - International - Premium Economy Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15794, 14848, 'Air Passenger Distance - International - Premium Economy Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15795, 14848, 'Air Passenger Distance - International - Business Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15796, 14848, 'Air Passenger Distance - International - Business Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15797, 14848, 'Air Passenger Distance - International - First Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15798, 14848, 'Air Passenger Distance - International - First Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15799, 14867, 'Air Passenger Distance - International - Average Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15800, 14867, 'Air Passenger Distance - International - Average Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15801, 14867, 'Air Passenger Distance - International - Economy Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15802, 14867, 'Air Passenger Distance - International - Economy Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15803, 14867, 'Air Passenger Distance - International - Premium Economy Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15804, 14867, 'Air Passenger Distance - International - Premium Economy Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15805, 14867, 'Air Passenger Distance - International - Business Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15806, 14867, 'Air Passenger Distance - International - Business Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15807, 14867, 'Air Passenger Distance - International - First Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15808, 14867, 'Air Passenger Distance - International - First Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15809, 14922, 'Road Vehicle Distance - Car (Class A -Mini) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15810, 14922, 'Road Vehicle Distance - Car (Class B -Supermini) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15811, 14922, 'Road Vehicle Distance - Car (Class C -Lower Medium) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15812, 14922, 'Road Vehicle Distance - Car (Class D -Upper Medium) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15813, 14922, 'Road Vehicle Distance - Car (Class E -Executive) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15814, 14922, 'Road Vehicle Distance - Car (Class F -Luxury) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15815, 14922, 'Road Vehicle Distance - Car (Class G -Sports) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15816, 14922, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15817, 14922, 'Road Vehicle Distance - Car (Class I -MPV) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15818, 14922, 'Road Vehicle Distance - Car (Small Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15819, 14922, 'Road Vehicle Distance - Car (Medium Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15820, 14922, 'Road Vehicle Distance - Car (Large Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15821, 14922, 'Road Vehicle Distance - Car (Average Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15822, 14922, 'Road Vehicle Distance - Car (Class A -Mini) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15823, 14922, 'Road Vehicle Distance - Car (Class B -Supermini) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15824, 14922, 'Road Vehicle Distance - Car (Class C -Lower Medium) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15825, 14922, 'Road Vehicle Distance - Car (Class D -Upper Medium) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15826, 14922, 'Road Vehicle Distance - Car (Class E -Executive) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15827, 14922, 'Road Vehicle Distance - Car (Class F -Luxury) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15828, 14922, 'Road Vehicle Distance - Car (Class G -Sports) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15829, 14922, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15830, 14922, 'Road Vehicle Distance - Car (Class I -MPV) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15831, 14922, 'Road Vehicle Distance - Car (Small Car) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15832, 14922, 'Road Vehicle Distance - Car (Medium Car) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15833, 14922, 'Road Vehicle Distance - Car (Large Car) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15834, 14922, 'Road Vehicle Distance - Car (Average Car) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15835, 14922, 'Road Vehicle Distance - Car (Class A -Mini) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15836, 14922, 'Road Vehicle Distance - Car (Class B -Supermini) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15837, 14922, 'Road Vehicle Distance - Car (Class C -Lower Medium) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15838, 14922, 'Road Vehicle Distance - Car (Class D -Upper Medium) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15839, 14922, 'Road Vehicle Distance - Car (Class E -Executive) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15840, 14922, 'Road Vehicle Distance - Car (Class F -Luxury) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15841, 14922, 'Road Vehicle Distance - Car (Class G -Sports) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15842, 14922, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15843, 14922, 'Road Vehicle Distance - Car (Class I -MPV) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15844, 14922, 'Road Vehicle Distance - Car (Small Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15845, 14922, 'Road Vehicle Distance - Car (Medium Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15846, 14922, 'Road Vehicle Distance - Car (Large Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15847, 14922, 'Road Vehicle Distance - Car (Average Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15848, 15788, 'Road Vehicle Distance - Car (Class A -Mini) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15849, 15788, 'Road Vehicle Distance - Car (Class B -Supermini) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15850, 15788, 'Road Vehicle Distance - Car (Class C -Lower Medium) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15851, 15788, 'Road Vehicle Distance - Car (Class D -Upper Medium) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15852, 15788, 'Road Vehicle Distance - Car (Class E -Executive) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15853, 15788, 'Road Vehicle Distance - Car (Class F -Luxury) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15854, 15788, 'Road Vehicle Distance - Car (Class G -Sports) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15855, 15788, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15856, 15788, 'Road Vehicle Distance - Car (Class I -MPV) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15857, 15788, 'Road Vehicle Distance - Car (Small Car) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15858, 15788, 'Road Vehicle Distance - Car (Medium Car) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15859, 15788, 'Road Vehicle Distance - Car (Large Car) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15860, 15788, 'Road Vehicle Distance - Car (Average Car) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15861, 14930, 'Road Vehicle Distance - Car (Class A -Mini) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15862, 14930, 'Road Vehicle Distance - Car (Class B -Supermini) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15863, 14930, 'Road Vehicle Distance - Car (Class C -Lower Medium) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15864, 14930, 'Road Vehicle Distance - Car (Class D -Upper Medium) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15865, 14930, 'Road Vehicle Distance - Car (Class E -Executive) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15866, 14930, 'Road Vehicle Distance - Car (Class F -Luxury) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15867, 14930, 'Road Vehicle Distance - Car (Class G -Sports) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15868, 14930, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15869, 14930, 'Road Vehicle Distance - Car (Class I -MPV) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15870, 14930, 'Road Vehicle Distance - Car (Small Car) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15871, 14930, 'Road Vehicle Distance - Car (Medium Car) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15872, 14930, 'Road Vehicle Distance - Car (Large Car) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15873, 14930, 'Road Vehicle Distance - Car (Average Car) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15874, 14930, 'Road Vehicle Distance - Car (Class A -Mini) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15875, 14930, 'Road Vehicle Distance - Car (Class B -Supermini) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15876, 14930, 'Road Vehicle Distance - Car (Class C -Lower Medium) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15877, 14930, 'Road Vehicle Distance - Car (Class D -Upper Medium) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15878, 14930, 'Road Vehicle Distance - Car (Class E -Executive) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15879, 14930, 'Road Vehicle Distance - Car (Class F -Luxury) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15880, 14930, 'Road Vehicle Distance - Car (Class G -Sports) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15881, 14930, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15882, 14930, 'Road Vehicle Distance - Car (Class I -MPV) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15883, 14930, 'Road Vehicle Distance - Car (Small Car) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15884, 14930, 'Road Vehicle Distance - Car (Medium Car) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15885, 14930, 'Road Vehicle Distance - Car (Large Car) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15886, 14930, 'Road Vehicle Distance - Car (Average Car) Battery Electric Vehicle (Upstream)', 10, 0);




BEGIN
	security.user_pkg.logonadmin;
	BEGIN
		INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (18, 'Chain product metric');
		COMMIT;
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;
END;
/
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Product Supplier Product Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductSupplierProductFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productSupplierProductFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductSupplierProductFilterAdapter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action <> 'default';
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	v_desc := 'Product Metric Value Product Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductMetricValProductFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productMetricValProductFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductMetricValProductFilterAdapter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action <> 'default';
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	v_desc := 'Product Supplier Metric Value Product Supplier Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productSupplierMetricValProductSupplierFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action <> 'default';
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
DECLARE
	v_card_id	NUMBER(10);
BEGIN	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductSupplierProductFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Supplier Product Filter Adapter', 'chain.product_supplier_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			VALUES (r.app_sid, 60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductMetricValProductFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Metric Value Product Filter Adapter', 'chain.product_metric_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 62
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			VALUES (r.app_sid, 62, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Supplier Metric Value Product Supplier Filter Adapter', 'chain.prdct_supp_mtrc_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 63
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			VALUES (r.app_sid, 63, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/
DECLARE
	v_card_id	NUMBER(10);
BEGIN	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.CompanyProductFilterAdapter';
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			VALUES (r.app_sid, 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/
BEGIN
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		VALUES (csr.plugin_id_seq.nextval, 10, 'Product supplier list (Company)', '/csr/site/chain/manageCompany/controls/ProductSupplierListTab.js', 'Chain.ManageCompany.ProductSupplierListTab', 'Credit360.Chain.Plugins.ProductSupplierListDto', 'This tab shows the product supplier list for a company.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		VALUES (csr.plugin_id_seq.nextval, 10, 'Product supplier list (Purchaser)', '/csr/site/chain/manageCompany/controls/ProductSupplierListPurchaserTab.js', 'Chain.ManageCompany.ProductSupplierListPurchaserTab', 'Credit360.Chain.Plugins.ProductSupplierListDto', 'This tab shows the product supplier list for a purchaser.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		VALUES (csr.plugin_id_seq.nextval, 10, 'Product supplier list (Supplier)', '/csr/site/chain/manageCompany/controls/ProductSupplierListSupplierTab.js', 'Chain.ManageCompany.ProductSupplierListSupplierTab', 'Credit360.Chain.Plugins.ProductSupplierListDto', 'This tab shows the product supplier list for a supplier.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
DECLARE
	v_new_menu_sid security.security_pkg.t_sid_id;
	v_groups_sid security.security_pkg.t_sid_id;
	v_admins_group_sid security.security_pkg.t_sid_id;
	v_admin_menu_sid security.security_pkg.t_sid_id;
	v_act_id security.security_pkg.t_act_id;
BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT host, app_sid
		  FROM csr.customer
		 WHERE LOWER(host) IN (
			SELECT LOWER(website_name)
			  FROM security.website
			)
	) LOOP
		security.user_pkg.logonadmin(r.host);
		v_act_id := security.security_pkg.getAct;
		BEGIN
			v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
			v_admins_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
			v_admin_menu_sid := security.securableobject_pkg.getsidfrompath(null, r.app_sid, 'menu/admin');
			BEGIN
				v_new_menu_sid := security.securableobject_pkg.getsidfrompath(NULL, r.app_sid, 'menu/admin/csr_admin_jobs');
			EXCEPTION
				WHEN security.security_pkg.object_not_found THEN
					NULL;
			END;
			IF v_new_menu_sid IS NULL THEN
				security.menu_pkg.createMenu(v_act_id,
				v_admin_menu_sid, 'csr_admin_jobs', 'Batch jobs', '/csr/site/admin/jobs/jobs.acds', -1, null, v_new_menu_sid);
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_new_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_admins_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			END IF;
		EXCEPTION
			WHEN security.security_pkg.object_not_found THEN
				NULL;
		END;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'UK', 'UNITED KINGDOM', null, null, 'gb', null);
DECLARE
	v_arb_period	NUMBER(10);
	v_cnt			NUMBER(10);
BEGIN
	FOR c IN (
		SELECT DISTINCT c.app_sid, c.host, st.meter_source_type_id
		  FROM csr.meter_source_type st
		  JOIN csr.customer c ON c.app_sid = st.app_sid
		 WHERE st.allow_null_start_dtm = 1
	) LOOP
		
		security.user_pkg.logonadmin(c.host);
		SELECT COUNT(*) 
		  INTO v_cnt
		  FROM csr.meter_source_type
		 WHERE name = 'period';
		IF v_cnt > 0 THEN
			SELECT DISTINCT meter_source_type_id
			  INTO v_arb_period
			  FROM csr.meter_source_type
			 WHERE name = 'period';
			
			UPDATE csr.all_meter
			   SET meter_source_type_id = v_arb_period
			 WHERE app_sid = c.app_sid
			   AND meter_source_type_id =  c.meter_source_type_id
			   AND urjanet_meter_id IS NULL;
		END IF;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (99, 'API FileSharing', 'EnableFileSharingApi', 'Enables the FileSharing Api.');
BEGIN
	security.user_pkg.LogonAdmin;
	-- Create web resources for all surveys that don't already have one
	FOR r IN (
		SELECT DISTINCT survey_sid, w.web_root_sid_id, pwr.path parent_path, so.name
		  FROM surveys.survey s
		  JOIN security.securable_object so ON s.survey_sid = so.sid_id
		  JOIN security.website w ON s.app_sid = w.application_sid_id
		  JOIN security.web_resource pwr ON s.parent_sid = pwr.sid_id
		  LEFT JOIN security.web_resource wr ON s.survey_sid = wr.sid_id
		 WHERE wr.sid_id IS NULL
	) LOOP
		INSERT INTO security.web_resource(sid_id, web_root_sid_id, path, rewrite_path)
		VALUES (r.survey_sid, r.web_root_sid_id, r.parent_path || '/' || r.name,
			'/csr/site/surveys/view.acds?surveySid='||r.survey_sid||'&'||'testMode=false');
	END LOOP;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE surveys.question_version
	   SET display_type = 'repeater'
	 WHERE question_id IN (
		SELECT question_id
		  FROM surveys.question
		 WHERE question_type = 'matrixset'
	 );
END;
/




CREATE OR REPLACE PACKAGE surveys.campaign_pkg IS END;
/
grant execute on surveys.campaign_pkg to web_user;


@..\tag_pkg
@..\csr_data_pkg
@..\chain\chain_pkg
@..\chain\product_metric_pkg
@..\automated_export_pkg
@..\chain\product_supplier_report_pkg
@..\chain\product_metric_report_pkg
@..\chain\prdct_supp_mtrc_report_pkg
@..\automated_import_pkg
@..\chain\filter_pkg
@..\chain\company_filter_pkg
@..\chain\chain_link_pkg
@..\meter_pkg
--@..\surveys\survey_pkg
--@..\surveys\campaign_pkg
--@..\surveys\question_library_pkg
--@..\surveys\condition_pkg
@..\enable_pkg
--@..\surveys\question_library_report_pkg
@..\quick_survey_pkg
@..\campaign_pkg
@..\flow_pkg


@..\tag_body
@..\chain\company_product_body
@..\chain\product_supplier_report_body
@..\chain\product_metric_body
@..\chain\product_metric_report_body
@..\chain\prdct_supp_mtrc_report_body
@..\meter_monitor_body
@..\compliance_body
@..\automated_export_body
@..\automated_import_body
@..\chain\filter_body
@..\chain\company_filter_body
@..\chain\chain_link_body
@..\enable_body
@..\meter_body
@..\issue_body
@..\issue_report_body
@..\compliance_register_report_body
--@..\surveys\condition_body
--@..\surveys\question_library_body
--@..\surveys\survey_body
--@..\surveys\campaign_body
--@..\surveys\question_library_report_body
@..\integration_api_body
@..\campaign_body
@..\quick_survey_body
@..\flow_body



@update_tail
