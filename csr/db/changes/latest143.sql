-- Please update version.sql too -- this keeps clean builds in sync
define version=143
@update_header

/*
GEO_TYPE
0 for location
1 for country
2 for region
*/
ALTER TABLE REGION 
ADD (   
        GEO_TYPE                    NUMBER,
        GEO_CODE                    VARCHAR(10),
        GEO_LATITUDE                NUMBER,
        GEO_LONGITUDE               NUMBER
    );

@update_tail
