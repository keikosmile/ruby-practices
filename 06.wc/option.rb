# 文字列をimmutable（破壊的変更不可）にする
# frozen_string_literal: true

class Option
  attr_accessor :option_hash

  def initialize
    @option_hash = { l: false, w: false, c: false, m: false }
    @total_hash = { l: 0, w: 0, c: 0, m: 0 }
  end

  def apply_option(buf)
    string = ''
    string += apply_l_option(buf) if @option_hash[:l]
    string += apply_w_option(buf) if @option_hash[:w]
    string += apply_c_option(buf) if @option_hash[:c]
    string += apply_m_option(buf) if @option_hash[:m]
    string
  end

  # l オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_l_option(buf)
    # 行数を数える（@bufが不正なバイト列を含む場合?に置き換える）
    n_line = buf.scrub.count("\n")
    @total_hash[:l] += n_line
    n_line.to_s.rjust(8)
  end

  # w オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_w_option(buf)
    # 文字列がascii文字だけの場合
    if buf.ascii_only?
      n_word = buf.split.count
    else
      # 空白文字
      # 空白    ' ' : 0x20
      # 改頁    \f  : 0x0C
      # 改行    \n  : 0xA
      # 復帰    \r  : 0x0D
      # 水平タブ \t  : 0x09
      # 垂直タブ \v  : 0x0B
      # ノーブレークスペース  : 0x85
      wspace_array = %w[20 0C A 0D 09 0B 85]

      # 文字列をUTF-8で符号化しバイト単位に分割、16進数表記に変換する
      buf_array = buf.bytes.map do |b|
        b.to_s(16).upcase
      end
      # 空白文字で区切られた単語数を数える
      word_flag = 1
      n_word = 0
      buf_array.each do |b|
        if wspace_array.include?(b)
          word_flag = 1
        elsif word_flag == 1
          word_flag = 0
          n_word += 1
        end
      end
    end
    @total_hash[:w] += n_word
    n_word.to_s.rjust(8)
  end

  # c オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_c_option(buf)
    # バイト数を数える（文字列のバイト長を整数で返す）
    n_bytesize = buf.bytesize
    @total_hash[:c] += n_bytesize
    n_bytesize.to_s.rjust(8)
  end

  # m オプションを適用し、1文字のスペースと７桁の数字からなる文字列を得る
  def apply_m_option(buf)
    # 文字数を数える（マルチバイト文字1文字を1文字と数える）
    n_size = buf.size
    @total_hash[:m] += n_size
    n_size.to_s.rjust(8)
  end

  # total の値を ＠answer_string に書き込む
  def write_total
    string = ''
    string += @total_hash[:l].to_s.rjust(8) if @option_hash[:l]
    string += @total_hash[:w].to_s.rjust(8) if @option_hash[:w]
    string += @total_hash[:c].to_s.rjust(8) if @option_hash[:c]
    string += @total_hash[:m].to_s.rjust(8) if @option_hash[:m]
    string += " total\n"
    string
  end
end
