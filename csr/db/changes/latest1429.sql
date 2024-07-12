-- Please update version.sql too -- this keeps clean builds in sync
define version=1429
@update_header

create table csr.alert (
	app_sid							number(10) default sys_context('security', 'app') not null,
	alert_id						raw(16) not null,
	to_user_sid						number(10),
	to_email_address				varchar2(255) not null,
	sent_dtm						date default sysdate not null,
	message							blob not null,
	constraint pk_alert primary key (app_sid, alert_id),
	constraint fk_alert_csr_user foreign key (app_sid, to_user_sid)
	references csr.csr_user (app_sid, csr_user_sid),
	constraint uk_alert_alert_id unique (alert_id)
);
create index csr.ix_alert_to_user on csr.alert (app_sid, to_user_sid);

create table csr.alert_bounce (
	app_sid							number(10) default sys_context('security', 'app') not null,
	alert_id						raw(16) not null,
	received_dtm					date default sysdate not null,
	message							blob not null,
	constraint fk_alert_bounce_alert foreign key (app_sid, alert_id)
	references csr.alert (app_sid, alert_id)
);
create index csr.ix_alert_bounce_alert on csr.alert_bounce (app_sid, alert_id);

alter table csr.customer add bounce_tracking_enabled number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_bounce_track_enabled check (bounce_tracking_enabled in (0,1));

CREATE TABLE CSRIMP.ALERT (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ALERT_ID						RAW(16) NOT NULL,
	TO_USER_SID						NUMBER(10),
	TO_EMAIL_ADDRESS				VARCHAR2(255) NOT NULL,
	SENT_DTM						DATE DEFAULT SYSDATE NOT NULL,
	MESSAGE							BLOB NOT NULL,
	CONSTRAINT PK_ALERT PRIMARY KEY (CSRIMP_SESSION_ID, ALERT_ID),
    CONSTRAINT FK_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE	
);

CREATE TABLE CSRIMP.ALERT_BOUNCE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ALERT_ID						RAW(16) NOT NULL,
	RECEIVED_DTM					DATE DEFAULT SYSDATE NOT NULL,
	MESSAGE							BLOB NOT NULL,
    CONSTRAINT FK_ALERT_BOUNCE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

delete from csrimp.csrimp_session;
alter table csrimp.customer add bounce_tracking_enabled number(1) not null;
alter table csrimp.customer add constraint ck_cust_bounce_track_enabled check (bounce_tracking_enabled in (0,1));

CREATE TABLE csrimp.map_alert (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_alert_id					RAW(16) NOT NULL,
	new_alert_id					RAW(16) NOT NULL,
	CONSTRAINT pk_map_alert PRIMARY KEY (old_alert_id) USING INDEX,
	CONSTRAINT uk_map_alert UNIQUE (new_alert_id) USING INDEX,
    CONSTRAINT FK_MAP_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant insert,select,update,delete on csrimp.alert to web_user;
grant insert,select,update,delete on csrimp.alert_bounce to web_user;
grant insert on csr.alert to csrimp;
grant insert on csr.alert_bounce to csrimp;

@../alert_pkg
@../alert_body
@../csr_data_body
@../csr_app_body
@../csrimp/imp_pkg
@../csrimp/imp_body
@../schema_pkg
@../schema_body

@update_tail
