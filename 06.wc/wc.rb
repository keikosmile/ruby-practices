#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require 'optparse'
require_relative 'option'

class Wc
  def initialize
    @option = Option.new
    @files = []
    @answer_string = ''
  end

  def wc(argv_array)
    # コマンドライン引数をオプションとファイル配列にパースする。無効なオプションが指定されていなければ
    if argv_parse(argv_array)
      total = 0

      # コマンドライン引数にファイル名がない場合
      if @files.empty?
        # 標準入力かパイプから読み込み、オプションを適用し答えの文字列を得る
        @answer_string += "\n" if count_file(nil)
      # コマンドライン引数にファイル名がある場合
      else
        # ファイルごとに
        @files.each do |file|
          # ファイルを開いて読み込み、オプションを適用し答えの文字列を得る
          @answer_string += " #{file}\n" if count_file(file)
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

  # コマンドライン引数を受け取り、オプションはハッシュに格納し、残りは配列に入れ空文字列を返す
  def argv_parse(argv_array)
    # OptionParseオブジェクトoptを生成する
    opt = OptionParser.new
    # オプションを取り扱うブロックをoptに登録し、ハッシュに格納する
    opt.on('-l') { @option.option_hash[:l] = true }
    opt.on('-w') { @option.option_hash[:w] = true }
    opt.on('-c') { @option.option_hash[:c] = true, @option.option_hash[:m] = false }
    opt.on('-m') { @option.option_hash[:m] = true, @option.option_hash[:c] = false }
    # 残りのコマンドライン引数を配列に入れる
    begin
      @files = opt.order(argv_array)
      # オプションが指定されていない場合、デフォルトで行数、単語数、バイト数を表示する
      @option.option_hash = { l: true, w: true, c: true } if @option.option_hash == { l: false, w: false, c: false, m: false }
    # 無効なオプションが指定されていた場合
    rescue OptionParser::ParseError => e
      @answer_string += "wc: illegal option -- #{e.args[0][1]}\nusage: wc [-clmw] [file ...]\n"
      return false
    end
    true
  end

  # ファイルを開いて読み込み、オプションを適用し閉じる
  def count_file(file)
    buf = ''

    if file.nil?
      # 標準入力から、EOF(Ctrl＋Dが押される)まで文字列を読み込む
      buf = $stdin.read
    else
      begin
        # ファイルを読み込みモードで開く
        File.open(file, 'r') do |f|
          # EOFまでの全てのデータを読み込み、文字列を得る
          buf = f.read
        end
      # 例外処理
      rescue Errno::ENOENT
        @answer_string += "wc: #{file}: open: No such file or directory\n"
        return false
      rescue Errno::EISDIR
        @answer_string += "wc: #{file}: read: Is a directory\n"
        return false
      end
    end

    # オプションを適用し、文字列を得る
    @answer_string += @option.apply_option(buf)
    true
    # apply_option(buf)
  end
end

# スクリプトをシェルから実行した時のみに評価される
if __FILE__ == $PROGRAM_NAME
  # メインルーチン
  wc = Wc.new
  wc.wc(ARGV)
end
