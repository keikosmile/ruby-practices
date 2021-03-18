#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require 'optparse'
require_relative 'wild_dir_file'

class Ls
  def initialize(argv_array)
    # コマンドライン引数を、インスタンス変数に格納する
    @option_hash = { a: false, l: false, r: false }
    @wild_dir_file = WildDirFile.new(argv_parse(argv_array), @option_hash)
  end

  # コマンドライン引数を受け取り、オプションはハッシュに格納し、残りは配列で返す
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

  def ls
    # マッチしないワイルドカード配列はあるか？
    if @wild_dir_file.not_match_wildcard_array_exist?
      # マッチしないワイルドカードに対する答えの文字列を設定する
      @wild_dir_file.set_answer_not_match_wildcard
      # 答えの文字列を表示し終了
      return @wild_dir_file.show_answer_string
    end

    # マッチしないディレクトリかファイル配列はあるか？
    if @wild_dir_file.not_match_directory_file_array_exist?
      # マッチしないディレクトリかファイルに対する答えの文字列を設定する
      @wild_dir_file.set_answer_not_match_directory_file
    end

    # マッチするファイル配列はあるか？
    if @wild_dir_file.file_array_exist?
      # マッチするファイルに対する答えの文字列を設定する
      @wild_dir_file.set_answer_file
    end

    # マッチするディレクトリ配列はあるか？
    if @wild_dir_file.directory_array_exist?
      # マッチするディレクトリに対する答えの文字列を設定する
      @wild_dir_file.set_answer_directory
    end

    # 答えの文字列を表示し返す
    @wild_dir_file.show_answer_string
  end
end

if __FILE__ == $PROGRAM_NAME
  ls = Ls.new(ARGV)
  ls.ls
end
