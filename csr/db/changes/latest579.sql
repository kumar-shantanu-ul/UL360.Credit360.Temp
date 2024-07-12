-- Please update version.sql too -- this keeps clean builds in sync
define version=579
@update_header

drop table TEMP_IND_TREE;

CREATE GLOBAL TEMPORARY TABLE TEMP_IND_TREE
(
    APP_SID                       NUMBER(10, 0),
    IND_SID                       NUMBER(10, 0),
    PARENT_SID                    NUMBER(10, 0),
    DESCRIPTION                   VARCHAR2(1023),
    IND_TYPE                      NUMBER(10, 0),
    MEASURE_SID                   NUMBER(10, 0),
    MEASURE_DESCRIPTION			  VARCHAR2(255),
    FORMAT_MASK					  VARCHAR2(255),
    ACTIVE                        NUMBER(10, 0)
) ON COMMIT DELETE ROWS;

@../scenario_body

@update_tail
