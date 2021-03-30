# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require 'io/console/size'
require_relative 'long_format_file'

module DirectoriesFilesMethods
  # aオプションを適用する
  def apply_a_option(directories_files_array)
    # . ./ .. .xx ./.xx ../.xx ../../../.xx などを除く
    directories_files_array.delete_if do |f|
      f.eql?('.') || f.eql?('./') || f.eql?('..') || File.basename(f).start_with?('.')
    end
  end

  # rオプションを適用する
  def apply_r_option(directories_files_array)
    # 逆順にする
    directories_files_array.reverse!
  end

  # lオプションを適用し、総ブロック数を返す
  def apply_l_option(dir, directories_files_array)
    long_format_files_array = []
    # ロングフォーマットファイル形式のクラスインスタンスを作成し、配列に挿入する
    directories_files_array.each do |file|
      long_format_files_array.push(LongFormatFile.new(dir, file))
    end

    # ロングフォーマット形式ファイル毎の各インスタンス変数のlengthを得て、最高幅を決める
    max_nlink = max_username = max_groupname = max_size = total_blocks = 0
    long_format_files_array.each do |file|
      max_nlink = (file.nlink.length > max_nlink ? file.nlink.length : max_nlink)
      max_username = (file.username.length > max_username ? file.username.length : max_username)
      max_groupname = (file.groupname.length > max_groupname ? file.groupname.length : max_groupname)
      max_size = (file.size.length > max_size ? file.size.length : max_size)
      total_blocks += file.blocks
    end

    # ロングフォーマットファイル形式の文字列を得て、入れ替える
    idx = 0
    directories_files_array.map! do
      # ロングフォーマットファイル形式の文字列を得る
      long_format_file = long_format_files_array[idx]
      idx += 1
      # 最高幅に合わせて、右寄せ・左寄せする
      long_format_file.set_string_width(max_nlink, max_username, max_groupname, max_size)
      # ディレクトリ・ファイル配列の要素を、ロングフォーマットファイル形式の文字列と入れ替える
      long_format_file.long_format_file_string
    end

    # 総ブロック数を返す
    total_blocks
  end

  # ディレクトリ・ファイル配列にa/r/lオプションを適用し、総ブロック数を返したか否か、総ブロック数を返す
  def apply_options(option_hash, dir, directories_files_array)
    # aオプションがfalseなら、適用する
    apply_a_option(directories_files_array) unless option_hash[:a]
    directories_files_array.sort!

    # rオプションがtrueなら、適用する
    apply_r_option(directories_files_array) if option_hash[:r]

    # lオプションがtrueなら、適用する（ロングフォーマット形式の配列にし、総ブロック数を表示し返す）
    total_blocks_boolean = false
    total_blocks = 0
    if option_hash[:l]
      total_blocks = apply_l_option(dir, directories_files_array)
      # ディレクトリ・ファイル配列が空でなければ、総ブロック数を表示する
      total_blocks_boolean = true unless directories_files_array.empty?
    end
    # 総ブロック数を表示するか否か、総ブロック数を返す
    [total_blocks_boolean, total_blocks]
  end

  # ASCII文字を1文字、非ASCII文字（マルチバイト文字）を2文字としてカウントし、文字列の長さを返す（表示用）
  def ascii_length_x2(string)
    string.length + string.chars.count { |c| !c.ascii_only? }
  end

  # ASCII文字を1文字、非ASCII文字（マルチバイト文字）を3文字としてカウントし、文字列の長さを返す（実際の計算用）
  def ascii_length_x3(string)
    string.length + (string.chars.count { |c| !c.ascii_only? } * 2)
  end

  # ディレクトリ・ファイル配列の各要素にタブを必要数挿入する
  def add_tabs(directories_files_array, max_directory_file_1tab_length, tabsize)
    directories_files_array.map! do |directory_file|
      # 最長の文字列の長さ - 各要素の文字列の長さ から、残りの文字数を得る
      remainder = max_directory_file_1tab_length - ascii_length_x2(directory_file)
      # 残りの文字数のタブの個数を得る
      tab_times = remainder / tabsize
      # 残りの文字数から、タブで割り切れずさらに残った文字数を得る
      tab_remainder = remainder % tabsize
      # さらに残った文字数があれば、タブの個数を１つ繰り上げる
      tab_times += (tab_remainder.zero? ? 0 : 1)
      # ディレクトリ・ファイル配列の各要素に、タブを足して書き換える
      directory_file + "\t" * tab_times
    end
  end

  # コンソール幅に合わせてディレクトリ・ファイル配列の列を設定し、各要素にタブを挿入し、列・行数を返す
  def columns_rows(directories_files_array)
    # コンソール幅を得る
    console_width = IO.console_size.last
    # １タブに対する文字数を設定する
    tabsize = 8

    # ディレクトリ・ファイル配列のなかで、最長の文字列の長さを得る
    max_directory_file_1tab_length = 0
    directories_files_array.each do |directory_file|
      # ディレクトリ・ファイル名から、ASCII文字を1文字、非ASCII文字（マルチバイト文字）を3文字としてカウントした文字列の長さを得て、その中で使われているタブの個数を得る
      tab_times = ascii_length_x3(directory_file) / tabsize
      # ディレクトリ・ファイル名 + 1tabとした時の、文字列の長さを得る
      directory_file_1tab_length = tabsize * (tab_times + 1)
      # ディレクトリ・ファイル配列のなかで、最長の文字列の長さを得る
      max_directory_file_1tab_length = directory_file_1tab_length > max_directory_file_1tab_length ? directory_file_1tab_length : max_directory_file_1tab_length
    end

    # 最長の文字列の長さによって、tab_timesを増やす
    # コンソール幅 / 最長の文字列の長さ から、 列数を得る
    columns = console_width / max_directory_file_1tab_length
    # ディレクトリ・ファイル配列の要素数が列数より少なければ、要素数を列数とする
    columns = (directories_files_array.count < columns ? directories_files_array.count : columns)

    # 要素数 / 列数 から、行数を得る (余がでたら１つ繰り上がる)
    rows = directories_files_array.count / columns
    modulo = directories_files_array.count % columns
    rows += (modulo.zero? ? 0 : 1)

    # 最小限の行数になった上で、改めて列数を計算する
    columns = directories_files_array.count / rows

    # ディレクトリ・ファイル配列の各要素にタブを必要数挿入する
    add_tabs(directories_files_array, max_directory_file_1tab_length, tabsize)

    # 列・行数を返す
    [columns, rows]
  end

  # コンソール幅に合わせてディレクトリ・ファイル配列を列表示するよう答えの文字列を設定し返す
  def answer_string_column(directories_files_array)
    # コンソール幅に合わせてディレクトリ・ファイル配列の列を設定し、各要素にタブを挿入し、列・行数を返す
    columns, rows = columns_rows(directories_files_array)
    # ディレクトリ・ファイル配列を列で揃えた１行ずつに並べ直し、１行ずつ答えの文字列を得る
    row = 0
    answer_string = ''
    while row < rows
      # １行ずつディレクトリ・ファイル名を列で揃える
      row_array = []
      column = 0
      while column <= columns
        directory_file = directories_files_array[row + rows * column]
        row_array.push(directory_file) unless directory_file.nil?
        column += 1
      end
      # 最後にpushした要素の\t\t..を\nに変換する
      row_array_last_directory_file = row_array.last.delete("\t")
      row_array[row_array.size - 1] = "#{row_array_last_directory_file}\n"
      # 列を揃えた答えの文字列１行を得る
      answer_string += row_array.join
      row += 1
    end
    # 答えの文字列を返す
    answer_string
  end
end
