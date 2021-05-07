#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require 'optparse'
require_relative 'option'

# WCコマンドを再現するクラス
class Wc
  # Wcオブジェクトの作成
  def initialize
    @option = Option.new
    @files = []
    @answer_string = ''
  end

  # メインメソッド
  # ==== 引数
  # * +argv_array+ ARGVの配列
  # ==== 戻り値
  # * +answer_string+ 答えの文字列
  def main(argv_array)
    # コマンドライン引数をオプションとファイル配列にパースする。無効なオプションが指定されていなければ
    if argv_parse(argv_array)
      total = 0

      # コマンドライン引数にファイル名がない場合
      if @files.empty?
        # 標準入力かパイプから読み込み、オプションを適用し答えの文字列を得る
        count_stdin
      # コマンドライン引数にファイル名がある場合
      else
        # ファイルごとに
        @files.each do |file|
          # 各ファイルを開いて読み込み、オプションを適用し答えの文字列を得る
          count_file(file)
          total += 1
        end
      end
      # total の値を ＠answer_string に書き込む
      @answer_string += @option.write_total if total > 1
    end
    # 答えの文字列を表示し返す
    print @answer_string
    @answer_string
  end

  # コマンドライン引数をパースするメソッド
  # ==== 引数
  # * +argv_array+ ARGVの配列
  # ==== 戻り値
  # * +boolean+ 無効なオプションが指定されていれば+false+、指定されていなければ+true+
  def argv_parse(argv_array)
    # OptionParseオブジェクトoptを生成する
    opt = OptionParser.new
    # オプションを取り扱うブロックをoptに登録し、オプションインスタンスを介しハッシュに格納する
    opt.on('-l') { @option.option_hash[:l] = true }
    opt.on('-w') { @option.option_hash[:w] = true }
    opt.on('-c') { @option.option_hash[:c] = true, @option.option_hash[:m] = false }
    opt.on('-m') { @option.option_hash[:m] = true, @option.option_hash[:c] = false }
    begin
      # 残りのコマンドライン引数を配列に入れる
      @files = opt.order(argv_array)
      # オプションが指定されていない場合、デフォルトで行数、単語数、バイト数を表示するようオプションインスタンスを介して設定する
      @option.set_option_default
    # 無効なオプションが指定されていた場合
    rescue OptionParser::ParseError => e
      @answer_string += "wc: illegal option -- #{e.args[0][1]}\nusage: wc [-clmw] [file ...]\n"
      return false
    end
    true
  end

  # 標準入力を読み込み、オプションを適用し答えの文字列を設定するメソッド
  def count_stdin
    # 標準入力から、EOF(Ctrl＋Dが押される)まで文字列を読み込む
    buf = $stdin.read

    # 各オプションを適用し、得られた文字列を答えの文字列に加える
    @answer_string += @option.apply_option(buf)
    # 最後に改行する
    @answer_string += "\n"
  end

  # 各ファイルを開いて読み込み、オプションを適用し答えの文字列を設定するメソッド
  # ==== 引数
  # * +file+ ファイル名
  def count_file(file)
    buf = ''

    begin
      # ファイルを読み込みモードで開く
      File.open(file, 'r') do |f|
        # EOFまでの全てのデータを読み込み、文字列を得る
        buf = f.read
      end
    # 例外処理
    rescue Errno::ENOENT
      @answer_string += "wc: #{file}: open: No such file or directory\n"
    rescue Errno::EISDIR
      @answer_string += "wc: #{file}: read: Is a directory\n"
    else
      # 各オプションを適用し、得られた文字列を答えの文字列に加える
      @answer_string += @option.apply_option(buf)
      # 最後にファイル名を付け改行する
      @answer_string += " #{file}\n"
    end
  end
end

# スクリプトをシェルから実行した時のみに評価される
if __FILE__ == $PROGRAM_NAME
  # メインルーチン
  wc = Wc.new
  wc.main(ARGV)
end
