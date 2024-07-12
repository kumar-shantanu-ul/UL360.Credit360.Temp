-- Please update version.sql too -- this keeps clean builds in sync
define version=2293
@update_header

INSERT INTO csr.capability VALUES('Hide year on chart axis labels when chart has FlyCalc', 0);

@update_tail
