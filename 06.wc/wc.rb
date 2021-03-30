#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
#frozen_string_literal: true

require 'optparse'

class Wc
  def initialize(argv_array)
    # ファイルの行数、単語数、バイト数を標準出力に表示する
    @option_hash = { c: true, m: false, l: true, w: true }
    @files = argv_parse(argv_array)
    @buf = ""
  end

  # コマンドライン引数を受け取り、オプションはハッシュに格納し、残りは配列で返す
  def argv_parse(argv_array)
    # OptionParseオブジェクトoptを生成する
    opt = OptionParser.new
    # オプションを取り扱うブロックをoptに登録する
    opt.on('-c') { |v| v }
    opt.on('-m') { |v| v }
    opt.on('-l') { |v| v }
    opt.on('-w') { |v| v }
    # オプションをハッシュに格納し、残りのコマンドライン引数を配列で返す
    opt.order!(argv_array, into: @option_hash)
  end

  def wc
    # ファイルを開いて読み込み、オプションを適用し文字列を得る
    answer_string = file_io
    # 答えの文字列を表示し返す
    print answer_string
    answer_string
  end

  # ファイルを開いて読み込み、オプションを適用し閉じる
  def file_io
    begin
      File.open(@files[0], "r") do |file|
        # EOFまでの全てのデータをバイナリ読み込みメソッドとして読み込み、その文字列を返す
        @buf = file.read(nil)
      end
    # 例外処理
    rescue Errno::ENOENT => e
      "wc: #{@files[0]}: open: No such file or directory\n"
    rescue Errno::EISDIR => e
      "wc: #{@files[0]}: read: Is a directory\n"
    else
      # オプションを適用し、文字列を返す
      "#{apply_options} #{@files[0]}\n"
    end
  end

  # オプションを適用する
  def apply_options
    # 改行文字を数え、answer_stringに設定する
    apply_l_option if @option_hash[:l]
  end

  # l オプションを適用し、1文字のスペースと７桁の数字で返す
  def apply_l_option
    # 行数を数える
    n_lines = @buf.count("\n")
    n_lines.to_s.rjust(8)
  end
end

if __FILE__ == $PROGRAM_NAME
  wc = Wc.new(ARGV)
  wc.wc
end
