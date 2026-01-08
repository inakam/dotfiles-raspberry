#!/bin/bash
# ~/.claude/scripts/auto-format.sh
#
# ファイルの拡張子に応じて適切なフォーマッターを自動で実行するスクリプト

# 標準入力からJSONを読み込む
INPUT=$(cat)

# jqを使ってファイルパスを抽出
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# ファイルパスが取得できなかった場合はエラー終了
if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" == "null" ]; then
  exit 2
fi

# ファイルが存在しない場合は終了
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# ファイルの拡張子に応じて処理を分岐
case "$FILE_PATH" in
  *.go)
    # Go言語のフォーマット
    if command -v gofmt &> /dev/null; then
      gofmt -w "$FILE_PATH"
    else
      echo "警告: gofmtコマンドが見つかりません。Go言語のフォーマットをスキップします。" >&2
    fi
    ;;

  *.py)
    # Pythonのフォーマット (ruffを使用)
    if command -v ruff &> /dev/null; then
      ruff check "$FILE_PATH" --fix
      ruff format "$FILE_PATH"
    else
      echo "警告: ruffコマンドが見つかりません。Pythonのフォーマットをスキップします。" >&2
    fi
    ;;

  *.js|*.jsx|*.ts|*.tsx|*.json|*.md)
    # JavaScript, TypeScript, JSON, Markdownのフォーマット (prettierを使用)
    if command -v prettier &> /dev/null; then
      # --ignore-unknown オプションで未対応の拡張子を無視する
      prettier --write "$FILE_PATH" --ignore-unknown
    else
      echo "警告: prettierコマンドが見つかりません。フォーマットをスキップします。" >&2
    fi
    ;;
esac

exit 0
