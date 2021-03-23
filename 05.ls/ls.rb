#!/usr/bin/env ruby

# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require 'optparse'
require_relative 'wildcards_directories_files'

class Ls
  def initialize(argv_array)
    @option_hash = { a: false, l: false, r: false }
    # コマンドライン引数を、オプションのハッシュとワイルドカード・ディレクトリ・ファイルクラスインスタンスに分けて格納する
    @wildcards_directories_files = WildcardsDirectoriesFiles.new(argv_parse(argv_array), @option_hash)
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
    # ワイルドカード・ディレクトリ・ファイルクラスインスタンスのうち、マッチしないワイルドカード配列に対する処理をする
    answer_string = @wildcards_directories_files.not_matched_wildcards_exec
    # 答えの文字列があれば、表示して終了
    unless answer_string.empty?
      print answer_string
      return answer_string
    end

    # ワイルドカード・ディレクトリ・ファイルクラスインスタンスのうち、マッチしないディレクトリ・ファイル配列、マッチするファイル配列、マッチするディレクトリ配列、に対する処理をする
    answer_string = @wildcards_directories_files.directories_files_exec
    # 答えの文字列を表示し返す
    print answer_string
    answer_string
  end
end

if __FILE__ == $PROGRAM_NAME
  ls = Ls.new(ARGV)
  ls.ls
end
