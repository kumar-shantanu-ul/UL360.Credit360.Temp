-- Please update version.sql too -- this keeps clean builds in sync
define version=62
@update_header

CREATE TABLE donations.UK_CHARITY (
	TITLE					VARCHAR2(255) NOT NULL,
	CHARITY_NUMBER			VARCHAR2(40) NOT NULL,
	ACTIVITIES				VARCHAR2(4000),
	CONTACT_NAME			VARCHAR2(255),
	ADDRESS					VARCHAR2(255),
	WEBSITE					VARCHAR2(255),
	TELEPHONE				VARCHAR2(255),
	DATE_REGISTERED			DATE,
	DATE_REMOVED			DATE,
	ACCOUNTS_DATE			DATE,
	SPENDING				NUMBER(10),
	INCOME					NUMBER(10),
	COMPANY_NUMBER			VARCHAR2(255),
	OPENLYLOCAL_URL			VARCHAR2(255),
	TWITTER_ACCOUNT_NAME	VARCHAR2(255),
	FACEBOOK_ACCOUNT_NAME	VARCHAR2(255),
	YOUTUBE_ACCOUNT_NAME	VARCHAR2(255),
	CREATED_AT				DATE NOT NULL,
	UPDATED_AT				DATE NOT NULL,
	CONSTRAINT PK_UK_CHARITY PRIMARY KEY (CHARITY_NUMBER)
);


@update_tail
