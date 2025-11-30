# SwiftShogi

[![Test](https://github.com/kk-no/SwiftShogi/actions/workflows/test.yml/badge.svg)](https://github.com/kk-no/SwiftShogi/actions/workflows/test.yml)
[![Swift Version](https://img.shields.io/badge/Swift-5.1+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

将棋のアプリケーション開発のために作られた Swift ライブラリです。  

## 基本的な使用方法

```swift
import SwiftShogi

// 初期局面を作成
let position = Position()

// USI形式で指し手を作成
if let move = position.createMove(from: "7g7f") {
    position.move(move)
}

// KIF形式の棋譜を読み込む
if let record = try? Kakinoki.importKIF(from: kifString) {
    // 棋譜を1手ずつ進める
    while record.goForward() {
        print(record.current.displayText)
    }
}
```

## 棋譜構造

棋譜は 1 手が 1 ノードとなるような木構造で表されています。  
前後の指し手は `next` プロパティと `prev` プロパティで相互に参照を持っています。  
分岐は兄弟ノードからの `branch` プロパティで参照されています。  

指し手を進めたり戻したりする場合は `Record.goForward()` や `Record.goBack()`、`Record.goto()` を使います。  
分岐は `Record.switchBranchByIndex()` で切り替えることができます。

## 対応フォーマット

- **KIF** - 伝統的な棋譜フォーマット（人間が読みやすい形式）
- **CSA** - コンピュータ将棋協会の標準フォーマット

## 主なデータ型

### `class Record`

棋譜を表すクラスです。分岐付きのKIF形式と同等の情報に加えて、現在の局面を管理します。

### `class RecordNode`

棋譜内の各指し手ノードを表すクラスです。次の手、前の手、分岐への参照を持ちます。

### `class Position`

局面を表すクラスです。盤面、駒台、手番などの情報を管理し、指し手の生成や実行を行います。

### `class Board`

盤面を表すクラスです。9×9のマスに配置された駒の情報を保持します。

### `class Hand`

駒台を表すクラスです。捕獲された持ち駒の情報を管理します。

### `struct Move`

指し手を表す構造体です。移動元、移動先、成り、取った駒などの情報を含みます。

### `enum Piece`

駒の種類を表す列挙型です。歩、香、桂、銀、金、角、飛、王とそれぞれの成駒を含みます。

### `enum Color`

手番を表す列挙型です。先手（black）と後手（white）を持ちます。

### `struct Square`

盤上のマス目を表す構造体です。筋（file: 1-9）と段（rank: 1-9）で位置を表現します。


## ライセンス

[MIT License](LICENSE)
