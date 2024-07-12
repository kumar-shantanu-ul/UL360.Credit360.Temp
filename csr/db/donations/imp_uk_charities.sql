-- http://opencharities.org/charities.csv.zip
-- The zipped file is checked in -- don't forget to unzip!
/*
Dear Richard,

Thank you for your email dated August 25th, 2011.  I can confirm that Crown copyright information taken from the Charities Commission may be re-used under the terms of the Open Government Licence (OGL)  The OGL is a free licence developed to enable freer use of government information and public sector information without the need for formal agreements or any registration transaction,  This licence replaces the Click-Use PSI Licence and takes the form of a simple set of terms and conditions for re-use and can be viewed at http://www.nationalarchives.gov.uk/doc/open-government-licence/open-government-licence.htm  

N.B. Please note, this licence does not cover material acknowledged to be the copyright of a third party.  If you wish to re-use third party copyrighted material, you have a legal obligation to contact the copyright holder for permission to do so.

I hope this information helps, but if you do have any questions, please feel free to get in touch with me again.


Yours sincerely



Judy 

Judy Nokes
Information Policy Adviser
 

Dragonfly House
2 Gilders Way
Norwich 
NR3 1UB
Tel:  01603 553223
Fax: 01603 553227

Open Government Licence and UK Government Licensing Framework launched 30 September 2010
*/
prompt Enter folder (e.g. \cvs\csr\db\donations)
define dir=&&1

connect system/manager@&_CONNECT_IDENTIFIER
-- *****************************************************************************************************
-- remember this folder must be on the SAME machine as the database to which you are uploading the data!
-- *****************************************************************************************************
create or replace directory charities_data as '&&dir';
grant read, write on directory charities_data to donations;

connect donations/donations@&_CONNECT_IDENTIFIER
-- AL32UTF8
CREATE TABLE charities_load (
	TITLE					VARCHAR2(255),
	CHARITY_NUMBER			VARCHAR2(40),
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
	CREATED_AT				VARCHAR2(255),
	UPDATED_AT				VARCHAR2(255)
) ORGANIZATION EXTERNAL (
	TYPE ORACLE_LOADER
	DEFAULT DIRECTORY charities_data
	ACCESS PARAMETERS (
		RECORDS DELIMITED BY 0x'0a'
		CHARACTERSET WE8ISO8859P1  
		BADFILE charities_data :'imp_uk_charities.bad'
		LOGFILE charities_data :'imp_uk_charities.log'
		FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
		LRTRIM
		MISSING FIELD VALUES ARE NULL
		(
			TITLE					CHAR(255),
			CHARITY_NUMBER			CHAR(40),
			ACTIVITIES				CHAR(4000),
			CONTACT_NAME			CHAR(255),
			ADDRESS					CHAR(255),
			WEBSITE					CHAR(255),
			TELEPHONE				CHAR(255),
			DATE_REGISTERED			DATE  "YYYY-MM-DD",
			DATE_REMOVED			DATE  "YYYY-MM-DD",
			ACCOUNTS_DATE			DATE  "YYYY-MM-DD",
			SPENDING,				
			INCOME,
			COMPANY_NUMBER			CHAR(255),
			OPENLYLOCAL_URL			CHAR(255),
			TWITTER_ACCOUNT_NAME	CHAR(255),
			FACEBOOK_ACCOUNT_NAME	CHAR(255),
			YOUTUBE_ACCOUNT_NAME	CHAR(255),
			CREATED_AT				CHAR(255),
			UPDATED_AT				CHAR(255)
        )
	)
	LOCATION ('uk_charities.csv')
) REJECT LIMIT UNLIMITED;

-- check that charity_number is distinct
-- select charity_number from ew_load group by charity_number having count(*) > 1;

INSERT INTO UK_CHARITY (
		TITLE,
		CHARITY_NUMBER,
		ACTIVITIES,
		CONTACT_NAME,
		ADDRESS,
		WEBSITE,
		TELEPHONE,
		DATE_REGISTERED,
		DATE_REMOVED,
		ACCOUNTS_DATE,
		SPENDING,
		INCOME,
		COMPANY_NUMBER,
		OPENLYLOCAL_URL,
		TWITTER_ACCOUNT_NAME,
		FACEBOOK_ACCOUNT_NAME,
		YOUTUBE_ACCOUNT_NAME,
		CREATED_AT,
		UPDATED_AT
	)
	SELECT
		TITLE,
		CHARITY_NUMBER,
		ACTIVITIES,
		CONTACT_NAME,
		ADDRESS,
		WEBSITE,
		TELEPHONE,
		DATE_REGISTERED,
		DATE_REMOVED,
		ACCOUNTS_DATE,
		SPENDING,
		INCOME,
		COMPANY_NUMBER,
		OPENLYLOCAL_URL,
		TWITTER_ACCOUNT_NAME,
		FACEBOOK_ACCOUNT_NAME,
		YOUTUBE_ACCOUNT_NAME,
		CAST(SYS_EXTRACT_UTC(TO_TIMESTAMP_TZ(CREATED_AT, 'yyyy-mm-dd"T"hh24:mi:ssTZH:TZM')) AS DATE),
		CAST(SYS_EXTRACT_UTC(TO_TIMESTAMP_TZ(UPDATED_AT, 'yyyy-mm-dd"T"hh24:mi:ssTZH:TZM')) AS DATE)
	FROM charities_load;

DROP TABLE charities_load PURGE;
DROP DIRECTORY charities_data;

quit
