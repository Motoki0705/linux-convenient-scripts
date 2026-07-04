# Linux Convenient Scripts

日常的なLinux作業を便利にするためのシェルスクリプト集です。

## ディレクトリ構成

- `agents/`: AIエージェント (Claude, Codex) のバックグラウンド実行用スクリプトを格納
- `install_aliases.sh`: 本リポジトリのスクリプト群を簡単に呼び出せるよう、エイリアスを一括登録するセットアップスクリプト

## スクリプト一覧

### `agents/claude-bg.sh` (Alias: `ccb`)
Claude Codeのバックグラウンドセッションを簡単に立ち上げるためのスクリプトです。

**使用例:**
```bash
ccb --name fix-tests --model fable --effort high --query "pytestを実行し、失敗を修正してください。"
```

### `agents/codex-bg.sh` (Alias: `codexb`)
Codex CLIをバックグラウンドで非対話的に実行するためのスクリプトです。

**使用例:**
```bash
codexb --name refactor --model gpt-5.4 --effort xhigh -s workspace-write -a never -q "src以下を整理してください"
```

## その他登録されるエイリアス
`install_aliases.sh` を実行すると、AI系スクリプト以外にも以下のエイリアスが合わせて登録されます。
- `cc` : `claude code`
- `wns` : `watch -t nvidia-smi`

## セットアップ方法 (新しい環境への導入)

別のPCや新しい環境に導入する場合は、以下の手順を実行するだけでエイリアスの設定まで一括で完了します。

```bash
# 1. リポジトリのクローン
git clone git@github.com:Motoki0705/linux-convenient-scripts.git ~/scripts
cd ~/scripts

# 2. エイリアスの一括インストール
./install_aliases.sh

# 3. シェルの設定を再読み込み (Bashの場合)
source ~/.bashrc
```
