-- Please update version.sql too -- this keeps clean builds in sync
define version=824
@update_header

ALTER TABLE csr.location DROP COLUMN is_search_fail;
ALTER TABLE csr.custom_location DROP COLUMN is_search_fail;

DROP TABLE csr.logistics_changed CASCADE CONSTRAINTS;

ALTER TABLE CSR.CUSTOM_DISTANCE DROP PRIMARY KEY DROP INDEX;
ALTER TABLE CSR.DISTANCE DROP PRIMARY KEY DROP INDEX;

DROP TABLE CSR.TRANSPORT CASCADE CONSTRAINTS;

ALTER TABLE CSR.CUSTOM_DISTANCE RENAME COLUMN TRANSPORT_ID TO TRANSPORT_MODE_ID;
ALTER TABLE CSR.DISTANCE RENAME COLUMN TRANSPORT_ID TO TRANSPORT_MODE_ID;

ALTER TABLE CSR.CUSTOM_DISTANCE ADD (
	CONSTRAINT PK_CUSTOM_DISTANCE PRIMARY KEY (APP_SID, ORIGIN_ID, DESTINATION_ID, TRANSPORT_MODE_ID)
);

ALTER TABLE CSR.DISTANCE ADD (
	CONSTRAINT PK_DISTANCE PRIMARY KEY (ORIGIN_ID, DESTINATION_ID, TRANSPORT_MODE_ID)
);

CREATE TABLE CSR.TRANSPORT_MODE(
    TRANSPORT_MODE_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_TRANSPORT_MODE PRIMARY KEY (TRANSPORT_MODE_ID)
);

BEGIN
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (1, 'Air'); --csr_data_pkg.transport_mode_AIR
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (2, 'Sea'); --csr_data_pkg.transport_mode_SEA
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (3, 'Road'); --csr_data_pkg.transport_mode_ROAD
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (4, 'Barge'); --csr_data_pkg.transport_mode_BARGE
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (5, 'Rail'); --csr_data_pkg.transport_mode_RAIL
END;
/


ALTER TABLE CSR.CUSTOM_DISTANCE ADD CONSTRAINT FK_TRANS_MODE_CUS_DIST 
    FOREIGN KEY (TRANSPORT_MODE_ID)
    REFERENCES CSR.TRANSPORT_MODE(TRANSPORT_MODE_ID);

ALTER TABLE CSR.DISTANCE ADD CONSTRAINT FK_TRANS_MODE_DIST 
    FOREIGN KEY (TRANSPORT_MODE_ID)
    REFERENCES CSR.TRANSPORT_MODE(TRANSPORT_MODE_ID) ;

CREATE TABLE CSR.LOGISTICS_TAB_MODE(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TAB_SID              NUMBER(10, 0)    NOT NULL,
    transport_mode_ID    NUMBER(10, 0)    NOT NULL,
    SET_DISTANCE_SP      VARCHAR2(255)    NOT NULL,
    GET_ROWS_SP          VARCHAR2(255)    NOT NULL,
	START_JOB_SP		VARCHAR2(255)    NOT NULL,
	DELETE_ROW_SP		VARCHAR2(255)    NOT NULL,
     IS_DIRTY             NUMBER(1, 0)     DEFAULT 0 NOT NULL,
     PROCESSING			 NUMBER(1, 0)     DEFAULT 0 NOT NULL,
     PROCESSOR_CLASS	 VARCHAR2(128)     NOT NULL,
    CONSTRAINT CHK_LOG_TAB_TYPE_IS_DIRTY CHECK (IS_DIRTY IN (0,1)),
    CONSTRAINT CHK_LOG_TAB_TYPE_PROCESS CHECK (PROCESSING IN (0,1)),
    CONSTRAINT PK_LOGISTICS_TAB_MODE PRIMARY KEY (APP_SID, TAB_SID, PROCESSOR_CLASS)
);


ALTER TABLE CSR.LOGISTICS_TAB_MODE ADD CONSTRAINT FK_LOG_DEFLT_LOG_TAB_TYPE 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.LOGISTICS_DEFAULT(APP_SID)
;

ALTER TABLE CSR.LOGISTICS_TAB_MODE ADD CONSTRAINT FK_LOG_MODE_LOG_TAB 
    FOREIGN KEY (TRANSPORT_MODE_ID)
    REFERENCES CSR.TRANSPORT_MODE(TRANSPORT_MODE_ID);


-- external reference
ALTER TABLE CSR.LOGISTICS_TAB_MODE ADD CONSTRAINT FK_TAB_LOG_TAB_MODE 
    FOREIGN KEY (APP_SID, TAB_SID)
    REFERENCES CMS.TAB(APP_SID, TAB_SID) ON DELETE CASCADE;

-- XXX: what references this? need to recreate these....?
DROP TABLE cSR.LOGISTICS_ERROR_LOG CASCADE CONSTRAINTS;


-- clean up unused columns
ALTER TABLE csr.CUSTOM_LOCATION DROP CONSTRAINT RefREGION2088;
ALTER TABLE csr.CUSTOM_LOCATION DROP COLUMN REGION;
ALTER TABLE csr.LOCATION DROP CONSTRAINT RefREGION2094;
ALTER TABLE csr.LOCATION DROP COLUMN REGION;


CREATE TABLE CSR.LOGISTICS_ERROR_LOG(
    APP_SID                   NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    LOGISTICS_ERROR_LOG_ID    NUMBER(10, 0)     NOT NULL,
    TAB_SID                   NUMBER(10, 0)     NOT NULL,
    PROCESSOR_CLASS           VARCHAR2(128)     NOT NULL,
    ID                        NUMBER(10, 0)     NOT NULL,
    MESSAGE                   VARCHAR2(2048)    NOT NULL,
    LOGGED_DTM				  DATE				DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_LOGISTICS_ERROR_LOG PRIMARY KEY (APP_SID, LOGISTICS_ERROR_LOG_ID)
);

ALTER TABLE CSR.LOGISTICS_ERROR_LOG ADD CONSTRAINT FK_LOG_TAB_MODE_ERR_LOG 
    FOREIGN KEY (APP_SID, TAB_SID, PROCESSOR_CLASS)
    REFERENCES CSR.LOGISTICS_TAB_MODE(APP_SID, TAB_SID, PROCESSOR_CLASS);

CREATE SEQUENCE CSR.LOGISTICS_ERROR_LOG_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

-- get custom_location back under control
ALTER TABLE CSR.CUSTOM_LOCATION ADD (LOCATION_HASH RAW(20));
 
UPDATE csr.custom_location 
   SET location_hash = DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(
					UPPER(address||'|'||city||'|'||province||'|'||postcode||'|'||country),
					'AL32UTF8'), 3) --dbms_crypto.hash_sh1
 WHERE location_type_id = 4; 
 
UPDATE csr.custom_location 
   SET location_hash = DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(UPPER(name), 'AL32UTF8'), 3) --dbms_crypto.hash_sh1
 WHERE location_type_id != 4;

ALTER TABLE CSR.CUSTOM_LOCATION MODIFY LOCATION_HASH NOT NULL;

-- remove duplicates
DELETE FROM csr.custom_location
  WHERE custom_location_id in (
	SELECT custom_location_id 
	  FROM (
		SELECT ROW_NUMBER() OVER (PARTITION BY location_hash ORDER BY custom_Location_id) rn, 
			cl.custom_Location_id
		  FROM csr.custom_location cl
	  )
	 WHERE rn > 1
);

CREATE UNIQUE INDEX CSR.AK_CUSTOM_LOCATION ON CSR.CUSTOM_LOCATION(APP_SID, LOCATION_TYPE_ID, LOCATION_HASH);

-- clean up prior to sticking in our unqiue constraint
BEGIN
    FOR r IN (
         SELECT location_id, change_to_location_id
           FROM (
              SELECT l.location_id,
                ROW_NUMBER() OVER (PARTITION BY name, location_type_Id, longitude, latitude ORDER BY location_id) rn,
                MIN(location_id) OVER (PARTITION BY name, location_type_Id, longitude, latitude ORDER BY location_id) change_to_location_id
                FROM csr.location l
               WHERE longitude IS NOT NULL AND latitude IS NOT NULL
          )
         WHERE rn > 1
    )
    LOOP
        BEGIN
            UPDATE csr.custom_distance SET origin_id = r.change_to_Location_id WHERE origin_id = r.location_id;
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                DELETE FROM csr.custom_distance WHERE origin_id = r.location_Id;
        END;
        BEGIN
            UPDATE csr.custom_distance SET destination_id = r.change_to_Location_id WHERE destination_id = r.location_id;
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                DELETE FROM csr.custom_distance WHERE destination_id = r.location_Id;
        END;
        BEGIN
            UPDATE csr.distance SET origin_id = r.change_to_Location_id WHERE origin_id = r.location_id;
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                DELETE FROM csr.distance WHERE origin_id = r.location_Id;
        END;
        BEGIN
            UPDATE csr.distance SET destination_id = r.change_to_Location_id WHERE destination_id = r.location_id;
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                DELETE FROM csr.distance WHERE destination_id = r.location_Id;
        END;
        UPDATE csr.custom_location SET location_id = r.change_to_Location_id WHERE location_id = r.location_id;
        -- clean up
        DELETE FROM csr.location WHERE location_id = r.location_id;
    END LOOP;
END;
/

CREATE INDEX CSR.UK_LOCATION ON CSR.LOCATION(LOCATION_TYPE_ID, UPPER(NAME), NVL(LONGITUDE, LOCATION_ID + 1000), NVL(LATITUDE, LOCATION_ID + 1000));


declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'LOGISTICS_TAB_MODE',
		'LOGISTICS_ERROR_LOG'
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



CREATE TABLE POSTCODE.CONTINENT(
    CONTINENT    VARCHAR2(2)      NOT NULL,
    LABEL        VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_CONTINENT PRIMARY KEY (CONTINENT)
);

ALTER TABLE POSTCODE.COUNTRY ADD (
    AREA_IN_SQKM   NUMBER(16, 2),
    CONTINENT      VARCHAR2(2),
    CURRENCY       VARCHAR2(10),
    ISO3           VARCHAR2(3)
);

ALTER TABLE POSTCODE.COUNTRY ADD CONSTRAINT FK_CONTINENT_COUNTRY 
    FOREIGN KEY (CONTINENT)
    REFERENCES POSTCODE.CONTINENT(CONTINENT);


BEGIN
INSERT INTO POSTCODE.CONTINENT (CONTINENT, LABEL) VALUES ('AF', 'Africa');
INSERT INTO POSTCODE.CONTINENT (CONTINENT, LABEL) VALUES ('AS', 'Asia');
INSERT INTO POSTCODE.CONTINENT (CONTINENT, LABEL) VALUES ('EU', 'Europe');
INSERT INTO POSTCODE.CONTINENT (CONTINENT, LABEL) VALUES ('NA', 'North America');
INSERT INTO POSTCODE.CONTINENT (CONTINENT, LABEL) VALUES ('OC', 'Oceania');
INSERT INTO POSTCODE.CONTINENT (CONTINENT, LABEL) VALUES ('SA', 'South America');
INSERT INTO POSTCODE.CONTINENT (CONTINENT, LABEL) VALUES ('AN', 'Antarctica');
END;
/

begin
update postcode.country set iso3 ='ata', area_in_sqkm = 14000000, currency = '', continent='AN' where country='aq';
update postcode.country set iso3 ='bih', area_in_sqkm = 51129, currency = 'BAM', continent='EU' where country='ba';
update postcode.country set iso3 ='bra', area_in_sqkm = 8511965, currency = 'BRL', continent='SA' where country='br';
update postcode.country set iso3 ='cck', area_in_sqkm = 14, currency = 'AUD', continent='AS' where country='cc';
update postcode.country set iso3 ='cxr', area_in_sqkm = 135, currency = 'AUD', continent='AS' where country='cx';
update postcode.country set iso3 ='esh', area_in_sqkm = 266000, currency = 'MAD', continent='AF' where country='eh';
update postcode.country set iso3 ='fra', area_in_sqkm = 547030, currency = 'EUR', continent='EU' where country='fr';
update postcode.country set iso3 ='gmb', area_in_sqkm = 11300, currency = 'GMD', continent='AF' where country='gm';
update postcode.country set iso3 ='hmd', area_in_sqkm = 412, currency = 'AUD', continent='AN' where country='hm';
update postcode.country set iso3 ='ken', area_in_sqkm = 582650, currency = 'KES', continent='AF' where country='ke';
update postcode.country set iso3 ='kaz', area_in_sqkm = 2717300, currency = 'KZT', continent='AS' where country='kz';
update postcode.country set iso3 ='lso', area_in_sqkm = 30355, currency = 'LSL', continent='AF' where country='ls';
update postcode.country set iso3 ='mli', area_in_sqkm = 1240000, currency = 'XOF', continent='AF' where country='ml';
update postcode.country set iso3 ='mus', area_in_sqkm = 2040, currency = 'MUR', continent='AF' where country='mu';
update postcode.country set iso3 ='nic', area_in_sqkm = 129494, currency = 'NIO', continent='NA' where country='ni';
update postcode.country set iso3 ='pyf', area_in_sqkm = 4167, currency = 'XPF', continent='OC' where country='pf';
update postcode.country set iso3 ='rou', area_in_sqkm = 237500, currency = 'RON', continent='EU' where country='ro';
update postcode.country set iso3 ='sgp', area_in_sqkm = 693, currency = 'SGD', continent='AS' where country='sg';
update postcode.country set iso3 ='stp', area_in_sqkm = 1001, currency = 'STD', continent='AF' where country='st';
update postcode.country set iso3 ='ton', area_in_sqkm = 748, currency = 'TOP', continent='OC' where country='to';
update postcode.country set iso3 ='ury', area_in_sqkm = 176220, currency = 'UYU', continent='SA' where country='uy';
update postcode.country set iso3 ='wlf', area_in_sqkm = 274, currency = 'XPF', continent='OC' where country='wf';
update postcode.country set iso3 ='ala', area_in_sqkm = 13517, currency = 'EUR', continent='EU' where country='ax';
update postcode.country set iso3 ='gbr', area_in_sqkm = 244820, currency = 'GBP', continent='EU' where country='gb';
update postcode.country set iso3 ='grl', area_in_sqkm = 2166086, currency = 'DKK', continent='NA' where country='gl';
update postcode.country set iso3 ='grc', area_in_sqkm = 131940, currency = 'EUR', continent='EU' where country='gr';
update postcode.country set iso3 ='guy', area_in_sqkm = 214970, currency = 'GYD', continent='SA' where country='gy';
update postcode.country set iso3 ='hrv', area_in_sqkm = 56542, currency = 'HRK', continent='EU' where country='hr';
update postcode.country set iso3 ='imn', area_in_sqkm = 572, currency = 'GBP', continent='EU' where country='im';
update postcode.country set iso3 ='ita', area_in_sqkm = 301230, currency = 'EUR', continent='EU' where country='it';
update postcode.country set iso3 ='kgz', area_in_sqkm = 198500, currency = 'KGS', continent='AS' where country='kg';
update postcode.country set iso3 ='prk', area_in_sqkm = 120540, currency = 'KPW', continent='AS' where country='kp';
update postcode.country set iso3 ='lux', area_in_sqkm = 2586, currency = 'EUR', continent='EU' where country='lu';
update postcode.country set iso3 ='mne', area_in_sqkm = 14026, currency = 'EUR', continent='EU' where country='me';
update postcode.country set iso3 ='mng', area_in_sqkm = 1565000, currency = 'MNT', continent='AS' where country='mn';
update postcode.country set iso3 ='msr', area_in_sqkm = 102, currency = 'XCD', continent='NA' where country='ms';
update postcode.country set iso3 ='mys', area_in_sqkm = 329750, currency = 'MYR', continent='AS' where country='my';
update postcode.country set iso3 ='nga', area_in_sqkm = 923768, currency = 'NGN', continent='AF' where country='ng';
update postcode.country set iso3 ='nru', area_in_sqkm = 21, currency = 'AUD', continent='OC' where country='nr';
update postcode.country set iso3 ='per', area_in_sqkm = 1285220, currency = 'PEN', continent='SA' where country='pe';
update postcode.country set iso3 ='pol', area_in_sqkm = 312685, currency = 'PLN', continent='EU' where country='pl';
update postcode.country set iso3 ='pse', area_in_sqkm = 5970, currency = 'ILS', continent='AS' where country='ps';
update postcode.country set iso3 ='rwa', area_in_sqkm = 26338, currency = 'RWF', continent='AF' where country='rw';
update postcode.country set iso3 ='sdn', area_in_sqkm = 1861484, currency = 'SDG', continent='AF' where country='sd';
update postcode.country set iso3 ='sjm', area_in_sqkm = 62049, currency = 'NOK', continent='EU' where country='sj';
update postcode.country set iso3 ='slv', area_in_sqkm = 21040, currency = 'USD', continent='NA' where country='sv';
update postcode.country set iso3 ='tha', area_in_sqkm = 514000, currency = 'THB', continent='AS' where country='th';
update postcode.country set iso3 ='tun', area_in_sqkm = 163610, currency = 'TND', continent='AF' where country='tn';
update postcode.country set iso3 ='twn', area_in_sqkm = 35980, currency = 'TWD', continent='AS' where country='tw';
update postcode.country set iso3 ='usa', area_in_sqkm = 9629091, currency = 'USD', continent='NA' where country='us';
update postcode.country set iso3 ='vgb', area_in_sqkm = 153, currency = 'USD', continent='NA' where country='vg';
update postcode.country set iso3 ='zwe', area_in_sqkm = 390580, currency = 'ZWL', continent='AF' where country='zw';
update postcode.country set iso3 ='alb', area_in_sqkm = 28748, currency = 'ALL', continent='EU' where country='al';
update postcode.country set iso3 ='aut', area_in_sqkm = 83858, currency = 'EUR', continent='EU' where country='at';
update postcode.country set iso3 ='bel', area_in_sqkm = 30510, currency = 'EUR', continent='EU' where country='be';
update postcode.country set iso3 ='bol', area_in_sqkm = 1098580, currency = 'BOB', continent='SA' where country='bo';
update postcode.country set iso3 ='blz', area_in_sqkm = 22966, currency = 'BZD', continent='NA' where country='bz';
update postcode.country set iso3 ='civ', area_in_sqkm = 322460, currency = 'XOF', continent='AF' where country='ci';
update postcode.country set iso3 ='cub', area_in_sqkm = 110860, currency = 'CUP', continent='NA' where country='cu';
update postcode.country set iso3 ='dnk', area_in_sqkm = 43094, currency = 'DKK', continent='EU' where country='dk';
update postcode.country set iso3 ='egy', area_in_sqkm = 1001450, currency = 'EGP', continent='AF' where country='eg';
update postcode.country set iso3 ='fin', area_in_sqkm = 337030, currency = 'EUR', continent='EU' where country='fi';
update postcode.country set iso3 ='gab', area_in_sqkm = 267667, currency = 'XAF', continent='AF' where country='ga';
update postcode.country set iso3 ='gin', area_in_sqkm = 245857, currency = 'GNF', continent='AF' where country='gn';
update postcode.country set iso3 ='gnb', area_in_sqkm = 36120, currency = 'XOF', continent='AF' where country='gw';
update postcode.country set iso3 ='isr', area_in_sqkm = 20770, currency = 'ILS', continent='AS' where country='il';
update postcode.country set iso3 ='jam', area_in_sqkm = 10991, currency = 'JMD', continent='NA' where country='jm';
update postcode.country set iso3 ='kna', area_in_sqkm = 261, currency = 'XCD', continent='NA' where country='kn';
update postcode.country set iso3 ='ltu', area_in_sqkm = 65200, currency = 'LTL', continent='EU' where country='lt';
update postcode.country set iso3 ='mdg', area_in_sqkm = 587040, currency = 'MGA', continent='AF' where country='mg';
update postcode.country set iso3 ='mlt', area_in_sqkm = 316, currency = 'EUR', continent='EU' where country='mt';
update postcode.country set iso3 ='nam', area_in_sqkm = 825418, currency = 'NAD', continent='AF' where country='na';
update postcode.country set iso3 ='npl', area_in_sqkm = 140800, currency = 'NPR', continent='AS' where country='np';
update postcode.country set iso3 ='png', area_in_sqkm = 462840, currency = 'PGK', continent='OC' where country='pg';
update postcode.country set iso3 ='reu', area_in_sqkm = 2517, currency = 'EUR', continent='AF' where country='re';
update postcode.country set iso3 ='swe', area_in_sqkm = 449964, currency = 'SEK', continent='EU' where country='se';
update postcode.country set iso3 ='sen', area_in_sqkm = 196190, currency = 'XOF', continent='AF' where country='sn';
update postcode.country set iso3 ='tca', area_in_sqkm = 430, currency = 'USD', continent='NA' where country='tc';
update postcode.country set iso3 ='ukr', area_in_sqkm = 603700, currency = 'UAH', continent='EU' where country='ua';
update postcode.country set iso3 ='vir', area_in_sqkm = 352, currency = 'USD', continent='NA' where country='vi';
update postcode.country set iso3 ='and', area_in_sqkm = 468, currency = 'EUR', continent='EU' where country='ad';
update postcode.country set iso3 ='are', area_in_sqkm = 82880, currency = 'AED', continent='AS' where country='ae';
update postcode.country set iso3 ='afg', area_in_sqkm = 647500, currency = 'AFN', continent='AS' where country='af';
update postcode.country set iso3 ='atg', area_in_sqkm = 443, currency = 'XCD', continent='NA' where country='ag';
update postcode.country set iso3 ='aia', area_in_sqkm = 102, currency = 'XCD', continent='NA' where country='ai';
update postcode.country set iso3 ='arm', area_in_sqkm = 29800, currency = 'AMD', continent='AS' where country='am';
update postcode.country set iso3 ='ant', area_in_sqkm = 960, currency = 'ANG', continent='NA' where country='an';
update postcode.country set iso3 ='ago', area_in_sqkm = 1246700, currency = 'AOA', continent='AF' where country='ao';
update postcode.country set iso3 ='apc', area_in_sqkm = 0, currency = 'USD', continent='AS' where country='ap'; --dummy
update postcode.country set iso3 ='arg', area_in_sqkm = 2766890, currency = 'ARS', continent='SA' where country='ar';
update postcode.country set iso3 ='asm', area_in_sqkm = 199, currency = 'USD', continent='OC' where country='as';
update postcode.country set iso3 ='aus', area_in_sqkm = 7686850, currency = 'AUD', continent='OC' where country='au';
update postcode.country set iso3 ='abw', area_in_sqkm = 193, currency = 'AWG', continent='NA' where country='aw';
update postcode.country set iso3 ='aze', area_in_sqkm = 86600, currency = 'AZN', continent='AS' where country='az';
update postcode.country set iso3 ='brb', area_in_sqkm = 431, currency = 'BBD', continent='NA' where country='bb';
update postcode.country set iso3 ='bgd', area_in_sqkm = 144000, currency = 'BDT', continent='AS' where country='bd';
update postcode.country set iso3 ='bfa', area_in_sqkm = 274200, currency = 'XOF', continent='AF' where country='bf';
update postcode.country set iso3 ='bgr', area_in_sqkm = 110910, currency = 'BGN', continent='EU' where country='bg';
update postcode.country set iso3 ='bhr', area_in_sqkm = 665, currency = 'BHD', continent='AS' where country='bh';
update postcode.country set iso3 ='bdi', area_in_sqkm = 27830, currency = 'BIF', continent='AF' where country='bi';
update postcode.country set iso3 ='ben', area_in_sqkm = 112620, currency = 'XOF', continent='AF' where country='bj';
update postcode.country set iso3 ='bmu', area_in_sqkm = 53, currency = 'BMD', continent='NA' where country='bm';
update postcode.country set iso3 ='brn', area_in_sqkm = 5770, currency = 'BND', continent='AS' where country='bn';
update postcode.country set iso3 ='bhs', area_in_sqkm = 13940, currency = 'BSD', continent='NA' where country='bs';
update postcode.country set iso3 ='btn', area_in_sqkm = 47000, currency = 'BTN', continent='AS' where country='bt';
update postcode.country set iso3 ='bvt', area_in_sqkm = 49, currency = 'NOK', continent='AN' where country='bv';
update postcode.country set iso3 ='bwa', area_in_sqkm = 600370, currency = 'BWP', continent='AF' where country='bw';
update postcode.country set iso3 ='blr', area_in_sqkm = 207600, currency = 'BYR', continent='EU' where country='by';
update postcode.country set iso3 ='can', area_in_sqkm = 9984670, currency = 'CAD', continent='NA' where country='ca';
update postcode.country set iso3 ='cod', area_in_sqkm = 2345410, currency = 'CDF', continent='AF' where country='cd';
update postcode.country set iso3 ='caf', area_in_sqkm = 622984, currency = 'XAF', continent='AF' where country='cf';
update postcode.country set iso3 ='cog', area_in_sqkm = 342000, currency = 'XAF', continent='AF' where country='cg';
update postcode.country set iso3 ='che', area_in_sqkm = 41290, currency = 'CHF', continent='EU' where country='ch';
update postcode.country set iso3 ='cok', area_in_sqkm = 240, currency = 'NZD', continent='OC' where country='ck';
update postcode.country set iso3 ='chl', area_in_sqkm = 756950, currency = 'CLP', continent='SA' where country='cl';
update postcode.country set iso3 ='cmr', area_in_sqkm = 475440, currency = 'XAF', continent='AF' where country='cm';
update postcode.country set iso3 ='chn', area_in_sqkm = 9596960, currency = 'CNY', continent='AS' where country='cn';
update postcode.country set iso3 ='col', area_in_sqkm = 1138910, currency = 'COP', continent='SA' where country='co';
update postcode.country set iso3 ='cri', area_in_sqkm = 51100, currency = 'CRC', continent='NA' where country='cr';
update postcode.country set iso3 ='cpv', area_in_sqkm = 4033, currency = 'CVE', continent='AF' where country='cv';
update postcode.country set iso3 ='cyp', area_in_sqkm = 9250, currency = 'EUR', continent='EU' where country='cy';
update postcode.country set iso3 ='cze', area_in_sqkm = 78866, currency = 'CZK', continent='EU' where country='cz';
update postcode.country set iso3 ='deu', area_in_sqkm = 357021, currency = 'EUR', continent='EU' where country='de';
update postcode.country set iso3 ='dji', area_in_sqkm = 23000, currency = 'DJF', continent='AF' where country='dj';
update postcode.country set iso3 ='dma', area_in_sqkm = 754, currency = 'XCD', continent='NA' where country='dm';
update postcode.country set iso3 ='dom', area_in_sqkm = 48730, currency = 'DOP', continent='NA' where country='do';
update postcode.country set iso3 ='dza', area_in_sqkm = 2381740, currency = 'DZD', continent='AF' where country='dz';
update postcode.country set iso3 ='ecu', area_in_sqkm = 283560, currency = 'USD', continent='SA' where country='ec';
update postcode.country set iso3 ='est', area_in_sqkm = 45226, currency = 'EUR', continent='EU' where country='ee';
update postcode.country set iso3 ='eri', area_in_sqkm = 121320, currency = 'ERN', continent='AF' where country='er';
update postcode.country set iso3 ='esp', area_in_sqkm = 504782, currency = 'EUR', continent='EU' where country='es';
update postcode.country set iso3 ='eth', area_in_sqkm = 1127127, currency = 'ETB', continent='AF' where country='et';
update postcode.country set iso3 ='eur', area_in_sqkm = 0, currency = 'EUR', continent='EU' where country='eu'; --dummy
update postcode.country set iso3 ='fji', area_in_sqkm = 18270, currency = 'FJD', continent='OC' where country='fj';
update postcode.country set iso3 ='flk', area_in_sqkm = 12173, currency = 'FKP', continent='SA' where country='fk';
update postcode.country set iso3 ='fsm', area_in_sqkm = 702, currency = 'USD', continent='OC' where country='fm';
update postcode.country set iso3 ='fro', area_in_sqkm = 1399, currency = 'DKK', continent='EU' where country='fo';
update postcode.country set iso3 ='grd', area_in_sqkm = 344, currency = 'XCD', continent='NA' where country='gd';
update postcode.country set iso3 ='geo', area_in_sqkm = 69700, currency = 'GEL', continent='AS' where country='ge';
update postcode.country set iso3 ='guf', area_in_sqkm = 91000, currency = 'EUR', continent='SA' where country='gf';
update postcode.country set iso3 ='ggy', area_in_sqkm = 78, currency = 'GBP', continent='EU' where country='gg';
update postcode.country set iso3 ='gha', area_in_sqkm = 239460, currency = 'GHS', continent='AF' where country='gh';
update postcode.country set iso3 ='gib', area_in_sqkm = 7, currency = 'GIP', continent='EU' where country='gi';
update postcode.country set iso3 ='glp', area_in_sqkm = 1780, currency = 'EUR', continent='NA' where country='gp';
update postcode.country set iso3 ='gnq', area_in_sqkm = 28051, currency = 'XAF', continent='AF' where country='gq';
update postcode.country set iso3 ='sgs', area_in_sqkm = 3903, currency = 'GBP', continent='AN' where country='gs';
update postcode.country set iso3 ='gtm', area_in_sqkm = 108890, currency = 'GTQ', continent='NA' where country='gt';
update postcode.country set iso3 ='gum', area_in_sqkm = 549, currency = 'USD', continent='OC' where country='gu';
update postcode.country set iso3 ='hkg', area_in_sqkm = 1092, currency = 'HKD', continent='AS' where country='hk';
update postcode.country set iso3 ='hnd', area_in_sqkm = 112090, currency = 'HNL', continent='NA' where country='hn';
update postcode.country set iso3 ='hti', area_in_sqkm = 27750, currency = 'HTG', continent='NA' where country='ht';
update postcode.country set iso3 ='hun', area_in_sqkm = 93030, currency = 'HUF', continent='EU' where country='hu';
update postcode.country set iso3 ='idn', area_in_sqkm = 1919440, currency = 'IDR', continent='AS' where country='id';
update postcode.country set iso3 ='irl', area_in_sqkm = 70280, currency = 'EUR', continent='EU' where country='ie';
update postcode.country set iso3 ='ind', area_in_sqkm = 3287590, currency = 'INR', continent='AS' where country='in';
update postcode.country set iso3 ='iot', area_in_sqkm = 60, currency = 'USD', continent='AS' where country='io';
update postcode.country set iso3 ='irq', area_in_sqkm = 437072, currency = 'IQD', continent='AS' where country='iq';
update postcode.country set iso3 ='irn', area_in_sqkm = 1648000, currency = 'IRR', continent='AS' where country='ir';
update postcode.country set iso3 ='isl', area_in_sqkm = 103000, currency = 'ISK', continent='EU' where country='is';
update postcode.country set iso3 ='jey', area_in_sqkm = 116, currency = 'GBP', continent='EU' where country='je';
update postcode.country set iso3 ='jor', area_in_sqkm = 92300, currency = 'JOD', continent='AS' where country='jo';
update postcode.country set iso3 ='jpn', area_in_sqkm = 377835, currency = 'JPY', continent='AS' where country='jp';
update postcode.country set iso3 ='khm', area_in_sqkm = 181040, currency = 'KHR', continent='AS' where country='kh';
update postcode.country set iso3 ='kir', area_in_sqkm = 811, currency = 'AUD', continent='OC' where country='ki';
update postcode.country set iso3 ='com', area_in_sqkm = 2170, currency = 'KMF', continent='AF' where country='km';
update postcode.country set iso3 ='kor', area_in_sqkm = 98480, currency = 'KRW', continent='AS' where country='kr';
update postcode.country set iso3 ='kwt', area_in_sqkm = 17820, currency = 'KWD', continent='AS' where country='kw';
update postcode.country set iso3 ='cym', area_in_sqkm = 262, currency = 'KYD', continent='NA' where country='ky';
update postcode.country set iso3 ='lao', area_in_sqkm = 236800, currency = 'LAK', continent='AS' where country='la';
update postcode.country set iso3 ='lbn', area_in_sqkm = 10400, currency = 'LBP', continent='AS' where country='lb';
update postcode.country set iso3 ='lca', area_in_sqkm = 616, currency = 'XCD', continent='NA' where country='lc';
update postcode.country set iso3 ='lie', area_in_sqkm = 160, currency = 'CHF', continent='EU' where country='li';
update postcode.country set iso3 ='lka', area_in_sqkm = 65610, currency = 'LKR', continent='AS' where country='lk';
update postcode.country set iso3 ='lbr', area_in_sqkm = 111370, currency = 'LRD', continent='AF' where country='lr';
update postcode.country set iso3 ='lva', area_in_sqkm = 64589, currency = 'LVL', continent='EU' where country='lv';
update postcode.country set iso3 ='lby', area_in_sqkm = 1759540, currency = 'LYD', continent='AF' where country='ly';
update postcode.country set iso3 ='mar', area_in_sqkm = 446550, currency = 'MAD', continent='AF' where country='ma';
update postcode.country set iso3 ='mco', area_in_sqkm = 2, currency = 'EUR', continent='EU' where country='mc';
update postcode.country set iso3 ='mda', area_in_sqkm = 33843, currency = 'MDL', continent='EU' where country='md';
update postcode.country set iso3 ='mhl', area_in_sqkm = 181, currency = 'USD', continent='OC' where country='mh';
update postcode.country set iso3 ='mkd', area_in_sqkm = 25333, currency = 'MKD', continent='EU' where country='mk';
update postcode.country set iso3 ='mmr', area_in_sqkm = 678500, currency = 'MMK', continent='AS' where country='mm';
update postcode.country set iso3 ='mac', area_in_sqkm = 254, currency = 'MOP', continent='AS' where country='mo';
update postcode.country set iso3 ='mnp', area_in_sqkm = 477, currency = 'USD', continent='OC' where country='mp';
update postcode.country set iso3 ='mtq', area_in_sqkm = 1100, currency = 'EUR', continent='NA' where country='mq';
update postcode.country set iso3 ='mrt', area_in_sqkm = 1030700, currency = 'MRO', continent='AF' where country='mr';
update postcode.country set iso3 ='mdv', area_in_sqkm = 300, currency = 'MVR', continent='AS' where country='mv';
update postcode.country set iso3 ='mwi', area_in_sqkm = 118480, currency = 'MWK', continent='AF' where country='mw';
update postcode.country set iso3 ='mex', area_in_sqkm = 1972550, currency = 'MXN', continent='NA' where country='mx';
update postcode.country set iso3 ='moz', area_in_sqkm = 801590, currency = 'MZN', continent='AF' where country='mz';
update postcode.country set iso3 ='ncl', area_in_sqkm = 19060, currency = 'XPF', continent='OC' where country='nc';
update postcode.country set iso3 ='ner', area_in_sqkm = 1267000, currency = 'XOF', continent='AF' where country='ne';
update postcode.country set iso3 ='nfk', area_in_sqkm = 35, currency = 'AUD', continent='OC' where country='nf';
update postcode.country set iso3 ='nld', area_in_sqkm = 41526, currency = 'EUR', continent='EU' where country='nl';
update postcode.country set iso3 ='nor', area_in_sqkm = 324220, currency = 'NOK', continent='EU' where country='no';
update postcode.country set iso3 ='niu', area_in_sqkm = 260, currency = 'NZD', continent='OC' where country='nu';
update postcode.country set iso3 ='nzl', area_in_sqkm = 268680, currency = 'NZD', continent='OC' where country='nz';
update postcode.country set iso3 ='omn', area_in_sqkm = 212460, currency = 'OMR', continent='AS' where country='om';
update postcode.country set iso3 ='pan', area_in_sqkm = 78200, currency = 'PAB', continent='NA' where country='pa';
update postcode.country set iso3 ='phl', area_in_sqkm = 300000, currency = 'PHP', continent='AS' where country='ph';
update postcode.country set iso3 ='pak', area_in_sqkm = 803940, currency = 'PKR', continent='AS' where country='pk';
update postcode.country set iso3 ='spm', area_in_sqkm = 242, currency = 'EUR', continent='NA' where country='pm';
update postcode.country set iso3 ='pcn', area_in_sqkm = 47, currency = 'NZD', continent='OC' where country='pn';
update postcode.country set iso3 ='pri', area_in_sqkm = 9104, currency = 'USD', continent='NA' where country='pr';
update postcode.country set iso3 ='prt', area_in_sqkm = 92391, currency = 'EUR', continent='EU' where country='pt';
update postcode.country set iso3 ='plw', area_in_sqkm = 458, currency = 'USD', continent='OC' where country='pw';
update postcode.country set iso3 ='pry', area_in_sqkm = 406750, currency = 'PYG', continent='SA' where country='py';
update postcode.country set iso3 ='qat', area_in_sqkm = 11437, currency = 'QAR', continent='AS' where country='qa';
update postcode.country set iso3 ='srb', area_in_sqkm = 88361, currency = 'RSD', continent='EU' where country='rs';
update postcode.country set iso3 ='rus', area_in_sqkm = 17100000, currency = 'RUB', continent='EU' where country='ru';
update postcode.country set iso3 ='sau', area_in_sqkm = 1960582, currency = 'SAR', continent='AS' where country='sa';
update postcode.country set iso3 ='slb', area_in_sqkm = 28450, currency = 'SBD', continent='OC' where country='sb';
update postcode.country set iso3 ='syc', area_in_sqkm = 455, currency = 'SCR', continent='AF' where country='sc';
update postcode.country set iso3 ='shn', area_in_sqkm = 410, currency = 'SHP', continent='AF' where country='sh';
update postcode.country set iso3 ='svn', area_in_sqkm = 20273, currency = 'EUR', continent='EU' where country='si';
update postcode.country set iso3 ='svk', area_in_sqkm = 48845, currency = 'EUR', continent='EU' where country='sk';
update postcode.country set iso3 ='sle', area_in_sqkm = 71740, currency = 'SLL', continent='AF' where country='sl';
update postcode.country set iso3 ='smr', area_in_sqkm = 61, currency = 'EUR', continent='EU' where country='sm';
update postcode.country set iso3 ='som', area_in_sqkm = 637657, currency = 'SOS', continent='AF' where country='so';
update postcode.country set iso3 ='sur', area_in_sqkm = 163270, currency = 'SRD', continent='SA' where country='sr';
update postcode.country set iso3 ='syr', area_in_sqkm = 185180, currency = 'SYP', continent='AS' where country='sy';
update postcode.country set iso3 ='swz', area_in_sqkm = 17363, currency = 'SZL', continent='AF' where country='sz';
update postcode.country set iso3 ='tcd', area_in_sqkm = 1284000, currency = 'XAF', continent='AF' where country='td';
update postcode.country set iso3 ='atf', area_in_sqkm = 7829, currency = 'EUR', continent='AN' where country='tf';
update postcode.country set iso3 ='tgo', area_in_sqkm = 56785, currency = 'XOF', continent='AF' where country='tg';
update postcode.country set iso3 ='tjk', area_in_sqkm = 143100, currency = 'TJS', continent='AS' where country='tj';
update postcode.country set iso3 ='tkl', area_in_sqkm = 10, currency = 'NZD', continent='OC' where country='tk';
update postcode.country set iso3 ='tls', area_in_sqkm = 15007, currency = 'USD', continent='OC' where country='tl';
update postcode.country set iso3 ='tkm', area_in_sqkm = 488100, currency = 'TMT', continent='AS' where country='tm';
update postcode.country set iso3 ='tur', area_in_sqkm = 780580, currency = 'TRY', continent='AS' where country='tr';
update postcode.country set iso3 ='tto', area_in_sqkm = 5128, currency = 'TTD', continent='NA' where country='tt';
update postcode.country set iso3 ='tuv', area_in_sqkm = 26, currency = 'AUD', continent='OC' where country='tv';
update postcode.country set iso3 ='tza', area_in_sqkm = 945087, currency = 'TZS', continent='AF' where country='tz';
update postcode.country set iso3 ='uga', area_in_sqkm = 236040, currency = 'UGX', continent='AF' where country='ug';
update postcode.country set iso3 ='umi', area_in_sqkm = 0, currency = 'USD', continent='OC' where country='um';
update postcode.country set iso3 ='uzb', area_in_sqkm = 447400, currency = 'UZS', continent='AS' where country='uz';
update postcode.country set iso3 ='vat', area_in_sqkm = .44, currency = 'EUR', continent='EU' where country='va';
update postcode.country set iso3 ='vct', area_in_sqkm = 389, currency = 'XCD', continent='NA' where country='vc';
update postcode.country set iso3 ='ven', area_in_sqkm = 912050, currency = 'VEF', continent='SA' where country='ve';
update postcode.country set iso3 ='vnm', area_in_sqkm = 329560, currency = 'VND', continent='AS' where country='vn';
update postcode.country set iso3 ='vut', area_in_sqkm = 12200, currency = 'VUV', continent='OC' where country='vu';
update postcode.country set iso3 ='wsm', area_in_sqkm = 2944, currency = 'WST', continent='OC' where country='ws';
update postcode.country set iso3 ='yem', area_in_sqkm = 527970, currency = 'YER', continent='AS' where country='ye';
update postcode.country set iso3 ='myt', area_in_sqkm = 374, currency = 'EUR', continent='AF' where country='yt';
update postcode.country set iso3 ='zaf', area_in_sqkm = 1219912, currency = 'ZAR', continent='AF' where country='za';
update postcode.country set iso3 ='zmb', area_in_sqkm = 752614, currency = 'ZMK', continent='AF' where country='zm';
END;
/




CREATE TABLE POSTCODE.COUNTRY_ALIAS(
    COUNTRY    VARCHAR2(2)      NOT NULL,
    ALIAS      VARCHAR2(200)    NOT NULL,
    LANG       VARCHAR2(10)     DEFAULT 'en' NOT NULL,
    CONSTRAINT PK_COUNTRY_ALIAS PRIMARY KEY (COUNTRY, ALIAS, LANG)
);


ALTER TABLE POSTCODE.COUNTRY_ALIAS ADD CONSTRAINT FK_CNTRY_CNTRY_ALIAS 
    FOREIGN KEY (COUNTRY)
    REFERENCES POSTCODE.COUNTRY(COUNTRY);

-- english aliases
BEGIN
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('gb', 'UK', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('gb', 'Great Britain', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('kr', 'Korea', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('kr', 'South Korea', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('kp', 'North Korea', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('ru', 'Russia', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('us', 'United States of America', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('us', 'USA', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('us', 'US', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('cd', 'Congo', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('cd', 'DRC', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('ly', 'Libya', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('ir', 'Iran', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('tz', 'Tanzania', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('pg', 'PNG', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('ci', 'Ivory Coast', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('sa', 'Saudi', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('sy', 'Syria', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('ae', 'UAE', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('sj', 'Svalbard', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('ba', 'Bosnia', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('md', 'Moldova', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('fk', 'Falklands', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('fk', 'Falkland Islands', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('gs', 'South Georgia', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('va', 'Vatican City', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('va', 'Vatican', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('vg', 'BVI', 'en');
INSERT INTO POSTCODE.COUNTRY_ALIAS (COUNTRY, ALIAS, LANG) VALUES ('vg', 'British Virgin Islands', 'en');
END;
/

-- french, spanish, portuguese, dutch and german names we might encounter
BEGIN
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nu','Isla Niue','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nz','Nueva Zelanda','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('om','Om'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pa','Panam'||UNISTR('\00E1')||'','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pe','Per'||UNISTR('\00FA')||'','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pf','Polinesia Francesa','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pg','Pap'||UNISTR('\00FA')||'a-Nueva Guinea','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ph','Filipinas','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pk','Pakist'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pl','Polonia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pm','San Pedro y Miquel'||UNISTR('\00F3')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pn','Pitcairn','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pr','Puerto Rico','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ps','Territorios Palestinos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pt','Portugal','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pw','Palau','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('py','Paraguay','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('qa','Qatar','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('re','Reuni'||UNISTR('\00F3')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ro','Ruman'||UNISTR('\00ED')||'a','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rs','Serbia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ru','Rusia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rw','Ruanda','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sa','Arabia Saud'||UNISTR('\00ED')||'','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sb','Islas Salom'||UNISTR('\00F3')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sc','Seychelles','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sd','Sud'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('se','Suecia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sg','Singapur','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sh','Santa Elena','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('si','Eslovenia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sj','Svalbard y Jan Mayen','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sk','Eslovaquia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sl','Sierra Leona','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sm','San Marino','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sn','Senegal','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('so','Somalia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sr','Surinam','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('st','Santo Tom'||UNISTR('\00E9')||' y Pr'||UNISTR('\00ED')||'ncipe','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sv','El Salvador','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sy','Siria','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sz','Suazilandia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tc','Islas Turcas y Caicos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('td','Chad','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tf','Territorios Australes Franceses','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tg','Togo','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('th','Tailandia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tj','Tayikist'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tk','Tokelau','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tl','Timor-Leste','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tm','Turkmenist'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tn','T'||UNISTR('\00FA')||'nez','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('to','Tonga','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tr','Turqu'||UNISTR('\00ED')||'a','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tt','Trinidad y Tobago','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tv','Tuvalu','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tw','Taiw'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tz','Tanzania','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ua','Ucrania','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ug','Uganda','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('um','Islas menores alejadas de los Estados Unidos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('us','Estados Unidos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uy','Uruguay','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uz','Uzbekist'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('va','Ciudad del Vaticano','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vc','San Vicente y las Granadinas','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ve','Venezuela','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vg','Islas V'||UNISTR('\00ED')||'rgenes Brit'||UNISTR('\00E1')||'nicas','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vi','Islas V'||UNISTR('\00ED')||'rgenes de los Estados Unidos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vn','Vietnam','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vu','Vanuatu','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('wf','Wallis y Futuna','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ws','Samoa','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ye','Yemen','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('yt','Mayotte','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('za','Sud'||UNISTR('\00E1')||'frica','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zm','Zambia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zw','Zimbabue','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ad','Andorra','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ae','Emirados '||UNISTR('\00C1')||'rabes Unidos','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('af','Afeganist'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ag','Ant'||UNISTR('\00ED')||'gua e Barbuda','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ai','Anguilla','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('al','Alb'||UNISTR('\00E2')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('am','Arm'||UNISTR('\00EA')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('an','Antilhas Holandesas','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ao','Angola','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aq','Ant'||UNISTR('\00E1')||'rtida','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ar','Argentina','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('as','Samoa Americana','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('at',''||UNISTR('\00C1')||'ustria','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('au','Austr'||UNISTR('\00E1')||'lia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aw','Aruba','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ax','Ilhas Aland','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('az','Azerbaij'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ba','B'||UNISTR('\00F3')||'snia-Herzegovina','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bb','Barbados','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bd','Bangladesh','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('be','B'||UNISTR('\00E9')||'lgica','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bf','Burquina Faso','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bg','Bulg'||UNISTR('\00E1')||'ria','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bh','Bahrein','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bi','Burundi','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bj','Benin','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bm','Bermuda','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bn','Brunei','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bo','Bol'||UNISTR('\00ED')||'via','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('br','Brasil','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bs','Bahamas','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bt','But'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bv','Ilha Bouvet','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bw','Botsuana','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('by','Belarus','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bz','Belize','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ca','Canad'||UNISTR('\00E1')||'','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cc','Ilhas Coco','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cd','Congo-Kinshasa','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cf','Rep'||UNISTR('\00FA')||'blica Centro-Africana','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cg','Congo','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ch','Su'||UNISTR('\00ED')||''||UNISTR('\00E7')||'a','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ci','C'||UNISTR('\00F4')||'te d''Ivoire','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ck','Ilhas Cook','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cl','Chile','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cm','Camar'||UNISTR('\00F5')||'es','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cn','China','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('co','Col'||UNISTR('\00F4')||'mbia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cr','Costa Rica','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cu','Cuba','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cv','Cabo Verde','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cx','Ilhas Natal','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cy','Chipre','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cz','Rep'||UNISTR('\00FA')||'blica Tcheca','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('de','Alemanha','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dj','Djibuti','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dk','Dinamarca','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dm','Dominica','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('do','Rep'||UNISTR('\00FA')||'blica Dominicana','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dz','Arg'||UNISTR('\00E9')||'lia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ec','Equador','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ee','Est'||UNISTR('\00F4')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eg','Egito','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eh','Saara Ocidental','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('er','Eritreia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('es','Espanha','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('et','Eti'||UNISTR('\00F3')||'pia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fi','Finl'||UNISTR('\00E2')||'ndia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fj','Fiji','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fk','Ilhas Malvinas','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fm','Micron'||UNISTR('\00E9')||'sia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fo','Ilhas Faro'||UNISTR('\00E9')||'','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fr','Fran'||UNISTR('\00E7')||'a','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ga','Gab'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gb','Reino Unido','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gd','Granada','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ge','Ge'||UNISTR('\00F3')||'rgia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gf','Guiana Francesa','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gg','Guernsey','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gh','Gana','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gi','Gibraltar','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gl','Gro'||UNISTR('\00EA')||'nlandia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gm','G'||UNISTR('\00E2')||'mbia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gn','Guin'||UNISTR('\00E9')||'','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gp','Guadalupe','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gq','Guin'||UNISTR('\00E9')||' Equatorial','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gr','Gr'||UNISTR('\00E9')||'cia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gs','Ge'||UNISTR('\00F3')||'rgia do Sul e Ilhas Sandwich do Sul','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gt','Guatemala','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gu','Guam','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gw','Guin'||UNISTR('\00E9')||' Bissau','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gy','Guiana','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hk','Hong Kong','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hm','Ilha Heard e Ilhas McDonald','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hn','Honduras','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hr','Cro'||UNISTR('\00E1')||'cia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ht','Haiti','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hu','Hungria','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('id','Indon'||UNISTR('\00E9')||'sia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ie','Irlanda','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('il','Israel','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('im','Ilha de Man','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('in',''||UNISTR('\00CD')||'ndia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('io','Territ'||UNISTR('\00F3')||'rio Brit'||UNISTR('\00E2')||'nico do Oceano '||UNISTR('\00CD')||'ndico','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('iq','Iraque','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ir','Ir'||UNISTR('\00E3')||'','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('is','Isl'||UNISTR('\00E2')||'ndia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('it','It'||UNISTR('\00E1')||'lia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('je','Jersey','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jm','Jamaica','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jo','Jord'||UNISTR('\00E2')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jp','Jap'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ke','Qu'||UNISTR('\00EA')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kg','Quirguist'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kh','Camboja','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ki','Quiribati','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('km','Comores','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kn','S'||UNISTR('\00E3')||'o Crist'||UNISTR('\00F3')||'v'||UNISTR('\00E3')||'o e N'||UNISTR('\00E9')||'vis','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kp','Coreia do Norte','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kr','Coreia do Sul','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kw','Kuwait','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ky','Ilhas Caiman','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kz','Cazaquist'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('la','Laos','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lb','L'||UNISTR('\00ED')||'bano','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lc','Santa L'||UNISTR('\00FA')||'cia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('li','Liechtenstein','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lk','Sri Lanka','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lr','Lib'||UNISTR('\00E9')||'ria','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ls','Lesoto','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lt','Litu'||UNISTR('\00E2')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lu','Luxemburgo','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lv','Let'||UNISTR('\00F4')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ly','L'||UNISTR('\00ED')||'bia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ma','Marrocos','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mc','M'||UNISTR('\00F4')||'naco','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('md','Mold'||UNISTR('\00E1')||'via','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('me','Montenegro','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mg','Madagascar','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mh','Ilhas Marshall','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mk','Maced'||UNISTR('\00F4')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ml','Mali','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mm','Mianmar [Birm'||UNISTR('\00E2')||'nia]','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mn','Mong'||UNISTR('\00F3')||'lia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mo','Macau','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mp','Ilhas Marianas do Norte','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mq','Martinica','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mr','Maurit'||UNISTR('\00E2')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ms','Montserrat','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mt','Malta','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mu','Maur'||UNISTR('\00ED')||'cio','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mv','Maldivas','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mw','Malau'||UNISTR('\00ED')||'','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mx','M'||UNISTR('\00E9')||'xico','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('my','Mal'||UNISTR('\00E1')||'sia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mz','Mo'||UNISTR('\00E7')||'ambique','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('na','Nam'||UNISTR('\00ED')||'bia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nc','Nova Caled'||UNISTR('\00F4')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ne','N'||UNISTR('\00ED')||'ger','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nf','Ilha Norfolk','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ng','Nig'||UNISTR('\00E9')||'ria','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ni','Nicar'||UNISTR('\00E1')||'gua','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nl','Holanda','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('no','Noruega','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('np','Nepal','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nr','Nauru','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nu','Niue','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nz','Nova Zel'||UNISTR('\00E2')||'ndia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('om','Om'||UNISTR('\00E3')||'','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pa','Panam'||UNISTR('\00E1')||'','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pe','Peru','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pf','Polin'||UNISTR('\00E9')||'sia Francesa','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pg','Papua Nova Guin'||UNISTR('\00E9')||'','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ph','Filipinas','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pk','Paquist'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pl','Pol'||UNISTR('\00F4')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pm','Saint Pierre e Miquelon','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pn','Pitcairn','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pr','Porto Rico','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ps','Territ'||UNISTR('\00F3')||'rios palestinos','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pt','Portugal','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pw','Palau','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('py','Paraguai','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('qa','Catar','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('re','Reuni'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ro','Rom'||UNISTR('\00EA')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rs','S'||UNISTR('\00E9')||'rvia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ru','R'||UNISTR('\00FA')||'ssia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rw','Ruanda','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sa','Ar'||UNISTR('\00E1')||'bia Saudita','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sb','Ilhas Salom'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sc','Seicheles','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sd','Sud'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('se','Su'||UNISTR('\00E9')||'cia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sg','Cingapura','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sh','Santa Helena','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('si','Eslov'||UNISTR('\00EA')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sj','Svalbard e Jan Mayen','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sk','Eslov'||UNISTR('\00E1')||'quia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sl','Serra Leoa','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sm','San Marino','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sn','Senegal','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('so','Som'||UNISTR('\00E1')||'lia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sr','Suriname','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('st','S'||UNISTR('\00E3')||'o Tom'||UNISTR('\00E9')||' e Pr'||UNISTR('\00ED')||'ncipe','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sv','El Salvador','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sy','S'||UNISTR('\00ED')||'ria','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sz','Suazil'||UNISTR('\00E2')||'ndia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tc','Ilhas Turks e Caicos','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('td','Chade','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tf','Terras Austrais Francesas','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tg','Togo','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('th','Tail'||UNISTR('\00E2')||'ndia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tj','Tadjiquist'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tk','Tokelau','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tl','Timor-Leste','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tm','Turcomenist'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tn','Tun'||UNISTR('\00ED')||'sia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('to','Tonga','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tr','Turquia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tt','Trinidad e Tobago','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tv','Tuvalu','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tw','Taiwan','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tz','Tanz'||UNISTR('\00E2')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ua','Ucr'||UNISTR('\00E2')||'nia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ug','Uganda','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('um','Ilhas Menores Distantes dos Estados Unidos','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('us','Estados Unidos','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uy','Uruguai','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uz','Uzbequist'||UNISTR('\00E3')||'o','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('va','Vaticano','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vc','S'||UNISTR('\00E3')||'o Vicente e Granadinas','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ve','Venezuela','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vg','Ilhas Virgens Brit'||UNISTR('\00E2')||'nicas','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vi','Ilhas Virgens dos EUA','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vn','Vietn'||UNISTR('\00E3')||'','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vu','Vanuatu','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('wf','Wallis e Futuna','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ws','Samoa','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ye','I'||UNISTR('\00EA')||'men','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('yt','Mayotte','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('za',''||UNISTR('\00C1')||'frica do Sul','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zm','Z'||UNISTR('\00E2')||'mbia','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zw','Zimb'||UNISTR('\00E1')||'bue','pt');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ad','Andorra','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ae','Verenigde Arabische Emiraten','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('af','Afghanistan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ag','Antigua en Barbuda','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ai','Anguilla','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('al','Albani'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('am','Armeni'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('an','Nederlandse Antillen','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ao','Angola','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aq','Antarctica','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ar','Argentini'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('as','Amerikaans Samoa','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('at','Oostenrijk','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('au','Australi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aw','Aruba','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ax',''||UNISTR('\00C5')||'land','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('az','Azerbeidzjan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ba','Bosni'||UNISTR('\00EB')||' en Herzegovina','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bb','Barbados','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bd','Bangladesh','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('be','Belgi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bf','Burkina Faso','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bg','Bulgarije','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bh','Bahrein','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bi','Burundi','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bj','Benin','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bm','Bermuda','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bn','Brunei','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bo','Bolivia','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('br','Brazili'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bs','Bahamas','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bt','Bhutan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bv','Bouveteiland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bw','Botswana','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('by','Wit-Rusland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bz','Belize','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ca','Canada','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cc','Cocoseilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cd','Congo-Kinshasa','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cf','Centraal-Afrikaanse Republiek','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cg','Congo','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ch','Zwitserland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ci','Ivoorkust','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ck','Cookeilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cl','Chili','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cm','Kameroen','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cn','China','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('co','Colombia','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cr','Costa Rica','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cu','Cuba','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cv','Kaapverdi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cx','Christmaseiland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cy','Cyprus','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cz','Tsjechi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('de','Duitsland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dj','Djibouti','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dk','Denemarken','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dm','Dominica','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('do','Dominicaanse Republiek','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dz','Algerije','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ec','Ecuador','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ee','Estland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eg','Egypte','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eh','West-Sahara','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('er','Eritrea','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('es','Spanje','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('et','Ethiopi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fi','Finland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fj','Fiji','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fk','Falklandeilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fm','Micronesia','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fo','Faer'||UNISTR('\00F6')||'er','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fr','Frankrijk','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ga','Gabon','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gb','Verenigd Koninkrijk','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gd','Grenada','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ge','Georgi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gf','Frans-Guyana','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gg','Guernsey','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gh','Ghana','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gi','Gibraltar','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gl','Groenland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gm','Gambia','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gn','Guinee','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gp','Guadeloupe','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gq','Equatoriaal-Guinea','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gr','Griekenland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gs','Zuid-Georgi'||UNISTR('\00EB')||' en de Zuid-Sandwich-eilande','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gt','Guatemala','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gu','Guam','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gw','Guinee-Bissau','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gy','Guyana','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hk','Hongkong','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hm','Heard- en McDonaldeilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hn','Honduras','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hr','Kroati'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ht','Ha'||UNISTR('\00EF')||'ti','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hu','Hongarije','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('id','Indonesi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ie','Ierland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('il','Isra'||UNISTR('\00EB')||'l','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('im','Isle of Man','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('in','India','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('io','Britse Gebieden in de Indische Oceaan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('iq','Irak','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ir','Iran','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('is','IJsland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('it','Itali'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('je','Jersey','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jm','Jamaica','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jo','Jordani'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jp','Japan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ke','Kenia','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kg','Kirgizi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kh','Cambodja','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ki','Kiribati','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('km','Comoren','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kn','Saint Kitts en Nevis','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kp','Noord-Korea','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kr','Zuid-Korea','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kw','Koeweit','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ky','Caymaneilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kz','Kazachstan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('la','Laos','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lb','Libanon','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lc','Saint Lucia','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('li','Liechtenstein','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lk','Sri Lanka','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lr','Liberia','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ls','Lesotho','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lt','Litouwen','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lu','Luxemburg','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lv','Letland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ly','Libi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ma','Marokko','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mc','Monaco','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('md','Moldavi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('me','Montenegro','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mg','Madagaskar','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mh','Marshalleilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mk','Macedoni'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ml','Mali','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mm','Birma','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mn','Mongoli'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mo','Macao','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mp','Noordelijke Marianeneilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mq','Martinique','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mr','Mauritani'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ms','Montserrat','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mt','Malta','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mu','Mauritius','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mv','Maldiven','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mw','Malawi','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mx','Mexico','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('my','Maleisi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mz','Mozambique','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('na','Namibi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nc','Nieuw-Caledoni'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ne','Niger','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nf','Norfolkeiland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ng','Nigeria','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ni','Nicaragua','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nl','Nederland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('no','Noorwegen','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('np','Nepal','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nr','Nauru','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nu','Niue','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nz','Nieuw-Zeeland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('om','Oman','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pa','Panama','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pe','Peru','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pf','Frans-Polynesi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pg','Papoea-Nieuw-Guinea','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ph','Filipijnen','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pk','Pakistan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pl','Polen','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pm','Saint Pierre en Miquelon','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pn','Pitcairn','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pr','Puerto Rico','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ps','Palestijns Gebied','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pt','Portugal','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pw','Palau','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('py','Paraguay','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('qa','Qatar','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('re','R'||UNISTR('\00E9')||'union','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ro','Roemeni'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rs','Servi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ru','Rusland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rw','Rwanda','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sa','Saoedi-Arabi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sb','Salomonseilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sc','Seychellen','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sd','Soedan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('se','Zweden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sg','Singapore','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sh','Sint-Helena','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('si','Sloveni'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sj','Svalbard en Jan Mayen','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sk','Slowakije','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sl','Sierra Leone','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sm','San Marino','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sn','Senegal','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('so','Somali'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sr','Suriname','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('st','Sao Tom'||UNISTR('\00E9')||' en Principe','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sv','El Salvador','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sy','Syri'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sz','Swaziland','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tc','Turks- en Caicoseilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('td','Tsjaad','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tf','Franse Gebieden in de zuidelijke Indische Oceaan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tg','Togo','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('th','Thailand','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tj','Tadzjikistan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tk','Tokelau','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tl','Oost-Timor','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tm','Turkmenistan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tn','Tunesi'||UNISTR('\00EB')||'','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('to','Tonga','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tr','Turkije','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tt','Trinidad en Tobago','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tv','Tuvalu','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tw','Taiwan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tz','Tanzania','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ua','Oekra'||UNISTR('\00EF')||'ne','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ug','Oeganda','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('um','Amerikaanse kleinere afgelegen eilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('us','Verenigde Staten','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uy','Uruguay','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uz','Oezbekistan','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('va','Vaticaanstad','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vc','Saint Vincent en de Grenadines','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ve','Venezuela','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vg','Britse Maagdeneilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vi','Amerikaanse Maagdeneilanden','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vn','Vietnam','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vu','Vanuatu','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('wf','Wallis en Futuna','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ws','Samoa','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ye','Jemen','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('yt','Mayotte','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('za','Zuid-Afrika','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zm','Zambia','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zw','Zimbabwe','nl');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ad','Andorre','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ae',''||UNISTR('\00C9')||'mirats arabes unis','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('af','Afghanistan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ag','Antigua-et-Barbuda','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ai','Anguilla','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('al','Albanie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('am','Arm'||UNISTR('\00E9')||'nie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('an','Antilles n'||UNISTR('\00E9')||'erlandaises','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ao','Angola','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aq','Antarctique','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ar','Argentine','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('as','Samoa am'||UNISTR('\00E9')||'ricaines','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('at','Autriche','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('au','Australie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aw','Aruba','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ax',''||UNISTR('\00C5')||'land','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('az','Azerba'||UNISTR('\00EF')||'djan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ba','Bosnie-Herz'||UNISTR('\00E9')||'govine','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bb','Barbade','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bd','Bangladesh','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('be','Belgique','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bf','Burkina Faso','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bg','Bulgarie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bh','Bahre'||UNISTR('\00EF')||'n','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bi','Burundi','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bj','B'||UNISTR('\00E9')||'nin','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bm','Bermudes','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bn','Brun'||UNISTR('\00E9')||'i Darussalam','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bo','Bolivie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('br','Br'||UNISTR('\00E9')||'sil','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bs','Bahamas','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bt','Bhoutan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bv',''||UNISTR('\00CE')||'le Bouvet','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bw','Botswana','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('by','B'||UNISTR('\00E9')||'larus','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bz','Belize','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ca','Canada','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cc',''||UNISTR('\00CE')||'les Cocos - Keeling','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cd','Congo-Kinshasa','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cf','R'||UNISTR('\00E9')||'publique centrafricaine','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cg','Congo-Brazzaville','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ch','Suisse','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ci','C'||UNISTR('\00F4')||'te d''Ivoire','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ck',''||UNISTR('\00CE')||'les Cook','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cl','Chili','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cm','Cameroun','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cn','Chine','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('co','Colombie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cr','Costa Rica','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cu','Cuba','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cv','Cap-Vert','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cx',''||UNISTR('\00CE')||'le Christmas','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cy','Chypre','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cz','R'||UNISTR('\00E9')||'publique tch'||UNISTR('\00E8')||'que','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('de','Allemagne','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dj','Djibouti','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dk','Danemark','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dm','Dominique','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('do','R'||UNISTR('\00E9')||'publique dominicaine','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dz','Alg'||UNISTR('\00E9')||'rie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ec',''||UNISTR('\00C9')||'quateur','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ee','Estonie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eg',''||UNISTR('\00C9')||'gypte','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eh','Sahara occidental','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('er',''||UNISTR('\00C9')||'rythr'||UNISTR('\00E9')||'e','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('es','Espagne','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('et',''||UNISTR('\00C9')||'thiopie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fi','Finlande','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fj','Fidji','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fk',''||UNISTR('\00CE')||'les Malouines','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fm',''||UNISTR('\00C9')||'tats f'||UNISTR('\00E9')||'d'||UNISTR('\00E9')||'r'||UNISTR('\00E9')||'s de Micron'||UNISTR('\00E9')||'sie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fo',''||UNISTR('\00CE')||'les F'||UNISTR('\00E9')||'ro'||UNISTR('\00E9')||'','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fr','France','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ga','Gabon','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gb','Royaume-Uni','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gd','Grenade','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ge','G'||UNISTR('\00E9')||'orgie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gf','Guyane fran'||UNISTR('\00E7')||'aise','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gg','Guernesey','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gh','Ghana','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gi','Gibraltar','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gl','Groenland','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gm','Gambie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gn','Guin'||UNISTR('\00E9')||'e','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gp','Guadeloupe','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gq','Guin'||UNISTR('\00E9')||'e '||UNISTR('\00E9')||'quatoriale','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gr','Gr'||UNISTR('\00E8')||'ce','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gs',''||UNISTR('\00CE')||'les G'||UNISTR('\00E9')||'orgie du Sud et Sandwich du Sud','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gt','Guatemala','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gu','Guam','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gw','Guin'||UNISTR('\00E9')||'e-Bissau','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gy','Guyana','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hk','Hong Kong','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hm',''||UNISTR('\00CE')||'les Heard et MacDonald','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hn','Honduras','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hr','Croatie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ht','Ha'||UNISTR('\00EF')||'ti','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hu','Hongrie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('id','Indon'||UNISTR('\00E9')||'sie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ie','Irlande','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('il','Isra'||UNISTR('\00EB')||'l','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('im',''||UNISTR('\00CE')||'le de Man','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('in','Inde','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('io','Territoire britannique de l'||UNISTR('\2019')||'oc'||UNISTR('\00E9')||'an Indien','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('iq','Irak','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ir','Iran','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('is','Islande','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('it','Italie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('je','Jersey','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jm','Jama'||UNISTR('\00EF')||'que','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jo','Jordanie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jp','Japon','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ke','Kenya','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kg','Kirghizistan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kh','Cambodge','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ki','Kiribati','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('km','Comores','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kn','Saint-Kitts-et-Nevis','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kp','Cor'||UNISTR('\00E9')||'e du Nord','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kr','Cor'||UNISTR('\00E9')||'e du Sud','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kw','Kowe'||UNISTR('\00EF')||'t','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ky',''||UNISTR('\00CE')||'les Ca'||UNISTR('\00EF')||'mans','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kz','Kazakhstan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('la','Laos','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lb','Liban','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lc','Sainte-Lucie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('li','Liechtenstein','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lk','Sri Lanka','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lr','Lib'||UNISTR('\00E9')||'ria','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ls','Lesotho','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lt','Lituanie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lu','Luxembourg','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lv','Lettonie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ly','Libye','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ma','Maroc','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mc','Monaco','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('md','Moldavie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('me','Mont'||UNISTR('\00E9')||'n'||UNISTR('\00E9')||'gro','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mg','Madagascar','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mh',''||UNISTR('\00CE')||'les Marshall','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mk','Mac'||UNISTR('\00E9')||'doine','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ml','Mali','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mm','Myanmar','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mn','Mongolie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mo','Macao','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mp',''||UNISTR('\00CE')||'les Mariannes du Nord','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mq','Martinique','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mr','Mauritanie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ms','Montserrat','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mt','Malte','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mu','Maurice','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mv','Maldives','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mw','Malawi','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mx','Mexique','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('my','Malaisie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mz','Mozambique','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('na','Namibie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nc','Nouvelle-Cal'||UNISTR('\00E9')||'donie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ne','Niger','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nf',''||UNISTR('\00CE')||'le Norfolk','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ng','Nig'||UNISTR('\00E9')||'ria','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ni','Nicaragua','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nl','Pays-Bas','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('no','Norv'||UNISTR('\00E8')||'ge','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('np','N'||UNISTR('\00E9')||'pal','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nr','Nauru','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nu','Niue','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nz','Nouvelle-Z'||UNISTR('\00E9')||'lande','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('om','Oman','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pa','Panama','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pe','P'||UNISTR('\00E9')||'rou','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pf','Polyn'||UNISTR('\00E9')||'sie fran'||UNISTR('\00E7')||'aise','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pg','Papouasie-Nouvelle-Guin'||UNISTR('\00E9')||'e','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ph','Philippines','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pk','Pakistan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pl','Pologne','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pm','Saint-Pierre-et-Miquelon','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pn','Pitcairn','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pr','Porto Rico','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ps','Territoire palestinien','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pt','Portugal','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pw','Palaos','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('py','Paraguay','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('qa','Qatar','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('re','R'||UNISTR('\00E9')||'union','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ro','Roumanie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rs','Serbie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ru','Russie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rw','Rwanda','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sa','Arabie saoudite','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sb',''||UNISTR('\00CE')||'les Salomon','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sc','Seychelles','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sd','Soudan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('se','Su'||UNISTR('\00E8')||'de','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sg','Singapour','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sh','Sainte-H'||UNISTR('\00E9')||'l'||UNISTR('\00E8')||'ne','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('si','Slov'||UNISTR('\00E9')||'nie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sj','Svalbard et '||UNISTR('\00CE')||'le Jan Mayen','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sk','Slovaquie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sl','Sierra Leone','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sm','Saint-Marin','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sn','S'||UNISTR('\00E9')||'n'||UNISTR('\00E9')||'gal','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('so','Somalie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sr','Suriname','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('st','S'||UNISTR('\00E3')||'o Tom'||UNISTR('\00E9')||'-et-Pr'||UNISTR('\00ED')||'ncipe','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sv','El Salvador','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sy','Syrie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sz','Swaziland','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tc',''||UNISTR('\00CE')||'les Turks et Ca'||UNISTR('\00EF')||'ques','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('td','Tchad','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tf','Terres australes fran'||UNISTR('\00E7')||'aises','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tg','Togo','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('th','Tha'||UNISTR('\00EF')||'lande','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tj','Tadjikistan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tk','Tokelau','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tl','Timor oriental','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tm','Turkm'||UNISTR('\00E9')||'nistan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tn','Tunisie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('to','Tonga','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tr','Turquie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tt','Trinit'||UNISTR('\00E9')||'-et-Tobago','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tv','Tuvalu','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tw','Ta'||UNISTR('\00EF')||'wan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tz','Tanzanie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ua','Ukraine','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ug','Ouganda','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('um',''||UNISTR('\00CE')||'les mineures '||UNISTR('\00E9')||'loign'||UNISTR('\00E9')||'es des '||UNISTR('\00C9')||'tats-Unis','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('us',''||UNISTR('\00C9')||'tats-Unis','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uy','Uruguay','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uz','Ouzb'||UNISTR('\00E9')||'kistan','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('va',''||UNISTR('\00C9')||'tat de la Cit'||UNISTR('\00E9')||' du Vatican','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vc','Saint-Vincent-et-les Grenadines','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ve','Venezuela','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vg',''||UNISTR('\00CE')||'les Vierges britanniques','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vi',''||UNISTR('\00CE')||'les Vierges des '||UNISTR('\00C9')||'tats-Unis','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vn','Vi'||UNISTR('\00EA')||'t Nam','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vu','Vanuatu','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('wf','Wallis-et-Futuna','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ws','Samoa','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ye','Y'||UNISTR('\00E9')||'men','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('yt','Mayotte','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('za','Afrique du Sud','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zm','Zambie','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zw','Zimbabwe','fr');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ad','Andorra','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ae','Vereinigte Arabische Emirate','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('af','Afghanistan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ag','Antigua und Barbuda','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ai','Anguilla','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('al','Albanien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('am','Armenien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('an','Niederl'||UNISTR('\00E4')||'ndische Antillen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ao','Angola','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aq','Antarktis','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ar','Argentinien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('as','Amerikanisch-Samoa','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('at',''||UNISTR('\00D6')||'sterreich','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('au','Australien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aw','Aruba','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ax','Alandinseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('az','Aserbaidschan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ba','Bosnien u. Herzegowina','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bb','Barbados','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bd','Bangladesch','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('be','Belgien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bf','Burkina Faso','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bg','Bulgarien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bh','Bahrain','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bi','Burundi','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bj','Benin','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bm','Bermuda','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bn','Brunei Darussalam','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bo','Bolivien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('br','Brasilien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bs','Bahamas','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bt','Bhutan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bv','Bouvetinsel','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bw','Botsuana','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('by','Belarus','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bz','Belize','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ca','Kanada','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cc','Kokosinseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cd','Kongo-Kinshasa','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cf','Zentralafrikanische Republik','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cg','Kongo [Republik]','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ch','Schweiz','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ci','C'||UNISTR('\00F4')||'te d''Ivoire','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ck','Cookinseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cl','Chile','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cm','Kamerun','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cn','China','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('co','Kolumbien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cr','Costa Rica','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cu','Kuba','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cv','Kap Verde','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cx','Weihnachtsinsel','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cy','Zypern','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cz','Tschechische Republik','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('de','Deutschland','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dj','Dschibuti','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dk','D'||UNISTR('\00E4')||'nemark','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dm','Dominica','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('do','Dominikanische Republik','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dz','Algerien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ec','Ecuador','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ee','Estland','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eg',''||UNISTR('\00C4')||'gypten','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eh','Westsahara','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('er','Eritrea','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('es','Spanien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('et',''||UNISTR('\00C4')||'thiopien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fi','Finnland','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fj','Fidschi','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fk','Falklandinseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fm','Mikronesien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fo','F'||UNISTR('\00E4')||'r'||UNISTR('\00F6')||'er','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fr','Frankreich','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ga','Gabun','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gb','Vereinigtes K'||UNISTR('\00F6')||'nigreich','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gd','Grenada','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ge','Georgien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gf','Franz'||UNISTR('\00F6')||'sisch-Guayana','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gg','Guernsey','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gh','Ghana','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gi','Gibraltar','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gl','Gr'||UNISTR('\00F6')||'nland','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gm','Gambia','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gn','Guinea','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gp','Guadeloupe','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gq',''||UNISTR('\00C4')||'quatorialguinea','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gr','Griechenland','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gs','S'||UNISTR('\00FC')||'dgeorgien und die S'||UNISTR('\00FC')||'dlichen Sandwichinseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gt','Guatemala','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gu','Guam','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gw','Guinea-Bissau','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gy','Guyana','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hk','Hongkong','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hm','Heard- und McDonald-Inseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hn','Honduras','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hr','Kroatien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ht','Haiti','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hu','Ungarn','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('id','Indonesien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ie','Irland','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('il','Israel','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('im','Isle of Man','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('in','Indien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('io','Britisches Territorium im Indischen Ozean','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('iq','Irak','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ir','Iran','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('is','Island','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('it','Italien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('je','Jersey','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jm','Jamaika','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jo','Jordanien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jp','Japan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ke','Kenia','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kg','Kirgisistan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kh','Kambodscha','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ki','Kiribati','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('km','Komoren','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kn','St. Kitts und Nevis','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kp','Nordkorea','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kr','S'||UNISTR('\00FC')||'dkorea','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kw','Kuwait','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ky','Kaimaninseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kz','Kasachstan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('la','Laos','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lb','Libanon','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lc','St. Lucia','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('li','Liechtenstein','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lk','Sri Lanka','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lr','Liberia','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ls','Lesotho','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lt','Litauen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lu','Luxemburg','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lv','Lettland','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ly','Libyen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ma','Marokko','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mc','Monaco','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('md','Moldau','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('me','Montenegro','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mg','Madagaskar','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mh','Marshallinseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mk','Mazedonien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ml','Mali','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mm','Burma','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mn','Mongolei','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mo','Macao','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mp','N'||UNISTR('\00F6')||'rdliche Marianen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mq','Martinique','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mr','Mauretanien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ms','Montserrat','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mt','Malta','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mu','Mauritius','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mv','Malediven','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mw','Malawi','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mx','Mexiko','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('my','Malaysia','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mz','Mosambik','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('na','Namibia','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nc','Neukaledonien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ne','Niger','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nf','Norfolkinsel','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ng','Nigeria','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ni','Nicaragua','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nl','Niederlande','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('no','Norwegen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('np','Nepal','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nr','Nauru','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nu','Niue','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nz','Neuseeland','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('om','Oman','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pa','Panama','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pe','Peru','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pf','Franz'||UNISTR('\00F6')||'sisch-Polynesien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pg','Papua-Neuguinea','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ph','Philippinen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pk','Pakistan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pl','Polen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pm','St. Pierre und Miquelon','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pn','Pitcairn','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pr','Puerto Rico','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ps','Pal'||UNISTR('\00E4')||'stinensische Autonomiegebiete','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pt','Portugal','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('pw','Palau','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('py','Paraguay','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('qa','Katar','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('re','R'||UNISTR('\00E9')||'union','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ro','Rum'||UNISTR('\00E4')||'nien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rs','Serbien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ru','Russische F'||UNISTR('\00F6')||'deration','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('rw','Ruanda','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sa','Saudi-Arabien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sb','Salomonen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sc','Seychellen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sd','Sudan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('se','Schweden','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sg','Singapur','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sh','St. Helena','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('si','Slowenien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sj','Svalbard und Jan Mayen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sk','Slowakei','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sl','Sierra Leone','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sm','San Marino','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sn','Senegal','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('so','Somalia','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sr','Suriname','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('st','S'||UNISTR('\00E3')||'o Tom'||UNISTR('\00E9')||' und Pr'||UNISTR('\00ED')||'ncipe','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sv','El Salvador','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sy','Syrien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('sz','Swasiland','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tc','Turks- und Caicosinseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('td','Tschad','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tf','Franz'||UNISTR('\00F6')||'sische S'||UNISTR('\00FC')||'d- und Antarktisgebiete','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tg','Togo','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('th','Thailand','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tj','Tadschikistan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tk','Tokelau','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tl','Osttimor','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tm','Turkmenistan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tn','Tunesien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('to','Tonga','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tr','T'||UNISTR('\00FC')||'rkei','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tt','Trinidad und Tobago','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tv','Tuvalu','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tw','Taiwan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('tz','Tansania','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ua','Ukraine','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ug','Uganda','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('um','Amerikanisch-Ozeanien','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('us','Vereinigte Staaten','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uy','Uruguay','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('uz','Usbekistan','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('va','Vatikanstadt','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vc','St. Vincent und die Grenadinen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ve','Venezuela','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vg','Britische Jungferninseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vi','Amerikanische Jungferninseln','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vn','Vietnam','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('vu','Vanuatu','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('wf','Wallis und Futuna','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ws','Samoa','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ye','Jemen','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('yt','Mayotte','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('za','S'||UNISTR('\00FC')||'dafrika','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zm','Sambia','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('zw','Simbabwe','de');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ad','Andorra','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ae','Emiratos '||UNISTR('\00C1')||'rabes Unidos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('af','Afganist'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ag','Antigua y Barbuda','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ai','Anguila','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('al','Albania','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('am','Armenia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('an','Antillas Neerlandesas','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ao','Angola','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aq','Ant'||UNISTR('\00E1')||'rtida','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ar','Argentina','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('as','Samoa Americana','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('at','Austria','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('au','Australia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('aw','Aruba','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ax','Islas '||UNISTR('\00C5')||'land','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('az','Azerbaiy'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ba','Bosnia-Herzegovina','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bb','Barbados','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bd','Bangladesh','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('be','B'||UNISTR('\00E9')||'lgica','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bf','Burkina Faso','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bg','Bulgaria','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bh','Bahr'||UNISTR('\00E9')||'in','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bi','Burundi','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bj','Ben'||UNISTR('\00ED')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bm','Bermudas','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bn','Brun'||UNISTR('\00E9')||'i','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bo','Bolivia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('br','Brasil','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bs','Bahamas','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bt','But'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bv','Isla Bouvet','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bw','Botsuana','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('by','Bielorrusia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('bz','Belice','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ca','Canad'||UNISTR('\00E1')||'','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cc','Islas Cocos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cd','Congo - Kinshasa','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cf','Rep'||UNISTR('\00FA')||'blica Centroafricana','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cg','Congo [Rep'||UNISTR('\00FA')||'blica]','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ch','Suiza','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ci','Costa de Marfil','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ck','Islas Cook','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cl','Chile','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cm','Camer'||UNISTR('\00FA')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cn','China','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('co','Colombia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cr','Costa Rica','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cu','Cuba','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cv','Cabo Verde','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cx','Isla Christmas','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cy','Chipre','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('cz','Rep'||UNISTR('\00FA')||'blica Checa','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('de','Alemania','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dj','Yibuti','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dk','Dinamarca','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dm','Dominica','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('do','Rep'||UNISTR('\00FA')||'blica Dominicana','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('dz','Argelia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ec','Ecuador','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ee','Estonia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eg','Egipto','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('eh','S'||UNISTR('\00E1')||'hara Occidental','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('er','Eritrea','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('es','Espa'||UNISTR('\00F1')||'a','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('et','Etiop'||UNISTR('\00ED')||'a','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fi','Finlandia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fj','Fiyi','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fk','Islas Malvinas','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fm','Micronesia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fo','Islas Feroe','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('fr','Francia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ga','Gab'||UNISTR('\00F3')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gb','Reino Unido','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gd','Granada','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ge','Georgia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gf','Guayana Francesa','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gg','Guernsey','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gh','Ghana','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gi','Gibraltar','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gl','Groenlandia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gm','Gambia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gn','Guinea','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gp','Guadalupe','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gq','Guinea Ecuatorial','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gr','Grecia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gs','Georgia del Sur e Islas Sandwich del Sur','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gt','Guatemala','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gu','Guam','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gw','Guinea-Bissau','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('gy','Guyana','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hk','Hong Kong','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hm','Islas Heard y McDonald','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hn','Honduras','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hr','Croacia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ht','Hait'||UNISTR('\00ED')||'','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('hu','Hungr'||UNISTR('\00ED')||'a','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('id','Indonesia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ie','Irlanda','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('il','Israel','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('im','Isla de Man','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('in','India','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('io','Territorio Brit'||UNISTR('\00E1')||'nico del Oc'||UNISTR('\00E9')||'ano '||UNISTR('\00CD')||'ndico','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('iq','Iraq','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ir','Ir'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('is','Islandia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('it','Italia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('je','Jersey','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jm','Jamaica','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jo','Jordania','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('jp','Jap'||UNISTR('\00F3')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ke','Kenia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kg','Kirguist'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kh','Camboya','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ki','Kiribati','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('km','Comoras','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kn','San Crist'||UNISTR('\00F3')||'bal y Nieves','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kp','Corea del Norte','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kr','Corea del Sur','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kw','Kuwait','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ky','Islas Caim'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('kz','Kazajist'||UNISTR('\00E1')||'n','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('la','Laos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lb','L'||UNISTR('\00ED')||'bano','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lc','Santa Luc'||UNISTR('\00ED')||'a','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('li','Liechtenstein','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lk','Sri Lanka','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lr','Liberia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ls','Lesoto','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lt','Lituania','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lu','Luxemburgo','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('lv','Letonia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ly','Libia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ma','Marruecos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mc','M'||UNISTR('\00F3')||'naco','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('md','Moldavia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('me','Montenegro','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mg','Madagascar','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mh','Islas Marshall','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mk','Macedonia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ml','Mali','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mm','Myanmar [Birmania]','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mn','Mongolia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mo','Macao','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mp','Islas Marianas del Norte','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mq','Martinica','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mr','Mauritania','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ms','Montserrat','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mt','Malta','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mu','Mauricio','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mv','Maldivas','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mw','Malaui','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mx','M'||UNISTR('\00E9')||'xico','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('my','Malasia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('mz','Mozambique','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('na','Namibia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nc','Nueva Caledonia','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ne','N'||UNISTR('\00ED')||'ger','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nf','Isla Norfolk','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ng','Nigeria','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('ni','Nicaragua','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nl','Pa'||UNISTR('\00ED')||'ses Bajos','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('no','Noruega','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('np','Nepal','es');
INSERT INTO postcode.country_alias (country, alias, lang) VALUES ('nr','Nauru','es');
END;
/

GRANT SELECT, REFERENCES ON POSTCODE.CONTINENT TO CSR;
GRANT SELECT, REFERENCES ON POSTCODE.COUNTRY_ALIAS TO CSR;

@..\csr_Data_pkg
@..\logistics_pkg
@..\logistics_body

@update_tail