# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require_relative 'directories_files_methods'

class MatchedFiles
  include DirectoriesFilesMethods

  def initialize(option_hash)
    @option_hash = option_hash
    @matched_files_array = []
  end

  # マッチするファイル配列に追加する
  def push(file)
    @matched_files_array.push(file)
  end

  # マッチするファイル配列はあるか？
  def exist?
    !@matched_files_array.empty?
  end

  # マッチするファイル配列があれば、マッチするファイルクラスに対する答えの文字列を得て返す
  def answer_string
    answer_string = ''
    if exist?
      # ファイルの配列にオプションを適用し、適用後の配列を返す
      apply_options(@option_hash, '', @matched_files_array)
      # lオプションがあれば、ファイル配列ごとに１行で表示するよう答えの文字列を設定する
      answer_string +=  if @option_hash[:l]
                          "#{@matched_files_array.join("\n")}\n"
                        else
                          # lオプションがなければ、コンソール幅に合わせてファイル配列を列表示するよう答えの文字列を設定し返す
                          answer_string_column(@matched_files_array)
                        end
    end
    # 答えの文字列を返す
    answer_string
  end
end
