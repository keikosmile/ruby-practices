#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
#frozen_string_literal: true

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
      # ファイルごとに
      @files.each do |file|
        # ファイルを開いて読み込み、オプションを適用し答えの文字列を得る
        @answer_string += " #{file}\n" if count_file(file)
        total += 1
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
      @files = opt.parse(argv_array)
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
    begin
      File.open(file, "r") do |f|
        # EOFまでの全てのデータを読み込み、その文字列を返す
        buf = f.read
      end
    # 例外処理
    rescue Errno::ENOENT
      @answer_string += "wc: #{file}: open: No such file or directory\n"
      return false
    rescue Errno::EISDIR
      @answer_string += "wc: #{file}: read: Is a directory\n"
      return false
    # 正常にファイルを開ければ
    else
      # オプションを適用し、文字列を得る
      apply_l_option(buf) if @option_hash[:l]
      apply_w_option(buf) if @option_hash[:w]
      apply_c_option(buf) if @option_hash[:c]
      apply_m_option(buf) if @option_hash[:m]
      return true
    end
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
    # 単語数を数える（@bufが不正なバイト列を含む場合?に置き換える）
    # 空白文字（半角スペース、タブ、改行文字）で区切る
    #@buf.bytes
    n_word = buf.scrub.split.count
    @answer_string += n_word.to_s.rjust(8)
    @total_hash[:w] += n_word
  end

  # c オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_c_option(buf)
    # バイト数を数える
    n_bytesize = buf.bytesize
    @answer_string += n_bytesize.to_s.rjust(8)
    @total_hash[:c] += n_bytesize
  end

  # m オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_m_option(buf)
    # 文字数を数える（マルチバイト文字1文字も1文字として返す）
    n_size = buf.size
    @answer_string += n_size.to_s.rjust(8)
    @total_hash[:m] += n_size
  end
end

if __FILE__ == $PROGRAM_NAME
  wc = Wc.new
  wc.wc(ARGV)
end
