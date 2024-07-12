-- Please update version.sql too -- this keeps clean builds in sync
define version=37
@update_header


CREATE OR REPLACE TYPE T_BUDGET_ID_ROW AS OBJECT (
	BUDGET_ID		NUMBER(10),
	CAN_VIEW_ALL	NUMBER(1),
	CAN_VIEW_MINE	NUMBER(1)
);
/

CREATE OR REPLACE TYPE T_BUDGET_ID_TABLE AS TABLE OF T_BUDGET_ID_ROW;
/


@../donation_pkg
@../donation_body
@../budget_pkg
@../budget_body


@update_tail
