# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require 'io/console/size'
require_relative 'wildcard_test'
require_relative 'long_format_file'

# オプション以外のコマンドライン引数の配列
class WildDirFile
  include WildcardTest

  def initialize(argv_array, option_hash)
    @option_hash = option_hash
    @not_match_wildcard_array = []
    @directory_file_array = []
    @directory_array = []
    @file_array = []
    @not_match_directory_file_array = []
    @answer_string = ''
    @console_width = IO.console_size.last
    @tabsize = 8

    # オプション以外のコマンドライン引数は空か
    if argv_array.empty?
      @directory_array.push('./')
    # オプション以外のコマンドライン引数を、ディレクトリ・ワイルドカード・ファイルの配列に分ける
    else
      separate_wildcard_directory_file_array(argv_array)
    end
  end

  # オプション以外のコマンドライン引数を、ディレクトリ・ワイルドカード・ファイルの配列に分ける
  def separate_wildcard_directory_file_array(argv_array)
    # ワイルドカードを含む文字列を展開し、マッチしない文字列、ディレクトリ・ファイル配列に分ける
    argv_array.each do |i|
      # ワイルドカードを含むなら
      if wildcard?(i)
        # ワイルドカードを満たす文字列の配列を得る
        wildcard_array = Dir.glob(i)
        # p "wildcard_array = #{wildcard_array}"
        # ワイルドカードを満たす文字列が空なら、マッチしない配列に挿入
        if wildcard_array.empty?
          @not_match_wildcard_array.push(i)
        # ワイルドカードを満たす文字列を、ディレクトリ・ファイル配列に挿入
        else
          @directory_file_array.push(wildcard_array)
        end
      # ワイルドカードを含まないなら、ディレクトリ・ファイル配列に挿入
      else
        @directory_file_array.push(i)
      end
    end

    # ディレクトリ・ファイル配列を、ディレクトリ配列、ファイル配列、マッチしないファイル配列に分ける
    @directory_file_array.flatten!
    @directory_file_array.each do |i|
      # ディレクトリなら
      if FileTest.directory?(i)
        @directory_array.push(i)
      # ファイルなら
      elsif FileTest.exist?(i)
        @file_array.push(i)
      # 存在しないファイルかディレクトリなら
      else
        @not_match_directory_file_array.push(i)
      end
    end

    # p "not_match_wildcard_array = #{@not_match_wildcard_array}"
    # p "directory_file_array = #{@directory_file_array}"
    # p "directory_array = #{@directory_array}"
    # p "file_array = #{@file_array}"
    # p "not_match_directory_file_array = #{@not_match_directory_file_array}"
  end

  # マッチしないワイルドカード配列はあるか？
  def not_match_wildcard_array_exist?
    !@not_match_wildcard_array.empty?
  end

  # マッチしないワイルドカードに対する答えの文字列を設定する
  def set_answer_not_match_wildcard
    @answer_string = "zsh: no matches found: #{@not_match_wildcard_array[0]}\n"
  end

  # マッチしないディレクトリかファイル配列はあるか？
  def not_match_directory_file_array_exist?
    !@not_match_directory_file_array.empty?
  end

  # マッチしないディレクトリかファイルに対する答えの文字列を設定する
  def set_answer_not_match_directory_file
    @not_match_directory_file_array.sort!
    @not_match_directory_file_array.each do |df|
      @answer_string += "ls: #{df}: No such file or directory\n"
    end
  end

  # マッチするファイル配列はあるか？
  def file_array_exist?
    !@file_array.empty?
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

  # 画面の大きさに合わせてディレクトリかファイルを列表示するよう答えの文字列を設定する
  # !!!!!!! [] が来たとき、エラーになっている！！！！！！
  def calculate_answer_string_column(directory_file_array)
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

  # マッチするファイルに対する答えの文字列を設定する
  def set_answer_file
    # 配列を一重にする
    # @wildcard_file_array.flatten!
    # ファイルの配列にオプションを適用し、適用後の配列を返す
    file_array = apply_options(@file_array, '')
    # lオプションがあれば、ファイルごとに１行で表示するよう答えの文字列を設定する
    if @option_hash[:l]
      @answer_string += "#{file_array.join("\n")}\n"
    else
      # lオプションがなければ、画面の大きさに合わせてファイルを列表示するよう答えの文字列を設定する
      calculate_answer_string_column(file_array)
    end
  end

  # マッチするディレクトリ配列はあるか？
  def directory_array_exist?
    !@directory_array.empty?
  end

  # ディレクトリ内のディレクトリかファイルを配列で得て返す
  def get_directory_file_array(dir)
    directory_file_array = []
    Dir.foreach(dir) do |directory_file_string|
      # p "#{dir} #{directory_file_string}"
      directory_file_array.push(directory_file_string)
    end
    directory_file_array
  end

  # マッチするディレクトリに対する答えの文字列を設定する
  def set_answer_directory
    # マッチするファイル配列があれば、答えの文字列に改行を設定する
    @answer_string += "\n" if file_array_exist?
    # ディレクトリの配列をソートする
    @directory_array.sort!
    # rオプションがあれば、ディレクトリ名配列を逆順にする
    @directory_array.reverse! if @option_hash[:r]

    @directory_array.each_with_index do |dir, idx|
      # ディレクトリの配列が１つより多いか、マッチしない・するファイルがあれば、ディレクトリ名を設定する
      @answer_string += "#{dir}:\n" if @directory_array.size > 1 || not_match_directory_file_array_exist? || file_array_exist?
      # ディレクトリ内のディレクトリかファイルを配列で得て返す
      directory_file_array = get_directory_file_array(dir)
      # p directory_file_array
      # ディレクトリかファイルの配列にオプションを適用し、適用後の配列を返す
      directory_file_array = apply_options(directory_file_array, dir)
      # p directory_file_array
      # lオプションがあれば、ディレクトリかファイルごとに１行で表示するよう答えの文字列を設定する

      if @option_hash[:l]
        @answer_string += "#{directory_file_array.join("\n")}\n"
      # lオプションがなければ、画面の大きさに合わせてディレクトリかファイルを列表示するよう答えの文字列を設定する
      else
        calculate_answer_string_column(directory_file_array) unless directory_file_array.empty?
      end
      # ディレクトリの配列で最後の要素以外は、改行を答えの文字列に設定する
      @answer_string += "\n" if @directory_array.size - 1 != idx
    end
  end

  # 答えの文字列を表示し返す
  def show_answer_string
    print @answer_string
    @answer_string
  end
end
