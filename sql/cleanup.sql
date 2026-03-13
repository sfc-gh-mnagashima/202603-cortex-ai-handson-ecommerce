-- ============================================================
-- コスメECハンズオン クリーンアップスクリプト
-- セットアップで作成した全リソースを逆順で削除
-- ============================================================
USE ROLE ACCOUNTADMIN;

-- ============================================================
-- STEP 1: Cortex Agent の削除
-- ============================================================
DROP AGENT IF EXISTS COSME_EC_HANDSON.ANALYTICS.COSME_ANALYST_AGENT;
DROP AGENT IF EXISTS COSME_EC_HANDSON.ANALYTICS.COSME_EC_AGENT;

-- ============================================================
-- STEP 2: Semantic View の削除
-- ============================================================
DROP SEMANTIC VIEW IF EXISTS COSME_EC_HANDSON.ANALYTICS.FACT_ORDER_ANALYSIS;
DROP SEMANTIC VIEW IF EXISTS COSME_EC_HANDSON.ANALYTICS.FACT_REVIEW_ANALYSIS;
DROP SEMANTIC VIEW IF EXISTS COSME_EC_HANDSON.ANALYTICS.COSME_ANALYST;

-- ============================================================
-- STEP 3: Cortex Search Service の削除
-- ============================================================
DROP CORTEX SEARCH SERVICE IF EXISTS COSME_EC_HANDSON.ANALYTICS.FAQ_SEARCH;
DROP CORTEX SEARCH SERVICE IF EXISTS COSME_EC_HANDSON.ANALYTICS.PRODUCT_SEARCH;
DROP CORTEX SEARCH SERVICE IF EXISTS COSME_EC_HANDSON.ANALYTICS.REVIEW_SEARCH;
DROP CORTEX SEARCH SERVICE IF EXISTS COSME_EC_HANDSON.ANALYTICS.COSME_SEARCH_SERVICE;

-- ============================================================
-- STEP 4: ビューの削除
-- ============================================================
DROP VIEW IF EXISTS COSME_EC_HANDSON.ANALYTICS.SEARCH_DOCUMENTS;

-- ============================================================
-- STEP 5: AI処理結果テーブルの削除
-- ============================================================
DROP TABLE IF EXISTS COSME_EC_HANDSON.ANALYTICS.EVALS_TABLE;
DROP TABLE IF EXISTS COSME_EC_HANDSON.ANALYTICS.REVIEW_DETAILS;
DROP TABLE IF EXISTS COSME_EC_HANDSON.ANALYTICS.PRODUCTS_WITH_CATEGORY;

-- ============================================================
-- STEP 6: 生データテーブルの削除
-- ============================================================
DROP TABLE IF EXISTS COSME_EC_HANDSON.RAW.FAQ_DOCS;
DROP TABLE IF EXISTS COSME_EC_HANDSON.RAW.REVIEWS;
DROP TABLE IF EXISTS COSME_EC_HANDSON.RAW.INVENTORY;
DROP TABLE IF EXISTS COSME_EC_HANDSON.RAW.ORDER_ITEMS;
DROP TABLE IF EXISTS COSME_EC_HANDSON.RAW.ORDERS;
DROP TABLE IF EXISTS COSME_EC_HANDSON.RAW.CUSTOMERS;
DROP TABLE IF EXISTS COSME_EC_HANDSON.RAW.PRODUCTS;

-- ============================================================
-- STEP 7: ファイルフォーマットの削除
-- ============================================================
DROP FILE FORMAT IF EXISTS COSME_EC_HANDSON.RAW.CSV_FORMAT;
DROP FILE FORMAT IF EXISTS COSME_EC_HANDSON.RAW.JSON_FORMAT;

-- ============================================================
-- STEP 8: Git リポジトリの削除
-- ============================================================
DROP GIT REPOSITORY IF EXISTS COSME_EC_HANDSON.RAW.GIT_COSME_EC_HANDSON;

-- ============================================================
-- STEP 9: ステージの削除
-- ============================================================
DROP STAGE IF EXISTS COSME_EC_HANDSON.ANALYTICS.EVAL_CONFIG_STAGE;
DROP STAGE IF EXISTS COSME_EC_HANDSON.RAW.HANDSON_RESOURCES;

-- ============================================================
-- STEP 10: スキーマの削除
-- ============================================================
DROP SCHEMA IF EXISTS COSME_EC_HANDSON.ANALYTICS;
DROP SCHEMA IF EXISTS COSME_EC_HANDSON.RAW;

-- ============================================================
-- STEP 11: データベースの削除
-- ============================================================
DROP DATABASE IF EXISTS COSME_EC_HANDSON;

-- ============================================================
-- STEP 12: API Integration の削除
-- ============================================================
DROP API INTEGRATION IF EXISTS cosme_ec_git_api_integration;

-- ============================================================
-- STEP 13: Compute Pool の削除
-- ============================================================
DROP COMPUTE POOL IF EXISTS COSME_EC_COMPUTE_POOL;

-- ============================================================
-- STEP 14: ウェアハウスの削除
-- ============================================================
DROP WAREHOUSE IF EXISTS COSME_EC_WH;

-- ============================================================
-- STEP 15: クロスリージョン推論の設定をリセット
-- ============================================================
-- ALTER ACCOUNT UNSET CORTEX_ENABLED_CROSS_REGION;
