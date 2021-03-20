# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require_relative 'not_matched_wildcards'
require_relative 'directories_files'

class WildcardsDirectoriesFiles
  def initialize(argv_array, option_hash)
    # ワイルドカードにマッチしないクラスインスタンス
    @not_matched_wildcards = NotMatchedWildcards.new
    # ディレクトリ・ファイルクラスインスタンス
    @directories_files = DirectoriesFiles.new(option_hash)

    # オプション以外のコマンドライン引数は空か
    if argv_array.empty?
      @directories_files.directory_push('./')
    else
      # オプション以外のコマンドライン引数を、ワイルドカードにマッチしないクラスインスタンス、ディレクトリ・ファイルクラスインスタンスに分ける
      separate_not_matched_wildcards(argv_array)
      # ディレクトリ・ファイルクラスインスタンスのなかで、マッチするディレクトリ配列、マッチするファイル配列、マッチしないディレクトリ・ファイル配列に分ける
      @directories_files.separate_directory_file_array
    end
  end

  # 文字列がワイルドカードを含むか判定する
  def wildcard?(str)
    str.include?('*') || str.include?('?') || (str.include?('[') && str.include?(']')) || (str.include?('{') && str.include?('}')) || str.include?('**/')
  end

  # オプション以外のコマンドライン引数を、ワイルドカードにマッチしないクラスインスタンス、ディレクトリ・ファイルクラスインスタンスに分ける
  def separate_not_matched_wildcards(argv_array)
    argv_array.each do |string|
      # ワイルドカードを含むなら
      if wildcard?(string)
        # ワイルドカードを満たす文字列の配列を得る
        wildcards_array = Dir.glob(string)
        # ワイルドカードを満たす文字列の配列が空なら、ワイルドカードにマッチしないクラスインスタンスに追加
        if wildcards_array.empty?
          @not_matched_wildcards.push(string)
        # ワイルドカードを満たす文字列の配列を、ディレクトリ・ファイルクラスインスタンスに追加
        else
          @directories_files.directories_files_push(wildcards_array)
        end
      # ワイルドカードを含まないなら、ディレクトリ・ファイルクラスインスタンスに追加
      else
        @directories_files.directories_files_push(string)
      end
    end
  end

  # ワイルドカードにマッチしないクラスインスタンスに対する答えの文字列を得て返す
  def not_matched_wildcards_exec
    @not_matched_wildcards.answer_string
  end

  # ディレクトリ・ファイルクラスインスタンスに対する答えの文字列を得て返す
  def directories_files_exec
    @directories_files.answer_string
  end
end
