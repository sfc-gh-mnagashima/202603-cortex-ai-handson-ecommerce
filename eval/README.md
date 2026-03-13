# Cortex Agent Evaluations — エージェント評価

[Cortex Agent Evaluations](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-evaluations) を使って、エージェントの品質を定量的に測定します。

## 評価メトリクス

| メトリクス | 種別 | 説明 |
|-----------|------|------|
| Answer Correctness | ビルトイン | エージェント回答の正確性 |
| Logical Consistency | ビルトイン | 回答の論理的一貫性 |
| Groundedness | カスタム | 回答がツール出力のエビデンスに基づいているか |
| Execution Efficiency | カスタム | ツール呼び出しの効率性（冗長な呼び出しがないか） |
| Tool Selection | カスタム | 適切なツールが選択されているか |

## 評価ワークフロー

```
1. 評価データセット作成    →  Ground Truth（正解データ）を含む質問セット
2. YAML 設定ファイル確認   →  メトリクス定義（ビルトイン + カスタム LLM Judge）
3. 評価実行              →  EXECUTE_AI_EVALUATION でエージェントを評価
4. 結果確認              →  GET_AI_EVALUATION_DATA またはSnowsight UI で確認
```

ノートブック（`handson_notebook.ipynb` Section 6）で上記ワークフローを実行できます。

## ファイル構成

| ファイル | 説明 |
|---------|------|
| `evals.json` | 評価用 Ground Truth データ（21件）。FAQ 4件、商品検索 2件、注文分析 6件、レビュー分析 4件、複合 5件 |
| `cosme_agent_eval_config.yaml` | 評価メトリクス設定。ビルトイン 2 種 + カスタム 3 種（日本語プロンプト） |

## Ground Truth データの構造

```json
{
  "INPUT_QUERY": "返品・交換のポリシーについて教えてください。",
  "GROUND_TRUTH_DATA": {
    "ground_truth_invocations": [
      {"tool_name": "cortex_search", "service": "FAQ_SEARCH"}
    ],
    "ground_truth_output": "商品到着後7日以内であれば..."
  }
}
```

- `ground_truth_invocations`: 期待されるツール呼び出し（tool_name + service）
- `ground_truth_output`: 期待される回答内容

## 改善サイクル（応用）

評価結果を基にエージェントを改善し、再評価で効果を検証できます：

1. **ベースライン評価**: 現在のエージェント構成でスコアを取得
2. **エージェント改善**: `ALTER AGENT ... MODIFY LIVE VERSION SET SPECIFICATION` でオーケストレーション指示・ツール説明を強化
3. **改善版評価**: 同じデータセットで再評価
4. **結果比較**: Snowsight UI（AI & ML > Agents > Evaluations タブ）で 2 つのランを並べて比較

## 参考リンク

- [Getting Started with Cortex Agent Evaluations（クイックスタートガイド）](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agent-evaluations/)
- [Cortex Agent Evaluations ドキュメント](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-evaluations)
