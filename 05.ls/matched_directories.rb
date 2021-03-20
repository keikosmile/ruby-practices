# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

require_relative 'directories_files_methods'

class MatchedDirectories
  include DirectoriesFilesMethods

  def initialize(option_hash)
    @option_hash = option_hash
    @matched_directories_array = []
  end

  # ディレクトリ文字列をマッチするディレクトリ配列に追加する
  def push(directory)
    @matched_directories_array.push(directory)
  end

  # マッチするディレクトリ配列はあるか？
  def exist?
    !@matched_directories_array.empty?
  end

  # ディレクトリごとに、答えの文字列を得て追加する
  def each_directories_answer_string(answer_string, directory_boolean)
    @matched_directories_array.each_with_index do |dir, idx|
      # ディレクトリごとにディレクトリ名を答えの文字列に設定する
      answer_string += "#{dir}:\n" if directory_boolean
      # ディレクトリ内のディレクトリかファイルを配列で得て返す
      directories_files_array = Dir.entries(dir)
      # ディレクトリかファイルの配列にa/r/lオプションを適用し、総ブロック数を表示するか否か、総ブロック数を返す
      total_blocks_boolean, total_blocks = apply_options(@option_hash, dir, directories_files_array)
      # 総ブロック数を答えの文字列に追加する
      answer_string += "total #{total_blocks}\n" if total_blocks_boolean
      # ディレクトリかファイル配列が空でなければ
      unless directories_files_array.empty?
        # lオプションがあれば、ディレクトリ・ファイル配列ごとに１行で表示するよう答えの文字列を設定する
        answer_string +=  if @option_hash[:l]
                            "#{directories_files_array.join("\n")}\n"
                          # lオプションがなければ、コンソール幅に合わせてディレクトリ・ファイル配列を列表示するよう答えの文字列を設定する
                          else
                            answer_string_column(directories_files_array)
                          end
      end
      # マッチするディレクトリ配列で最後の要素以外は、改行を答えの文字列に設定する
      answer_string += "\n" if idx != @matched_directories_array.size - 1
    end
    # 答えの文字列を設定する
    answer_string
  end

  # マッチするディレクトリ配列があれば、マッチするディレクトリクラスに対する答えの文字列を得る
  def answer_string(not_matched_directories_files_boolean, matched_files_boolean)
    answer_string = ''
    if exist?
      # マッチするファイル配列があれば、１行あける
      answer_string += "\n" if matched_files_boolean

      # マッチするディレクトリ配列をソートする
      @matched_directories_array.sort!
      # rオプションがあれば、マッチするディレクトリ配列を逆順にする
      @matched_directories_array.reverse! if @option_hash[:r]

      # マッチするディレクトリ配列が１要素より多いか、マッチしないディレクトリ・ファイル配列、マッチするファイル配列があれば、ディレクトリごとにディレクトリ名を設定するようにする
      directory_boolean = if @matched_directories_array.size > 1 || not_matched_directories_files_boolean || matched_files_boolean
                            true
                          else
                            false
                          end
      # ディレクトリごとに、答えの文字列を得て追加する
      answer_string = each_directories_answer_string(answer_string, directory_boolean)
    end
    # 答えの文字列を返す
    answer_string
  end
end
