-- Please update version.sql too -- this keeps clean builds in sync
define version=940
@update_header

CREATE TABLE CSR.EST_ATTR_MAPPING_TAG(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    EST_ACCOUNT_SID          NUMBER(10, 0)    NOT NULL,
    ATTR_NAME                VARCHAR2(256)    NOT NULL,
    TAG_ID                   NUMBER(10, 0)    NOT NULL,
    IND_SID                  NUMBER(10, 0),
    MEASURE_CONVERSION_ID    NUMBER(10, 0),
    CONSTRAINT PK_EST_ATTR_MAPPING_TAG PRIMARY KEY (APP_SID, EST_ACCOUNT_SID, ATTR_NAME, TAG_ID)
)
;

CREATE TABLE CSR.EST_METRIC_MAPPING_TAG(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    EST_ACCOUNT_SID          NUMBER(10, 0)    NOT NULL,
    METRIC_NAME              VARCHAR2(256)    NOT NULL,
    TAG_ID                   NUMBER(10, 0)    NOT NULL,
    IND_SID                  NUMBER(10, 0),
    MEASURE_CONVERSION_ID    NUMBER(10, 0),
    CONSTRAINT PK_EST_METRIC_MAPPING_TAG PRIMARY KEY (APP_SID, EST_ACCOUNT_SID, METRIC_NAME, TAG_ID)
)
;

CREATE TABLE CSR.EST_OTHER_MAPPING(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    EST_ACCOUNT_SID          NUMBER(10, 0)    NOT NULL,
    MAPPING_NAME             VARCHAR2(256)    NOT NULL,
    IND_SID                  NUMBER(10, 0),
    MEASURE_CONVERSION_ID    NUMBER(10, 0),
    HELPER                   VARCHAR2(256),
    CONSTRAINT PK_EST_OTHER_MAPPING PRIMARY KEY (APP_SID, EST_ACCOUNT_SID, MAPPING_NAME)
)
;

CREATE TABLE CSR.EST_OTHER_MAPPING_TAG(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    EST_ACCOUNT_SID          NUMBER(10, 0)    NOT NULL,
    MAPPING_NAME             VARCHAR2(256)    NOT NULL,
    TAG_ID                   NUMBER(10, 0)    NOT NULL,
    IND_SID                  NUMBER(10, 0),
    MEASURE_CONVERSION_ID    NUMBER(10, 0),
    CONSTRAINT PK_EST_OTHER_MAPPING_TAG PRIMARY KEY (APP_SID, EST_ACCOUNT_SID, MAPPING_NAME, TAG_ID)
)
;

ALTER TABLE CSR.EST_BUILDING_METRIC_MAPPING ADD(
    MEASURE_CONVERSION_ID    NUMBER(10, 0)
)
;

ALTER TABLE CSR.EST_SPACE_ATTR_MAPPING ADD(
    MEASURE_CONVERSION_ID    NUMBER(10, 0)
)
;

-- FKs

ALTER TABLE CSR.EST_ATTR_MAPPING_TAG ADD CONSTRAINT FK_ATTMAP_ATTMAPTAG 
    FOREIGN KEY (APP_SID, EST_ACCOUNT_SID, ATTR_NAME)
    REFERENCES CSR.EST_SPACE_ATTR_MAPPING(APP_SID, EST_ACCOUNT_SID, ATTR_NAME)
;

ALTER TABLE CSR.EST_ATTR_MAPPING_TAG ADD CONSTRAINT FK_IND_ATTMAPTAG 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;


ALTER TABLE CSR.EST_ATTR_MAPPING_TAG ADD CONSTRAINT FK_MCONV_ATTMAPTAG 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.EST_ATTR_MAPPING_TAG ADD CONSTRAINT FK_TAG_ATTMAPTAG 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;

ALTER TABLE CSR.EST_BUILDING_METRIC_MAPPING ADD CONSTRAINT FK_MCONV_METMAP 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.EST_METRIC_MAPPING_TAG ADD CONSTRAINT FK_BLDMETMAP_MATMAPTAG 
    FOREIGN KEY (APP_SID, EST_ACCOUNT_SID, METRIC_NAME)
    REFERENCES CSR.EST_BUILDING_METRIC_MAPPING(APP_SID, EST_ACCOUNT_SID, METRIC_NAME)
;

ALTER TABLE CSR.EST_METRIC_MAPPING_TAG ADD CONSTRAINT FK_IND_METMAPTAG 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.EST_METRIC_MAPPING_TAG ADD CONSTRAINT FK_MCONV_METMAPTAG 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.EST_METRIC_MAPPING_TAG ADD CONSTRAINT FK_TAG_METMAPTAG 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;

ALTER TABLE CSR.EST_OTHER_MAPPING ADD CONSTRAINT FK_ESTACC_OTHMAP 
    FOREIGN KEY (APP_SID, EST_ACCOUNT_SID)
    REFERENCES CSR.EST_ACCOUNT(APP_SID, EST_ACCOUNT_SID)
;

ALTER TABLE CSR.EST_OTHER_MAPPING ADD CONSTRAINT FK_IND_OTHMAP 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.EST_OTHER_MAPPING ADD CONSTRAINT FK_MCONV_OTHMAP 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.EST_OTHER_MAPPING_TAG ADD CONSTRAINT FK_IND_OTHMAPTAG 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.EST_OTHER_MAPPING_TAG ADD CONSTRAINT FK_MCONV_OTHMAPTAG 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.EST_OTHER_MAPPING_TAG ADD CONSTRAINT FK_OTHMAP_OTHMAPTAG 
    FOREIGN KEY (APP_SID, EST_ACCOUNT_SID, MAPPING_NAME)
    REFERENCES CSR.EST_OTHER_MAPPING(APP_SID, EST_ACCOUNT_SID, MAPPING_NAME)
;

ALTER TABLE CSR.EST_OTHER_MAPPING_TAG ADD CONSTRAINT FK_TAG_OTHMAPTAG 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;

ALTER TABLE CSR.EST_SPACE_ATTR_MAPPING ADD CONSTRAINT FK_MCONV_ATTMAP 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

-- FK indexes
CREATE INDEX csr.ix_attmap_attmaptag ON csr.est_attr_mapping_tag (app_sid, est_account_sid, attr_name);
CREATE INDEX csr.ix_ind_attmaptag ON csr.est_attr_mapping_tag (app_sid, ind_sid);
CREATE INDEX csr.ix_mconv_attmaptag ON csr.est_attr_mapping_tag (app_sid, measure_conversion_id);
CREATE INDEX csr.ix_tag_attmaptag ON csr.est_attr_mapping_tag (app_sid, tag_id);
CREATE INDEX csr.ix_mconv_metmap ON csr.est_building_metric_mapping (app_sid, measure_conversion_id);
CREATE INDEX csr.ix_bldmetmap_matmaptag ON csr.est_metric_mapping_tag (app_sid, est_account_sid, metric_name);
CREATE INDEX csr.ix_ind_metmaptag ON csr.est_metric_mapping_tag (app_sid, ind_sid);
CREATE INDEX csr.ix_mconv_metmaptag ON csr.est_metric_mapping_tag (app_sid, measure_conversion_id);
CREATE INDEX csr.ix_tag_metmaptag ON csr.est_metric_mapping_tag (app_sid, tag_id);
CREATE INDEX csr.ix_estacc_othmap ON csr.est_other_mapping (app_sid, est_account_sid);
CREATE INDEX csr.ix_ind_othmap ON csr.est_other_mapping (app_sid, ind_sid);
CREATE INDEX csr.ix_mconv_othmap ON csr.est_other_mapping (app_sid, measure_conversion_id);
CREATE INDEX csr.ix_ind_othmaptag ON csr.est_other_mapping_tag (app_sid, ind_sid);
CREATE INDEX csr.ix_mconv_othmaptag ON csr.est_other_mapping_tag (app_sid, measure_conversion_id);
CREATE INDEX csr.ix_othmap_othmaptag ON csr.est_other_mapping_tag (app_sid, est_account_sid, mapping_name);
CREATE INDEX csr.ix_tag_othmaptag ON csr.est_other_mapping_tag (app_sid, tag_id);
CREATE INDEX csr.ix_mconv_attmap ON csr.est_space_attr_mapping (app_sid, measure_conversion_id);

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'EST_ATTR_MAPPING_TAG',
		'EST_METRIC_MAPPING_TAG',
		'EST_OTHER_MAPPING',
		'EST_OTHER_MAPPING_TAG'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
/

@../energy_star_pkg
@../energy_star_body

@update_tail