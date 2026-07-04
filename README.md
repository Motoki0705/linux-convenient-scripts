# Linux Convenient Scripts

日常的なLinux作業を便利にするためのシェルスクリプト集です。

## スクリプト一覧

### `claude-bg.sh`
Claude Codeのバックグラウンドセッションを簡単に立ち上げるためのスクリプトです。

**使用例:**
```bash
# 基本的な使い方
./claude-bg.sh --name <session-name> --query "<request>"

# aliasを設定しての使用例 (例: ccb)
ccb --name fix-tests --model fable --effort high --query "pytestを実行し、失敗を修正してください。"
```

## セットアップ
各スクリプトに実行権限を付与し、必要に応じて `.bashrc` や `.zshrc` などでエイリアスを設定して使用してください。
