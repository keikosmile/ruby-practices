#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require 'optparse'
require_relative 'long_format_file'

class Ls
  def initialize
    @option_hash = {:a=>false, :l=>false, :r=>false}
    @wildcard_directory_array = []
    @not_match_wildcard_array = []
    @not_match_file_array = []
    @wildcard_file_array = []
    @directory_array = []
    @answer_string = ""
  end

  def argv_parse(argv_array)
    opt = OptionParser.new
    opt.on('-a') {|v| v}
    opt.on('-l') {|v| v}
    opt.on('-r') {|v| v}
    opt.order!(argv_array, into: @option_hash)
    @wildcard_directory_array = argv_array
  end

  def separate_directory_wildcard_array
    # オプション以外の配列は空か
    if @wildcard_directory_array.empty?
      @directory_array.push("./")
    else
      @wildcard_directory_array.each do |i|
        # ディレクトリ名か
        if FileTest.directory?(i)
          @directory_array.push(i)
        # ワイルドカードか
        elsif i.include?("*") || i.include?("?") || (i.include?("[") && i.include?("]")) || (i.include?("{") && i.include?("}")) || i.include?("**/")
          file_array = Dir.glob(i)
          # ワイルドカードがマッチしなければ
          if file_array.empty?
            @not_match_wildcard_array.push(i)
          # ワイルドカードがマッチすれば
          else
            @wildcard_file_array.push(file_array)
          end
        # ファイルなら
        else
          if FileTest.exist?(i)
            @wildcard_file_array.push(i)
          else
            @not_match_file_array.push(i)
          end
        end
      end
    end
    #p "directory_array = #{@directory_array}"
    #p "wildcard_file_array = #{@wildcard_file_array}"
  end

  def ls
    separate_directory_wildcard_array

    # マッチしないワイルドカードがあれば、それを表示し終了
    unless @not_match_wildcard_array.empty?
      @answer_string = "zsh: no matches found: #{@not_match_wildcard_array[0]}\n"
      p @answer_string
      print @answer_string
      return @answer_string
    end

    # マッチしないファイル名があれば、それを表示
    unless @not_match_file_array.empty?
      @not_match_file_array.sort!
      @not_match_file_array.each do |f|
        # 提出時に\nを\tにして横並びにし、最後に\nを入れる
        @answer_string += "ls: #{f}: No such file or directory\n"
      end
    end

    # マッチするワイルドカードかファイル名があれば、それらを１行で表示
    unless @wildcard_file_array.empty?
      # 配列を一重にする
      @wildcard_file_array.flatten!
      # オプションを適用する
      file_array = apply_options(@wildcard_file_array, "")
      #p "file_array #{file_array}"
      # 提出時にjoinを\tにして横並びにする
      @answer_string += file_array.join("\n") + "\n"
    end

    # ディレクトリ名配列があれば、それらを表示
    unless @directory_array.empty?
      # ディレクトリ名配列をソートする
      @directory_array.sort!
      # rオプションがあれば、ディレクトリ名配列を逆順にする
      if @option_hash[:r]
        @directory_array.reverse!
      end
      unless @wildcard_file_array.empty?
        @answer_string += "\n"
      end

      @directory_array.each_with_index do |dir, idx|
        if @directory_array.size > 1 || !@not_match_file_array.empty? || !@wildcard_file_array.empty?
          @answer_string += "#{dir}:\n"
        end
        # ディレクトリ内のディレクトリかファイルを配列で得る
        directory_file_array = get_directory_file_array(dir)
        #p "directory_file_array #{directory_file_array}"
        # ディレクトリかファイルの配列にオプションを適用する
        directory_file_array = apply_options(directory_file_array, dir)
        # 提出時にjoinを\tにして横並びにする
        @answer_string += directory_file_array.join("\n") + "\n"
        if @directory_array.size - 1 != idx
          @answer_string += "\n"
        end
      end
    end

    p @answer_string
    print @answer_string
    @answer_string
  end

  # ディレクトリ内のディレクトリかファイルを配列で得る
  def get_directory_file_array(dir)
    directory_file_array = []
    Dir.foreach(dir) do |directory_file_string|
      directory_file_array.push(directory_file_string)
    end
    directory_file_array
  end

  # ファイルの配列にオプションを適用する
  def apply_options(directory_file_array, dir)
    # . ./ .. .xx ./.xx ../.xx ../../../.xx などを除かずに残す
    unless @option_hash[:a]
      directory_file_array.delete_if do |f|
        #p File.basename(f, ".*")
        f.eql?(".") || f.eql?("./") || f.eql?("..") || File.basename(f).start_with?(".")
      end
    end
    #p "directory_file_array = #{directory_file_array}"

    directory_file_array.sort!
    if @option_hash[:r]
      directory_file_array.reverse!
    end

    if @option_hash[:l]
      long_format_file_array = []
      # ロングフォーマット形式ファイルのインスタンスを作成し、配列に挿入する
      directory_file_array.each do |file|
        if dir == "."
          dir = "./"
        end
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

      unless dir.empty?
        @answer_string += "total #{total}\n"
      end

      # 最高幅に合わせて、右寄せ・左寄せする
      long_format_file_array.each do |long|
        long.set_string_width(max_nlink, max_username, max_groupname, max_size)
      end

      directory_file_array.each_with_index do |file, idx|
        file.replace(long_format_file_array[idx].get_string)
      end
    end
    #p "directory_file_array = #{directory_file_array}"
    directory_file_array
  end
end

if __FILE__ == $PROGRAM_NAME
  ls = Ls.new
  ls.argv_parse(ARGV)
  ls.ls
end
