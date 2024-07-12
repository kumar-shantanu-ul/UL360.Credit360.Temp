set echo on
whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

define host='&&1'
define usr='&&2'

exec security.user_pkg.logonadmin('&&host');


declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_users
	 where username = UPPER('&usr');
	if v_exists = 0 then
		execute immediate 'create user &&usr identified by &&usr temporary tablespace temp default tablespace users quota unlimited on users';
	end if;
end;
/

grant select on cms.context to &&usr;
grant select on cms.fast_context to &&usr;
grant execute on cms.tab_pkg to &&usr;
grant execute on security.security_pkg to &&usr;
GRANT SELECT, REFERENCES ON csr.initiative TO &&usr;
GRANT SELECT ON cms.temp_upload TO web_user;

-- Drop relevent tables
DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(40);
	v_list t_tabs := t_tabs(
		'MV',
		'MEASUREMENT_OPTION',
		'MV_YES_NO'
	);
BEGIN
	cms.tab_pkg.enabletrace;
	FOR i IN 1 .. v_list.count 
	LOOP
		-- USER, table_name, cascade, drop physical
		cms.tab_pkg.DropTable('&&usr', v_list(i), true, true);
	END LOOP;
END;
/

/********************************************************************************
 ENUMERATION TABLES
 ********************************************************************************/
-- MEASUREMENT_OPTION
CREATE TABLE &&usr..MEASUREMENT_OPTION (
    MEASUREMENT_OPTION_ID    NUMBER(10) NOT NULL,
    LABEL                    VARCHAR2(255) NOT NULL,
    POS                      NUMBER(10) DEFAULT 0 NOT NULL,
    CONSTRAINT PK_MEASUREMENT_OPTION PRIMARY KEY (MEASUREMENT_OPTION_ID)
);

BEGIN
    INSERT INTO &&usr..MEASUREMENT_OPTION (MEASUREMENT_OPTION_ID, LABEL, POS) VALUES (1, 'A', 1);
    INSERT INTO &&usr..MEASUREMENT_OPTION (MEASUREMENT_OPTION_ID, LABEL, POS) VALUES (2, 'B', 2);
    INSERT INTO &&usr..MEASUREMENT_OPTION (MEASUREMENT_OPTION_ID, LABEL, POS) VALUES (3, 'C', 3);
    INSERT INTO &&usr..MEASUREMENT_OPTION (MEASUREMENT_OPTION_ID, LABEL, POS) VALUES (4, 'D', 4);
END;
/

COMMENT ON TABLE &&usr..MEASUREMENT_OPTION IS 'desc="Measurement option"';
COMMENT ON COLUMN &&usr..MEASUREMENT_OPTION.MEASUREMENT_OPTION_ID IS 'desc="Ref",auto';
COMMENT ON COLUMN &&usr..MEASUREMENT_OPTION.LABEL IS 'desc="Label"';
COMMENT ON COLUMN &&usr..MEASUREMENT_OPTION.POS IS 'desc="Position in list",pos';

-- YES NO
CREATE TABLE &&usr..MV_YES_NO (
    MV_YES_NO_ID   NUMBER(10)      NOT NULL, 
    LABEL       VARCHAR2(255)   NOT NULL, 
    POS         NUMBER(10)      DEFAULT 0 NOT NULL,  
    CONSTRAINT PK_MV_YES_NO PRIMARY KEY (MV_YES_NO_ID) 
);
INSERT INTO &&usr..MV_YES_NO (MV_YES_NO_ID, LABEL, POS) VALUES (1, 'Yes', 1);
INSERT INTO &&usr..MV_YES_NO (MV_YES_NO_ID, LABEL, POS) VALUES (0, 'No', 2);
    
COMMENT ON COLUMN &&usr..MV_YES_NO.MV_YES_NO_ID IS 'desc="Ref",auto';
COMMENT ON COLUMN &&usr..MV_YES_NO.LABEL IS 'desc="Label"';
COMMENT ON COLUMN &&usr..MV_YES_NO.POS IS 'desc="Position in list",pos';

/********************************************************************************
 TABLES
 ********************************************************************************/
-- MV
CREATE TABLE &&usr..MV (
	INITIATIVE_SID					NUMBER(10) NOT NULL,
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	MEASUREMENT_OPTION_ID			NUMBER(10) NOT NULL,
	BASELINE_FROM					DATE,
	BASELINE_TO						DATE,
	REPORTING_PERIOD_FROM			DATE,
	REPORTING_PERIOD_TO				DATE,
	REPORTING_PERIOD_FORECAST		NUMBER(24,10),
	REPORTING_PERIOD_ACTUAL			NUMBER(24,10),
	KWH_CHANGE						NUMBER(24,10),
	PCT_CHANGE						NUMBER(24,10),
	COMMENTARY						CLOB,
	ESTIMATED_MONTHLY_SAVING		NUMBER(24,10),
	ESTIMATION_METHOD_COMMENTARY	CLOB,
	ESTIMATION_METHOD_APPROVAL		NUMBER(10),
	RULE_OF_THUMB_MONTHLY_SAVING	NUMBER(24,10),
	RULE_OF_THUMB_COMMENTARY		CLOB,
	SAVING_METHOD_APPROVAL			NUMBER(10),
	DOC_FILE						BLOB,
	DOC_MIME						VARCHAR2(100),
	DOC_NAME						VARCHAR2(255),
	CONSTRAINT PK_MV PRIMARY KEY (INITIATIVE_SID)
);

ALTER TABLE &&usr..MV ADD CONSTRAINT FK_MV_MEASUREMENT_OPTION
    FOREIGN KEY (MEASUREMENT_OPTION_ID)
    REFERENCES &&usr..MEASUREMENT_OPTION(MEASUREMENT_OPTION_ID);

ALTER TABLE &&usr..MV ADD CONSTRAINT FK_MV_MV_YES_NO
    FOREIGN KEY (ESTIMATION_METHOD_APPROVAL)
    REFERENCES &&usr..MV_YES_NO(MV_YES_NO_ID);

ALTER TABLE &&usr..MV ADD CONSTRAINT FK_MV_MV_YES_NO_2
    FOREIGN KEY (SAVING_METHOD_APPROVAL)
    REFERENCES &&usr..MV_YES_NO(MV_YES_NO_ID);

ALTER TABLE &&usr..MV ADD CONSTRAINT FK_MV_INITIATIVE
    FOREIGN KEY (INITIATIVE_SID)
    REFERENCES CSR.INITIATIVE(INITIATIVE_SID);


COMMENT ON TABLE &&usr..MV IS 'desc="Measurement and Validation"';
COMMENT ON COLUMN &&usr..MV.INITIATIVE_SID IS 'desc="Initiative"';
COMMENT ON COLUMN &&usr..MV.APP_SID IS 'app';
COMMENT ON COLUMN &&usr..MV.MEASUREMENT_OPTION_ID IS 'desc="Measurement option",enum,enum_desc_col=label,enum_pos_col=pos';
COMMENT ON COLUMN &&usr..MV.BASELINE_FROM IS 'desc="Baseline from"';
COMMENT ON COLUMN &&usr..MV.BASELINE_TO IS 'desc="Baseline to"';
COMMENT ON COLUMN &&usr..MV.REPORTING_PERIOD_FROM IS 'desc="Reporting period from"';
COMMENT ON COLUMN &&usr..MV.REPORTING_PERIOD_TO IS 'desc="Reporting period to"';
COMMENT ON COLUMN &&usr..MV.REPORTING_PERIOD_FORECAST IS 'desc="Reporting period forecast"';
COMMENT ON COLUMN &&usr..MV.REPORTING_PERIOD_ACTUAL IS 'desc="Reporting period actual"';
COMMENT ON COLUMN &&usr..MV.KWH_CHANGE IS 'desc="kWh change"';
COMMENT ON COLUMN &&usr..MV.PCT_CHANGE IS 'desc="% change"';
COMMENT ON COLUMN &&usr..MV.COMMENTARY IS 'desc="Commentary"';
COMMENT ON COLUMN &&usr..MV.ESTIMATED_MONTHLY_SAVING IS 'desc="Estimated monthly saving"';
COMMENT ON COLUMN &&usr..MV.ESTIMATION_METHOD_COMMENTARY IS 'desc="Estimation method commentary"';
COMMENT ON COLUMN &&usr..MV.ESTIMATION_METHOD_APPROVAL IS 'desc="Estimation method approval",enum,enum_desc_col=label,enum_pos_col=pos';
COMMENT ON COLUMN &&usr..MV.RULE_OF_THUMB_MONTHLY_SAVING IS 'desc="Rule of thumb monthly saving"';
COMMENT ON COLUMN &&usr..MV.RULE_OF_THUMB_COMMENTARY IS 'desc="Rule of thumb commentary"';
COMMENT ON COLUMN &&usr..MV.SAVING_METHOD_APPROVAL IS 'desc="Saving method approval",enum,enum_desc_col=label,enum_pos_col=pos';
COMMENT ON COLUMN &&usr..MV.DOC_FILE IS 'desc="Please attach supporting M and V template",file,file_mime=doc_mime,file_name=doc_name';

/********************************************************************************
 CROSS-TABLE CONSTRAINTS
 ********************************************************************************/
/********************************************************************************
 TABLE REGISTRATION
 ********************************************************************************/
spool registerTables.log
BEGIN
	cms.tab_pkg.enabletrace;
	cms.tab_pkg.AllowTable('CSR', 'INITIATIVE');
    cms.tab_pkg.registertable(UPPER('&&usr'), 'MV', FALSE);
END;
/

GRANT INSERT, UPDATE, DELETE ON &&usr..MV TO web_user;

COMMIT;

spool off
exit
