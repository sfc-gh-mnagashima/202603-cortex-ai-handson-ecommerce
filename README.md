# Cortex AI ハンズオン — コスメECサイト

Snowflake の Cortex AI 機能を使って、**コスメECサイトの売上・レビュー・在庫データを自然言語で分析できる AI エージェント**を一気通貫で構築するハンズオンです。

## ハンズオンの流れ

| Section | やること | 学べる Snowflake 機能 |
|:-------:|----------|----------------------|
| 1 | AI でRAWデータを拡張する | AI Functions（AI_CLASSIFY / AI_COMPLETE） |
| 2 | FAQ・商品・レビューの意味検索を可能にする | Cortex Search Service |
| 3 | データの意味を定義する（売上分析・レビュー分析） | Semantic View（Cortex Analyst） |
| 4 | AI エージェントを組み立てる | Cortex Agent |
| 5 | 動かしてみよう！ | Snowflake Intelligence |
| 6 | エージェントを評価する | Cortex Agent Evaluations |

> Section 1〜5 の詳細な解説・SQL は `handson_notebook.ipynb` に記載しています。
> Section 6（エージェント評価）の詳細は `eval/README.md` を参照してください。

## アーキテクチャ

```mermaid
graph TB
    %% ========== Layer 1: User ==========
    U((ユーザー))

    %% ========== Layer 2: Agent ==========
    subgraph AGENT["Section 4 — Cortex Agent"]
        Agent(COSME_ANALYST_AGENT)
    end

    %% ========== Layer 3: Analyst + Search ==========
    subgraph ANALYST["Section 3 — Cortex Analyst"]
        SV_ORDER(ORDER_ANALYST<br/>売上・在庫分析)
        SV_REVIEW(REVIEW_ANALYST<br/>レビュー分析)
    end

    subgraph SEARCH["Section 2 — Cortex Search"]
        CS_FAQ(FAQ_SEARCH)
        CS_PRODUCT(PRODUCT_SEARCH)
        CS_REVIEW(REVIEW_SEARCH)
    end

    %% ========== Layer 4: ANALYTICS ==========
    subgraph ANALYTICS["ANALYTICS スキーマ"]
        EP[PRODUCTS_WITH_CATEGORY]
        ERD[REVIEW_DETAILS]
    end

    %% ========== Layer 5: AI Pipeline ==========
    subgraph PIPELINE["Section 1 — AI Functions"]
        AI_CLASSIFY["AI_CLASSIFY<br/>カテゴリ自動分類"]
        AI_COMPLETE["AI_COMPLETE<br/>観点別感情分析"]
    end

    %% ========== Layer 6: RAW ==========
    subgraph RAW["RAW スキーマ"]
        ORDERS[ORDERS]
        ORDER_ITEMS[ORDER_ITEMS]
        PRODUCTS[PRODUCTS]
        CUSTOMERS[CUSTOMERS]
        INVENTORY[INVENTORY]
        REVIEWS[REVIEWS]
        FAQ[FAQ_DOCS]
    end

    %% ========== Edges: User <-> Agent (top-down) ==========
    U -->|自然言語で質問| Agent
    Agent -->|回答| U

    %% ========== Edges: Agent -> Tools (top-down) ==========
    Agent -->|Text-to-SQL| SV_ORDER
    Agent -->|Text-to-SQL| SV_REVIEW
    Agent -->|意味検索| CS_FAQ
    Agent -->|意味検索| CS_PRODUCT
    Agent -->|意味検索| CS_REVIEW

    %% ========== Edges: Tools -> ANALYTICS (top-down) ==========
    SV_ORDER -.-> EP
    SV_REVIEW -.-> ERD
    CS_PRODUCT -.-> EP
    CS_REVIEW -.-> ERD

    %% ========== Edges: ANALYTICS -> PIPELINE (top-down) ==========
    EP -.->|生成元| AI_CLASSIFY
    ERD -.->|生成元| AI_COMPLETE

    %% ========== Edges: PIPELINE -> RAW (top-down) ==========
    AI_CLASSIFY -.->|入力| PRODUCTS
    AI_COMPLETE -.->|入力| REVIEWS

    %% ========== Edges: Tools -> RAW (top-down, skip layers) ==========
    SV_ORDER -.-> ORDERS & ORDER_ITEMS & CUSTOMERS & INVENTORY
    SV_REVIEW -.-> REVIEWS & CUSTOMERS
    CS_FAQ -.-> FAQ

    %% ========== Styles ==========
    style U fill:#E3F2FD,stroke:#1565C0,stroke-width:2px,color:#0D47A1
    style Agent fill:#BBDEFB,stroke:#1565C0,stroke-width:2px,color:#0D47A1

    style SV_ORDER fill:#C8E6C9,stroke:#2E7D32,stroke-width:2px,color:#1B5E20
    style SV_REVIEW fill:#C8E6C9,stroke:#2E7D32,stroke-width:2px,color:#1B5E20

    style CS_FAQ fill:#E1BEE7,stroke:#6A1B9A,stroke-width:2px,color:#4A148C
    style CS_PRODUCT fill:#E1BEE7,stroke:#6A1B9A,stroke-width:2px,color:#4A148C
    style CS_REVIEW fill:#E1BEE7,stroke:#6A1B9A,stroke-width:2px,color:#4A148C

    style AI_CLASSIFY fill:#FFE0B2,stroke:#E65100,stroke-width:2px,color:#BF360C
    style AI_COMPLETE fill:#FFE0B2,stroke:#E65100,stroke-width:2px,color:#BF360C

    style EP fill:#FFF9C4,stroke:#F9A825,stroke-width:1px,color:#555
    style ERD fill:#FFF9C4,stroke:#F9A825,stroke-width:1px,color:#555

    style PRODUCTS fill:#F5F5F5,stroke:#9E9E9E,color:#555
    style CUSTOMERS fill:#F5F5F5,stroke:#9E9E9E,color:#555
    style ORDERS fill:#F5F5F5,stroke:#9E9E9E,color:#555
    style ORDER_ITEMS fill:#F5F5F5,stroke:#9E9E9E,color:#555
    style INVENTORY fill:#F5F5F5,stroke:#9E9E9E,color:#555
    style REVIEWS fill:#F5F5F5,stroke:#9E9E9E,color:#555
    style FAQ fill:#F5F5F5,stroke:#9E9E9E,color:#555

    style AGENT fill:#E3F2FD22,stroke:#1565C0,stroke-width:2px,stroke-dasharray:5 5
    style ANALYST fill:#C8E6C922,stroke:#2E7D32,stroke-width:2px,stroke-dasharray:5 5
    style SEARCH fill:#E1BEE722,stroke:#6A1B9A,stroke-width:2px,stroke-dasharray:5 5
    style PIPELINE fill:#FFE0B222,stroke:#E65100,stroke-width:2px,stroke-dasharray:5 5
    style ANALYTICS fill:#FFF9C422,stroke:#F9A825,stroke-width:1px,stroke-dasharray:5 5
    style RAW fill:#F5F5F522,stroke:#9E9E9E,stroke-width:1px,stroke-dasharray:5 5
```

## データセット

| テーブル | 件数 | 概要 |
|---------|------|------|
| PRODUCTS | 50 | 商品マスタ（5カテゴリ） |
| CUSTOMERS | 200 | 顧客マスタ（年代・都道府県・会員ランク） |
| ORDERS | 1,000 | 注文ヘッダ（2025/04〜2026/03） |
| ORDER_ITEMS | 3,638 | 注文明細 |
| INVENTORY | 50 | 在庫 |
| REVIEWS | 500 | 商品レビュー（日本語） |
| FAQ_DOCS | 30 | FAQドキュメント |
| EVALS_TABLE | 21 | エージェント評価用 Ground Truth データ |

## セットアップ手順

```sql
-- 1. 環境構築 + データ投入（評価データセット・評価設定ステージ含む）
-- sql/setup.sql を Snowsight SQL Worksheet で実行

-- 2. ハンズオン（Snowflake Workspace Notebook で実行）
-- handson_notebook.ipynb を Snowflake にインポートして Section 1〜6 を実行

-- 3. クリーンアップ（ハンズオン終了後）
-- sql/cleanup.sql を実行
```

## リポジトリ構成

```
.
├── README.md
├── handson_notebook.ipynb        -- ハンズオン本体（Section 1〜6）
├── csv/                          -- サンプルデータ（7テーブル分）
├── eval/
│   ├── README.md                    -- エージェント評価の詳細ドキュメント
│   ├── evals.json                   -- 評価用 Ground Truth データ（21件、JSON）
│   └── cosme_agent_eval_config.yaml -- 評価メトリクス設定（YAML）
└── sql/
    ├── setup.sql                 -- 環境構築 + データ投入 + 評価データセット
    └── cleanup.sql               -- 全リソース削除
```
