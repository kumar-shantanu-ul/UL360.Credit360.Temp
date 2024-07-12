-- Please update version.sql too -- this keeps clean builds in sync
define version=5
@update_header

drop table ind;
CREATE GLOBAL TEMPORARY TABLE IND(
    IND_SID                       NUMBER(10, 0)     NOT NULL,
    PARENT_SID                    NUMBER(10, 0),
    NAME                          VARCHAR2(255)     NOT NULL,
    DESCRIPTION                   VARCHAR2(1023),
    IND_TYPE                      NUMBER(10, 0)     NOT NULL,
    TOLERANCE_TYPE                NUMBER(2, 0)      NOT NULL,
    PCT_UPPER_TOLERANCE           NUMBER(10, 4)     NOT NULL,
    PCT_LOWER_TOLERANCE           NUMBER(10, 4)     NOT NULL,
    MEASURE_SID                   NUMBER(10, 0),
    MULTIPLIER                    NUMBER(10, 0)     NOT NULL,
    SCALE                         NUMBER(10, 0),
    FORMAT_MASK                   VARCHAR2(255),
    LAST_MODIFIED_DTM             DATE,
    ACTIVE                        NUMBER(10, 0),
    TARGET_DIRECTION              NUMBER(10, 0)     NOT NULL,
    POS                           NUMBER(10, 0)     NOT NULL,
    INFO_XML                      SYS.XMLType,
    START_MONTH                   NUMBER(10, 0),
    DIVISIBLE                     NUMBER(10, 0),
    NULL_MEANS_NULL               NUMBER(10, 0),
    AGGREGATE                     VARCHAR2(24)      NOT NULL,
    DEFAULT_INTERVAL              CHAR(1)           NOT NULL,
    CALC_START_DTM_ADJUSTMENT     NUMBER(10, 0)     NOT NULL,
    CALC_XML                      SYS.XMLType,
    GRI                           VARCHAR2(255),
    LOOKUP_KEY                    VARCHAR2(64),
    OWNER_SID                     NUMBER(10, 0),
    IND_ACTIVITY_TYPE_ID          NUMBER(10, 0),
    CORE                          NUMBER(1, 0)      NOT NULL,
    ROLL_FORWARD                  NUMBER(1, 0)      NOT NULL,
    FACTOR_TYPE_ID                NUMBER(10, 0),
    MAP_TO_IND_SID                NUMBER(10, 0),
    GAS_MEASURE_SID               NUMBER(10, 0),
    GAS_TYPE_ID                   NUMBER(10, 0),
    CALC_DESCRIPTION              VARCHAR2(4000),
    NORMALIZE                     NUMBER(1, 0)      NOT NULL,
    DO_TEMPORAL_AGGREGATION       NUMBER(1, 0)      NOT NULL,
    CONSTRAINT IND_TOLERANCE CHECK (tolerance_type = 0 OR (pct_upper_tolerance IS NOT NULL AND pct_lower_tolerance IS NOT NULL)),
    CONSTRAINT CK_IND_AGGR CHECK (aggregate IN ('SUM', 'FORCE SUM', 'AVERAGE', 'NONE', 'DOWN', 'FORCE DOWN')),
    CONSTRAINT CK_IND_TYPE CHECK (IND_TYPE IN (0,1,2)),
    CHECK (CORE IN (0,1)),
    CONSTRAINT CK_IND_ROLL_FORWARD CHECK (ROLL_FORWARD IN (0, 1)),
    CONSTRAINT CK_IND_NORMALIZE CHECK (NORMALIZE IN (0,1)),
    CHECK (DO_TEMPORAL_AGGREGATION IN (0,1)),
    CONSTRAINT PK_IND PRIMARY KEY (IND_SID)
) ON COMMIT DELETE ROWS
;

drop table dataview;
CREATE GLOBAL TEMPORARY TABLE DATAVIEW(
    DATAVIEW_SID                   NUMBER(10, 0)     NOT NULL,
    PARENT_SID                     NUMBER(10, 0)     NOT NULL,
    NAME                           VARCHAR2(256),
    START_DTM                      DATE              NOT NULL,
    END_DTM                        DATE,
    GROUP_BY                       VARCHAR2(128)     NOT NULL,
    INTERVAL                       VARCHAR2(10)      NOT NULL,
    CHART_CONFIG_XML               CLOB,
    CHART_STYLE_XML                CLOB,
    POS                            NUMBER(10, 0)	 NOT NULL,
    DESCRIPTION                    VARCHAR2(2048),
    DATAVIEW_TYPE_ID               NUMBER(6, 0)      NOT NULL,
    USE_UNMERGED                   NUMBER(1, 0)      NOT NULL,
    USE_BACKFILL                   NUMBER(1, 0)      NOT NULL,
    USE_PENDING                    NUMBER(1, 0)      NOT NULL,
    SHOW_CALC_TRACE                NUMBER(1, 0)      NOT NULL,
    SHOW_VARIANCE                  NUMBER(1, 0)      NOT NULL,
    SORT_BY_MOST_RECENT            NUMBER(1, 0)      NOT NULL,
    INCLUDE_PARENT_REGION_NAMES    NUMBER(1, 0)      NOT NULL,
    LAST_UPDATED_DTM               DATE              NOT NULL,
    LAST_UPDATED_SID               NUMBER(10, 0),
    CONSTRAINT CK_DATAVIEW_USE_UNMERGED CHECK (USE_UNMERGED IN (0,1)),
    CONSTRAINT CK_DATAVIEW_USE_BACKFILL CHECK (USE_BACKFILL IN (0,1)),
    CONSTRAINT CK_DATAVIEW_SHOW_CALC_TRACE CHECK (SHOW_CALC_TRACE IN (0,1)),
    CONSTRAINT CK_DATAVIEW_SHOW_VARIANCE CHECK (SHOW_VARIANCE IN (0,1)),
    CONSTRAINT CK_DATASOURCE_USE_PENDING CHECK (USE_PENDING IN (0,1)),
    CONSTRAINT CHK_DATAVIEW_INCL_PAR_REG CHECK (INCLUDE_PARENT_REGION_NAMES IN (0,1)),
    CONSTRAINT PK_DATAVIEW PRIMARY KEY (DATAVIEW_SID)
) ON COMMIT DELETE ROWS
;

@../imp_body.sql

@update_tail
