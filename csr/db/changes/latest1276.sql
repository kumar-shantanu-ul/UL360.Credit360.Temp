-- Please update version.sql too -- this keeps clean builds in sync
define version=1276
@update_header

alter table csr.customer add use_var_expl_groups number(1) default 0 not null;
alter table csr.customer add constraint ck_use_var_expl_groups check (use_var_expl_groups in (0,1));

alter table csr.var_expl add hidden number(1) default 0 not null;
alter table csr.var_expl add constraint ck_var_expl_hidden check (hidden in (0,1));

create or replace package csr.var_expl_pkg as
procedure dummy;
end;
/
create or replace package body csr.var_expl_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on csr.var_expl_pkg to web_user;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.SHEET_VALUE_VAR_EXPL(
    SHEET_VALUE_ID    NUMBER(10, 0)    NOT NULL,
    VAR_EXPL_ID       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SHEET_VALUE_VAR_EXPL PRIMARY KEY (SHEET_VALUE_ID, VAR_EXPL_ID)
) ON COMMIT DELETE ROWS
;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.VAR_EXPL(
    VAR_EXPL_ID          NUMBER(10, 0)    NOT NULL,
    VAR_EXPL_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                VARCHAR2(255)    NOT NULL,
    REQUIRES_NOTE        NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    POS                  NUMBER(10, 0)    DEFAULT 0,
    HIDDEN		         NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_REQUIRES_NOTE CHECK (REQUIRES_NOTE IN (0,1)),
    CONSTRAINT CK_VAR_EXPL_HIDDEN CHECK (HIDDEN IN (0,1)),
    CONSTRAINT PK_VAR_EXPL PRIMARY KEY (VAR_EXPL_ID)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.VAR_EXPL_GROUP(
    VAR_EXPL_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_VAR_EXPL_GROUP PRIMARY KEY (VAR_EXPL_GROUP_ID)
) ON COMMIT DELETE ROWS;

create global temporary table csrimp.map_var_expl_group(
	old_var_expl_group_id					number(10)	not null,
	new_var_expl_group_id					number(10)	not null,
	constraint pk_map_var_expl_group primary key (old_var_expl_group_id) using index,
	constraint uk_map_var_expl_group unique (new_var_expl_group_id) using index
) on commit delete rows;

create global temporary table csrimp.map_var_expl(
	old_var_expl_id							number(10)	not null,
	new_var_expl_id							number(10)	not null,
	constraint pk_map_var_expl primary key (old_var_expl_id) using index,
	constraint uk_map_var_expl unique (new_var_expl_id) using index
) on commit delete rows;

grant select, insert on csr.sheet_value_var_expl to csrimp;
grant select, insert on csr.var_expl to csrimp;
grant select, insert on csr.var_expl_group to csrimp;
grant select on csr.var_expl_id_seq to csrimp;
grant select on csr.var_expl_group_id_seq to csrimp;
grant insert,select,update,delete on csrimp.var_expl to web_user;
grant insert,select,update,delete on csrimp.var_expl_group to web_user;

@../schema_pkg
@../var_expl_pkg
@../csr_app_body
@../schema_body
@../var_expl_body
@../csrimp/imp_body

@update_tail
