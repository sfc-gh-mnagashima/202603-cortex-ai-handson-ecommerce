-- ============================================================
-- コスメECハンズオン セットアップスクリプト
-- データベース・ウェアハウス・スキーマの作成
-- GitHub連携 + CSVを取得し、7テーブルを作成
-- ============================================================
USE ROLE ACCOUNTADMIN;

-- ============================================================
-- STEP 1: クロスリージョン推論を有効化
--   Cortex AI関数を利用するために必要な設定
-- ============================================================
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- ============================================================
-- STEP 2: ウェアハウスの作成
-- ============================================================
CREATE WAREHOUSE IF NOT EXISTS COSME_EC_WH
    WAREHOUSE_SIZE = 'SMALL'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'コスメECハンズオン用ウェアハウス';

USE WAREHOUSE COSME_EC_WH;

-- ============================================================
-- STEP 3: データベースの作成
-- ============================================================
CREATE DATABASE IF NOT EXISTS COSME_EC_HANDSON
    COMMENT = 'Cortex AIハンズオン用コスメECサイトデータセット';

USE DATABASE COSME_EC_HANDSON;

-- ============================================================
-- STEP 4: スキーマの作成
-- ============================================================
CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = '生データ格納用スキーマ（CSV取り込み先）';

CREATE SCHEMA IF NOT EXISTS ANALYTICS
    COMMENT = '分析・AI処理結果格納用スキーマ';

-- ============================================================
-- STEP 5: API Integration の作成
-- ============================================================
CREATE OR REPLACE API INTEGRATION cosme_ec_git_api_integration
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-mnagashima/')
    ENABLED = TRUE
    COMMENT = 'コスメECハンズオン用 GitHub API Integration';

-- ============================================================
-- STEP 6: Git Repository の作成
-- ============================================================
CREATE OR REPLACE GIT REPOSITORY COSME_EC_HANDSON.RAW.GIT_COSME_EC_HANDSON
    API_INTEGRATION = cosme_ec_git_api_integration
    ORIGIN = 'https://github.com/sfc-gh-mnagashima/202603-cortex-ai-handson-ecommerce.git'
    COMMENT = 'コスメECハンズオン用 GitHub リポジトリ';

-- ============================================================
-- STEP 7: ステージの作成
-- ============================================================
USE SCHEMA RAW;

CREATE OR REPLACE STAGE COSME_EC_HANDSON.RAW.HANDSON_RESOURCES
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    COMMENT = 'ハンズオン資材用ステージ（CSVファイル格納）';

-- ============================================================
-- STEP 8: GitHubリポジトリからCSVをステージにコピー
-- ============================================================
COPY FILES INTO @COSME_EC_HANDSON.RAW.HANDSON_RESOURCES/csv/
    FROM @COSME_EC_HANDSON.RAW.GIT_COSME_EC_HANDSON/branches/main/csv/
    PATTERN = '.*\.csv$';

-- コピーされたファイルの確認
LIST @COSME_EC_HANDSON.RAW.HANDSON_RESOURCES/csv/;

-- ============================================================
-- STEP 9: CSVファイルフォーマットの作成
-- ============================================================
CREATE OR REPLACE FILE FORMAT COSME_EC_HANDSON.RAW.CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL')
    ENCODING = 'UTF8'
    COMMENT = 'CSV取り込み用フォーマット（ヘッダースキップ、UTF-8）';

-- ============================================================
-- STEP 10: 商品マスタ（PRODUCTS）
-- ============================================================
CREATE OR REPLACE TABLE COSME_EC_HANDSON.RAW.PRODUCTS (
    PRODUCT_ID    INT           NOT NULL  COMMENT '商品ID（主キー）',
    PRODUCT_NAME  VARCHAR(200)  NOT NULL  COMMENT '商品名',
    BRAND         VARCHAR(100)  NOT NULL  COMMENT 'ブランド名',
    PRICE         NUMBER(10,0)  NOT NULL  COMMENT '税込価格（円）',
    DESCRIPTION   VARCHAR(1000)           COMMENT '商品説明文',
    LAUNCH_DATE   DATE                    COMMENT '発売日',
    IS_ORGANIC    BOOLEAN                 COMMENT 'オーガニック認証の有無'
) COMMENT = '商品マスタ（コスメ商品の基本情報、カテゴリはAI_CLASSIFYで後付け）';

COPY INTO COSME_EC_HANDSON.RAW.PRODUCTS
FROM @COSME_EC_HANDSON.RAW.HANDSON_RESOURCES/csv/products.csv
FILE_FORMAT = (FORMAT_NAME = 'COSME_EC_HANDSON.RAW.CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- ============================================================
-- STEP 11: 顧客マスタ（CUSTOMERS）
-- ============================================================
CREATE OR REPLACE TABLE COSME_EC_HANDSON.RAW.CUSTOMERS (
    CUSTOMER_ID     INT           NOT NULL  COMMENT '顧客ID（主キー）',
    CUSTOMER_NAME   VARCHAR(100)  NOT NULL  COMMENT '顧客名',
    EMAIL           VARCHAR(200)  NOT NULL  COMMENT 'メールアドレス',
    AGE_GROUP       VARCHAR(20)             COMMENT '年代（10代/20代/30代/40代/50代以上）',
    PREFECTURE      VARCHAR(20)             COMMENT '都道府県',
    MEMBERSHIP_RANK VARCHAR(20)             COMMENT '会員ランク（レギュラー/シルバー/ゴールド/プラチナ）',
    REGISTERED_AT   DATE                    COMMENT '会員登録日'
) COMMENT = '顧客マスタ（会員情報・属性）';

COPY INTO COSME_EC_HANDSON.RAW.CUSTOMERS
FROM @COSME_EC_HANDSON.RAW.HANDSON_RESOURCES/csv/customers.csv
FILE_FORMAT = (FORMAT_NAME = 'COSME_EC_HANDSON.RAW.CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- ============================================================
-- STEP 12: 注文ヘッダ（ORDERS）
-- ============================================================
CREATE OR REPLACE TABLE COSME_EC_HANDSON.RAW.ORDERS (
    ORDER_ID            INT           NOT NULL  COMMENT '注文ID（主キー）',
    CUSTOMER_ID         INT           NOT NULL  COMMENT '顧客ID（外部キー→CUSTOMERS）',
    ORDER_DATE          DATE          NOT NULL  COMMENT '注文日',
    ORDER_STATUS        VARCHAR(20)   NOT NULL  COMMENT '注文ステータス（注文確定/決済完了/出荷準備中/配送中/配送済み/キャンセル/返品）',
    TOTAL_AMOUNT        NUMBER(10,0)  NOT NULL  COMMENT '合計金額（円、税込）',
    SHIPPING_FEE        NUMBER(10,0)  NOT NULL  COMMENT '送料（円、5500円以上で無料）',
    PAYMENT_METHOD      VARCHAR(30)             COMMENT '支払方法（クレジットカード/電子マネー/コンビニ払い/代引き）',
    SHIPPING_PREFECTURE VARCHAR(20)             COMMENT '配送先都道府県'
) COMMENT = '注文ヘッダ（注文ごとの概要情報）';

COPY INTO COSME_EC_HANDSON.RAW.ORDERS
FROM @COSME_EC_HANDSON.RAW.HANDSON_RESOURCES/csv/orders.csv
FILE_FORMAT = (FORMAT_NAME = 'COSME_EC_HANDSON.RAW.CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- ============================================================
-- STEP 13: 注文明細（ORDER_ITEMS）
-- ============================================================
CREATE OR REPLACE TABLE COSME_EC_HANDSON.RAW.ORDER_ITEMS (
    ORDER_ITEM_ID  INT           NOT NULL  COMMENT '明細ID（主キー）',
    ORDER_ID       INT           NOT NULL  COMMENT '注文ID（外部キー→ORDERS）',
    PRODUCT_ID     INT           NOT NULL  COMMENT '商品ID（外部キー→PRODUCTS）',
    QUANTITY       INT           NOT NULL  COMMENT '数量',
    UNIT_PRICE     NUMBER(10,0)  NOT NULL  COMMENT '購入時単価（円）',
    SUBTOTAL       NUMBER(10,0)  NOT NULL  COMMENT '小計（数量×単価）'
) COMMENT = '注文明細（注文内の各商品の情報）';

COPY INTO COSME_EC_HANDSON.RAW.ORDER_ITEMS
FROM @COSME_EC_HANDSON.RAW.HANDSON_RESOURCES/csv/order_items.csv
FILE_FORMAT = (FORMAT_NAME = 'COSME_EC_HANDSON.RAW.CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- ============================================================
-- STEP 14: 在庫（INVENTORY）
-- ============================================================
CREATE OR REPLACE TABLE COSME_EC_HANDSON.RAW.INVENTORY (
    PRODUCT_ID          INT           NOT NULL  COMMENT '商品ID（外部キー→PRODUCTS）',
    STOCK_QUANTITY      INT           NOT NULL  COMMENT '現在在庫数',
    REORDER_POINT       INT           NOT NULL  COMMENT '発注点（この数量を下回ったら補充が必要）',
    WAREHOUSE_LOCATION  VARCHAR(50)             COMMENT '保管倉庫（東京倉庫A棟/大阪倉庫B棟/福岡倉庫C棟）',
    LAST_RESTOCKED_AT   DATE                    COMMENT '最終入荷日'
) COMMENT = '在庫テーブル（商品ごとの現在在庫と保管場所）';

COPY INTO COSME_EC_HANDSON.RAW.INVENTORY
FROM @COSME_EC_HANDSON.RAW.HANDSON_RESOURCES/csv/inventory.csv
FILE_FORMAT = (FORMAT_NAME = 'COSME_EC_HANDSON.RAW.CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- ============================================================
-- STEP 15: 商品レビュー（REVIEWS）
-- ============================================================
CREATE OR REPLACE TABLE COSME_EC_HANDSON.RAW.REVIEWS (
    REVIEW_ID         INT            NOT NULL  COMMENT 'レビューID（主キー）',
    PRODUCT_ID        INT            NOT NULL  COMMENT '商品ID（外部キー→PRODUCTS）',
    CUSTOMER_ID       INT            NOT NULL  COMMENT '顧客ID（外部キー→CUSTOMERS）',
    ORDER_ID          INT            NOT NULL  COMMENT '注文ID（外部キー→ORDERS、配送済み注文のみ）',
    RATING            INT            NOT NULL  COMMENT '星評価（1〜5）',
    REVIEW_TEXT       VARCHAR(2000)  NOT NULL  COMMENT 'レビュー本文（日本語中心、一部英語・中国語）',
    REVIEW_DATE       DATE           NOT NULL  COMMENT '投稿日',
    HELPFUL_COUNT     INT                      COMMENT '「参考になった」の数'
) COMMENT = '商品レビュー（AI関数分析のメイン対象データ）';

COPY INTO COSME_EC_HANDSON.RAW.REVIEWS
FROM @COSME_EC_HANDSON.RAW.HANDSON_RESOURCES/csv/reviews.csv
FILE_FORMAT = (FORMAT_NAME = 'COSME_EC_HANDSON.RAW.CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- ============================================================
-- STEP 16: FAQドキュメント（FAQ_DOCS）
-- ============================================================
CREATE OR REPLACE TABLE COSME_EC_HANDSON.RAW.FAQ_DOCS (
    FAQ_ID        VARCHAR(10)    NOT NULL  COMMENT 'FAQ ID（主キー）',
    CATEGORY      VARCHAR(50)    NOT NULL  COMMENT 'FAQカテゴリ（返品・交換/配送/成分・アレルギー/スキンケア相談/ポイント・会員）',
    TITLE         VARCHAR(200)   NOT NULL  COMMENT 'ドキュメントタイトル',
    CONTENT       VARCHAR(2000)  NOT NULL  COMMENT '本文（Cortex Search / Agent での検索対象）',
    LAST_UPDATED  DATE                     COMMENT '最終更新日'
) COMMENT = 'FAQドキュメント（Cortex Search・Agent用ナレッジベース）';

COPY INTO COSME_EC_HANDSON.RAW.FAQ_DOCS
FROM @COSME_EC_HANDSON.RAW.HANDSON_RESOURCES/csv/faq_docs.csv
FILE_FORMAT = (FORMAT_NAME = 'COSME_EC_HANDSON.RAW.CSV_FORMAT')
ON_ERROR = 'CONTINUE';

-- ============================================================
-- STEP 17: データ確認サマリ
-- ============================================================
SELECT 'PRODUCTS'      AS "テーブル名", COUNT(*) AS "件数" FROM COSME_EC_HANDSON.RAW.PRODUCTS
UNION ALL
SELECT 'CUSTOMERS',     COUNT(*) FROM COSME_EC_HANDSON.RAW.CUSTOMERS
UNION ALL
SELECT 'ORDERS',        COUNT(*) FROM COSME_EC_HANDSON.RAW.ORDERS
UNION ALL
SELECT 'ORDER_ITEMS',   COUNT(*) FROM COSME_EC_HANDSON.RAW.ORDER_ITEMS
UNION ALL
SELECT 'INVENTORY',     COUNT(*) FROM COSME_EC_HANDSON.RAW.INVENTORY
UNION ALL
SELECT 'REVIEWS',       COUNT(*) FROM COSME_EC_HANDSON.RAW.REVIEWS
UNION ALL
SELECT 'FAQ_DOCS',      COUNT(*) FROM COSME_EC_HANDSON.RAW.FAQ_DOCS
ORDER BY "テーブル名";
