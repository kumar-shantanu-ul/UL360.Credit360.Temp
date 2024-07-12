CREATE OR REPLACE PACKAGE CHAIN.newsflash_pkg
IS

FUNCTION ChainNewsSummary RETURN CHAIN.T_NEWSFLASH_TABLE;

PROCEDURE GetNewsflashSummarySP
(
	out_sp OUT customer_options.newsflash_summary_sp%TYPE
);

PROCEDURE AddNewsflash
(
	in_content newsflash.content%TYPE,
	out_newsflash_id OUT newsflash.newsflash_id%TYPE
);

PROCEDURE RestrictNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_for_suppliers NUMBER DEFAULT 0,
	in_for_users NUMBER DEFAULT 0
);

PROCEDURE ExpireNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_expiry_dtm DATE DEFAULT SYSDATE
);

PROCEDURE ReleaseNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_release_dtm DATE DEFAULT SYSDATE
);

PROCEDURE GetNewsSummary
(
	out_news_summary_cur OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE HideNewsflashFromUser
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_user_sid newsflash_user_settings.user_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

END newsflash_pkg;
/
