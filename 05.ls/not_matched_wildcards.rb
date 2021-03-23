# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

class NotMatchedWildcards
  def initialize
    @not_matched_wildcards_array = []
  end

  # マッチしないワイルドカード配列に追加する
  def push(string)
    @not_matched_wildcards_array.push(string)
  end

  # マッチしないワイルドカード配列はあるか？
  def exist?
    !@not_matched_wildcards_array.empty?
  end

  # マッチしないワイルドカード配列があれば、マッチしないワイルドカードクラスに対する答えの文字列を得る
  def answer_string
    answer_string = ''
    # マッチしないワイルドカードがあれば、答えの文字列を設定する
    answer_string = "zsh: no matches found: #{@not_matched_wildcards_array[0]}\n" if exist?
    # 答えの文字列を返す
    answer_string
  end
end
