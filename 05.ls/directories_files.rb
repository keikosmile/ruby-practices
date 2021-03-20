# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require_relative 'not_matched_directories_files'
require_relative 'matched_files'
require_relative 'matched_directories'

class DirectoriesFiles
  def initialize(option_hash)
    # マッチしないディレクトリ・ファイルクラスインスタンス
    @not_matched_directories_files = NotMatchedDirectoriesFiles.new
    # ディレクトリ・ファイル配列
    @directories_files_array = []
    # マッチするファイルクラスインスタンス
    @matched_files = MatchedFiles.new(option_hash)
    # マッチするディレクトリクラスインスタンス
    @matched_directories = MatchedDirectories.new(option_hash)
  end

  # ディレクトリ・ファイル文字列の配列を、ディレクトリ・ファイル配列に追加する
  def directories_files_push(directory_file_array)
    @directories_files_array.push(directory_file_array)
  end

  # ディレクトリ文字列を、ディレクトリ配列に追加する
  def directory_push(directory)
    @matched_directories.push(directory)
  end

  # ディレクトリ・ファイル配列を、マッチするディレクトリクラスインスタンス、マッチするファイルクラスインスタンス、マッチしないディレクトリ・ファイルクラスインスタンスに分けて追加する
  def separate_directory_file_array
    @directories_files_array.flatten!
    @directories_files_array.each do |string|
      # ディレクトリなら、マッチするディレクトリクラスインスタンスに追加する
      if FileTest.directory?(string)
        @matched_directories.push(string)
      # ファイルなら、マッチするファイルクラスインスタンスに追加する
      elsif FileTest.exist?(string)
        @matched_files.push(string)
      # 存在しないディレクトリ・ファイルなら、マッチしないディレクトリ・ファイルクラスインスタンスに追加する
      else
        @not_matched_directories_files.push(string)
      end
    end
  end

  # ディレクトリ・ファイルクラスインスタンスから、答えの文字列を得て返す
  def answer_string
    answer_string = ''
    # マッチしないディレクトリ・ファイルクラスインスタンスから、答えの文字列を得る
    answer_string += @not_matched_directories_files.answer_string
    # マッチするファイルクラスインスタンスから、答えの文字列を得る
    answer_string += @matched_files.answer_string
    # マッチするディレクトリクラスインスタンスから、答えの文字列を得る
    answer_string += @matched_directories.answer_string(@not_matched_directories_files.exist?, @matched_files.exist?)
    # 答えの文字列を返す
    answer_string
  end
end
