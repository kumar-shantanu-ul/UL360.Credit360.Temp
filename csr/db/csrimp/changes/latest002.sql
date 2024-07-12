-- Please update version.sql too -- this keeps clean builds in sync
define version=2
@update_header

connect csr/csr@&_CONNECT_IDENTIFIER
grant select,insert on csr.imp_conflict to csrimp;
grant select,insert on csr.imp_conflict_val to csrimp;
grant select,insert on csr.imp_ind to csrimp;
grant select,insert on csr.imp_region to csrimp;
grant select,insert on csr.imp_session to csrimp;
grant select,insert on csr.imp_measure to csrimp;
grant select,insert on csr.imp_val to csrimp;
grant select,insert on csr.file_upload to csrimp;
grant select on csr.imp_conflict_id_seq to csrimp;
grant select on csr.imp_ind_id_seq to csrimp;
grant select on csr.imp_region_id_seq to csrimp;
grant select on csr.imp_measure_id_seq to csrimp;
grant select on csr.imp_val_id_seq to csrimp;
grant execute on csr.fileupload_pkg to csrimp;
grant execute on csr.imp_pkg to csrimp;
connect csrimp/csrimp@&_CONNECT_IDENTIFIER

create global temporary table map_imp_conflict(
	old_imp_conflict_id				number(10)	not null,
	new_imp_conflict_id				number(10)	not null,
	constraint pk_map_imp_conflict primary key (old_imp_conflict_id) using index,
	constraint uk_map_imp_conflict unique (new_imp_conflict_id) using index
) on commit delete rows;

create global temporary table map_imp_ind(
	old_imp_ind_id					number(10)	not null,
	new_imp_ind_id					number(10)	not null,
	constraint pk_map_imp_ind primary key (old_imp_ind_id) using index,
	constraint uk_map_imp_ind unique (new_imp_ind_id) using index
) on commit delete rows;

create global temporary table map_imp_region(
	old_imp_region_id				number(10)	not null,
	new_imp_region_id				number(10)	not null,
	constraint pk_map_imp_region primary key (old_imp_region_id) using index,
	constraint uk_map_imp_region unique (new_imp_region_id) using index
) on commit delete rows;

create global temporary table map_imp_measure(
	old_imp_measure_id				number(10)	not null,
	new_imp_measure_id				number(10)	not null,
	constraint pk_map_imp_measure primary key (old_imp_measure_id) using index,
	constraint uk_map_imp_measure unique (new_imp_measure_id) using index
) on commit delete rows;

create global temporary table map_imp_session(
	old_imp_session_sid				number(10)	not null,
	new_imp_session_sid				number(10)	not null,
	constraint pk_map_imp_session primary key (old_imp_session_sid) using index,
	constraint uk_map_imp_session unique (new_imp_session_sid) using index
) on commit delete rows;

create global temporary table map_imp_val(
	old_imp_val_id					number(10)	not null,
	new_imp_val_id					number(10)	not null,
	constraint pk_map_imp_val primary key (old_imp_val_id) using index,
	constraint uk_map_imp_val unique (new_imp_val_id) using index
) on commit delete rows;

create global temporary table map_file_upload(
	old_file_upload_sid				number(10)	not null,
	new_file_upload_sid				number(10)	not null,
	constraint pk_map_file_upload primary key (old_file_upload_sid) using index,
	constraint uk_map_file_upload unique (new_file_upload_sid) using index
) on commit delete rows;

create global temporary table map_val(
	old_val_id						number(10)	not null,
	new_val_id						number(10)	not null,
	constraint pk_map_val primary key (old_val_id) using index,
	constraint uk_map_val unique (new_val_id) using index
) on commit delete rows;

CREATE GLOBAL TEMPORARY TABLE IMP_CONFLICT(
    IMP_CONFLICT_ID         NUMBER(10, 0)    NOT NULL,
    IMP_SESSION_SID         NUMBER(10, 0)    NOT NULL,
    RESOLVED_BY_USER_SID    NUMBER(10, 0),
    START_DTM               DATE             NOT NULL,
    END_DTM                 DATE             NOT NULL,
    REGION_SID              NUMBER(10, 0)    NOT NULL,
    IND_SID                 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_IMP_CONFLICT PRIMARY KEY (IMP_CONFLICT_ID)
)
;

CREATE GLOBAL TEMPORARY TABLE IMP_CONFLICT_VAL(
    IMP_CONFLICT_ID    NUMBER(10, 0)    NOT NULL,
    IMP_VAL_ID         NUMBER(10, 0)    NOT NULL,
    ACCEPT             NUMBER(10, 0)    DEFAULT (0) NOT NULL,
    CONSTRAINT PK_IMP_CONFLICT_VAL PRIMARY KEY (IMP_CONFLICT_ID, IMP_VAL_ID)
)
;

CREATE GLOBAL TEMPORARY TABLE IMP_IND(
    IMP_IND_ID         NUMBER(10, 0)     NOT NULL,
    DESCRIPTION        VARCHAR2(1023)    NOT NULL,
    MAPS_TO_IND_SID    NUMBER(10, 0),
    IGNORE             NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CONSTRAINT PK_IMP_IND PRIMARY KEY (IMP_IND_ID)
)
;

CREATE GLOBAL TEMPORARY TABLE IMP_MEASURE(
    IMP_MEASURE_ID                   NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                      VARCHAR2(255)    NOT NULL,
    MAPS_TO_MEASURE_CONVERSION_ID    NUMBER(10, 0),
    MAPS_TO_MEASURE_SID              NUMBER(10, 0),
    IMP_IND_ID                       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_IMP_MEASURE PRIMARY KEY (IMP_MEASURE_ID)
)
;

CREATE GLOBAL TEMPORARY TABLE IMP_REGION(
    IMP_REGION_ID         NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(255)    NOT NULL,
    MAPS_TO_REGION_SID    NUMBER(10, 0),
    IGNORE                NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT PK_IMP_REGION PRIMARY KEY (IMP_REGION_ID)
)
;

CREATE GLOBAL TEMPORARY TABLE IMP_SESSION(
    IMP_SESSION_SID      NUMBER(10, 0)     NOT NULL,
    PARENT_SID           NUMBER(10, 0)     NOT NULL,
    NAME                 VARCHAR2(256),
    OWNER_SID            NUMBER(10, 0)     NOT NULL,
    UPLOADED_DTM         DATE,
    FILE_PATH            VARCHAR2(256)     NOT NULL,
    PARSE_STARTED_DTM    DATE,
    PARSED_DTM           DATE,
    MERGED_DTM           DATE,
    RESULT_CODE          NUMBER(10, 0),
    MESSAGE              VARCHAR2(2048),
    CONSTRAINT PK_IMP_SESSION PRIMARY KEY (IMP_SESSION_SID)
)
;

CREATE GLOBAL TEMPORARY TABLE IMP_VAL(
    IMP_VAL_ID         NUMBER(10, 0)     NOT NULL,
    IMP_IND_ID         NUMBER(10, 0)     NOT NULL,
    IMP_REGION_ID      NUMBER(10, 0)     NOT NULL,
    IMP_MEASURE_ID     NUMBER(10, 0),
    UNKNOWN            VARCHAR2(2048),
    START_DTM          DATE              NOT NULL,
    END_DTM            DATE              NOT NULL,
    VAL                NUMBER(24, 10)    NOT NULL,
    FILE_SID           NUMBER(10, 0),
    A                  NUMBER(10, 0),
    B                  NUMBER(10, 0),
    C                  NUMBER(10, 0),
    IMP_SESSION_SID    NUMBER(10, 0)     NOT NULL,
    SET_VAL_ID         NUMBER(10, 0),
    NOTE               CLOB,
    CONSTRAINT CK_IMP_VAL_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM),
    CONSTRAINT CK_IMP_VAL_CONV_COMPLETED CHECK ((a is null and b is null and c is null) or (a is not null and b is not null and c is not null)),
    CONSTRAINT PK_IMP_VAL PRIMARY KEY (IMP_VAL_ID)
)
;

CREATE GLOBAL TEMPORARY TABLE IMP_FILE_UPLOAD(
    FILE_UPLOAD_SID      NUMBER(10, 0)    NOT NULL,
    FILENAME             VARCHAR2(255)    NOT NULL,
    MIME_TYPE            VARCHAR2(256)    NOT NULL,
    PARENT_SID           NUMBER(10, 0)    NOT NULL,
    DATA                 BLOB             NOT NULL,
    SHA1                 RAW(20)          NOT NULL,
    LAST_MODIFIED_DTM    DATE             DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_FILE_UPLOAD PRIMARY KEY (FILE_UPLOAD_SID)
)
;

connect csr/csr@&_CONNECT_IDENTIFIER
@../../schema_pkg
@../../schema_body
connect csrimp/csrimp@&_CONNECT_IDENTIFIER

@../imp_body

@update_tail
