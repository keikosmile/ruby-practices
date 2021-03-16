#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require 'optparse'
require 'io/console/size'
require_relative 'long_format_file'

class Ls
  def initialize(argv_array)
    # オプションをハッシュに格納し、残りのコマンドライン引数を配列に格納する
    @option_hash = { a: false, l: false, r: false }
    @wildcard_file_directory_array = argv_parse(argv_array)

    @not_match_wildcard_array = []
    @not_match_file_array = []
    @wildcard_file_array = []
    @directory_array = []
    # オプション以外のコマンドライン引数は空か
    if @wildcard_file_directory_array.empty?
      @directory_array.push('./')
    # オプション以外のコマンドライン引数を、ディレクトリ・ワイルドカード・ファイルの配列に分ける
    else
      separate_wildcard_file_directory_array
    end

    @answer_string = ''
    @console_width = IO.console_size.last
    @tabsize = 8
  end

  # オプションをハッシュに格納し、残りのコマンドライン引数を配列で返す
  def argv_parse(argv_array)
    # OptionParserオブジェクトoptを生成する
    opt = OptionParser.new
    # オプションを取り扱うブロックをoptに登録する
    opt.on('-a') { |v| v }
    opt.on('-l') { |v| v }
    opt.on('-r') { |v| v }
    # オプションをハッシュに格納し、残りのコマンドライン引数を配列で返す
    opt.order!(argv_array, into: @option_hash)
  end

  # ワイルドカードをマッチする配列とマッチしない配列に分ける
  def separate_wildcard_array(wildcard_string)
    file_array = Dir.glob(wildcard_string)
    # ワイルドカードがマッチしないなら
    if file_array.empty?
      @not_match_wildcard_array.push(wildcard_string)
    # ワイルドカードがマッチするなら
    else
      @wildcard_file_array.push(file_array)
    end
  end

  # オプション以外のコマンドライン引数を、ディレクトリ・ワイルドカード・ファイルの配列に分ける
  def separate_wildcard_file_directory_array
    @wildcard_file_directory_array.each do |i|
      # ディレクトリなら
      if FileTest.directory?(i)
        @directory_array.push(i)
      # ワイルドカードなら
      elsif i.include?('*') || i.include?('?') || (i.include?('[') && i.include?(']')) || (i.include?('{') && i.include?('}')) || i.include?('**/')
        # ワイルドカードをマッチする配列とマッチしない配列に分ける
        separate_wildcard_array(i)
      # ファイルなら
      elsif FileTest.exist?(i)
        @wildcard_file_array.push(i)
      # 存在しないファイルかディレクトリなら
      else
        @not_match_file_array.push(i)
      end
    end
  end

  # ファイルかディレクトリの配列にオプションを適用し、適用後の配列を返す
  def apply_options(directory_file_array, dir)
    # . ./ .. .xx ./.xx ../.xx ../../../.xx などを除かずに残す
    unless @option_hash[:a]
      directory_file_array.delete_if do |f|
        f.eql?('.') || f.eql?('./') || f.eql?('..') || File.basename(f).start_with?('.')
      end
    end

    directory_file_array.sort!
    directory_file_array.reverse! if @option_hash[:r]

    if @option_hash[:l]
      long_format_file_array = []
      # ロングフォーマット形式ファイルのインスタンスを作成し、配列に挿入する
      directory_file_array.each do |file|
        dir = './' if dir == '.'
        long_format_file_array.push(LongFormatFile.new(dir, file))
      end

      # ロングフォーマット形式ファイル毎の各インスタンス変数のlengthを得て、最高幅を決める
      max_nlink = max_username = max_groupname = max_size = total = 0
      long_format_file_array.each do |long|
        max_nlink = (long.nlink.length > max_nlink ? long.nlink.length : max_nlink)
        max_username = (long.username.length > max_username ? long.username.length : max_username)
        max_groupname = (long.groupname.length > max_groupname ? long.groupname.length : max_groupname)
        max_size = (long.size.length > max_size ? long.size.length : max_size)
        total += long.blocks
      end
      @answer_string += "total #{total}\n" unless dir.empty?

      # 最高幅に合わせて、右寄せ・左寄せする
      long_format_file_array.each do |long|
        long.set_string_width(max_nlink, max_username, max_groupname, max_size)
      end

      # ロングフォーマットファイル形式の文字列を得て、入れ替える
      directory_file_array.each_with_index do |file, idx|
        file.replace(long_format_file_array[idx].long_format_file)
      end
    end
    directory_file_array
  end

  # ASCII文字を1文字、非ASCII文字（マルチバイト文字）を2文字としてカウントし、文字列の長さを返す
  def ascii_width(string)
    string.length + string.chars.count { |c| !c.ascii_only? }
  end

  # 画面の大きさに合わせてディレクトリかファイルを列表示するよう文字列（@answer_string)を設定する
  def get_answer_string(directory_file_array)
    # 最長要素の長さ + \t = １列の長さ
    max_directory_file = 0
    directory_file_array.each do |directory_file|
      tab_times = ascii_width(directory_file) / @tabsize
      directory_file_tab_length = @tabsize * (tab_times + 1)
      max_directory_file = directory_file_tab_length > max_directory_file ? directory_file_tab_length : max_directory_file
    end

    # @console_width / １列の長さ = 列数
    columns = @console_width / max_directory_file
    columns = (directory_file_array.count < columns ? directory_file_array.count : columns)

    # 要素数 / 列数 = 行数 (余がでたら繰り上がる)
    rows = directory_file_array.count / columns
    modulo = directory_file_array.count % columns
    rows += (modulo.zero? ? 0 : 1)

    # 最小限の行数になった上で、改めて列数を計算
    columns = directory_file_array.count / rows

    directory_file_array.each do |directory_file|
      remainder = max_directory_file - ascii_width(directory_file)
      tab_times = remainder / @tabsize
      tab_remainder = remainder % @tabsize
      tab_times += 1 if tab_remainder != 0
      tmp = directory_file + "\t" * tab_times
      directory_file.replace(tmp)
    end

    r = 0
    while r < rows
      answer_array = []
      c = 0
      while c <= columns
        directory_file = directory_file_array[r + rows * c]
        answer_array.push(directory_file) unless directory_file.nil?
        c += 1
      end
      # 最後にpushした要素の\t\t..を\nに変換する
      last = answer_array.last.delete!("\t")
      answer_array.last.replace("#{last}\n")
      @answer_string += answer_array.join
      r += 1
    end
  end

  # ディレクトリ内のディレクトリかファイルを配列で得て返す
  def get_directory_file_array(dir)
    directory_file_array = []
    Dir.foreach(dir) do |directory_file_string|
      directory_file_array.push(directory_file_string)
    end
    directory_file_array
  end

  def ls
    # マッチしないワイルドカードがあれば、それを表示し終了
    unless @not_match_wildcard_array.empty?
      @answer_string = "zsh: no matches found: #{@not_match_wildcard_array[0]}\n"
      print @answer_string
      return @answer_string
    end

    # マッチしないファイルかディレクトリがあれば、それを表示
    unless @not_match_file_array.empty?
      @not_match_file_array.sort!
      @not_match_file_array.each do |file|
        @answer_string += "ls: #{file}: No such file or directory\n"
      end
    end

    # マッチするワイルドカードかファイルがあれば、それらを１行で表示
    unless @wildcard_file_array.empty?
      # 配列を一重にする
      @wildcard_file_array.flatten!
      # ファイルの配列にオプションを適用し、適用後の配列を返す
      file_array = apply_options(@wildcard_file_array, '')
      # lオプションがあれば、ファイルごとに１行で表示するよう文字列(@answer_string)を設定する
      if @option_hash[:l]
        @answer_string += "#{file_array.join("\n")}\n"
      else
        # lオプションがなければ、画面の大きさに合わせてファイルを列表示するよう文字列（@answer_string)を設定する
        get_answer_string(file_array)
      end
    end

    # ディレクトリの配列があれば、それらを表示
    unless @directory_array.empty?
      # ディレクトリの配列をソートする
      @directory_array.sort!
      # rオプションがあれば、ディレクトリ名配列を逆順にする
      @directory_array.reverse! if @option_hash[:r]
      @answer_string += "\n" unless @wildcard_file_array.empty?
      @directory_array.each_with_index do |dir, idx|
        # ディレクトリの配列が１つより多いか、マッチしないまたはマッチするファイルがあれば、ディレクトリ名を表示する
        @answer_string += "#{dir}:\n" if @directory_array.size > 1 || !@not_match_file_array.empty? || !@wildcard_file_array.empty?
        # ディレクトリ内のディレクトリかファイルを配列で得て返す
        directory_file_array = get_directory_file_array(dir)
        # ディレクトリかファイルの配列にオプションを適用し、適用後の配列を返す
        directory_file_array = apply_options(directory_file_array, dir)
        # lオプションがあれば、ディレクトリかファイルごとに１行で表示するよう文字列(@answer_string)を設定する
        if @option_hash[:l]
          @answer_string += "#{directory_file_array.join("\n")}\n"
        # lオプションがなければ、画面の大きさに合わせてディレクトリかファイルを列表示するよう文字列（@answer_string)を設定する
        else
          get_answer_string(directory_file_array)
        end
        @answer_string += "\n" if @directory_array.size - 1 != idx
      end
    end
    print @answer_string
    @answer_string
  end
end

if __FILE__ == $PROGRAM_NAME
  ls = Ls.new(ARGV)
  ls.ls
end
