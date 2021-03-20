# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

class NotMatchedDirectoriesFiles
  def initialize
    @not_matched_directories_files_array = []
  end

  # マッチしないディレクトリ・ファイル配列に追加する
  def push(directory_file)
    @not_matched_directories_files_array.push(directory_file)
  end

  # マッチしないディレクトリ・ファイル配列はあるか？
  def exist?
    !@not_matched_directories_files_array.empty?
  end

  # マッチしないディレクトリ・ファイル配列があれば、マッチしないディレクトリ・ファイルクラスに対する答えの文字列を得て返す
  def answer_string
    answer_string = ''
    if exist?
      @not_matched_directories_files_array.sort!
      @not_matched_directories_files_array.each do |directory_file|
        answer_string += "ls: #{directory_file}: No such file or directory\n"
      end
    end
    # 答えの文字列を返す
    answer_string
  end
end
