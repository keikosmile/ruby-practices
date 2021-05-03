#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
#frozen_string_literal: true1
require 'optparse'

class Wc
  def initialize
    @option_hash = { l: false, w: false, c: false, m: false }
    @files = []
    @answer_string = ""
    @total_hash = {l: 0, w: 0, c: 0, m: 0 }
  end

  def wc(argv_array)
    # コマンドライン引数をオプションとファイル配列にパースする
    argv_parse(argv_array)
    # 無効なオプションが指定されていなければ
    if @answer_string.empty?
      total = 0

      if @files.empty?
        @answer_string += "\n" if count_file(nil)
      else
        # ファイルごとに
        @files.each do |file|
          # ファイルを開いて読み込み、オプションを適用し答えの文字列を得る
          @answer_string += " #{file}\n" if count_file(file)
          total += 1
        end
      end
      if total > 1
        @answer_string += @total_hash[:l].to_s.rjust(8) if @option_hash[:l]
        @answer_string += @total_hash[:w].to_s.rjust(8) if @option_hash[:w]
        @answer_string += @total_hash[:c].to_s.rjust(8) if @option_hash[:c]
        @answer_string += @total_hash[:m].to_s.rjust(8) if @option_hash[:m]
        @answer_string += " total\n"
      end
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
    opt.on('-l') { |v| @option_hash[:l] = true }
    opt.on('-w') { |v| @option_hash[:w] = true }
    opt.on('-c') { |v| @option_hash[:c] = true, @option_hash[:m] = false }
    opt.on('-m') { |v| @option_hash[:m] = true, @option_hash[:c] = false }
    # 残りのコマンドライン引数を配列に入れる
    begin
      @files = opt.order(argv_array)
      # オプションが指定されていない場合、デフォルトで行数、単語数、バイト数を表示する
      if @option_hash == { l: false, w: false, c: false, m: false }
        @option_hash = { l: true, w: true, c: true }
      end
    # 無効なオプションが指定されていた場合
    rescue => e
      @answer_string += "wc: illegal option -- #{e.args[0][1]}\nusage: wc [-clmw] [file ...]\n"
    end
  end

  # ファイルを開いて読み込み、オプションを適用し閉じる
  def count_file(file)
    buf = ""

    if file.nil?
      # 標準入力から、EOF(Ctrl＋Dが押される)まで文字列を読み込む
      buf = $stdin.read
    else
      begin
        # ファイルを読み込みモードで開く
        File.open(file, "r") do |f|
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
    apply_l_option(buf) if @option_hash[:l]
    apply_w_option(buf) if @option_hash[:w]
    apply_c_option(buf) if @option_hash[:c]
    apply_m_option(buf) if @option_hash[:m]
    return true
  end

  # l オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_l_option(buf)
    # 行数を数える（@bufが不正なバイト列を含む場合?に置き換える）
    n_line = buf.scrub.count("\n")
    @answer_string += n_line.to_s.rjust(8)
    @total_hash[:l] += n_line
  end

  # w オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_w_option(buf)
    # 文字列がascii文字だけの場合
    if buf.ascii_only?
      n_word = buf.split.count
    else
      # 空白文字
      # 空白    ' ' : 0x20
      # 改頁    \f  : 0x0C
      # 改行    \n  : 0xA
      # 復帰    \r  : 0x0D
      # 水平タブ \t  : 0x09
      # 垂直タブ \v  : 0x0B
      # ノーブレークスペース  : 0x85
      wspace_array = ["20", "0C", "A", "0D", "09", "0B", "85"]

      # 文字列をUTF-8で符号化しバイト単位に分割、16進数表記に変換する
      buf_array = buf.bytes.map { |b|
        b.to_s(16).upcase
      }
      # 空白文字で区切られた単語数を数える
      word_flag = 1
      n_word = 0
      buf_array.each { |b|
        if wspace_array.include?(b)
          word_flag = 1;
        elsif word_flag == 1
          word_flag = 0;
          n_word += 1
        end
      }
    end
    @answer_string += n_word.to_s.rjust(8)
    @total_hash[:w] += n_word
  end

  # c オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_c_option(buf)
    # バイト数を数える（文字列のバイト長を整数で返す）
    n_bytesize = buf.bytesize
    @answer_string += n_bytesize.to_s.rjust(8)
    @total_hash[:c] += n_bytesize
  end

  # m オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_m_option(buf)
    # 文字数を数える（マルチバイト文字1文字を1文字と数える）
    n_size = buf.size
    @answer_string += n_size.to_s.rjust(8)
    @total_hash[:m] += n_size
  end
end

# スクリプトをシェルから実行した時のみに評価される
if __FILE__ == $PROGRAM_NAME
  # メインルーチン
  wc = Wc.new
  wc.wc(ARGV)
end
